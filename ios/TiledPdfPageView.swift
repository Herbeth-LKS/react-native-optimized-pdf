import UIKit

// View que desenha um PDF usando CATiledLayer.
// CATiledLayer divide o PDF em blocos ("tiles"), permitindo zoom e rolagem
// sem precisar renderizar o PDF inteiro de uma vez.
class TiledPdfPageView: UIView {
    var pdfPage: CGPDFPage?

    // Define o layer como CATiledLayer em vez do CALayer padrão
    override class var layerClass: AnyClass { CATiledLayer.self }
    private var tiledLayer: CATiledLayer { return layer as! CATiledLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTiledLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTiledLayer()
    }

    // Configuração do CATiledLayer
    private func setupTiledLayer() {
        // Tamanho de cada tile (ajustado para balancear memória e performance)
        tiledLayer.tileSize = CGSize(width: 512, height: 512)

        // Número de níveis de detalhe (zoom in/out)
        tiledLayer.levelsOfDetail = 2

        // permite zoom até 256x acima da resolução base
        tiledLayer.levelsOfDetailBias = 8

        // Mantém qualidade de acordo com a tela
        contentScaleFactor = UIScreen.main.scale

        // Fundo branco atrás do PDF
        backgroundColor = .white
    }

    // Renderiza o conteúdo do PDF
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(),
              let page = pdfPage else { return }

        ctx.saveGState()

        // Fundo branco no pedaço atual
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(rect)

        let pageRect = page.getBoxRect(.cropBox)

        // Ajusta coordenadas (UIKit e PDF têm sistemas de coordenadas diferentes)
        ctx.translateBy(x: 0, y: bounds.height)
        ctx.scaleBy(x: 1.0, y: -1.0)

        // Define a transformação para encaixar a página no espaço disponível
        let pdfTransform = page.getDrawingTransform(.cropBox, rect: bounds, rotate: 0, preserveAspectRatio: true)
        ctx.concatenate(pdfTransform)

        // Qualidade da renderização (melhor em zoom, mais rápida em tiles distantes)
        if tiledLayer.levelsOfDetail == 1 {
            ctx.interpolationQuality = .low
        } else {
            ctx.interpolationQuality = .high
        }

        // Desenha a página PDF
        ctx.drawPDFPage(page)
        ctx.restoreGState()
    }
}
