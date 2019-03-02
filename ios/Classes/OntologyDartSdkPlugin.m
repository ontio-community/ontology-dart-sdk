#import "OntologyDartSdkPlugin.h"
#import <ontology_dart_sdk/ontology_dart_sdk-Swift.h>

@implementation OntologyDartSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  [SwiftOntologyDartSdkPlugin registerWithRegistrar:registrar];
}
@end
