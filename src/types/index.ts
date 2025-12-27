import { ViewStyle } from 'react-native';

/**
 * Configuration for PDF source
 */
export interface PdfSource {
  /** URI of the PDF file (remote URL or local file path) */
  uri: string;
  /** Whether to cache the PDF file locally. Default: true */
  cache?: boolean;
  /** Custom filename for the cached file. If not provided, uses MD5 hash of URI */
  cacheFileName?: string;
  /** Cache expiration time in seconds. If not set, cache never expires */
  expiration?: number;
  /** HTTP method for download. Default: 'GET' */
  method?: string;
  /** HTTP headers for download request */
  headers?: Record<string, string>;
}

/**
 * Page dimensions returned by onLoadComplete event
 */
export interface PdfPageDimensions {
  width: number;
  height: number;
}

/**
 * Error event from native module
 */
export interface PdfErrorEvent {
  nativeEvent: {
    message: string;
  };
}

/**
 * Props for OptimizedPdfView component
 */
export interface OptimizedPdfViewProps {
  /** PDF source configuration */
  source: PdfSource;
  /** Maximum zoom level. Default: 3 */
  maximumZoom?: number;
  /** Enable antialiasing for better rendering quality. Default: true */
  enableAntialiasing?: boolean;
  /** Show built-in navigation controls. Default: true */
  showNavigationControls?: boolean;
  /** Custom style for the container */
  style?: ViewStyle;
  /** Callback when PDF is loaded successfully */
  onLoadComplete?: (currentPage: number, dimensions: PdfPageDimensions) => void;
  /** Callback when an error occurs */
  onError?: (error: PdfErrorEvent) => void;
  /** Callback when page count is available */
  onPageCount?: (numberOfPages: number) => void;
  /** Callback when page changes */
  onPageChange?: (currentPage: number) => void;
}

/**
 * Native event for load complete
 */
export interface NativeLoadCompleteEvent {
  nativeEvent: {
    currentPage: number;
    width: number;
    height: number;
  };
}

/**
 * Native event for page count
 */
export interface NativePageCountEvent {
  nativeEvent: {
    numberOfPages: number;
  };
}

/**
 * Props for navigation controls component
 */
export interface PdfNavigationControlsProps {
  currentPage: number;
  totalPages: number;
  onNextPage: () => void;
  onPrevPage: () => void;
  onPageChange: (page: number) => void;
  style?: ViewStyle;
}

/**
 * Props for loading overlay component
 */
export interface PdfLoadingOverlayProps {
  progress: number;
  style?: ViewStyle;
}

/**
 * Props for error overlay component
 */
export interface PdfErrorOverlayProps {
  error: string;
  style?: ViewStyle;
}
