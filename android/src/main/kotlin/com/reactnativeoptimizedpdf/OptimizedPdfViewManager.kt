package com.reactnativeoptimizedpdf

import com.facebook.react.bridge.ReadableMap
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp

/**
 * ViewManager que expõe o OptimizedPdfView para o React Native
 * 
 * Props suportadas:
 * - source: String (caminho do arquivo PDF)
 * - page: Int (página atual, 0-indexed)
 * - maximumZoom: Float (zoom máximo permitido)
 * - enableAntialiasing: Boolean (habilitar antialiasing)
 */
class OptimizedPdfViewManager : SimpleViewManager<OptimizedPdfView>() {

    companion object {
        const val REACT_CLASS = "OptimizedPdfView"
    }

    override fun getName(): String = REACT_CLASS

    override fun createViewInstance(reactContext: ThemedReactContext): OptimizedPdfView {
        return OptimizedPdfView(reactContext)
    }

    @ReactProp(name = "source")
    fun setSource(view: OptimizedPdfView, source: String?) {
        source?.let { view.setSource(it) }
    }

    @ReactProp(name = "page", defaultInt = 0)
    fun setPage(view: OptimizedPdfView, page: Int) {
        view.setPage(page)
    }

    @ReactProp(name = "maximumZoom", defaultFloat = 5.0f)
    fun setMaximumZoom(view: OptimizedPdfView, maximumZoom: Float) {
        view.setMaximumZoom(maximumZoom)
    }

    @ReactProp(name = "enableAntialiasing", defaultBoolean = true)
    fun setEnableAntialiasing(view: OptimizedPdfView, enableAntialiasing: Boolean) {
        view.setEnableAntialiasing(enableAntialiasing)
    }

    override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any>? {
        return MapBuilder.builder<String, Any>()
            .put("onLoadComplete", MapBuilder.of("registrationName", "onLoadComplete"))
            .put("onError", MapBuilder.of("registrationName", "onError"))
            .put("onPageCount", MapBuilder.of("registrationName", "onPageCount"))
            .build()
    }

    override fun onDropViewInstance(view: OptimizedPdfView) {
        super.onDropViewInstance(view)
        view.cleanup()
    }
}
