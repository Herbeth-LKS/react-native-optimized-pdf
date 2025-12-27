//@ts-nocheck
import React, { useState } from 'react';
import OptimizedPdfView, { PdfCacheService } from 'react-native-optimized-pdf';
import { SafeAreaView, StyleSheet, View, Text, Button, Alert } from 'react-native';

/**
 * Example app demonstrating react-native-optimized-pdf usage
 */
export default function ExampleApp() {
  const [currentPage, setCurrentPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [showControls, setShowControls] = useState(true);

  const pdfSource = {
    uri: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    cache: true,
    expiration: 86400, // 24 hours
  };

  const handleClearCache = async () => {
    try {
      await PdfCacheService.clearCache(pdfSource);
      Alert.alert('Success', 'Cache cleared successfully');
    } catch (error) {
      Alert.alert('Error', 'Failed to clear cache');
    }
  };

  const handleGetCacheSize = async () => {
    try {
      const size = await PdfCacheService.getCacheSize();
      const sizeMB = (size / 1024 / 1024).toFixed(2);
      Alert.alert('Cache Size', `${sizeMB} MB`);
    } catch (error) {
      Alert.alert('Error', 'Failed to get cache size');
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>PDF Viewer Example</Text>
        <Text style={styles.pageInfo}>
          Page {currentPage + 1} of {totalPages}
        </Text>
      </View>

      <OptimizedPdfView
        source={pdfSource}
        maximumZoom={5}
        enableAntialiasing={true}
        showNavigationControls={showControls}
        style={styles.pdf}
        onLoadComplete={(page, dimensions) => {
          console.log('PDF loaded:', { page, dimensions });
        }}
        onPageCount={(count) => {
          console.log('Total pages:', count);
          setTotalPages(count);
        }}
        onPageChange={(page) => {
          console.log('Page changed:', page);
          setCurrentPage(page);
        }}
        onError={(error) => {
          console.error('PDF error:', error);
          Alert.alert('Error', error.nativeEvent.message);
        }}
      />

      <View style={styles.footer}>
        <Button
          title={showControls ? 'Hide Controls' : 'Show Controls'}
          onPress={() => setShowControls(!showControls)}
        />
        <Button title="Clear Cache" onPress={handleClearCache} />
        <Button title="Cache Size" onPress={handleGetCacheSize} />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    padding: 16,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#000',
  },
  pageInfo: {
    fontSize: 14,
    color: '#666',
    marginTop: 4,
  },
  pdf: {
    flex: 1,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: 16,
    backgroundColor: '#fff',
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
});
