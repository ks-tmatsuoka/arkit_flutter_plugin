#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenEXRWriter : NSObject

+ (BOOL)writeHDRImageToPath:(NSString *)filePath
                      width:(int)width
                     height:(int)height
                  pixelData:(float *)pixelData
                      error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END