
import React from 'react';
import { ViewStyle } from 'react-native';
import { PdfSource } from './src/OptimizedPdfView';

export interface OptimizedPdfViewProps {
  source: PdfSource;
  maximumZoom?: number;
  enableAntialiasing?: boolean;
  style?: ViewStyle;
  onLoadComplete?: (currentPage: number, {width, height}: {width: number, height: number}) => void
  onError?: (error: {nativeEvent: {message: string}}) => void
  onPageCount?: (numberOfPages: number) => void
}

declare const OptimizedPdfView: React.ComponentType<OptimizedPdfViewProps>;

export default OptimizedPdfView;