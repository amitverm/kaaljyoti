package com.kaaljyoti

import com.google.android.gms.auth.blockstore.Blockstore
import com.google.android.gms.auth.blockstore.RetrieveBytesRequest
import com.google.android.gms.auth.blockstore.StoreBytesData
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Google Block Store carries the SQLCipher passphrase to the user's
        // next device (E2E-encrypted with the lockscreen), where the
        // Keystore-held copy cannot follow. No maintained Flutter plugin
        // exists, hence this small channel. Failures are expected on devices
        // without Play Services or a lockscreen — Dart falls back to
        // generating a fresh key.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "read" -> {
                        val request = RetrieveBytesRequest.Builder()
                            .setKeys(listOf(BLOCKSTORE_KEY))
                            .build()
                        Blockstore.getClient(this).retrieveBytes(request)
                            .addOnSuccessListener { response ->
                                val data = response.blockstoreDataMap[BLOCKSTORE_KEY]
                                result.success(data?.bytes?.toString(Charsets.UTF_8))
                            }
                            .addOnFailureListener { e ->
                                result.error("blockstore_read", e.message, null)
                            }
                    }
                    "write" -> {
                        val value = call.argument<String>("value")
                        if (value == null) {
                            result.error("blockstore_write", "missing value", null)
                            return@setMethodCallHandler
                        }
                        val data = StoreBytesData.Builder()
                            .setBytes(value.toByteArray(Charsets.UTF_8))
                            .setKey(BLOCKSTORE_KEY)
                            .setShouldBackupToCloud(true)
                            .build()
                        Blockstore.getClient(this).storeBytes(data)
                            .addOnSuccessListener { result.success(true) }
                            .addOnFailureListener { e ->
                                result.error("blockstore_write", e.message, null)
                            }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private companion object {
        const val CHANNEL = "kaaljyoti/blockstore"
        const val BLOCKSTORE_KEY = "kaaljyoti_db_passphrase_v1"
    }
}
