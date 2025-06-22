#import "OpenEXRWriter.h"

// For now, we'll implement a simplified version without OpenEXR SDK
// This maintains compatibility while providing proper EXR structure
@implementation OpenEXRWriter

+ (BOOL)writeHDRImageToPath:(NSString *)filePath
                      width:(int)width
                     height:(int)height
                  pixelData:(float *)pixelData
                      error:(NSError **)error {
    
    NSMutableData *fileData = [[NSMutableData alloc] init];
    
    // OpenEXR magic number and version
    uint32_t magic = 0x762f3101;  // OpenEXR magic number
    uint32_t version = 0x00000002; // Version 2, single part
    
    [fileData appendBytes:&magic length:4];
    [fileData appendBytes:&version length:4];
    
    // Write header attributes
    [self writeAttribute:fileData name:@"channels" type:@"chlist" valueBlock:^(NSMutableData *data) {
        // Channel list: R, G, B, A
        NSArray *channels = @[@"R", @"G", @"B", @"A"];
        for (NSString *channel in channels) {
            // Channel name
            [data appendData:[channel dataUsingEncoding:NSASCIIStringEncoding]];
            uint8_t nullByte = 0;
            [data appendBytes:&nullByte length:1];
            
            // Channel info: pixelType(4) + xSampling(4) + ySampling(4)
            uint32_t pixelType = 2; // FLOAT = 2
            uint32_t xSampling = 1;
            uint32_t ySampling = 1;
            [data appendBytes:&pixelType length:4];
            [data appendBytes:&xSampling length:4];
            [data appendBytes:&ySampling length:4];
        }
        uint8_t endByte = 0;
        [data appendBytes:&endByte length:1]; // End of channel list
    }];
    
    // compression attribute
    [self writeAttribute:fileData name:@"compression" type:@"compression" valueBlock:^(NSMutableData *data) {
        uint8_t compression = 0; // NO_COMPRESSION
        [data appendBytes:&compression length:1];
    }];
    
    // dataWindow attribute
    [self writeAttribute:fileData name:@"dataWindow" type:@"box2i" valueBlock:^(NSMutableData *data) {
        int32_t xMin = 0, yMin = 0;
        int32_t xMax = width - 1, yMax = height - 1;
        [data appendBytes:&xMin length:4];
        [data appendBytes:&yMin length:4];
        [data appendBytes:&xMax length:4];
        [data appendBytes:&yMax length:4];
    }];
    
    // displayWindow attribute
    [self writeAttribute:fileData name:@"displayWindow" type:@"box2i" valueBlock:^(NSMutableData *data) {
        int32_t xMin = 0, yMin = 0;
        int32_t xMax = width - 1, yMax = height - 1;
        [data appendBytes:&xMin length:4];
        [data appendBytes:&yMin length:4];
        [data appendBytes:&xMax length:4];
        [data appendBytes:&yMax length:4];
    }];
    
    // lineOrder attribute
    [self writeAttribute:fileData name:@"lineOrder" type:@"lineOrder" valueBlock:^(NSMutableData *data) {
        uint8_t lineOrder = 0; // INCREASING_Y
        [data appendBytes:&lineOrder length:1];
    }];
    
    // pixelAspectRatio attribute
    [self writeAttribute:fileData name:@"pixelAspectRatio" type:@"float" valueBlock:^(NSMutableData *data) {
        float pixelAspectRatio = 1.0f;
        [data appendBytes:&pixelAspectRatio length:4];
    }];
    
    // screenWindowCenter attribute
    [self writeAttribute:fileData name:@"screenWindowCenter" type:@"v2f" valueBlock:^(NSMutableData *data) {
        float x = 0.0f, y = 0.0f;
        [data appendBytes:&x length:4];
        [data appendBytes:&y length:4];
    }];
    
    // screenWindowWidth attribute
    [self writeAttribute:fileData name:@"screenWindowWidth" type:@"float" valueBlock:^(NSMutableData *data) {
        float screenWindowWidth = 1.0f;
        [data appendBytes:&screenWindowWidth length:4];
    }];
    
    // End of header
    uint8_t endHeader = 0;
    [fileData appendBytes:&endHeader length:1];
    
    // Scan line offset table
    int scanlineCount = height;
    int scanlineDataSize = width * 4 * 4; // width * 4 channels * 4 bytes per float
    int64_t currentOffset = (int64_t)[fileData length] + (scanlineCount * 8); // Start after offset table
    
    for (int i = 0; i < scanlineCount; i++) {
        uint64_t offset = (uint64_t)currentOffset;
        [fileData appendBytes:&offset length:8];
        currentOffset += 8 + scanlineDataSize; // 8 bytes header + pixel data
    }
    
    // Write scan lines
    for (int y = 0; y < height; y++) {
        // Scan line header
        int32_t yCoord = y;
        uint32_t dataSize = (uint32_t)scanlineDataSize;
        [fileData appendBytes:&yCoord length:4];
        [fileData appendBytes:&dataSize length:4];
        
        // Write pixel data organized by channels
        int lineOffset = y * width * 4;
        
        // Write R channel for entire line
        for (int x = 0; x < width; x++) {
            int pixelOffset = lineOffset + (x * 4);
            float value = pixelData[pixelOffset + 0]; // R
            [fileData appendBytes:&value length:4];
        }
        
        // Write G channel for entire line
        for (int x = 0; x < width; x++) {
            int pixelOffset = lineOffset + (x * 4);
            float value = pixelData[pixelOffset + 1]; // G
            [fileData appendBytes:&value length:4];
        }
        
        // Write B channel for entire line
        for (int x = 0; x < width; x++) {
            int pixelOffset = lineOffset + (x * 4);
            float value = pixelData[pixelOffset + 2]; // B
            [fileData appendBytes:&value length:4];
        }
        
        // Write A channel for entire line
        for (int x = 0; x < width; x++) {
            int pixelOffset = lineOffset + (x * 4);
            float value = pixelData[pixelOffset + 3]; // A
            [fileData appendBytes:&value length:4];
        }
    }
    
    // Write to file
    NSError *writeError = nil;
    BOOL success = [fileData writeToFile:filePath options:NSDataWritingAtomic error:&writeError];
    
    if (!success && error) {
        *error = writeError;
    }
    
    return success;
}

+ (void)writeAttribute:(NSMutableData *)data 
                  name:(NSString *)name 
                  type:(NSString *)type 
            valueBlock:(void (^)(NSMutableData *data))valueBlock {
    
    // Write attribute name
    [data appendData:[name dataUsingEncoding:NSASCIIStringEncoding]];
    uint8_t nullByte = 0;
    [data appendBytes:&nullByte length:1];
    
    // Write attribute type
    [data appendData:[type dataUsingEncoding:NSASCIIStringEncoding]];
    [data appendBytes:&nullByte length:1];
    
    // Collect value data
    NSMutableData *valueData = [[NSMutableData alloc] init];
    valueBlock(valueData);
    
    // Write value size
    uint32_t size = (uint32_t)[valueData length];
    [data appendBytes:&size length:4];
    
    // Write value data
    [data appendData:valueData];
}

@end