import Foundation

class HDRBinWriter {
    
    static func writeHDRImage(toPath filePath: String, 
                              width: Int, 
                              height: Int, 
                              pixelData: UnsafeMutablePointer<Float>) throws {
        
        let fileData = NSMutableData()
        
        // HDRBIN magic number and version
        let magicString = "HDRBIN"
        fileData.append(magicString.data(using: .ascii)!)
        
        var version: UInt16 = 1
        fileData.append(Data(bytes: &version, count: 2))
        
        // Image dimensions
        var imageWidth: UInt32 = UInt32(width)
        var imageHeight: UInt32 = UInt32(height)
        fileData.append(Data(bytes: &imageWidth, count: 4))
        fileData.append(Data(bytes: &imageHeight, count: 4))
        
        // Channel count (RGBA = 4)
        var channelCount: UInt8 = 4
        fileData.append(Data(bytes: &channelCount, count: 1))
        
        // Data type (Float32 = 1)
        var dataType: UInt8 = 1
        fileData.append(Data(bytes: &dataType, count: 1))
        
        // Reserved bytes for future use (8 bytes)
        let reserved = Data(count: 8)
        fileData.append(reserved)
        
        // Total header size: 6 (magic) + 2 (version) + 4 (width) + 4 (height) + 1 (channels) + 1 (datatype) + 8 (reserved) = 26 bytes
        
        // Write pixel data in RGBA interleaved format
        let totalPixels = width * height * 4
        for i in 0..<totalPixels {
            var value = pixelData[i]
            fileData.append(Data(bytes: &value, count: 4))
        }
        
        // Write to file
        try fileData.write(to: URL(fileURLWithPath: filePath), options: .atomic)
    }
}