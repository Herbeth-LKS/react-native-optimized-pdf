import Foundation

/// Errors that can occur during PDF operations.
enum PDFError: Error, LocalizedError {
    case emptySource
    case invalidPath(String)
    case documentLoadFailed(String)
    case passwordRequired
    case invalidPassword
    case pageNotFound(Int)
    case renderingFailed

    var errorDescription: String? {
        switch self {
        case .emptySource:
            return "PDF source path is empty"
        case .invalidPath(let path):
            return "Invalid PDF path: \(path)"
        case .documentLoadFailed(let path):
            return "Failed to open PDF at: \(path)"
        case .passwordRequired:
            return "PDF is password protected"
        case .invalidPassword:
            return "Invalid password for PDF"
        case .pageNotFound(let index):
            return "Page not found at index: \(index)"
        case .renderingFailed:
            return "Failed to render PDF page"
        }
    }

    /// Dictionary representation for React Native events.
    var eventPayload: [String: Any] {
        ["message": errorDescription ?? "Unknown error"]
    }
}
