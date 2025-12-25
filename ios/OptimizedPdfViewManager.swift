import Foundation
import React

@objc(OptimizedPdfViewManager)
class OptimizedPdfViewManager: RCTViewManager {

    override func view() -> UIView! {
        return OptimizedPdfView()
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }

    @objc func goToPage(_ node: NSNumber, page: NSNumber) {
        DispatchQueue.main.async {
            if let component = self.bridge.uiManager.view(
                forReactTag: node
            ) as? OptimizedPdfView {
                component.page = page
            }
        }
    }
}