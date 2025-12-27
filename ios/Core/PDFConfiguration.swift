import UIKit

/// Configuration options for PDF rendering.
struct PDFConfiguration {
    /// Maximum zoom scale allowed.
    var maximumZoom: CGFloat = 5.0

    /// Whether to enable antialiasing for smoother rendering.
    var enableAntialiasing: Bool = true

    /// Password for encrypted PDFs.
    var password: String?

    /// Size of each tile for CATiledLayer rendering.
    var tileSize: CGSize = CGSize(width: 512, height: 512)

    /// Number of detail levels for zoom.
    var levelsOfDetail: Int = 2

    /// Bias for levels of detail (allows zoom up to 2^bias resolution).
    var levelsOfDetailBias: Int = 8

    /// Animation duration for zoom reset.
    var zoomResetAnimationDuration: TimeInterval = 0.25

    /// Default configuration.
    static let `default` = PDFConfiguration()
}
