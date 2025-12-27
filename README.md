# React Native Optimized PDF

High-performance PDF viewer for React Native with optimized memory usage using CATiledLayer and automatic caching.

## Features

- 🚀 **Optimized memory usage** with CATiledLayer for smooth rendering
- 📦 **Automatic caching** with configurable expiration
- 📱 **Smooth zoom and scroll** with customizable maximum zoom
- 🎯 **Built-in page navigation** with optional custom controls
- 📊 **Comprehensive event callbacks** for load, error, and page events
- 🎨 **High-quality rendering** with antialiasing support
- 📈 **Download progress tracking** for remote PDFs
- ⚡ **TypeScript support** with full type definitions
- 🔧 **Modular architecture** with exportable utilities

## Installation

```bash
npm install react-native-optimized-pdf
# or
yarn add react-native-optimized-pdf
```

### iOS Setup

```bash
cd ios && pod install
```

## Usage

### Basic Example

```tsx
import OptimizedPdfView from 'react-native-optimized-pdf';

function App() {
  return (
    <OptimizedPdfView source={{ uri: 'https://example.com/sample.pdf' }} style={{ flex: 1 }} />
  );
}
```

### Advanced Example with All Options

```tsx
import OptimizedPdfView from 'react-native-optimized-pdf';

function App() {
  return (
    <OptimizedPdfView
      source={{
        uri: 'https://example.com/sample.pdf',
        cache: true,
        cacheFileName: 'my-custom-file.pdf',
        expiration: 86400, // 24 hours in seconds
        headers: {
          Authorization: 'Bearer token',
        },
      }}
      maximumZoom={5}
      enableAntialiasing={true}
      showNavigationControls={true}
      style={{ flex: 1 }}
      onLoadComplete={(page, dimensions) => {
        console.log(`Loaded page ${page}`, dimensions);
      }}
      onPageCount={(count) => {
        console.log(`Total pages: ${count}`);
      }}
      onPageChange={(page) => {
        console.log(`Changed to page ${page}`);
      }}
      onError={(error) => {
        console.error('PDF Error:', error.nativeEvent.message);
      }}
    />
  );
}
```

### Custom Navigation Controls

```tsx
import OptimizedPdfView from 'react-native-optimized-pdf';
import { useState } from 'react';
import { View, Text } from 'react-native';

function App() {
  const [currentPage, setCurrentPage] = useState(0);
  const [totalPages, setTotalPages] = useState(1);

  return (
    <View style={{ flex: 1 }}>
      <OptimizedPdfView
        source={{ uri: 'https://example.com/sample.pdf' }}
        showNavigationControls={false}
        onPageCount={setTotalPages}
        onPageChange={setCurrentPage}
        style={{ flex: 1 }}
      />

      {/* Your custom navigation UI */}
      <Text>
        Page {currentPage + 1} of {totalPages}
      </Text>
    </View>
  );
}
```

### Using Cache Service Directly

```tsx
import { PdfCacheService } from 'react-native-optimized-pdf';

// Clear specific cache
await PdfCacheService.clearCache({ uri: 'https://example.com/file.pdf' });

// Clear all cached PDFs
await PdfCacheService.clearAllCache();

// Get cache size in bytes
const size = await PdfCacheService.getCacheSize();
console.log(`Cache size: ${size / 1024 / 1024} MB`);

// Check if cache is valid
const isValid = await PdfCacheService.isCacheValid({
  uri: 'https://example.com/file.pdf',
  expiration: 3600,
});
```

## API Reference

### OptimizedPdfView Props

| Prop                     | Type                                                    | Default      | Description                            |
| ------------------------ | ------------------------------------------------------- | ------------ | -------------------------------------- |
| `source`                 | `PdfSource`                                             | **required** | PDF source configuration               |
| `maximumZoom`            | `number`                                                | `3`          | Maximum zoom level                     |
| `enableAntialiasing`     | `boolean`                                               | `true`       | Enable antialiasing for better quality |
| `showNavigationControls` | `boolean`                                               | `true`       | Show built-in navigation controls      |
| `style`                  | `ViewStyle`                                             | -            | Container style                        |
| `onLoadComplete`         | `(page: number, dimensions: PdfPageDimensions) => void` | -            | Called when PDF loads                  |
| `onPageCount`            | `(count: number) => void`                               | -            | Called when page count is available    |
| `onPageChange`           | `(page: number) => void`                                | -            | Called when page changes               |
| `onError`                | `(error: PdfErrorEvent) => void`                        | -            | Called on error                        |

### PdfSource

| Property        | Type                     | Default      | Description                                                  |
| --------------- | ------------------------ | ------------ | ------------------------------------------------------------ |
| `uri`           | `string`                 | **required** | PDF file URI (remote URL or local path)                      |
| `cache`         | `boolean`                | `true`       | Enable local caching                                         |
| `cacheFileName` | `string`                 | MD5 of URI   | Custom filename for cached file                              |
| `expiration`    | `number`                 | -            | Cache expiration in seconds (0 or undefined = no expiration) |
| `headers`       | `Record<string, string>` | -            | HTTP headers for download                                    |

### PdfCacheService

Static methods for managing PDF cache:

- `getCacheFilePath(source: PdfSource): string` - Get local cache path
- `isCacheValid(source: PdfSource): Promise<boolean>` - Check if cache is valid
- `downloadPdf(source: PdfSource, onProgress?: (percent: number) => void): Promise<string>` - Download and cache PDF
- `clearCache(source: PdfSource): Promise<void>` - Clear specific cached file
- `clearAllCache(): Promise<void>` - Clear all cached PDFs
- `getCacheSize(): Promise<number>` - Get total cache size in bytes

## Components

### PdfNavigationControls

Reusable navigation controls component:

```tsx
import { PdfNavigationControls } from 'react-native-optimized-pdf';

<PdfNavigationControls
  currentPage={0}
  totalPages={10}
  onNextPage={() => {}}
  onPrevPage={() => {}}
  onPageChange={(page) => {}}
/>;
```

### PdfLoadingOverlay

Loading state component with progress:

```tsx
import { PdfLoadingOverlay } from 'react-native-optimized-pdf';

<PdfLoadingOverlay progress={75} />;
```

### PdfErrorOverlay

Error state component:

```tsx
import { PdfErrorOverlay } from 'react-native-optimized-pdf';

<PdfErrorOverlay error="Failed to load PDF" />;
```

## Platform Support

| Platform | Supported                |
| -------- | ------------------------ |
| iOS      | ✅ Yes                   |
| Android  | ❌ Not yet (coming soon) |

## Performance Tips

1. **Enable caching** for remote PDFs to avoid re-downloading
2. **Set cache expiration** for frequently updated documents
3. **Use custom cache filenames** for better cache management
4. **Monitor cache size** and clear old files periodically
5. **Adjust maximum zoom** based on your needs (lower = better performance)
6. **Hide navigation controls** if implementing custom UI

## Troubleshooting

### PDF not loading

- Check that the URI is accessible
- Verify network permissions for remote URLs
- Check console for error messages
- Ensure file format is valid PDF

### High memory usage

- Reduce `maximumZoom` value
- Clear cache periodically
- Use smaller PDF files when possible

### Cache not working

- Verify write permissions
- Check available storage space
- Ensure `cache` is not set to `false`

## License

MIT

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Author

Created with ❤️ for the React Native community
