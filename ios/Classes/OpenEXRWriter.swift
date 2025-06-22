import Foundation

class OpenEXRWriter {
    
    static func writeHDRImage(toPath filePath: String, 
                              width: Int, 
                              height: Int, 
                              pixelData: UnsafeMutablePointer<Float>) throws {
        
        let fileData = NSMutableData()
        
        // OpenEXR magic number and version
        var magic: UInt32 = 0x762f3101  // OpenEXR magic number
        var version: UInt32 = 0x00000002 // Version 2, single part
        
        fileData.append(Data(bytes: &magic, count: 4))
        fileData.append(Data(bytes: &version, count: 4))
        
        // Write header attributes
        writeAttribute(to: fileData, name: "channels", type: "chlist") { data in
            // Channel list: R, G, B, A
            let channels = ["R", "G", "B", "A"]
            for channel in channels {
                // Channel name
                data.append(channel.data(using: .ascii)!)
                data.append(Data([0])) // null terminator
                
                // Channel info: pixelType(4) + xSampling(4) + ySampling(4)
                var pixelType: UInt32 = 2 // FLOAT = 2
                var xSampling: UInt32 = 1
                var ySampling: UInt32 = 1
                data.append(Data(bytes: &pixelType, count: 4))
                data.append(Data(bytes: &xSampling, count: 4))
                data.append(Data(bytes: &ySampling, count: 4))
            }
            data.append(Data([0])) // End of channel list
        }
        
        // compression attribute
        writeAttribute(to: fileData, name: "compression", type: "compression") { data in
            var compression: UInt8 = 0 // NO_COMPRESSION
            data.append(Data(bytes: &compression, count: 1))
        }
        
        // dataWindow attribute
        writeAttribute(to: fileData, name: "dataWindow", type: "box2i") { data in
            var xMin: Int32 = 0
            var yMin: Int32 = 0
            var xMax: Int32 = Int32(width - 1)
            var yMax: Int32 = Int32(height - 1)
            data.append(Data(bytes: &xMin, count: 4))
            data.append(Data(bytes: &yMin, count: 4))
            data.append(Data(bytes: &xMax, count: 4))
            data.append(Data(bytes: &yMax, count: 4))
        }
        
        // displayWindow attribute
        writeAttribute(to: fileData, name: "displayWindow", type: "box2i") { data in
            var xMin: Int32 = 0
            var yMin: Int32 = 0
            var xMax: Int32 = Int32(width - 1)
            var yMax: Int32 = Int32(height - 1)
            data.append(Data(bytes: &xMin, count: 4))
            data.append(Data(bytes: &yMin, count: 4))
            data.append(Data(bytes: &xMax, count: 4))
            data.append(Data(bytes: &yMax, count: 4))
        }
        
        // lineOrder attribute
        writeAttribute(to: fileData, name: "lineOrder", type: "lineOrder") { data in
            var lineOrder: UInt8 = 0 // INCREASING_Y
            data.append(Data(bytes: &lineOrder, count: 1))
        }
        
        // pixelAspectRatio attribute
        writeAttribute(to: fileData, name: "pixelAspectRatio", type: "float") { data in
            var pixelAspectRatio: Float = 1.0
            data.append(Data(bytes: &pixelAspectRatio, count: 4))
        }
        
        // screenWindowCenter attribute
        writeAttribute(to: fileData, name: "screenWindowCenter", type: "v2f") { data in
            var x: Float = 0.0
            var y: Float = 0.0
            data.append(Data(bytes: &x, count: 4))
            data.append(Data(bytes: &y, count: 4))
        }
        
        // screenWindowWidth attribute
        writeAttribute(to: fileData, name: "screenWindowWidth", type: "float") { data in
            var screenWindowWidth: Float = 1.0
            data.append(Data(bytes: &screenWindowWidth, count: 4))
        }
        
        // End of header
        fileData.append(Data([0])) // null byte to end header
        
        // Scan line offset table
        let scanlineCount = height
        let scanlineDataSize = width * 4 * 4 // width * 4 channels * 4 bytes per float
        var currentOffset = fileData.length + (scanlineCount * 8) // Start after offset table
        
        for _ in 0..<scanlineCount {
            var offset: UInt64 = UInt64(currentOffset)
            fileData.append(Data(bytes: &offset, count: 8))
            currentOffset += 8 + scanlineDataSize // 8 bytes header + pixel data
        }
        
        // Write scan lines
        for y in 0..<height {
            // Scan line header
            var yCoord: Int32 = Int32(y)
            var dataSize: UInt32 = UInt32(scanlineDataSize)
            fileData.append(Data(bytes: &yCoord, count: 4))
            fileData.append(Data(bytes: &dataSize, count: 4))
            
            // Write pixel data organized by channels
            let lineOffset = y * width * 4
            
            // Write R channel for entire line
            for x in 0..<width {
                let pixelOffset = lineOffset + (x * 4)
                var value = pixelData[pixelOffset + 0] // R
                fileData.append(Data(bytes: &value, count: 4))
            }
            
            // Write G channel for entire line
            for x in 0..<width {
                let pixelOffset = lineOffset + (x * 4)
                var value = pixelData[pixelOffset + 1] // G
                fileData.append(Data(bytes: &value, count: 4))
            }
            
            // Write B channel for entire line
            for x in 0..<width {
                let pixelOffset = lineOffset + (x * 4)
                var value = pixelData[pixelOffset + 2] // B
                fileData.append(Data(bytes: &value, count: 4))
            }
            
            // Write A channel for entire line
            for x in 0..<width {
                let pixelOffset = lineOffset + (x * 4)
                var value = pixelData[pixelOffset + 3] // A
                fileData.append(Data(bytes: &value, count: 4))
            }
        }
        
        // Write to file
        try fileData.write(to: URL(fileURLWithPath: filePath), options: .atomic)
    }
    
    private static func writeAttribute(to data: NSMutableData, 
                                       name: String, 
                                       type: String, 
                                       valueWriter: (NSMutableData) -> Void) {
        
        // Write attribute name
        data.append(name.data(using: .ascii)!)
        data.append(Data([0])) // null terminator
        
        // Write attribute type
        data.append(type.data(using: .ascii)!)
        data.append(Data([0])) // null terminator
        
        // Collect value data
        let valueData = NSMutableData()
        valueWriter(valueData)
        
        // Write value size
        var size: UInt32 = UInt32(valueData.length)
        data.append(Data(bytes: &size, count: 4))
        
        // Write value data
        data.append(valueData as Data)
    }
}