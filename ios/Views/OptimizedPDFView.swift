import UIKit
import React

/// Protocol for receiving PDF view events.
@objc protocol OptimizedPDFViewDelegate: AnyObject {
    @objc optional func pdfView(_ pdfView: OptimizedPDFView, didFailWithError error: Error)
    @objc optional func pdfView(_ pdfView: OptimizedPDFView, didLoadWithPageCount pageCount: Int)
    @objc optional func pdfView(_ pdfView: OptimizedPDFView, didDisplayPage page: Int, size: CGSize)
    @objc optional func pdfViewDidRequestPassword(_ pdfView: OptimizedPDFView)
}

/// A high-performance PDF view using CATiledLayer for smooth zooming and scrolling.
///
/// This view is optimized for React Native integration, providing callbacks for
/// load completion, errors, and page navigation events.
@objc(OptimizedPdfView)
final class OptimizedPDFView: UIScrollView {

    // MARK: - React Native Properties

    /// Path to the PDF file to display.
    @objc var source: String = "" {
        didSet {
            handleSourceChange()
        }
    }

    /// Current page index (0-based).
    @objc var page: NSNumber = 0 {
        didSet {
            handlePageChange(to: page.intValue)
        }
    }

    /// Maximum zoom scale.
    @objc var maximumZoom: NSNumber = 5.0 {
        didSet {
            configuration.maximumZoom = CGFloat(truncating: maximumZoom)
            applyZoomConfiguration()
        }
    }

    /// Whether antialiasing is enabled.
    @objc var enableAntialiasing: Bool = true {
        didSet {
            configuration.enableAntialiasing = enableAntialiasing
            tiledPageView.enableAntialiasing = enableAntialiasing
        }
    }

    /// Password for encrypted PDFs.
    @objc var password: String = "" {
        didSet {
            configuration.password = password.isEmpty ? nil : password
            retryLoadIfNeeded()
        }
    }

    // MARK: - React Native Event Callbacks

    @objc var onError: RCTDirectEventBlock?
    @objc var onLoadComplete: RCTDirectEventBlock?
    @objc var onPageCount: RCTDirectEventBlock?
    @objc var onPasswordRequired: RCTDirectEventBlock?

    // MARK: - Public Properties

    weak var pdfDelegate: OptimizedPDFViewDelegate?

    /// Current number of pages in the document.
    private(set) var pageCount: Int = 0

    // MARK: - Private Properties

    private var pdfDocument: CGPDFDocument?
    private let tiledPageView: TiledPDFPageView
    private var configuration = PDFConfiguration.default
    private let documentLoader: PDFDocumentLoading

    private var pendingPageIndex: Int?
    private var needsLoad = false
    private var lastBoundsSize: CGSize = .zero
    private var currentPageRect: CGRect?
    private var initialZoomScale: CGFloat = 1.0

    // MARK: - Initialization

    override init(frame: CGRect) {
        self.tiledPageView = TiledPDFPageView(frame: frame)
        self.documentLoader = PDFDocumentLoader.shared
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        self.tiledPageView = TiledPDFPageView(frame: .zero)
        self.documentLoader = PDFDocumentLoader.shared
        super.init(coder: coder)
        setupView()
    }

    /// Initializes with a custom document loader (useful for testing).
    init(frame: CGRect, documentLoader: PDFDocumentLoading) {
        self.tiledPageView = TiledPDFPageView(frame: frame)
        self.documentLoader = documentLoader
        super.init(frame: frame)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        setupScrollView()
        setupTiledPageView()
    }

    private func setupScrollView() {
        delegate = self
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        bouncesZoom = true
        applyZoomConfiguration()
    }

    private func setupTiledPageView() {
        tiledPageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tiledPageView.configuration = configuration
        addSubview(tiledPageView)
    }

    private func applyZoomConfiguration() {
        maximumZoomScale = configuration.maximumZoom

        guard let pageRect = currentPageRect else { return }

        let fitScale = calculateFitScale(for: pageRect)
        minimumZoomScale = fitScale
        initialZoomScale = fitScale
    }
}

// MARK: - Document Loading

private extension OptimizedPDFView {

    func handleSourceChange() {
        resetDocument()
        pendingPageIndex = page.intValue
        needsLoad = true
        setNeedsLayout()
    }

    func handlePageChange(to index: Int) {
        guard let document = pdfDocument else {
            pendingPageIndex = index
            return
        }

        let validIndex = clampPageIndex(index, for: document)
        displayPage(at: validIndex)
    }

    func retryLoadIfNeeded() {
        guard !password.isEmpty, pdfDocument == nil, needsLoad else { return }
        setNeedsLayout()
    }

    func resetDocument() {
        pdfDocument = nil
        pageCount = 0
    }

    func loadDocument() {
        guard !source.isEmpty else { return }

        let result = documentLoader.loadDocument(from: source, password: configuration.password)

        switch result {
        case .success(let document):
            handleLoadSuccess(document: document)

        case .failure(let error):
            handleLoadFailure(error: error)
        }
    }

    func handleLoadSuccess(document: CGPDFDocument) {
        pdfDocument = document
        pageCount = document.numberOfPages

        // Emit page count event on next run loop to ensure listeners are connected
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onPageCount?(["numberOfPages": NSNumber(value: self.pageCount)])
            self.pdfDelegate?.pdfView?(self, didLoadWithPageCount: self.pageCount)
        }

        // Display pending or first page
        let targetIndex = pendingPageIndex ?? 0
        pendingPageIndex = nil
        let validIndex = clampPageIndex(targetIndex, for: document)
        displayPage(at: validIndex)
    }

    func handleLoadFailure(error: PDFError) {
        if case .passwordRequired = error {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.onPasswordRequired?([:])
                self.pdfDelegate?.pdfViewDidRequestPassword?(self)
            }
        }

        onError?(error.eventPayload)
        pdfDelegate?.pdfView?(self, didFailWithError: error)
    }

    func clampPageIndex(_ index: Int, for document: CGPDFDocument) -> Int {
        max(0, min(index, document.numberOfPages - 1))
    }
}

// MARK: - Page Display

private extension OptimizedPDFView {

    func displayPage(at index: Int) {
        guard let document = pdfDocument,
              let page = document.page(at: index + 1) else {
            return
        }

        let pageRect = page.getBoxRect(.cropBox)
        currentPageRect = pageRect

        prepareForPageDisplay()
        configureTiledView(for: page, rect: pageRect)
        applyFitScale(for: pageRect)
        centerContent()
        notifyPageDisplayed(index: index, size: pageRect.size)
    }

    func prepareForPageDisplay() {
        zoomScale = 1.0
        contentOffset = .zero
    }

    func configureTiledView(for page: CGPDFPage, rect: CGRect) {
        tiledPageView.updateFrame(for: page)
        contentSize = rect.size
    }

    func applyFitScale(for pageRect: CGRect) {
        let fitScale = calculateFitScale(for: pageRect)
        minimumZoomScale = fitScale
        initialZoomScale = fitScale
        setZoomScale(fitScale, animated: false)
    }

    func notifyPageDisplayed(index: Int, size: CGSize) {
        let payload: [String: Any] = [
            "currentPage": index + 1,
            "width": size.width,
            "height": size.height
        ]

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onLoadComplete?(payload)
            self.pdfDelegate?.pdfView?(self, didDisplayPage: index + 1, size: size)
        }
    }
}

// MARK: - Layout & Scaling

private extension OptimizedPDFView {

    func calculateFitScale(for pageRect: CGRect) -> CGFloat {
        guard bounds.width > 0,
              bounds.height > 0,
              pageRect.width > 0,
              pageRect.height > 0 else {
            return 1.0
        }

        let scaleX = bounds.width / pageRect.width
        let scaleY = bounds.height / pageRect.height
        let scale = min(scaleX, scaleY)

        guard scale.isFinite, scale > 0 else {
            return 1.0
        }

        return scale
    }

    func centerContent() {
        let boundsSize = bounds.size
        var frame = tiledPageView.frame

        frame.origin.x = frame.width < boundsSize.width
            ? (boundsSize.width - frame.width) * 0.5
            : 0

        frame.origin.y = frame.height < boundsSize.height
            ? (boundsSize.height - frame.height) * 0.5
            : 0

        tiledPageView.frame = frame
    }
}

// MARK: - UIScrollViewDelegate

extension OptimizedPDFView: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        tiledPageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
    }
}

// MARK: - Lifecycle

extension OptimizedPDFView {

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.width > 0, bounds.height > 0 else { return }

        if needsLoad {
            needsLoad = false
            loadDocument()
            lastBoundsSize = bounds.size
            return
        }

        handleBoundsChange()
    }

    private func handleBoundsChange() {
        guard lastBoundsSize != bounds.size,
              let pageRect = currentPageRect else {
            centerContent()
            return
        }

        lastBoundsSize = bounds.size
        applyFitScale(for: pageRect)
        centerContent()
    }
}

// MARK: - Public Methods

extension OptimizedPDFView {

    /// Resets the zoom to fit the page.
    @objc func resetZoom() {
        UIView.animate(withDuration: configuration.zoomResetAnimationDuration) { [weak self] in
            guard let self = self else { return }
            self.setZoomScale(self.initialZoomScale, animated: false)
            self.centerContent()
        }
    }

    /// Navigates to a specific page.
    /// - Parameter index: The page index (0-based).
    @objc func goToPage(_ index: Int) {
        page = NSNumber(value: index)
    }
}
