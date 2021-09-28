package kr.co.thecheck.android.barcodescantest

import android.app.Activity
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Bundle
import android.view.KeyEvent
import android.view.View
import com.journeyapps.barcodescanner.CaptureManager
import com.journeyapps.barcodescanner.DecoratedBarcodeView
import com.journeyapps.barcodescanner.ViewfinderView
import java.util.*


/**
 * Custom Scannner Activity extending from Activity to display a custom layout form scanner view.
 */
class ScannerActivity : Activity() {

    private var capture: CaptureManager? = null
    private var barcodeScannerView: DecoratedBarcodeView? = null
    private var viewfinderView: ViewfinderView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_scanner)

        barcodeScannerView = findViewById(R.id.zxing_barcode_scanner)
        viewfinderView = findViewById(R.id.zxing_viewfinder_view)

        capture = CaptureManager(this, barcodeScannerView)
        capture!!.initializeFromIntent(intent, savedInstanceState)
        capture!!.setShowMissingCameraPermissionDialog(false)
        capture!!.decode()
        changeMaskColor(null)
        changeLaserVisibility(true)
    }

    override fun onResume() {
        super.onResume()
        capture!!.onResume()
    }

    override fun onPause() {
        super.onPause()
        capture!!.onPause()
    }

    override fun onDestroy() {
        super.onDestroy()
        capture!!.onDestroy()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        capture!!.onSaveInstanceState(outState)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        return barcodeScannerView!!.onKeyDown(keyCode, event) || super.onKeyDown(keyCode, event)
    }

    /**
     * Check if the device's camera has a Flashlight.
     * @return true if there is Flashlight, otherwise false.
     */
    private fun hasFlash(): Boolean {
        return applicationContext.packageManager
            .hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)
    }

    fun changeMaskColor(view: View?) {
        val rnd = Random()
        val color = Color.argb(100, rnd.nextInt(256), rnd.nextInt(256), rnd.nextInt(256))
        viewfinderView!!.setMaskColor(color)
    }

    fun changeLaserVisibility(visible: Boolean) {
        viewfinderView!!.setLaserVisibility(visible)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        capture!!.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}