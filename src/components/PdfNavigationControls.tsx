import React, { useState, useEffect } from 'react';
const { View, Text, TouchableOpacity, TextInput, StyleSheet } = require('react-native');
import type { PdfNavigationControlsProps } from '../types';

/**
 * Navigation controls for PDF pages
 * Provides previous/next buttons and page number input
 */
export const PdfNavigationControls: React.FC<PdfNavigationControlsProps> = ({
  currentPage,
  totalPages,
  onNextPage,
  onPrevPage,
  onPageChange,
  style,
}) => {
  const [inputPage, setInputPage] = useState((currentPage + 1).toString());

  useEffect(() => {
    setInputPage((currentPage + 1).toString());
  }, [currentPage]);

  const handleChangePageInput = (text: string) => {
    setInputPage(text);
  };

  const handleEndEditingPageInput = () => {
    const pageNumber = parseInt(inputPage, 10);
    if (!isNaN(pageNumber) && pageNumber >= 1 && pageNumber <= totalPages) {
      onPageChange(pageNumber - 1);
    } else {
      // Reset to current page if invalid
      setInputPage((currentPage + 1).toString());
    }
  };

  const isFirstPage = currentPage === 0;
  const isLastPage = currentPage === totalPages - 1;

  return (
    <View style={[styles.container, style]}>
      <TouchableOpacity
        onPress={onPrevPage}
        disabled={isFirstPage}
        style={[styles.navButton, isFirstPage && styles.disabledButton]}
        accessibilityLabel="Previous page"
        accessibilityRole="button"
      >
        <Text style={styles.navButtonText}>{'<'}</Text>
      </TouchableOpacity>

      <TextInput
        style={styles.pageInput}
        value={inputPage}
        keyboardType="number-pad"
        returnKeyType="done"
        onChangeText={handleChangePageInput}
        onEndEditing={handleEndEditingPageInput}
        accessibilityLabel={`Current page: ${currentPage + 1} of ${totalPages}`}
      />

      <Text style={styles.pageInfo}>/ {totalPages}</Text>

      <TouchableOpacity
        onPress={onNextPage}
        disabled={isLastPage}
        style={[styles.navButton, isLastPage && styles.disabledButton]}
        accessibilityLabel="Next page"
        accessibilityRole="button"
      >
        <Text style={styles.navButtonText}>{'>'}</Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    bottom: 20,
    left: 0,
    right: 0,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
  },
  navButton: {
    backgroundColor: 'rgba(0, 0, 0, 0.6)',
    padding: 10,
    marginHorizontal: 20,
    borderRadius: 8,
    minWidth: 44,
    minHeight: 44,
    justifyContent: 'center',
    alignItems: 'center',
  },
  navButtonText: {
    color: '#fff',
    fontSize: 20,
    fontWeight: '600',
  },
  disabledButton: {
    opacity: 0.4,
  },
  pageInfo: {
    color: '#000',
    fontSize: 16,
    fontWeight: '500',
  },
  pageInput: {
    width: 50,
    height: 40,
    borderWidth: 1,
    borderColor: '#000',
    borderRadius: 5,
    textAlign: 'center',
    color: '#000',
    marginHorizontal: 10,
    backgroundColor: '#fff',
    fontWeight: 'bold',
    fontSize: 16,
  },
});
