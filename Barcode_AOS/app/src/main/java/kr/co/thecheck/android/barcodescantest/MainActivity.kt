package kr.co.thecheck.android.barcodescantest

import android.content.Intent
import android.graphics.Bitmap
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.ImageView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.zxing.BarcodeFormat
import com.google.zxing.client.android.Intents
import com.google.zxing.integration.android.IntentIntegrator
import com.journeyapps.barcodescanner.BarcodeEncoder


class MainActivity : AppCompatActivity() {

    var QRCODE_REQUEST_CODE = 0x0000fff

    var imgView:ImageView? = null
    var btnScanner:Button? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        imgView = findViewById<ImageView>(R.id.imgView)
        imgView?.let {
            it.setImageBitmap(getQrCodeBitmap("ssid", "password")!!)
        }

        btnScanner = findViewById<Button>(R.id.btnScanner)
        btnScanner?.let {
            it.setOnClickListener {
                scanBarcodeCustomLayout()
            }
        }
    }

    fun scanBarcodeCustomLayout() {
        val integrator = IntentIntegrator(this)
        integrator.captureActivity = ScannerActivity::class.java
        integrator.setDesiredBarcodeFormats(IntentIntegrator.QR_CODE)
        integrator.setRequestCode(QRCODE_REQUEST_CODE)
        integrator.setPrompt("Scan something")
        integrator.setOrientationLocked(true)
        integrator.setBeepEnabled(false)
        integrator.initiateScan()
    }

    fun getQrCodeBitmap(ssid: String, password: String): Bitmap? {
        try {
            val barcodeEncoder = BarcodeEncoder()
            return barcodeEncoder.encodeBitmap("${ssid} ${password}", BarcodeFormat.QR_CODE, 512, 512)
        } catch (e: Exception) {
        }

        return null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        when (requestCode) {
            QRCODE_REQUEST_CODE -> {

                val result = IntentIntegrator.parseActivityResult(resultCode, data)
                if (result.contents == null) {
                    val originalIntent = result.originalIntent
                    if (originalIntent == null) {
                        Log.d("MainActivity", "Cancelled scan")
                        Toast.makeText(this, "Cancelled", Toast.LENGTH_LONG).show()
                    } else if (originalIntent.hasExtra(Intents.Scan.MISSING_CAMERA_PERMISSION)) {
                        Log.d("MainActivity", "Cancelled scan due to missing camera permission")
                        Toast.makeText(
                            this,
                            "Cancelled due to missing camera permission",
                            Toast.LENGTH_LONG
                        ).show()
                    }
                } else {
                    Log.d("MainActivity", "Scanned")
                    Toast.makeText(this, "Scanned: " + result.contents, Toast.LENGTH_LONG).show()
                }
            }
            else -> {
            }
        }
    }
}