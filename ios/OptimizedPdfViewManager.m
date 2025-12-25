#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(OptimizedPdfViewManager, RCTViewManager)

// Propriedades
RCT_EXPORT_VIEW_PROPERTY(source, NSString)
RCT_EXPORT_VIEW_PROPERTY(page, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(maximumZoom, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(onPdfError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPdfLoadComplete, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPdfPageCount, RCTDirectEventBlock)

// Métodos nativos
RCT_EXTERN_METHOD(goToPage:(nonnull NSNumber *)node
                  page:(nonnull NSNumber *)page)

@end
