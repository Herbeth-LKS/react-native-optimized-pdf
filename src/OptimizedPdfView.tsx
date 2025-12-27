import React, { useEffect, useRef, useState } from 'react';
const { View, Platform, requireNativeComponent } = require('react-native');
import { PdfCacheService } from './services/pdfCache';
import { PdfNavigationControls } from './components/PdfNavigationControls';
import { PdfLoadingOverlay, PdfErrorOverlay } from './components/PdfOverlays';
import {
  DEFAULT_MAXIMUM_ZOOM,
  DEFAULT_ENABLE_ANTIALIASING,
  DEFAULT_SHOW_NAVIGATION_CONTROLS,
  ERROR_MESSAGES,
} from './constants';
import type { OptimizedPdfViewProps, NativeLoadCompleteEvent, NativePageCountEvent } from './types';

const NativeOptimizedPdfView =
  Platform.OS === 'ios' || Platform.OS === 'android'
    ? requireNativeComponent('OptimizedPdfView')
    : () => null;

/**
 * OptimizedPdfView - High-performance PDF viewer for React Native
 *
 * Features:
 * - Automatic PDF caching with configurable expiration
 * - Progress tracking for downloads
 * - Page navigation with built-in controls
 * - Zoom support with configurable maximum
 * - High-quality rendering with antialiasing
 *
 * @example
 * ```tsx
 * <OptimizedPdfView
 *   source={{ uri: 'https://example.com/file.pdf', cache: true }}
 *   maximumZoom={5}
 *   onLoadComplete={(page, dimensions) => console.log('Loaded', page, dimensions)}
 * />
 * ```
 */
export default function OptimizedPdfView({
  source,
  maximumZoom = DEFAULT_MAXIMUM_ZOOM,
  enableAntialiasing = DEFAULT_ENABLE_ANTIALIASING,
  showNavigationControls = DEFAULT_SHOW_NAVIGATION_CONTROLS,
  style,
  onLoadComplete,
  onError,
  onPageCount,
  onPageChange,
}: OptimizedPdfViewProps) {
  const [localPath, setLocalPath] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const lastSource = useRef<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    const loadPdf = async () => {
      setLoading(true);
      setProgress(0);
      setError(null);
      setLocalPath(null);
      setPage(0);
      setTotalPages(1);
      lastSource.current = source.uri;

      try {
        const path = await PdfCacheService.downloadPdf(source, (p) => {
          if (!cancelled) {
            setProgress(p);
          }
        });

        if (!cancelled && lastSource.current === source.uri) {
          setLocalPath(PdfCacheService.normalizeFilePath(path));
          setLoading(false);
        }
      } catch (e: any) {
        if (!cancelled) {
          setError(e?.message || ERROR_MESSAGES.DOWNLOAD_FAILED);
          setLoading(false);
          onError?.({ nativeEvent: { message: e?.message || ERROR_MESSAGES.DOWNLOAD_FAILED } });
        }
      }
    };

    loadPdf();

    return () => {
      cancelled = true;
    };
  }, [source.uri, source.cache, source.cacheFileName, source.expiration, onError, source]);

  const handleNextPage = () => {
    if (page < totalPages - 1) {
      const newPage = page + 1;
      setPage(newPage);
      onPageChange?.(newPage);
    }
  };

  const handlePrevPage = () => {
    if (page > 0) {
      const newPage = page - 1;
      setPage(newPage);
      onPageChange?.(newPage);
    }
  };

  const handlePageChange = (newPage: number) => {
    setPage(newPage);
    onPageChange?.(newPage);
  };

  const handleLoadComplete = (event: NativeLoadCompleteEvent) => {
    const { currentPage, width, height } = event.nativeEvent;
    onLoadComplete?.(currentPage, { width, height });
  };

  const handlePageCount = (event: NativePageCountEvent) => {
    const { numberOfPages } = event.nativeEvent;
    setTotalPages(numberOfPages);
    onPageCount?.(numberOfPages);
  };

  if (loading) {
    return <PdfLoadingOverlay progress={progress} style={style} />;
  }

  if (error) {
    return <PdfErrorOverlay error={error} style={style} />;
  }

  if (!localPath) {
    return null;
  }

  return (
    <View style={[{ flex: 1 }, style]}>
      <NativeOptimizedPdfView
        source={localPath}
        page={page}
        enableAntialiasing={enableAntialiasing}
        maximumZoom={maximumZoom}
        style={{ flex: 1 }}
        onLoadComplete={handleLoadComplete}
        onError={onError}
        onPageCount={handlePageCount}
      />
      {showNavigationControls && (
        <PdfNavigationControls
          currentPage={page}
          totalPages={totalPages}
          onNextPage={handleNextPage}
          onPrevPage={handlePrevPage}
          onPageChange={handlePageChange}
        />
      )}
    </View>
  );
}
