package com.dusrel.note.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import kotlin.math.max

object WidgetBitmapHelper {
    fun renderText(text: String, textSize: Float, textColor: Int, isBold: Boolean = false): Bitmap {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.textSize = textSize
            this.color = textColor
            typeface = if (isBold) Typeface.create(Typeface.DEFAULT, Typeface.BOLD) else Typeface.DEFAULT
        }
        val width = max(1, paint.measureText(text).toInt() + 4)
        val fontMetrics = paint.fontMetrics
        val height = max(1, (fontMetrics.descent - fontMetrics.ascent).toInt() + 4)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawText(text, 2f, -fontMetrics.ascent + 2f, paint)
        return bitmap
    }
}

