/**
 * React Native bridge for OptimizedPDFViewManager.
 *
 * This file exposes the Swift view manager and its properties/methods
 * to the React Native JavaScript layer using the RCT_EXTERN macros.
 */

#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(OptimizedPdfViewManager, RCTViewManager)

#pragma mark - View Properties

/// Path to the PDF file to display.
RCT_EXPORT_VIEW_PROPERTY(source, NSString)

/// Current page index (0-based).
RCT_EXPORT_VIEW_PROPERTY(page, NSNumber)

/// Maximum zoom scale allowed.
RCT_EXPORT_VIEW_PROPERTY(maximumZoom, NSNumber)

/// Whether antialiasing is enabled for smoother rendering.
RCT_EXPORT_VIEW_PROPERTY(enableAntialiasing, BOOL)

/// Password for encrypted PDFs.
RCT_EXPORT_VIEW_PROPERTY(password, NSString)

#pragma mark - Event Callbacks

/// Called when an error occurs during PDF loading or rendering.
RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock)

/// Called when a page is fully loaded and displayed.
RCT_EXPORT_VIEW_PROPERTY(onLoadComplete, RCTDirectEventBlock)

/// Called when the document is loaded with the total page count.
RCT_EXPORT_VIEW_PROPERTY(onPageCount, RCTDirectEventBlock)

/// Called when the PDF requires a password to open.
RCT_EXPORT_VIEW_PROPERTY(onPasswordRequired, RCTDirectEventBlock)

#pragma mark - Native Methods

/// Navigates to a specific page in the PDF.
RCT_EXTERN_METHOD(goToPage:(nonnull NSNumber *)node
                  page:(nonnull NSNumber *)page)

/// Resets the zoom level to fit the page.
RCT_EXTERN_METHOD(resetZoom:(nonnull NSNumber *)node)

@end
