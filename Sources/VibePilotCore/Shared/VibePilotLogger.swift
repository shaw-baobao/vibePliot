import Foundation

public final class VibePilotLogger {
    public let logFileURL: URL

    private let queue = DispatchQueue(label: "com.vibepilot.logger")

    public init(fileManager: FileManager = .default) {
        let logsRoot = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("VibePilot", isDirectory: true)
        let sessionsRoot = logsRoot.appendingPathComponent("Sessions", isDirectory: true)

        try? fileManager.createDirectory(at: sessionsRoot, withIntermediateDirectories: true)

        let fileName = "VibePilot-\(Self.fileNameTimestampFormatter.string(from: Date())).log"
        self.logFileURL = sessionsRoot.appendingPathComponent(fileName)
    }

    @discardableResult
    public func log(_ message: String) -> String {
        let timestamp = Self.timestampFormatter.string(from: Date())
        let line = "[\(timestamp)] \(message)"

        queue.async { [logFileURL] in
            let text = line + "\n"
            let data = Data(text.utf8)

            if let handle = try? FileHandle(forWritingTo: logFileURL) {
                do {
                    try handle.seekToEnd()
                    try handle.write(contentsOf: data)
                    try handle.close()
                } catch {
                    try? handle.close()
                }
            } else {
                try? data.write(to: logFileURL, options: .atomic)
            }
        }

        NSLog("%@", line)
        return line
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    private static let fileNameTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}
