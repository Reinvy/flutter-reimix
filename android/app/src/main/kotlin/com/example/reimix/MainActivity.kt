package com.example.reimix

import android.content.ContentUris
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "reimix/media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "querySongs" -> {
                    try {
                        result.success(querySongs())
                    } catch (e: Exception) {
                        result.error("QUERY_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun querySongs(): List<Map<String, Any?>> {
        val songs = mutableListOf<Map<String, Any?>>()

        val projection = buildList {
            add(MediaStore.Audio.Media.DATA)
            add(MediaStore.Audio.Media.TITLE)
            add(MediaStore.Audio.Media.ARTIST)
            add(MediaStore.Audio.Media.ALBUM)
            add(MediaStore.Audio.Media.DURATION)
            add(MediaStore.Audio.Media.TRACK)
            add(MediaStore.Audio.Media.YEAR)
            add(MediaStore.Audio.Media.MIME_TYPE)
            // GENRE column available API 30+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                add(MediaStore.Audio.Media.GENRE)
            }
        }.toTypedArray()

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} = 1"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        val collection: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            @Suppress("DEPRECATION")
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }

        val cursor: Cursor? = contentResolver.query(
            collection,
            projection,
            selection,
            null,
            sortOrder
        )

        cursor?.use { c ->
            val dataCol     = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val titleCol    = c.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol   = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol    = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val trackCol    = c.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)
            val yearCol     = c.getColumnIndexOrThrow(MediaStore.Audio.Media.YEAR)
            val mimeCol     = c.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)
            val genreCol    = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
                                  c.getColumnIndex(MediaStore.Audio.Media.GENRE)
                              else -1

            while (c.moveToNext()) {
                val filePath = c.getString(dataCol) ?: continue
                songs.add(
                    mapOf(
                        "filePath"  to filePath,
                        "title"     to (c.getString(titleCol) ?: filePath.substringAfterLast('/')),
                        "artist"    to c.getString(artistCol),
                        "album"     to c.getString(albumCol),
                        "duration"  to c.getLong(durationCol),
                        "track"     to (if (c.isNull(trackCol)) null else c.getInt(trackCol)),
                        "year"      to (if (c.isNull(yearCol))  null else c.getInt(yearCol)),
                        "mimeType"  to c.getString(mimeCol),
                        "genre"     to (if (genreCol >= 0 && !c.isNull(genreCol)) c.getString(genreCol) else null),
                    )
                )
            }
        }

        return songs
    }
}
