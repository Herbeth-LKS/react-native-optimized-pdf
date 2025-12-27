import RNFS from 'react-native-fs';
import md5 from 'crypto-js/md5';
import type { PdfSource } from '../types';

/**
 * Service for handling PDF caching and downloads
 */
export class PdfCacheService {
  /**
   * Get the local file path for a cached PDF
   */
  static getCacheFilePath(source: PdfSource): string {
    const fileName = source.cacheFileName || `${md5(source.uri).toString()}.pdf`;
    return `${RNFS.CachesDirectoryPath}/${fileName}`;
  }

  /**
   * Check if a cached PDF exists and is still valid
   */
  static async isCacheValid(source: PdfSource): Promise<boolean> {
    const localPath = this.getCacheFilePath(source);
    const exists = await RNFS.exists(localPath);

    if (!exists) {
      return false;
    }

    // If expiration is not set, cache is always valid
    if (!source.expiration || source.expiration <= 0) {
      return true;
    }

    // Check if cache has expired
    const stat = await RNFS.stat(localPath);
    const now = Date.now() / 1000;
    return now - stat.mtime < source.expiration;
  }

  /**
   * Download a PDF file and cache it locally
   * @param source PDF source configuration
   * @param onProgress Optional callback for download progress
   * @returns Local file path
   */
  static async downloadPdf(
    source: PdfSource,
    onProgress?: (percent: number) => void,
  ): Promise<string> {
    const localPath = this.getCacheFilePath(source);

    // Check if we can use cached version
    if (source.cache !== false && (await this.isCacheValid(source))) {
      return localPath;
    }

    // Download the file
    const { promise } = RNFS.downloadFile({
      fromUrl: source.uri,
      toFile: localPath,
      background: false,
      headers: source.headers,
      progressDivider: 1,
      progress: (res) => {
        if (res.contentLength > 0 && onProgress) {
          const percent = Math.floor((res.bytesWritten / res.contentLength) * 100);
          onProgress(percent);
        }
      },
      begin: () => {
        // This callback is required for progress to update properly
      },
    });

    await promise;
    return localPath;
  }

  /**
   * Clear a specific cached PDF
   */
  static async clearCache(source: PdfSource): Promise<void> {
    const localPath = this.getCacheFilePath(source);
    const exists = await RNFS.exists(localPath);
    if (exists) {
      await RNFS.unlink(localPath);
    }
  }

  /**
   * Clear all cached PDFs
   */
  static async clearAllCache(): Promise<void> {
    const files = await RNFS.readDir(RNFS.CachesDirectoryPath);
    const pdfFiles = files.filter((file) => file.name.endsWith('.pdf'));
    await Promise.all(pdfFiles.map((file) => RNFS.unlink(file.path)));
  }

  /**
   * Get total size of cached PDFs in bytes
   */
  static async getCacheSize(): Promise<number> {
    const files = await RNFS.readDir(RNFS.CachesDirectoryPath);
    const pdfFiles = files.filter((file) => file.name.endsWith('.pdf'));
    return pdfFiles.reduce((total, file) => total + file.size, 0);
  }

  /**
   * Ensure the file path has the file:// protocol
   */
  static normalizeFilePath(path: string): string {
    return path.startsWith('file://') ? path : `file://${path}`;
  }
}
