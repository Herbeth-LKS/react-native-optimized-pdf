import Foundation
import CoreGraphics

/// Protocol for PDF document loading operations.
protocol PDFDocumentLoading {
    func loadDocument(from source: String, password: String?) -> Result<CGPDFDocument, PDFError>
}

/// Handles loading and unlocking PDF documents.
final class PDFDocumentLoader: PDFDocumentLoading {

    // MARK: - Singleton

    static let shared = PDFDocumentLoader()

    private init() {}

    // MARK: - Public Methods

    /// Loads a PDF document from the given source path.
    /// - Parameters:
    ///   - source: The file path to the PDF document.
    ///   - password: Optional password for encrypted PDFs.
    /// - Returns: A Result containing the loaded document or an error.
    func loadDocument(from source: String, password: String?) -> Result<CGPDFDocument, PDFError> {
        guard !source.isEmpty else {
            return .failure(.emptySource)
        }

        let url = normalizedURL(from: source)

        guard let document = CGPDFDocument(url as CFURL) else {
            return .failure(.documentLoadFailed(source))
        }

        return unlockIfNeeded(document: document, password: password)
    }

    // MARK: - Private Methods

    /// Normalizes the source path to a file URL.
    private func normalizedURL(from source: String) -> URL {
        let path = source.hasPrefix("file://")
            ? String(source.dropFirst(7))
            : source
        return URL(fileURLWithPath: path)
    }

    /// Attempts to unlock an encrypted PDF document.
    private func unlockIfNeeded(
        document: CGPDFDocument,
        password: String?
    ) -> Result<CGPDFDocument, PDFError> {
        guard document.isEncrypted else {
            return .success(document)
        }

        // Try empty password first (some PDFs use empty password for user access)
        if document.unlockWithPassword("") {
            return .success(document)
        }

        // Check if password was provided
        guard let password = password, !password.isEmpty else {
            return .failure(.passwordRequired)
        }

        // Try provided password
        guard document.unlockWithPassword(password) else {
            return .failure(.invalidPassword)
        }

        return .success(document)
    }
}
