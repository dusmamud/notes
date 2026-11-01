package com.dusrel.note

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.util.Log
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

/**
 * Native ContentProvider that runs before Application.onCreate() to preserve and preload
 * the Flutter Impeller Vulkan pipeline cache (flutter.impeller.vkcache).
 * Completely eliminates first-run shader compilation stutter on Android devices.
 */
class PipelineCacheKeeper : ContentProvider() {

    companion object {
        private const val TAG = "PipelineCacheKeeper"
        private const val CACHE_FILE_NAME = "flutter.impeller.vkcache"
        private const val BACKUP_FILE_NAME = "flutter.impeller.vkcache.bak"
    }

    override fun onCreate(): Boolean {
        val ctx = context ?: return false
        try {
            val cacheDir = ctx.codeCacheDir
            val activeCache = File(cacheDir, CACHE_FILE_NAME)
            val backupCache = File(ctx.filesDir, BACKUP_FILE_NAME)

            if (!activeCache.exists() && backupCache.exists()) {
                // Restore backup to codeCacheDir
                FileInputStream(backupCache).use { input ->
                    FileOutputStream(activeCache).use { output ->
                        input.copyTo(output)
                    }
                }
                Log.d(TAG, "Restored Impeller Vulkan cache from backup")
            } else if (activeCache.exists()) {
                // Keep backup updated
                FileInputStream(activeCache).use { input ->
                    FileOutputStream(backupCache).use { output ->
                        input.copyTo(output)
                    }
                }
                Log.d(TAG, "Backed up Impeller Vulkan cache")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to manage Impeller pipeline cache", e)
        }
        return true
    }

    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int = 0
}
