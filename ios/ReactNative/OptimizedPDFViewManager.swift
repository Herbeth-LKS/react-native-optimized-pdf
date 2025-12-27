import Foundation
import React

/// React Native View Manager for OptimizedPDFView.
///
/// This class bridges the native OptimizedPDFView with React Native,
/// exposing properties and methods to the JavaScript layer.
@objc(OptimizedPdfViewManager)
final class OptimizedPDFViewManager: RCTViewManager {

    // MARK: - RCTViewManager

    override func view() -> UIView! {
        OptimizedPDFView()
    }

    override static func requiresMainQueueSetup() -> Bool {
        true
    }

    // MARK: - Exported Methods

    /// Navigates to a specific page in the PDF.
    /// - Parameters:
    ///   - node: The React Native view tag.
    ///   - page: The page index to navigate to (0-based).
    @objc func goToPage(_ node: NSNumber, page: NSNumber) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let pdfView = self.bridge?.uiManager.view(forReactTag: node) as? OptimizedPDFView else {
                return
            }
            pdfView.goToPage(page.intValue)
        }
    }

    /// Resets the zoom level to fit the page.
    /// - Parameter node: The React Native view tag.
    @objc func resetZoom(_ node: NSNumber) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let pdfView = self.bridge?.uiManager.view(forReactTag: node) as? OptimizedPDFView else {
                return
            }
            pdfView.resetZoom()
        }
    }
}
