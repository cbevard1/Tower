import Foundation
import zlib

public extension Data {
    /// Check if data is gzipped (starts with 0x1f 0x8b)
    var isGzipped: Bool {
        count >= 2 && self[0] == 0x1f && self[1] == 0x8b
    }

    /// Decompress gzipped data using zlib
    func gunzipped() throws -> Data {
        guard isGzipped else { return self }
        
        var stream = z_stream()
        var status = inflateInit2_(&stream, 15 + 32, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard status == Z_OK else { throw XMLTVError.parseFailed("inflateInit2 failed: \(status)") }
        defer { inflateEnd(&stream) }
        
        var output = Data()
        let bufferSize = 65536
        var buffer = [UInt8](repeating: 0, count: 65536)
        
        // Set up input
        stream.next_in = UnsafeMutablePointer<Bytef>.allocate(capacity: count)
        defer { stream.next_in?.deallocate() }
        self.copyBytes(to: stream.next_in!, count: count)
        stream.avail_in = uInt(count)
        
        repeat {
            if stream.avail_out == 0 {
                output.append(contentsOf: buffer[0..<(bufferSize - Int(stream.avail_out))])
                stream.next_out = UnsafeMutablePointer<Bytef>(&buffer)
                stream.avail_out = uInt(bufferSize)
            }
            
            let status = inflate(&stream, Z_NO_FLUSH)
            if status == Z_STREAM_END { break }
            guard status == Z_OK else {
                throw XMLTVError.parseFailed("inflate failed: \(status)")
            }
        } while true
        
        output.append(contentsOf: buffer[0..<(bufferSize - Int(stream.avail_out))])
        return output
    }
}