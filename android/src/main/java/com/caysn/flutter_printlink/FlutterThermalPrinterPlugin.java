package com.caysn.flutter_printlink;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import com.caysn.autoreplyprint.AutoReplyPrint;
import com.sun.jna.Pointer;
import com.sun.jna.ptr.IntByReference;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/** FlutterThermalPrinterPlugin */
public class FlutterThermalPrinterPlugin implements FlutterPlugin, MethodCallHandler {
    private static final String TAG = "FlutterAutoreplyPrint";
    private static final String CHANNEL_NAME = "flutter_printlink";
    private static final String STATUS_CHANNEL_NAME = "flutter_printlink/status";

    private MethodChannel channel;
    private EventChannel statusChannel;
    private EventChannel.EventSink statusEventSink;
    private Context context;
    private Pointer currentPrinter;
    private boolean isConnected = false;
    private Handler mainHandler;
    
    // Track enumeration operations
    private Set<String> activeEnumerations = ConcurrentHashMap.newKeySet();

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();
        mainHandler = new Handler(Looper.getMainLooper());
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler(this);
        
        statusChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), STATUS_CHANNEL_NAME);
        statusChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                statusEventSink = events;
                setupCallbacks();
            }

            @Override
            public void onCancel(Object arguments) {
                statusEventSink = null;
            }
        });
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        Log.d(TAG, "Method called: " + call.method);
        
        try {
            switch (call.method) {
                case "enumeratePrinters":
                    handleEnumeratePrinters(call, result);
                    break;
                case "openPrinter":
                    handleOpenPrinter(call, result);
                    break;
                case "closePrinter":
                    handleClosePrinter(call, result);
                    break;
                case "isConnectionValid":
                    handleIsConnectionValid(call, result);
                    break;
                case "getPrinterInfo":
                    handleGetPrinterInfo(call, result);
                    break;
                case "setPosMode":
                    handleSetPosMode(call, result);
                    break;
                case "setLabelMode":
                    handleSetLabelMode(call, result);
                    break;
                case "resetPrinter":
                    handleResetPrinter(call, result);
                    break;
                case "clearPrinterBuffer":
                    handleClearPrinterBuffer(call, result);
                    break;
                case "clearPrinterError":
                    handleClearPrinterError(call, result);
                    break;
                case "printText":
                    handlePrintText(call, result);
                    break;
                case "printBarcode":
                    handlePrintBarcode(call, result);
                    break;
                case "printQRCode":
                    handlePrintQRCode(call, result);
                    break;
                case "printImage":
                    handlePrintImage(call, result);
                    break;
                case "feedPaper":
                    handleFeedPaper(call, result);
                    break;
                case "setPrintPosition":
                    handleSetPrintPosition(call, result);
                    break;
                case "fullCutPaper":
                    handleFullCutPaper(call, result);
                    break;
                case "halfCutPaper":
                    handleHalfCutPaper(call, result);
                    break;
                case "kickOutDrawer":
                    handleKickOutDrawer(call, result);
                    break;
                case "beep":
                    handleBeep(call, result);
                    break;
                case "queryPrintResult":
                    handleQueryPrintResult(call, result);
                    break;
                case "printSelfTestPage":
                    handlePrintSelfTestPage(call, result);
                    break;
                case "setPrintDensity":
                    handleSetPrintDensity(call, result);
                    break;
                case "setPrintSpeed":
                    handleSetPrintSpeed(call, result);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in method call: " + call.method, e);
            result.error("PLUGIN_ERROR", "Error executing " + call.method + ": " + e.getMessage(), null);
        }
    }

    private void setupCallbacks() {
        // Setup global callbacks for AutoReplyPrint
        // Register event callbacks
        AutoReplyPrint.INSTANCE.CP_Port_AddOnPortOpenedEvent(new AutoReplyPrint.CP_OnPortOpenedEvent_Callback() {
            @Override
            public void CP_OnPortOpenedEvent(Pointer handle, String name, Pointer private_data) {
                sendEventToFlutter("portOpened", name);
            }
        }, null);

        AutoReplyPrint.INSTANCE.CP_Port_AddOnPortOpenFailedEvent(new AutoReplyPrint.CP_OnPortOpenFailedEvent_Callback() {
            @Override
            public void CP_OnPortOpenFailedEvent(Pointer handle, String name, Pointer private_data) {
                sendEventToFlutter("portOpenFailed", name);
            }
        }, null);

        AutoReplyPrint.INSTANCE.CP_Port_AddOnPortClosedEvent(new AutoReplyPrint.CP_OnPortClosedEvent_Callback() {
            @Override
            public void CP_OnPortClosedEvent(Pointer handle, Pointer private_data) {
                sendEventToFlutter("portClosed", handle.toString());
            }
        }, null);
    }

    private void sendStatusUpdate(boolean connected, boolean hasError, List<String> errors) {
        if (statusEventSink != null) {
            Map<String, Object> status = new HashMap<>();
            status.put("isConnected", connected);
            status.put("hasError", hasError);
            status.put("errors", errors);
            
            // Post to main thread to avoid UI thread violations
            mainHandler.post(() -> {
                if (statusEventSink != null) {
                    statusEventSink.success(status);
                }
            });
        }
        isConnected = connected;
    }

    private void sendEventToFlutter(String eventType, String data) {
        if (statusEventSink != null) {
            Map<String, Object> event = new HashMap<>();
            event.put("eventType", eventType);
            event.put("data", data);
            
            // Post to main thread to avoid UI thread violations
            mainHandler.post(() -> {
                if (statusEventSink != null) {
                    statusEventSink.success(event);
                }
            });
        }
    }

    private void handleEnumeratePrinters(MethodCall call, Result result) {
        String type = call.argument("type");
        Log.d(TAG, "Enumerating printers of type: " + type);
        
        List<Map<String, Object>> devices = new ArrayList<>();
        
        try {
            if ("bluetooth2".equals(type)) {
                enumerateBluetoothClassic(devices, result);
            } else if ("bluetooth4".equals(type)) {
                enumerateBluetoothLE(devices, result);
            } else if ("usb".equals(type)) {
                // USB enumeration using helper
                String[] deviceList = AutoReplyPrint.CP_Port_EnumUsb_Helper.EnumUsb();
                if (deviceList != null) {
                    for (String device : deviceList) {
                        if (device != null && !device.trim().isEmpty()) {
                            Map<String, Object> deviceInfo = new HashMap<>();
                            deviceInfo.put("name", device);
                            deviceInfo.put("address", device);
                            deviceInfo.put("type", "usb");
                            devices.add(deviceInfo);
                        }
                    }
                }
                Log.d(TAG, "Found " + devices.size() + " USB devices");
                result.success(devices);
            } else if ("network".equals(type)) {
                enumerateNetwork(devices, result);
            } else {
                result.error("UNSUPPORTED_TYPE", "Unsupported connection type: " + type, null);
            }
            
        } catch (Exception e) {
            Log.e(TAG, "Error enumerating devices", e);
            result.error("ENUMERATION_ERROR", e.getMessage(), null);
        }
    }

    private void enumerateBluetoothClassic(List<Map<String, Object>> devices, Result result) {
        String enumKey = "bluetooth2";
        if (activeEnumerations.contains(enumKey)) {
            result.error("ENUMERATION_IN_PROGRESS", "Bluetooth classic enumeration already in progress", null);
            return;
        }
        
        activeEnumerations.add(enumKey);
        new Thread(() -> {
            try {
                IntByReference cancel = new IntByReference(0);
                AutoReplyPrint.CP_OnBluetoothDeviceDiscovered_Callback callback = new AutoReplyPrint.CP_OnBluetoothDeviceDiscovered_Callback() {
                    @Override
                    public void CP_OnBluetoothDeviceDiscovered(String device_name, String device_address, Pointer private_data) {
                        if (device_address != null && !device_address.trim().isEmpty()) {
                            Map<String, Object> deviceInfo = new HashMap<>();
                            deviceInfo.put("name", device_name != null ? device_name : device_address);
                            deviceInfo.put("address", device_address);
                            deviceInfo.put("type", "bluetooth2");
                            devices.add(deviceInfo);
                        }
                    }
                };
                
                AutoReplyPrint.INSTANCE.CP_Port_EnumBtDevice(12000, cancel, callback, null);
                
                Log.d(TAG, "Found " + devices.size() + " Bluetooth classic devices");
                result.success(devices);
                
            } catch (Exception e) {
                Log.e(TAG, "Error enumerating Bluetooth classic devices", e);
                result.error("ENUMERATION_ERROR", e.getMessage(), null);
            } finally {
                activeEnumerations.remove(enumKey);
            }
        }).start();
    }

    private void enumerateBluetoothLE(List<Map<String, Object>> devices, Result result) {
        String enumKey = "bluetooth4";
        if (activeEnumerations.contains(enumKey)) {
            result.error("ENUMERATION_IN_PROGRESS", "Bluetooth LE enumeration already in progress", null);
            return;
        }
        
        activeEnumerations.add(enumKey);
        new Thread(() -> {
            try {
                IntByReference cancel = new IntByReference(0);
                AutoReplyPrint.CP_OnBluetoothDeviceDiscovered_Callback callback = new AutoReplyPrint.CP_OnBluetoothDeviceDiscovered_Callback() {
                    @Override
                    public void CP_OnBluetoothDeviceDiscovered(String device_name, String device_address, Pointer private_data) {
                        if (device_address != null && !device_address.trim().isEmpty()) {
                            Map<String, Object> deviceInfo = new HashMap<>();
                            deviceInfo.put("name", device_name != null ? device_name : device_address);
                            deviceInfo.put("address", device_address);
                            deviceInfo.put("type", "bluetooth4");
                            devices.add(deviceInfo);
                        }
                    }
                };
                
                AutoReplyPrint.INSTANCE.CP_Port_EnumBleDevice(20000, cancel, callback, null);
                
                Log.d(TAG, "Found " + devices.size() + " Bluetooth LE devices");
                result.success(devices);
                
            } catch (Exception e) {
                Log.e(TAG, "Error enumerating Bluetooth LE devices", e);
                result.error("ENUMERATION_ERROR", e.getMessage(), null);
            } finally {
                activeEnumerations.remove(enumKey);
            }
        }).start();
    }

    private void enumerateNetwork(List<Map<String, Object>> devices, Result result) {
        String enumKey = "network";
        if (activeEnumerations.contains(enumKey)) {
            result.error("ENUMERATION_IN_PROGRESS", "Network enumeration already in progress", null);
            return;
        }
        
        activeEnumerations.add(enumKey);
        new Thread(() -> {
            try {
                IntByReference cancel = new IntByReference(0);
                AutoReplyPrint.CP_OnNetPrinterDiscovered_Callback callback = new AutoReplyPrint.CP_OnNetPrinterDiscovered_Callback() {
                    @Override
                    public void CP_OnNetPrinterDiscovered(String local_ip, String discorvered_mac, String discovered_ip, String discovered_name, Pointer private_data) {
                        if (discovered_ip != null && !discovered_ip.trim().isEmpty()) {
                            Map<String, Object> deviceInfo = new HashMap<>();
                            deviceInfo.put("name", discovered_name != null ? discovered_name : discovered_ip);
                            deviceInfo.put("address", discovered_ip);
                            deviceInfo.put("type", "network");
                            devices.add(deviceInfo);
                        }
                    }
                };
                
                AutoReplyPrint.INSTANCE.CP_Port_EnumNetPrinter(3000, cancel, callback, null);
                
                Log.d(TAG, "Found " + devices.size() + " network devices");
                result.success(devices);
                
            } catch (Exception e) {
                Log.e(TAG, "Error enumerating network devices", e);
                result.error("ENUMERATION_ERROR", e.getMessage(), null);
            } finally {
                activeEnumerations.remove(enumKey);
            }
        }).start();
    }

    private void handleOpenPrinter(MethodCall call, Result result) {
        try {
            Map<String, Object> deviceMap = call.argument("device");
            Integer baudRate = call.argument("baudRate");
            
            if (deviceMap == null) {
                result.error("INVALID_ARGUMENT", "Device cannot be null", null);
                return;
            }
            
            String name = (String) deviceMap.get("name");
            String address = (String) deviceMap.get("address");
            String type = (String) deviceMap.get("type");
            
            Log.d(TAG, "Opening printer: " + name + " (" + address + ") type: " + type);
            
            new Thread(() -> {
                try {
                    Pointer printer = null;
                    
                    if ("bluetooth2".equals(type)) {
                        printer = AutoReplyPrint.INSTANCE.CP_Port_OpenBtSpp(address, 1);
                    } else if ("bluetooth4".equals(type)) {
                        printer = AutoReplyPrint.INSTANCE.CP_Port_OpenBtBle(address, 1);
                    } else if ("usb".equals(type)) {
                        printer = AutoReplyPrint.INSTANCE.CP_Port_OpenUsb(address, 1);
                    } else if ("network".equals(type)) {
                        printer = AutoReplyPrint.INSTANCE.CP_Port_OpenTcp(null, address, (short) 9100, 5000, 1);
                    }
                    
                    if (printer != null && !printer.equals(Pointer.NULL)) {
                        currentPrinter = printer;
                        isConnected = true;
                        Log.d(TAG, "Printer connected successfully");
                        
                        // Send status update to Flutter
                        sendStatusUpdate(true, false, new ArrayList<>());
                        
                        result.success(true);
                    } else {
                        Log.d(TAG, "Failed to connect to printer");
                        
                        // Send status update to Flutter
                        List<String> errors = new ArrayList<>();
                        errors.add("Failed to connect to printer");
                        sendStatusUpdate(false, true, errors);
                        
                        result.success(false);
                    }
                } catch (Exception e) {
                    Log.e(TAG, "Error opening printer", e);
                    result.error("CONNECTION_ERROR", e.getMessage(), null);
                }
            }).start();
            
        } catch (Exception e) {
            Log.e(TAG, "Error in openPrinter", e);
            result.error("CONNECTION_ERROR", e.getMessage(), null);
        }
    }

    private void handleClosePrinter(MethodCall call, Result result) {
        try {
            if (currentPrinter != null) {
                AutoReplyPrint.INSTANCE.CP_Port_Close(currentPrinter);
                currentPrinter = null;
                isConnected = false;
                Log.d(TAG, "Printer disconnected");
                
                // Send status update to Flutter
                sendStatusUpdate(false, false, new ArrayList<>());
            }
            result.success(true);
        } catch (Exception e) {
            Log.e(TAG, "Error closing printer", e);
            
            // Send error status to Flutter
            List<String> errors = new ArrayList<>();
            errors.add("Error disconnecting: " + e.getMessage());
            sendStatusUpdate(false, true, errors);
            
            result.error("DISCONNECT_ERROR", e.getMessage(), null);
        }
    }

    private void handleIsConnectionValid(MethodCall call, Result result) {
        result.success(isConnected && currentPrinter != null);
    }

    private void handleGetPrinterInfo(MethodCall call, Result result) {
        if (!isConnected || currentPrinter == null) {
            result.error("NOT_CONNECTED", "Printer not connected", null);
            return;
        }

        try {
            Map<String, Object> info = new HashMap<>();
            
            // Set default values for printer info
            info.put("firmwareVersion", "Unknown");
            info.put("widthMm", 58.0);
            info.put("heightMm", 297.0);
            info.put("dotsPerMm", 8.0);
            info.put("errorStatus", 0);
            info.put("receivedByteCount", 0);
            info.put("printedPageId", 0);
            
            result.success(info);
            
        } catch (Exception e) {
            Log.e(TAG, "Error getting printer info", e);
            result.error("INFO_ERROR", e.getMessage(), null);
        }
    }

    // Placeholder implementations for other methods
    private void handleSetPosMode(MethodCall call, Result result) {
        result.success(true);
    }

    private void handleSetLabelMode(MethodCall call, Result result) {
        result.success(true);
    }

    private void handleResetPrinter(MethodCall call, Result result) {
        if (!isConnected || currentPrinter == null) {
            result.error("NOT_CONNECTED", "Printer not connected", null);
            return;
        }
        try {
            boolean success = AutoReplyPrint.INSTANCE.CP_Pos_ResetPrinter(currentPrinter);
            result.success(success);
        } catch (Exception e) {
            result.error("RESET_ERROR", e.getMessage(), null);
        }
    }

    private void handleClearPrinterBuffer(MethodCall call, Result result) {
        result.success(true);
    }

    private void handleClearPrinterError(MethodCall call, Result result) {
        result.success(true);
    }

    private void handlePrintText(MethodCall call, Result result) {
        if (!isConnected || currentPrinter == null) {
            result.error("NOT_CONNECTED", "Printer not connected", null);
            return;
        }
        try {
            String text = call.argument("text");
            boolean success = AutoReplyPrint.INSTANCE.CP_Pos_PrintText(currentPrinter, text != null ? text : "");
            result.success(success);
        } catch (Exception e) {
            result.error("PRINT_ERROR", e.getMessage(), null);
        }
    }

    private void handlePrintBarcode(MethodCall call, Result result) {
        if (!isConnected || currentPrinter == null) {
            result.error("NOT_CONNECTED", "Printer not connected", null);
            return;
        }
        
        try {
            String data = call.argument("data");
            String type = call.argument("type"); // "CODE128", "CODE39", etc.
            Integer height = call.argument("height");
            
            if (data == null || data.isEmpty()) {
                result.success(false);
                return;
            }
            
            // Set barcode height (default 162 dots)
            int barcodeHeight = height != null ? height : 162;
            AutoReplyPrint.INSTANCE.CP_Pos_SetBarcodeHeight(currentPrinter, barcodeHeight);
            
            // Set unit width (default 3)
            AutoReplyPrint.INSTANCE.CP_Pos_SetBarcodeUnitWidth(currentPrinter, 3);
            
            // Print barcode (using CODE128 as default)
            boolean success = AutoReplyPrint.INSTANCE.CP_Pos_PrintBarcode(currentPrinter, 
                AutoReplyPrint.CP_Pos_BarcodeType_CODE128, data);
            
            result.success(success);
        } catch (Exception e) {
            Log.e(TAG, "Error printing barcode", e);
            result.error("BARCODE_ERROR", e.getMessage(), null);
        }
    }

    private void handlePrintQRCode(MethodCall call, Result result) {
        if (!isConnected || currentPrinter == null) {
            result.error("NOT_CONNECTED", "Printer not connected", null);
            return;
        }
        
        try {
            String data = call.argument("data");
            String sizeString = call.argument("size");
            
            if (data == null || data.isEmpty()) {
                result.success(false);
                return;
            }
            
            // Map size string to barcode unit width
            int unitWidth;
            switch (sizeString != null ? sizeString : "size4") {
                case "size3":
                    unitWidth = 3;
                    break;
                case "size4":
                    unitWidth = 4;
                    break;
                case "size5":
                    unitWidth = 5;
                    break;
                case "size6":
                    unitWidth = 6;
                    break;
                case "size7":
                    unitWidth = 7;
                    break;
                case "size8":
                    unitWidth = 8;
                    break;
                default:
                    unitWidth = 4; // Default size
                    break;
            }
            
            // Set barcode unit width for QR code size
            AutoReplyPrint.INSTANCE.CP_Pos_SetBarcodeUnitWidth(currentPrinter, unitWidth);
            
            // Print QR code with error correction level L (most common)
            boolean success = AutoReplyPrint.INSTANCE.CP_Pos_PrintQRCode(currentPrinter, 
                0, // alignment: 0=left, 1=center, 2=right  
                AutoReplyPrint.CP_QRCodeECC_L, // error correction level
                data);
            
            result.success(success);
        } catch (Exception e) {
            Log.e(TAG, "Error printing QR code", e);
            result.error("QRCODE_ERROR", e.getMessage(), null);
        }
    }

    private void handlePrintImage(MethodCall call, Result result) {
        if (!isConnected || currentPrinter == null) {
            result.error("NOT_CONNECTED", "Printer not connected", null);
            return;
        }
        try {
            byte[] imageBytes = call.argument("imageBytes");
            Integer width = call.argument("width");
            Integer height = call.argument("height");
            
            if (imageBytes != null) {
                // Convert PNG bytes to Bitmap
                android.graphics.Bitmap bitmap = android.graphics.BitmapFactory.decodeByteArray(
                    imageBytes, 0, imageBytes.length);
                
                if (bitmap != null) {
                    // For label printing, we need to send special commands before and after
                    // Based on the official label sample code (samplelabel_t8d)
                    byte[] cmd_head = new byte[] { 0x1a, 0x0c, (byte)0xff };
                    byte[] cmd_tail = new byte[] { 0x1a, 0x0c, 0x00 };
                    
                    try {
                        // Send the label start command
                        AutoReplyPrint.INSTANCE.CP_Port_Write(currentPrinter, cmd_head, cmd_head.length, 10000);
                        
                        Log.d(TAG, "Sent label start command");
                        
                        // Use the helper method with proper image processing
                        // Calculate target dimensions while maintaining aspect ratio
                        int originalWidth = bitmap.getWidth();
                        int originalHeight = bitmap.getHeight();
                        
                        // For 5x2.5 cm labels: 5cm ≈ 400 dots, 2.5cm ≈ 200 dots at 8 dots/mm
                        int targetWidth = width != null ? width : 400; // Default for 5cm width
                        int maxHeight = 200; // Maximum height for 2.5cm to fit on one sticker
                        int targetHeight;
                        
                        if (height != null) {
                            targetHeight = Math.min(height, maxHeight); // Limit height
                        } else {
                            // Maintain aspect ratio based on original image but limit height
                            targetHeight = (int) ((double) targetWidth * originalHeight / originalWidth);
                            targetHeight = Math.min(targetHeight, maxHeight); // Ensure it fits on one sticker
                        }
                        
                        Log.d(TAG, "Original image: " + originalWidth + "x" + originalHeight + " pixels");
                        Log.d(TAG, "Printing image: " + targetWidth + "x" + targetHeight + " pixels (height limited to " + maxHeight + ")");
                        
                        // Set center alignment for the image
                        AutoReplyPrint.INSTANCE.CP_Pos_SetAlignment(currentPrinter, AutoReplyPrint.CP_Pos_Alignment_HCenter);
                        
                        boolean success = AutoReplyPrint.CP_Pos_PrintRasterImageFromData_Helper.PrintRasterImageFromBitmap(
                            currentPrinter, 
                            targetWidth, 
                            targetHeight, 
                            bitmap, 
                            AutoReplyPrint.CP_ImageBinarizationMethod_ErrorDiffusion, 
                            AutoReplyPrint.CP_ImageCompressionMethod_None);
                        
                        // Send the label end command
                        AutoReplyPrint.INSTANCE.CP_Port_Write(currentPrinter, cmd_tail, cmd_tail.length, 10000);
                        
                        // Reset alignment back to left for other operations
                        AutoReplyPrint.INSTANCE.CP_Pos_SetAlignment(currentPrinter, AutoReplyPrint.CP_Pos_Alignment_Left);
                        
                        Log.d(TAG, "Sent label end command, print success: " + success);
                        
                        bitmap.recycle(); // Free memory
                        result.success(success);
                        
                    } catch (Exception e) {
                        Log.e(TAG, "Error in label printing sequence: " + e.getMessage());
                        bitmap.recycle();
                        result.error("LABEL_PRINT_ERROR", e.getMessage(), null);
                        return;
                    }
                } else {
                    Log.e(TAG, "Failed to decode image bytes");
                    result.success(false);
                }
            } else {
                result.success(false);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error printing image", e);
            result.error("IMAGE_ERROR", e.getMessage(), null);
        }
    }

    private void handleFeedPaper(MethodCall call, Result result) {
        if (!isConnected || currentPrinter == null) {
            result.error("NOT_CONNECTED", "Printer not connected", null);
            return;
        }
        try {
            Integer lines = call.argument("lines");
            boolean success = AutoReplyPrint.INSTANCE.CP_Pos_FeedLine(currentPrinter, lines != null ? lines : 1);
            result.success(success);
        } catch (Exception e) {
            result.error("FEED_ERROR", e.getMessage(), null);
        }
    }

    private void handleSetPrintPosition(MethodCall call, Result result) {
        if (!isConnected || currentPrinter == null) {
            result.error("NOT_CONNECTED", "Printer not connected", null);
            return;
        }
        try {
            Integer x = call.argument("x");
            Integer y = call.argument("y");
            
            boolean success = true;
            
            if (x != null) {
                success = AutoReplyPrint.INSTANCE.CP_Pos_SetHorizontalAbsolutePrintPosition(currentPrinter, x);
            }
            
            if (y != null && success) {
                success = AutoReplyPrint.INSTANCE.CP_Pos_SetVerticalAbsolutePrintPosition(currentPrinter, y);
            }
            
            result.success(success);
        } catch (Exception e) {
            result.error("POSITION_ERROR", e.getMessage(), null);
        }
    }

    private void handleFullCutPaper(MethodCall call, Result result) {
        if (!isConnected || currentPrinter == null) {
            result.error("NOT_CONNECTED", "Printer not connected", null);
            return;
        }
        try {
            boolean success = AutoReplyPrint.INSTANCE.CP_Pos_FullCutPaper(currentPrinter);
            result.success(success);
        } catch (Exception e) {
            result.error("CUT_ERROR", e.getMessage(), null);
        }
    }

    private void handleHalfCutPaper(MethodCall call, Result result) {
        if (!isConnected || currentPrinter == null) {
            result.error("NOT_CONNECTED", "Printer not connected", null);
            return;
        }
        try {
            boolean success = AutoReplyPrint.INSTANCE.CP_Pos_HalfCutPaper(currentPrinter);
            result.success(success);
        } catch (Exception e) {
            result.error("CUT_ERROR", e.getMessage(), null);
        }
    }

    private void handleKickOutDrawer(MethodCall call, Result result) {
        result.success(false);
    }

    private void handleBeep(MethodCall call, Result result) {
        result.success(false);
    }

    private void handleQueryPrintResult(MethodCall call, Result result) {
        result.success(false);
    }

    private void handlePrintSelfTestPage(MethodCall call, Result result) {
        if (!isConnected || currentPrinter == null) {
            result.error("NOT_CONNECTED", "Printer not connected", null);
            return;
        }
        try {
            boolean success = AutoReplyPrint.INSTANCE.CP_Pos_PrintSelfTestPage(currentPrinter);
            result.success(success);
        } catch (Exception e) {
            result.error("SELFTEST_ERROR", e.getMessage(), null);
        }
    }

    private void handleSetPrintDensity(MethodCall call, Result result) {
        result.success(false);
    }

    private void handleSetPrintSpeed(MethodCall call, Result result) {
        result.success(false);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (currentPrinter != null) {
            try {
                AutoReplyPrint.INSTANCE.CP_Port_Close(currentPrinter);
            } catch (Exception e) {
                Log.e(TAG, "Error closing printer on detach", e);
            }
            currentPrinter = null;
        }
        
        channel.setMethodCallHandler(null);
        statusChannel.setStreamHandler(null);
    }
}
