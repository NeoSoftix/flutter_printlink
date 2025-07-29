#import "FlutterThermalPrinterPlugin.h"
#if __has_include(<flutter_printlink/flutter_printlink-Swift.h>)
#import <flutter_printlink/flutter_printlink-Swift.h>
#else
// For development
#import "flutter_printlink-Swift.h"
#endif

@implementation FlutterThermalPrinterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterThermalPrinterPlugin registerWithRegistrar:registrar];
}
@end
