import React from 'react';
import { requireNativeComponent, ViewStyle, Platform } from 'react-native';

export interface OptimizedPdfViewProps {
  source: string;
  page?: number;
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

const NativeOptimizedPdfView = (Platform.OS === 'ios'
  ? requireNativeComponent<OptimizedPdfViewProps>('OptimizedPdfView')
  : (() => null)) as React.ComponentType<OptimizedPdfViewProps>;

export default function OptimizedPdfView(props: OptimizedPdfViewProps) {
  return <NativeOptimizedPdfView {...props} />;
}

