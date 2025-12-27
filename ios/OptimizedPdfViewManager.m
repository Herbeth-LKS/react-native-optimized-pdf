#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(OptimizedPdfViewManager, RCTViewManager)

// Propriedades
RCT_EXPORT_VIEW_PROPERTY(source, NSString)
RCT_EXPORT_VIEW_PROPERTY(page, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(maximumZoom, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(enableAntialiasing, BOOL)
RCT_EXPORT_VIEW_PROPERTY(password, NSString)
RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLoadComplete, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPageCount, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPasswordRequired, RCTDirectEventBlock)

// Métodos nativos
RCT_EXTERN_METHOD(goToPage:(nonnull NSNumber *)node
                  page:(nonnull NSNumber *)page)

@end
