
import Foundation


extension URL
{
    static func temporaryURL(forFilename fileName: String, withExtension fileExtension: String = "txt") -> URL {
        
        let fileName = String(format: "%@_%@.%@", ProcessInfo.processInfo.globallyUniqueString, fileName, fileExtension)
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        return fileURL!
    }
}
