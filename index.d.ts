
import React from 'react';
import { ViewStyle } from 'react-native';
import { PdfSource } from './src/OptimizedPdfView';

export interface OptimizedPdfViewProps {
  source: PdfSource;
  maximumZoom?: number;
  style?: ViewStyle;
  onPdfLoadComplete?: (event: {
    nativeEvent: { width: number; height: number; page: number }
  }) => void;
  onPdfError?: (event: {
    nativeEvent: { message: string }
  }) => void;
  onPdfPageCount?: (event: {
    nativeEvent: { pages: number }
  }) => void;
}

declare const OptimizedPdfView: React.ComponentType<OptimizedPdfViewProps>;

export default OptimizedPdfView;