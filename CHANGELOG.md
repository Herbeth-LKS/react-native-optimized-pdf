# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Modular architecture with separated concerns
- `PdfCacheService` for advanced cache management
- `PdfNavigationControls` as standalone component
- `PdfLoadingOverlay` and `PdfErrorOverlay` components
- `showNavigationControls` prop to hide/show built-in controls
- `onPageChange` callback for page change events
- Comprehensive TypeScript types in `/src/types`
- JSDoc comments for better IDE support
- Cache utility methods (clearCache, clearAllCache, getCacheSize)
- Accessibility labels for navigation controls

### Changed

- Refactored component structure for better maintainability
- Improved error handling and messaging
- Better TypeScript type exports
- Enhanced documentation with more examples
- Cleaner imports using ES6 modules consistently

### Fixed

- Memory leaks in useEffect cleanup
- Proper file:// protocol handling
- Cache validation logic
