//
//  SpyneModule.m
//  testingbridge
//
//  Objective-C exports for the Swift `SpyneModule` React Native bridge.
//  The exported module name is `Spyne` so JavaScript can call NativeModules.Spyne.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(Spyne, RCTEventEmitter)

RCT_EXTERN_METHOD(start:(NSString *)userId
                  vin:(NSString *)vin
                  stockNumber:(NSString *)stockNumber
                  registrationNumber:(NSString *)registrationNumber
                  locale:(NSString *)locale)

RCT_EXTERN_METHOD(exitSDK)

@end
