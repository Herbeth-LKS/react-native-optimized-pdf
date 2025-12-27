package com.reactnativeoptimizedpdf

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import android.util.AttributeSet
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.widget.FrameLayout
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.encryption.InvalidPasswordException
import java.io.File
import java.io.FileOutputStream
import kotlin.math.max
import kotlin.math.min

/**
 * View otimizada para renderização de PDF no Android
 * 
 * Usa PdfRenderer do Android para renderização eficiente em memória
 * com suporte a zoom via ScaleGestureDetector e pan via GestureDetector
 */
class OptimizedPdfView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    private var pdfRenderer: PdfRenderer? = null
    private var fileDescriptor: ParcelFileDescriptor? = null
    private var currentPage: PdfRenderer.Page? = null
    private var currentBitmap: Bitmap? = null
    
    private var source: String = ""
    private var pageIndex: Int = 0
    private var maximumZoom: Float = 5.0f
    private var enableAntialiasing: Boolean = true
    private var password: String = ""
    
    private var scaleFactor: Float = 1.0f
    private var minScaleFactor: Float = 1.0f
    private var translateX: Float = 0f
    private var translateY: Float = 0f
    
    private var pageWidth: Int = 0
    private var pageHeight: Int = 0
    
    private var needsLoad: Boolean = false
    private var pendingPageIndex: Int? = null
    private var decryptedFile: File? = null
    private var pdfBoxInitialized: Boolean = false
    
    private val paint = Paint().apply {
        isAntiAlias = true
        isFilterBitmap = true
        isDither = true
    }

    private val scaleGestureDetector: ScaleGestureDetector
    private val gestureDetector: GestureDetector
    
    private var lastTouchX: Float = 0f
    private var lastTouchY: Float = 0f
    private var isDragging: Boolean = false

    init {
        setBackgroundColor(Color.WHITE)
        setWillNotDraw(false)
        
        scaleGestureDetector = ScaleGestureDetector(context, object : ScaleGestureDetector.SimpleOnScaleGestureListener() {
            override fun onScale(detector: ScaleGestureDetector): Boolean {
                val oldScale = scaleFactor
                scaleFactor *= detector.scaleFactor
                scaleFactor = max(minScaleFactor, min(scaleFactor, maximumZoom))
                
                if (oldScale != scaleFactor) {
                    val focusX = detector.focusX
                    val focusY = detector.focusY
                    
                    val oldScaledWidth = pageWidth * oldScale
                    val oldScaledHeight = pageHeight * oldScale
                    val oldContentX = (width - oldScaledWidth) / 2 + translateX
                    val oldContentY = (height - oldScaledHeight) / 2 + translateY
                    
                    val pdfX = (focusX - oldContentX) / oldScale
                    val pdfY = (focusY - oldContentY) / oldScale
                    
                    val newScaledWidth = pageWidth * scaleFactor
                    val newScaledHeight = pageHeight * scaleFactor
                    val newContentX = (width - newScaledWidth) / 2
                    val newContentY = (height - newScaledHeight) / 2
                    
                    translateX = focusX - newContentX - (pdfX * scaleFactor)
                    translateY = focusY - newContentY - (pdfY * scaleFactor)
                    
                    constrainTranslation()
                    invalidate()
                }
                return true
            }
        })
        
        gestureDetector = GestureDetector(context, object : GestureDetector.SimpleOnGestureListener() {
            override fun onDoubleTap(e: MotionEvent): Boolean {
                if (scaleFactor > minScaleFactor) {
                    animateToScale(minScaleFactor, e.x, e.y)
                } else {
                    animateToScale(min(2.5f, maximumZoom), e.x, e.y)
                }
                return true
            }
            
            override fun onScroll(
                e1: MotionEvent?,
                e2: MotionEvent,
                distanceX: Float,
                distanceY: Float
            ): Boolean {
                if (!scaleGestureDetector.isInProgress) {
                    translateX -= distanceX
                    translateY -= distanceY
                    constrainTranslation()
                    invalidate()
                }
                return true
            }
        })
    }

    private fun animateToScale(targetScale: Float, focusX: Float, focusY: Float) {
        val startScale = scaleFactor
        val startTranslateX = translateX
        val startTranslateY = translateY
        
        val oldScaledWidth = pageWidth * startScale
        val oldScaledHeight = pageHeight * startScale
        val oldContentX = (width - oldScaledWidth) / 2 + startTranslateX
        val oldContentY = (height - oldScaledHeight) / 2 + startTranslateY
        val pdfX = (focusX - oldContentX) / startScale
        val pdfY = (focusY - oldContentY) / startScale
        
        android.animation.ValueAnimator.ofFloat(0f, 1f).apply {
            duration = 250
            addUpdateListener { animator ->
                val fraction = animator.animatedValue as Float
                val currentScale = startScale + (targetScale - startScale) * fraction
                scaleFactor = currentScale
                
                if (targetScale <= minScaleFactor) {
                    translateX = startTranslateX * (1 - fraction)
                    translateY = startTranslateY * (1 - fraction)
                } else {
                    val newScaledWidth = pageWidth * currentScale
                    val newScaledHeight = pageHeight * currentScale
                    val newContentX = (width - newScaledWidth) / 2
                    val newContentY = (height - newScaledHeight) / 2
                    
                    translateX = focusX - newContentX - (pdfX * currentScale)
                    translateY = focusY - newContentY - (pdfY * currentScale)
                }
                constrainTranslation()
                invalidate()
            }
            start()
        }
    }

    private fun constrainTranslation() {
        val scaledWidth = pageWidth * scaleFactor
        val scaledHeight = pageHeight * scaleFactor
        
        val maxTranslateX = max(0f, (scaledWidth - width) / 2)
        val maxTranslateY = max(0f, (scaledHeight - height) / 2)
        
        if (scaledWidth <= width) {
            translateX = 0f
        } else {
            translateX = translateX.coerceIn(-maxTranslateX, maxTranslateX)
        }
        
        if (scaledHeight <= height) {
            translateY = 0f
        } else {
            translateY = translateY.coerceIn(-maxTranslateY, maxTranslateY)
        }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        var handled = scaleGestureDetector.onTouchEvent(event)
        handled = gestureDetector.onTouchEvent(event) || handled
        return handled || super.onTouchEvent(event)
    }

    fun setSource(source: String) {
        if (this.source != source) {
            this.source = source
            needsLoad = true
            pdfRenderer?.close()
            pdfRenderer = null
            pendingPageIndex = pageIndex
            requestLayout()
            invalidate()
        }
    }

    fun setPage(page: Int) {
        if (this.pageIndex != page) {
            this.pageIndex = page
            if (pdfRenderer != null) {
                displayPage(page)
            } else {
                pendingPageIndex = page
            }
        }
    }

    fun setMaximumZoom(zoom: Float) {
        this.maximumZoom = zoom
        if (scaleFactor > zoom) {
            scaleFactor = zoom
            invalidate()
        }
    }

    fun setEnableAntialiasing(enable: Boolean) {
        this.enableAntialiasing = enable
        paint.isAntiAlias = enable
        paint.isFilterBitmap = enable
        invalidate()
    }

    fun setPassword(pwd: String) {
        if (this.password != pwd) {
            this.password = pwd
            // Se já temos source mas falhou por senha, tenta recarregar
            if (source.isNotEmpty() && pdfRenderer == null) {
                needsLoad = true
                requestLayout()
            }
        }
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        super.onLayout(changed, left, top, right, bottom)
        
        if (width > 0 && height > 0 && needsLoad) {
            needsLoad = false
            loadPdf()
        } else if (changed && currentBitmap != null) {
            calculateFitScale()
            constrainTranslation()
        }
    }

    private fun loadPdf() {
        if (source.isEmpty()) return
        
        try {
            val path = if (source.startsWith("file://")) {
                source.substring(7)
            } else {
                source
            }
            
            val file = File(path)
            if (!file.exists()) {
                sendError("PDF file not found: $path")
                return
            }
            
            var pdfFile = file
            
            try {
                fileDescriptor = ParcelFileDescriptor.open(pdfFile, ParcelFileDescriptor.MODE_READ_ONLY)
                pdfRenderer = PdfRenderer(fileDescriptor!!)
            } catch (e: SecurityException) {
                fileDescriptor?.close()
                fileDescriptor = null
                
                pdfFile = decryptPdfWithPassword(file) ?: return
                
                fileDescriptor = ParcelFileDescriptor.open(pdfFile, ParcelFileDescriptor.MODE_READ_ONLY)
                pdfRenderer = PdfRenderer(fileDescriptor!!)
            }
            
            val pageCount = pdfRenderer!!.pageCount
            
            sendPageCount(pageCount)
            
            val targetPage = pendingPageIndex ?: 0
            pendingPageIndex = null
            displayPage(targetPage.coerceIn(0, pageCount - 1))
            
        } catch (e: Exception) {
            sendError("Failed to load PDF: ${e.message}")
        }
    }
    
    private fun decryptPdfWithPassword(file: File): File? {
        if (!pdfBoxInitialized) {
            PDFBoxResourceLoader.init(context)
            pdfBoxInitialized = true
        }
        
        val document: PDDocument
        try {
            document = if (password.isNotEmpty()) {
                PDDocument.load(file, password)
            } else {
                try {
                    PDDocument.load(file, "")
                } catch (e: InvalidPasswordException) {
                    sendPasswordRequired()
                    sendError("PDF is password protected")
                    return null
                }
            }
        } catch (e: InvalidPasswordException) {
            sendError("Invalid password for PDF")
            return null
        } catch (e: Exception) {
            sendError("Failed to decrypt PDF: ${e.message}")
            return null
        }
        
        try {
            if (document.isEncrypted) {
                document.setAllSecurityToBeRemoved(true)
            }
            
            val tempFile = File(context.cacheDir, "decrypted_${System.currentTimeMillis()}.pdf")
            document.save(FileOutputStream(tempFile))
            document.close()
            
            decryptedFile?.delete()
            decryptedFile = tempFile
            
            return tempFile
        } catch (e: Exception) {
            document.close()
            sendError("Failed to save decrypted PDF: ${e.message}")
            return null
        }
    }

    private fun displayPage(index: Int) {
        val renderer = pdfRenderer ?: return
        
        if (index < 0 || index >= renderer.pageCount) {
            sendError("Invalid page index: $index")
            return
        }
        
        currentPage?.close()
        
        currentPage = renderer.openPage(index)
        val page = currentPage!!
        
        pageWidth = page.width
        pageHeight = page.height
        
        val scale = calculateRenderScale()
        val bitmapWidth = (pageWidth * scale).toInt()
        val bitmapHeight = (pageHeight * scale).toInt()
        
        currentBitmap?.recycle()
        
        currentBitmap = Bitmap.createBitmap(bitmapWidth, bitmapHeight, Bitmap.Config.ARGB_8888)
        currentBitmap?.let { bitmap ->
            bitmap.eraseColor(Color.WHITE)
            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
        }
        
        pageIndex = index
        calculateFitScale()
        
        scaleFactor = minScaleFactor
        translateX = 0f
        translateY = 0f
        
        invalidate()
        
        sendLoadComplete(index, pageWidth, pageHeight)
    }

    private fun calculateRenderScale(): Float {
        val displayMetrics = resources.displayMetrics
        val screenDensity = displayMetrics.density
        
        val baseScale = 2.0f * screenDensity
        
        val maxDimension = max(pageWidth, pageHeight) * baseScale
        return if (maxDimension > 4096) {
            4096f / max(pageWidth, pageHeight)
        } else {
            baseScale
        }
    }

    private fun calculateFitScale() {
        if (pageWidth == 0 || pageHeight == 0 || width == 0 || height == 0) return
        
        val scaleX = width.toFloat() / pageWidth
        val scaleY = height.toFloat() / pageHeight
        minScaleFactor = min(scaleX, scaleY)
        
        if (scaleFactor < minScaleFactor) {
            scaleFactor = minScaleFactor
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        
        val bitmap = currentBitmap ?: return
        
        canvas.save()
        
        val scaledWidth = pageWidth * scaleFactor
        val scaledHeight = pageHeight * scaleFactor
        
        val centerX = (width - scaledWidth) / 2 + translateX
        val centerY = (height - scaledHeight) / 2 + translateY
        
        canvas.translate(centerX, centerY)
        canvas.scale(scaleFactor / calculateRenderScale(), scaleFactor / calculateRenderScale())
        
        canvas.drawBitmap(bitmap, 0f, 0f, paint)
        
        canvas.restore()
    }

    private fun sendLoadComplete(page: Int, width: Int, height: Int) {
        val reactContext = context as? ReactContext ?: return
        val event = Arguments.createMap().apply {
            putInt("currentPage", page + 1) // 1-indexed como no iOS
            putInt("width", width)
            putInt("height", height)
        }
        reactContext.getJSModule(RCTEventEmitter::class.java)
            .receiveEvent(id, "onLoadComplete", event)
    }

    private fun sendError(message: String) {
        val reactContext = context as? ReactContext ?: return
        val event = Arguments.createMap().apply {
            putString("message", message)
        }
        reactContext.getJSModule(RCTEventEmitter::class.java)
            .receiveEvent(id, "onError", event)
    }

    private fun sendPageCount(count: Int) {
        val reactContext = context as? ReactContext ?: return
        val event = Arguments.createMap().apply {
            putInt("numberOfPages", count)
        }
        reactContext.getJSModule(RCTEventEmitter::class.java)
            .receiveEvent(id, "onPageCount", event)
    }

    private fun sendPasswordRequired() {
        val reactContext = context as? ReactContext ?: return
        val event = Arguments.createMap()
        reactContext.getJSModule(RCTEventEmitter::class.java)
            .receiveEvent(id, "onPasswordRequired", event)
    }

    fun cleanup() {
        currentPage?.close()
        currentPage = null
        
        pdfRenderer?.close()
        pdfRenderer = null
        
        fileDescriptor?.close()
        fileDescriptor = null
        
        currentBitmap?.recycle()
        currentBitmap = null
        
        decryptedFile?.delete()
        decryptedFile = null
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        cleanup()
    }
}
