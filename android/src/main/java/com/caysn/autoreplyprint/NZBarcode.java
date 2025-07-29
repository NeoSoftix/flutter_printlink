package com.caysn.autoreplyprint;

import com.sun.jna.Library;
import com.sun.jna.Native;
import com.sun.jna.Platform;
import com.sun.jna.ptr.IntByReference;

public interface NZBarcode extends Library {

    // static interface method need jdk1.8. here we use inner class to avoid this porblem.
    class GetLibraryPath_Helper {
        // can replaced by absolute path
        public static String GetLibraryPath() {
            // force call JNI_OnLoad
            if (Platform.isAndroid())
                System.loadLibrary("autoreplyprint");
            return "autoreplyprint";
        }
    }

    public static final NZBarcode INSTANCE = (NZBarcode) Native.loadLibrary(NZBarcode.GetLibraryPath_Helper.GetLibraryPath(), NZBarcode.class);

    public int CP_Barcode_GetBarcodeWidth(int barcodeType, int barcodeUnitWidth, String barcodeData);

    public boolean CP_Barcode_GetBarcodeRGBAData(int barcodeType, int barcodeUnitWidth, int barcodeHeight, int barcodeColor, String barcodeData, int[] bitmap_buffer, int bitmap_buffer_bytesize, IntByReference bitmap_width, IntByReference bitmap_height);

}
