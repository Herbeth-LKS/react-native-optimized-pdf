import React, { useEffect, useRef, useState } from 'react'
import RNFS from 'react-native-fs'
import md5 from 'crypto-js/md5'
const {
  View,
  Text,
  ActivityIndicator,
  TouchableOpacity,
  TextInput,
  StyleSheet,
  ViewStyle,
} = require('react-native')

export interface PdfSource {
  uri: string
  cache?: boolean
  cacheFileName?: string
  expiration?: number
  method?: string
  headers?: Record<string, string>
}

export interface OptimizedPdfViewProps {
  source: PdfSource
  maximumZoom?: number
  enableAntialiasing?: boolean
  style?: typeof ViewStyle
  onLoadComplete?: ( currentPage: number,  {width, height}: {width: number, height: number} ) => void 
  onError?: (error: {nativeEvent: {message: string}}) => void
  onPageCount?:  (numberOfPages: number) => void
}

const NativeOptimizedPdfView =
  require('react-native').Platform.OS === 'ios'
    ? require('react-native').requireNativeComponent('OptimizedPdfView')
    : () => null

function getCacheFilePath(source: PdfSource) {
  const fileName = source.cacheFileName || md5(source.uri).toString() + '.pdf'
  return `${RNFS.CachesDirectoryPath}/${fileName}`
}

async function downloadPdf(
  source: PdfSource,
  onProgress?: (percent: number) => void,
) {
  const localPath = getCacheFilePath(source)
  const exists = await RNFS.exists(localPath)
  if (exists && source.cache !== false) {
    if (source.expiration && source.expiration > 0) {
      const stat = await RNFS.stat(localPath)
      const now = Date.now() / 1000
      if (now - stat.mtime < source.expiration) {
        return localPath
      }
    } else {
      return localPath
    }
  }
  const { promise } = RNFS.downloadFile({
    fromUrl: source.uri,
    toFile: localPath,
    background: false,
    headers: source.headers,
    progressDivider: 1,
    progress: (res) => {
      if (res.contentLength > 0 && onProgress) {
        const percent = Math.floor((res.bytesWritten / res.contentLength) * 100)
        onProgress(percent)
      }
    },
    begin: () => {
      // SEM ESSE BLOCO O PROGRESSO NÃO È ATUALIZADO
    },
  })
  await promise
  return localPath
}

export default function OptimizedPdfView({
  source,
  maximumZoom,
  enableAntialiasing = true,
  style,
  onLoadComplete,
  onError,
  onPageCount,
}: OptimizedPdfViewProps) {
  const [localPath, setLocalPath] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [progress, setProgress] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const [page, setPage] = useState(0)
  const [totalPages, setTotalPages] = useState(1)
  const [inputPage, setInputPage] = useState('1')
  const lastSource = useRef<string | null>(null)

  useEffect(() => {
    setInputPage((page + 1).toString())
  }, [page])

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    setProgress(0)
    setError(null)
    setLocalPath(null)
    setPage(0)
    setTotalPages(1)
    lastSource.current = source.uri
    ;(async () => {
      try {
        const path = await downloadPdf(source, (p) => {
          if (!cancelled) setProgress(p)
        })
        if (!cancelled && lastSource.current === source.uri) {
          setLocalPath(path.startsWith('file://') ? path : `file://${path}`)
          setLoading(false)
        }
      } catch (e: any) {
        if (!cancelled) {
          setError(e?.message || 'Failed to download PDF')
          setLoading(false)
        }
      }
    })()
    return () => {
      cancelled = true
    }
  }, [JSON.stringify(source)])

  const handleNextPage = () => {
    if (page < totalPages - 1) setPage(page + 1)
  }
  const handlePrevPage = () => {
    if (page > 0) setPage(page - 1)
  }
  const handleChangePageInput = (text: string) => setInputPage(text)
  const handleEndEditingPageInput = () => {
    const pageNumber = parseInt(inputPage, 10)
    if (!isNaN(pageNumber) && pageNumber >= 1 && pageNumber <= totalPages) {
      setPage(pageNumber - 1)
    } else {
      setInputPage((page + 1).toString())
    }
  }

  if (loading) {
    return (
      <View
        style={[
          { flex: 1, justifyContent: 'center', alignItems: 'center' },
          style,
        ]}
      >
        <ActivityIndicator size="large" color="#000" />
        <Text style={{ color: '#000', marginTop: 10 }}>{progress}%</Text>
      </View>
    )
  }
  if (error) {
    return (
      <View
        style={[
          { flex: 1, justifyContent: 'center', alignItems: 'center' },
          style,
        ]}
      >
        <Text style={{ color: 'red' }}>{error}</Text>
      </View>
    )
  }
  if (!localPath) return null

  return (
    <View style={[{ flex: 1 }, style]}>
      <NativeOptimizedPdfView
        source={localPath}
        page={page}
        enableAntialiasing={enableAntialiasing}
        maximumZoom={maximumZoom}
        style={{ flex: 1 }}
        onLoadComplete={({nativeEvent}: { nativeEvent: { currentPage: number; width: number; height: number } })=> {
          onLoadComplete?.(nativeEvent.currentPage, {width: nativeEvent.width, height: nativeEvent.height})
        }}
        onError={onError}
        onPageCount={({
          nativeEvent
        }: {
          nativeEvent: { numberOfPages: number }
        }) => {
          setTotalPages(nativeEvent.numberOfPages)
          onPageCount?.(nativeEvent.numberOfPages)
        }}
      />
      <View style={styles.navButtons}>
        <TouchableOpacity
          onPress={handlePrevPage}
          disabled={page === 0}
          style={[styles.navButton, page === 0 && styles.disabledButton]}
        >
          <Text style={{ color: '#fff', fontSize: 20 }}>{'<'}</Text>
        </TouchableOpacity>
        <TextInput
          style={styles.pageInput}
          value={inputPage}
          keyboardType="number-pad"
          returnKeyType="done"
          onChangeText={handleChangePageInput}
          onEndEditing={handleEndEditingPageInput}
        />
        <Text style={styles.pageInfo}>/ {totalPages}</Text>
        <TouchableOpacity
          onPress={handleNextPage}
          disabled={page === totalPages - 1}
          style={[
            styles.navButton,
            page === totalPages - 1 && styles.disabledButton,
          ]}
        >
          <Text style={{ color: '#fff', fontSize: 20 }}>{'>'}</Text>
        </TouchableOpacity>
      </View>
    </View>
  )
}

const styles = StyleSheet.create({
  navButtons: {
    position: 'absolute',
    bottom: 20,
    left: 0,
    right: 0,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
  },
  navButton: {
    backgroundColor: 'rgba(0,0,0,0.6)',
    padding: 10,
    marginHorizontal: 20,
    borderRadius: 8,
  },
  disabledButton: {
    opacity: 0.4,
  },
  pageInfo: {
    color: '#000',
    fontSize: 16,
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