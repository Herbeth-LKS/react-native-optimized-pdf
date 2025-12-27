# Contributing to React Native Optimized PDF

Thank you for considering contributing to this project! Here are some guidelines to help you get started.

## Development Setup

1. Clone the repository

```bash
git clone https://github.com/yourusername/react-native-optimized-pdf.git
cd react-native-optimized-pdf
```

2. Install dependencies

```bash
yarn install
```

3. Install pods (iOS)

```bash
cd ios && pod install
```

## Project Structure

```
react-native-optimized-pdf/
├── src/
│   ├── components/          # Reusable UI components
│   │   ├── PdfNavigationControls.tsx
│   │   └── PdfOverlays.tsx
│   ├── services/           # Business logic and utilities
│   │   └── pdfCache.ts
│   ├── types/              # TypeScript type definitions
│   │   └── index.ts
│   ├── constants.ts        # App constants
│   ├── OptimizedPdfView.tsx  # Main component
│   └── index.ts            # Public exports
├── ios/                    # Native iOS implementation
├── index.ts                # Package entry point
└── index.d.ts              # TypeScript declarations
```

## Code Style

- Use TypeScript for all new code
- Follow the existing code style (use Prettier and ESLint)
- Add JSDoc comments for public APIs
- Write meaningful commit messages

## Testing

Before submitting a PR:

1. Test on a real iOS device or simulator
2. Verify TypeScript types compile without errors
3. Check that all exports work correctly
4. Test with various PDF sources (local, remote, large files)

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Reporting Issues

When reporting issues, please include:

- React Native version
- iOS version
- Device/simulator information
- Steps to reproduce
- Expected vs actual behavior
- Error messages or logs

## Feature Requests

We welcome feature requests! Please open an issue and describe:

- The use case
- Why this would be useful
- Any implementation ideas

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
