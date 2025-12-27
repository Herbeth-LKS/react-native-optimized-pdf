import UIKit
import PDFKit
import React

// Classe que representa a View personalizada do PDF otimizado.
// É baseada em UIScrollView para permitir zoom e scroll sem travar,
@objc(OptimizedPdfView)
class OptimizedPdfView: UIScrollView, UIScrollViewDelegate {

    // Caminho do arquivo PDF a ser carregado
    @objc var source: String = "" {
        didSet {
            needsLoad = true
            pdfDocument = nil
            pendingPageIndex = Int(truncating: page)
            setNeedsLayout()
        }
    }

    @objc var page: NSNumber = 0 {
        didSet {
            let idx = page.intValue
            if let doc = pdfDocument {
                if idx >= 0, idx < doc.numberOfPages {
                    displayPage(index: idx)
                }
            } else {
                pendingPageIndex = idx
            }
        }
    }

    @objc var maximumZoom: NSNumber = 5.0 {
        didSet {
            self.maximumZoomScale = CGFloat(truncating: maximumZoom)
            if let lastRect = currentPageRect {
                let fit = fitScale(for: lastRect)
                self.minimumZoomScale = fit
                self.initialZoomScale = fit
            }
        }
    }

    @objc var enableAntialiasing: Bool = true {
        didSet {
            tiledView?.enableAntialiasing = enableAntialiasing
            tiledView?.setNeedsDisplay()
        }
    }

    // Eventos enviados para o React Native
    @objc var onError: RCTDirectEventBlock?
    @objc var onLoadComplete: RCTDirectEventBlock?
    @objc var onPageCount: RCTDirectEventBlock?

    // Documento PDF em memória (usando Core Graphics, mais leve que PDFKit para esse caso)
    private var pdfDocument: CGPDFDocument?

    // View responsável por desenhar a página atual usando CATiledLayer
    private var tiledView: TiledPdfPageView!
    private var initialZoomScale: CGFloat = 1.0
    private var needsLoad = false
    private var pendingPageIndex: Int?
    private var lastBoundsSize: CGSize = .zero
    private var currentPageRect: CGRect?

    // Inicializadores
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScrollView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScrollView()
    }

    // Configura a ScrollView para suportar zoom suave e sem travamentos
    private func setupScrollView() {
        delegate = self
        minimumZoomScale = 1.0
        maximumZoomScale = CGFloat(truncating: maximumZoom)
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        bouncesZoom = true // "efeito mola" ao dar zoom

        // Inicializa o tiledView que renderiza as páginas em blocos (tiles)
        tiledView = TiledPdfPageView(frame: bounds)
        tiledView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tiledView.enableAntialiasing = enableAntialiasing
        addSubview(tiledView)
    }

    // Carrega o PDF a partir de um caminho local
    private func loadPdf() {
        guard !source.isEmpty else { return }

        // Remove prefixo "file://" se existir
        let path = source.hasPrefix("file://") ? String(source.dropFirst(7)) : source
        let url = URL(fileURLWithPath: path)

        // Tenta abrir o documento PDF
        guard let doc = CGPDFDocument(url as CFURL) else {
            onError?(["message": "Failed to open PDF at \(source)"])
            return
        }

        pdfDocument = doc

        // Emite evento na próxima iteração do runloop p/ garantir listeners conectados
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onPageCount?(["numberOfPages": NSNumber(value: doc.numberOfPages)])
        }

        // Página desejada (ou 0 se não tiver)
        let idx = (pendingPageIndex ?? 0)
        pendingPageIndex = nil

        displayPage(index: max(0, min(idx, doc.numberOfPages - 1)))
    }

    // MARK: Exibir página
    private func displayPage(index: Int) {
        guard let doc = pdfDocument,
              let pageRef = doc.page(at: index + 1) else { return }

        let pageRect = pageRef.getBoxRect(.cropBox)
        currentPageRect = pageRect

        // Prepara conteúdo
        zoomScale = 1.0
        contentOffset = .zero
        tiledView.pdfPage = pageRef
        tiledView.frame = CGRect(origin: .zero, size: pageRect.size)
        tiledView.setNeedsDisplay()
        contentSize = pageRect.size

        // Fit seguro (só com bounds válidos)
        let fit = fitScale(for: pageRect)
        minimumZoomScale = fit
        initialZoomScale = fit
        setZoomScale(fit, animated: false)
        centerContent()

       // Evento enviado ao RN quando a página carrega
        let w = pageRect.width, h = pageRect.height
        DispatchQueue.main.async { [weak self] in
            self?.onLoadComplete?([ "currentPage": index + 1, "width": w, "height": h])
        }
    }

    // Cálculo de escala sempre com guarda
    private func fitScale(for pageRect: CGRect) -> CGFloat {
        guard bounds.width > 0, bounds.height > 0,
              pageRect.width > 0, pageRect.height > 0 else {
            return 1.0
        }
        let sW = bounds.width / pageRect.width
        let sH = bounds.height / pageRect.height
        let s = min(sW, sH)
        // evita zero/NaN/inf
        if s.isNaN || s.isInfinite || s <= 0 { return 1.0 }
        return s
    }

    private func centerContent() {
        let boundsSize = bounds.size
        var frameToCenter = tiledView.frame

        // Centro horizontal
        frameToCenter.origin.x = (frameToCenter.size.width < boundsSize.width)
            ? (boundsSize.width - frameToCenter.size.width) * 0.5
            : 0

        // Centro vertical
        frameToCenter.origin.y = (frameToCenter.size.height < boundsSize.height)
            ? (boundsSize.height - frameToCenter.size.height) * 0.5
            : 0

        tiledView.frame = frameToCenter
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return tiledView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
    }

    func resetZoom() {
        UIView.animate(withDuration: 0.25) {
            self.setZoomScale(self.initialZoomScale, animated: false)
            self.centerContent()
        }
    }

    // MARK: Layout ciclo
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { setNeedsLayout() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.width > 0, bounds.height > 0 else { return }

        // Carrega o PDF somente agora (props já setadas e bounds válidos)
        if needsLoad {
            needsLoad = false
            loadPdf()
            lastBoundsSize = bounds.size
            return
        }

        // Se mudou o tamanho (ex.: rotação), refaz o fit na página atual
        if lastBoundsSize != bounds.size, let rect = currentPageRect {
            lastBoundsSize = bounds.size
            let fit = fitScale(for: rect)
            minimumZoomScale = fit
            initialZoomScale = fit
            setZoomScale(fit, animated: false)
            centerContent()
        } else {
            centerContent()
        }
    }
}