import React from 'react';
const { View, Text, ActivityIndicator, StyleSheet } = require('react-native');
import type { PdfLoadingOverlayProps, PdfErrorOverlayProps } from '../types';

/**
 * Loading overlay with progress indicator
 */
export const PdfLoadingOverlay: React.FC<PdfLoadingOverlayProps> = ({ progress, style }) => {
  return (
    <View style={[styles.container, style]}>
      <ActivityIndicator size="large" color="#fff" />
      <Text style={styles.progressText}>{progress}%</Text>
    </View>
  );
};

/**
 * Error overlay for displaying error messages
 */
export const PdfErrorOverlay: React.FC<PdfErrorOverlayProps> = ({ error, style }) => {
  return (
    <View style={[styles.container, style]}>
      <Text style={styles.errorText}>{error}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  progressText: {
    color: '#fff',
    marginTop: 10,
    fontSize: 16,
    fontWeight: '600',
  },
  errorText: {
    color: '#d32f2f',
    fontSize: 16,
    textAlign: 'center',
  },
});
