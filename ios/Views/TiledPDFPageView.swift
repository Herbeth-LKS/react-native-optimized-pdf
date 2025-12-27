import UIKit
import CoreGraphics

/// A view that renders a PDF page using CATiledLayer for efficient tiled rendering.
///
/// CATiledLayer divides the content into tiles, allowing smooth zooming and scrolling
/// without rendering the entire PDF at once. This is essential for large PDF documents.
final class TiledPDFPageView: UIView {

    // MARK: - Properties

    /// The PDF page to render.
    var pdfPage: CGPDFPage? {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Whether antialiasing is enabled for rendering.
    var enableAntialiasing: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }

    /// The configuration for tiled rendering.
    var configuration: PDFConfiguration = .default {
        didSet {
            applyConfiguration()
        }
    }

    /// Returns CATiledLayer as the backing layer.
    override class var layerClass: AnyClass {
        CATiledLayer.self
    }

    /// Typed accessor for the tiled layer.
    private var tiledLayer: CATiledLayer {
        layer as! CATiledLayer
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    /// Initializes with a specific configuration.
    convenience init(frame: CGRect, configuration: PDFConfiguration) {
        self.init(frame: frame)
        self.configuration = configuration
        applyConfiguration()
    }

    private func commonInit() {
        applyConfiguration()
        contentScaleFactor = UIScreen.main.scale
        backgroundColor = .white
    }

    // MARK: - Configuration

    private func applyConfiguration() {
        tiledLayer.tileSize = configuration.tileSize
        tiledLayer.levelsOfDetail = configuration.levelsOfDetail
        tiledLayer.levelsOfDetailBias = configuration.levelsOfDetailBias
        enableAntialiasing = configuration.enableAntialiasing
    }

    // MARK: - Rendering

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              let page = pdfPage else {
            return
        }

        renderPage(page, in: context, rect: rect)
    }

    /// Renders the PDF page in the given graphics context.
    private func renderPage(_ page: CGPDFPage, in context: CGContext, rect: CGRect) {
        context.saveGState()
        defer { context.restoreGState() }

        // Configure rendering quality
        context.setShouldAntialias(enableAntialiasing)
        context.interpolationQuality = determineInterpolationQuality()

        // Fill background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect)

        // Transform coordinate system (UIKit uses top-left origin, PDF uses bottom-left)
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1.0, y: -1.0)

        // Apply PDF transform to fit the page
        let pdfTransform = page.getDrawingTransform(
            .cropBox,
            rect: bounds,
            rotate: 0,
            preserveAspectRatio: true
        )
        context.concatenate(pdfTransform)

        // Draw the page
        context.drawPDFPage(page)
    }

    /// Determines the interpolation quality based on zoom level.
    private func determineInterpolationQuality() -> CGInterpolationQuality {
        tiledLayer.levelsOfDetail == 1 ? .low : .high
    }
}

// MARK: - Public Methods

extension TiledPDFPageView {

    /// Prepares the view for displaying a new page.
    func prepareForReuse() {
        pdfPage = nil
        layer.contents = nil
    }

    /// Updates the view size to match the page dimensions.
    func updateFrame(for page: CGPDFPage) {
        let pageRect = page.getBoxRect(.cropBox)
        frame = CGRect(origin: .zero, size: pageRect.size)
        pdfPage = page
    }
}
