import Flutter
import UIKit
import CoreBluetooth
import ExternalAccessory

public class FlutterThermalPrinterPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    
    // Bluetooth management
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var printerCharacteristic: CBCharacteristic?
    
    // Connection state
    private var isConnected = false
    private var discoveredDevices: [CBPeripheral] = []
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_printlink", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "flutter_printlink/status", binaryMessenger: registrar.messenger())
        let instance = FlutterThermalPrinterPlugin()
        
        instance.channel = channel
        instance.eventChannel = eventChannel
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enumeratePrinters":
            handleEnumeratePrinters(call, result: result)
        case "openPrinter":
            handleOpenPrinter(call, result: result)
        case "closePrinter":
            handleClosePrinter(call, result: result)
        case "printText":
            handlePrintText(call, result: result)
        case "printQRCode":
            handlePrintQRCode(call, result: result)
        case "printImage":
            handlePrintImage(call, result: result)
        case "printBarcode":
            handlePrintBarcode(call, result: result)
        case "setLabelMode":
            handleSetLabelMode(call, result: result)
        case "setPosMode":
            handleSetPosMode(call, result: result)
        case "halfCutPaper":
            handleHalfCutPaper(call, result: result)
        case "fullCutPaper":
            handleFullCutPaper(call, result: result)
        case "resetPrinter":
            handleResetPrinter(call, result: result)
        case "getPrinterInfo":
            handleGetPrinterInfo(call, result: result)
        case "printSelfTestPage":
            handlePrintSelfTestPage(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Device Enumeration
    private func handleEnumeratePrinters(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let typeString = args["type"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid connection type", details: nil))
            return
        }
        
        switch typeString {
        case "bluetooth2", "bluetooth4":
            enumerateBluetoothPrinters(result: result)
        case "usb":
            enumerateUSBPrinters(result: result)
        case "network":
            enumerateNetworkPrinters(result: result)
        default:
            result(FlutterError(code: "UNSUPPORTED_TYPE", message: "Connection type not supported on iOS", details: nil))
        }
    }
    
    private func enumerateBluetoothPrinters(result: @escaping FlutterResult) {
        discoveredDevices.removeAll()
        
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
        
        // Store the result callback for later use
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let devices = self.discoveredDevices.map { peripheral in
                return [
                    "name": peripheral.name ?? "Unknown Device",
                    "address": peripheral.identifier.uuidString,
                    "type": "bluetooth"
                ]
            }
            result(devices)
        }
        
        if centralManager?.state == .poweredOn {
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    private func enumerateUSBPrinters(result: @escaping FlutterResult) {
        // iOS doesn't support direct USB printer connections like Android
        // This would require MFi certified accessories
        let accessories = EAAccessoryManager.shared().connectedAccessories
        let usbDevices = accessories.compactMap { accessory -> [String: Any]? in
            if accessory.protocolStrings.contains("com.apple.printer") {
                return [
                    "name": accessory.name,
                    "address": accessory.serialNumber ?? "",
                    "type": "usb"
                ]
            }
            return nil
        }
        result(usbDevices)
    }
    
    private func enumerateNetworkPrinters(result: @escaping FlutterResult) {
        // Network printer discovery would require implementing Bonjour/mDNS
        // For now, return empty array
        result([])
    }
    
    // MARK: - Connection Management
    private func handleOpenPrinter(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let deviceInfo = args["device"] as? [String: Any],
              let address = deviceInfo["address"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing device information", details: nil))
            return
        }
        
        // Find the peripheral by UUID
        if let peripheral = discoveredDevices.first(where: { $0.identifier.uuidString == address }) {
            connectedPeripheral = peripheral
            centralManager?.connect(peripheral, options: nil)
            
            // Wait for actual connection result from delegate
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if self.isConnected {
                    result(true)
                } else {
                    result(FlutterError(code: "CONNECTION_TIMEOUT", message: "Connection timed out", details: nil))
                }
            }
        } else {
            result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device not found", details: nil))
        }
    }
    
    private func handleClosePrinter(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        
        isConnected = false
        connectedPeripheral = nil
        printerCharacteristic = nil
        sendStatusUpdate()
        result(true)
    }
    
    // MARK: - Printing Operations
    private func handlePrintText(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let text = args["text"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing text parameter", details: nil))
            return
        }
        
        guard isConnected else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Printer not connected", details: nil))
            return
        }
        
        // Convert text to printer commands (ESC/POS)
        var printData = Data()
        
        // Apply settings if provided
        if let settings = args["settings"] as? [String: Any] {
            if let alignment = settings["alignment"] as? String {
                switch alignment {
                case "center":
                    printData.append(Data([0x1B, 0x61, 0x01])) // ESC a 1
                case "right":
                    printData.append(Data([0x1B, 0x61, 0x02])) // ESC a 2
                default:
                    printData.append(Data([0x1B, 0x61, 0x00])) // ESC a 0 (left)
                }
            }
            
            if let bold = settings["bold"] as? Bool, bold {
                printData.append(Data([0x1B, 0x45, 0x01])) // ESC E 1 (bold on)
            }
            
            if let textSize = settings["textSize"] as? String {
                switch textSize {
                case "size2":
                    printData.append(Data([0x1D, 0x21, 0x11])) // Double width and height
                case "size3":
                    printData.append(Data([0x1D, 0x21, 0x22])) // Triple width and height
                case "size4":
                    printData.append(Data([0x1D, 0x21, 0x33])) // Quad width and height
                default:
                    printData.append(Data([0x1D, 0x21, 0x00])) // Normal size
                }
            }
        }
        
        // Add text data
        if let textData = text.data(using: .utf8) {
            printData.append(textData)
        }
        
        // Reset formatting
        printData.append(Data([0x1B, 0x45, 0x00])) // Bold off
        printData.append(Data([0x1D, 0x21, 0x00])) // Normal size
        printData.append(Data([0x1B, 0x61, 0x00])) // Left align
        
        sendDataToPrinter(printData)
        result(true)
    }
    
    private func handlePrintQRCode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let data = args["data"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing data parameter", details: nil))
            return
        }
        
        guard isConnected else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Printer not connected", details: nil))
            return
        }
        
        // ESC/POS QR Code commands
        var qrData = Data()
        
        // QR Code model
        qrData.append(Data([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]))
        
        // QR Code size
        let size: UInt8 = 8 // Default size
        if let sizeArg = args["size"] as? String {
            switch sizeArg {
            case "size1": qrData.append(Data([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x04]))
            case "size2": qrData.append(Data([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x06]))
            case "size3": qrData.append(Data([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x08]))
            case "size4": qrData.append(Data([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x0A]))
            default: qrData.append(Data([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x08]))
            }
        } else {
            qrData.append(Data([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x08]))
        }
        
        // QR Code error correction
        qrData.append(Data([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x31])) // Medium error correction
        
        // Store data
        let dataBytes = data.data(using: .utf8) ?? Data()
        let dataLength = dataBytes.count + 3
        let lengthLow = UInt8(dataLength & 0xFF)
        let lengthHigh = UInt8((dataLength >> 8) & 0xFF)
        
        qrData.append(Data([0x1D, 0x28, 0x6B, lengthLow, lengthHigh, 0x31, 0x50, 0x30]))
        qrData.append(dataBytes)
        
        // Print QR Code
        qrData.append(Data([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]))
        
        sendDataToPrinter(qrData)
        result(true)
    }
    
    private func handlePrintImage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imageData = args["imageBytes"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing image data", details: nil))
            return
        }
        
        guard isConnected else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Printer not connected", details: nil))
            return
        }
        
        // Get width and height parameters
        let targetWidth = args["width"] as? Int ?? 400
        let targetHeight = args["height"] as? Int ?? 200
        let useHighQuality = args["highQuality"] as? Bool ?? false // Optional quality setting
        
        // Convert image to bitmap and send to printer
        if let image = UIImage(data: imageData.data) {
            // Resize image to target dimensions first
            let resizedImage = resizeImage(image, targetSize: CGSize(width: targetWidth, height: targetHeight))
            
            let bitmapData: Data?
            if useHighQuality {
                bitmapData = convertImageToThermalBitmapWithDithering(resizedImage, width: targetWidth, height: targetHeight)
            } else {
                bitmapData = convertImageToThermalBitmap(resizedImage, width: targetWidth, height: targetHeight)
            }
            
            if let bitmapData = bitmapData {
                // Add label mode commands before printing (same as Android)
                var fullPrintData = Data()
                
                // Label mode start
                fullPrintData.append(Data([0x1A, 0x0C, 0xFF]))
                
                // Center alignment
                fullPrintData.append(Data([0x1B, 0x61, 0x01]))
                
                // Add the bitmap data
                fullPrintData.append(bitmapData)
                
                // Label mode end
                fullPrintData.append(Data([0x1A, 0x0C, 0x00]))
                
                // Reset alignment
                fullPrintData.append(Data([0x1B, 0x61, 0x00]))
                
                sendDataToPrinter(fullPrintData)
                result(true)
            } else {
                result(FlutterError(code: "IMAGE_CONVERSION_ERROR", message: "Failed to convert image", details: nil))
            }
        } else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Invalid image data", details: nil))
        }
    }
    
    private func handlePrintBarcode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let data = args["data"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing barcode data", details: nil))
            return
        }
        
        guard isConnected else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Printer not connected", details: nil))
            return
        }
        
        // ESC/POS Barcode commands (CODE128 example)
        var barcodeData = Data()
        
        // Set barcode height
        let height = args["height"] as? Int ?? 162
        barcodeData.append(Data([0x1D, 0x68, UInt8(height)]))
        
        // Set barcode width
        barcodeData.append(Data([0x1D, 0x77, 0x03]))
        
        // Print barcode (CODE128)
        barcodeData.append(Data([0x1D, 0x6B, 0x49]))
        barcodeData.append(Data([UInt8(data.count)]))
        barcodeData.append(data.data(using: .ascii) ?? Data())
        
        sendDataToPrinter(barcodeData)
        result(true)
    }
    
    // MARK: - Mode Control
    private func handleSetLabelMode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isConnected else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Printer not connected", details: nil))
            return
        }
        
        // Label mode commands (specific to thermal printers)
        let labelModeData = Data([0x1A, 0x0C, 0xFF]) // Start label mode
        sendDataToPrinter(labelModeData)
        result(true)
    }
    
    private func handleSetPosMode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isConnected else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Printer not connected", details: nil))
            return
        }
        
        // POS mode commands
        let posModeData = Data([0x1A, 0x0C, 0x00]) // Start POS mode
        sendDataToPrinter(posModeData)
        result(true)
    }
    
    // MARK: - Paper Control
    private func handleHalfCutPaper(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isConnected else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Printer not connected", details: nil))
            return
        }
        
        let cutData = Data([0x1D, 0x56, 0x01]) // Half cut
        sendDataToPrinter(cutData)
        result(true)
    }
    
    private func handleFullCutPaper(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isConnected else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Printer not connected", details: nil))
            return
        }
        
        let cutData = Data([0x1D, 0x56, 0x00]) // Full cut
        sendDataToPrinter(cutData)
        result(true)
    }
    
    private func handleResetPrinter(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isConnected else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Printer not connected", details: nil))
            return
        }
        
        let resetData = Data([0x1B, 0x40]) // ESC @
        sendDataToPrinter(resetData)
        result(true)
    }
    
    // MARK: - Printer Info
    private func handleGetPrinterInfo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isConnected else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Printer not connected", details: nil))
            return
        }
        
        // Return simulated printer info for iOS
        let printerInfo: [String: Any] = [
            "firmwareVersion": "iOS-1.0.0",
            "widthMm": 58,
            "heightMm": 40,
            "dotsPerMm": 8.0,
            "errorStatus": 0,
            "receivedByteCount": 0,
            "printedPageId": 0
        ]
        
        result(printerInfo)
    }
    
    private func handlePrintSelfTestPage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isConnected else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Printer not connected", details: nil))
            return
        }
        
        // Create a comprehensive self test page - build all data at once for speed
        var testData = Data()
        
        // Reset printer
        testData.append(Data([0x1B, 0x40])) // ESC @
        
        // Title
        testData.append(Data([0x1B, 0x61, 0x01])) // Center align
        testData.append(Data([0x1B, 0x45, 0x01])) // Bold on
        testData.append("THERMAL PRINTER SELF TEST\n".data(using: .utf8) ?? Data())
        testData.append(Data([0x1B, 0x45, 0x00])) // Bold off
        testData.append("==========================\n\n".data(using: .utf8) ?? Data())
        
        // Left align for details
        testData.append(Data([0x1B, 0x61, 0x00])) // Left align
        
        // Build all text content at once
        let testContent = """
        Date: \(Date())
        Platform: iOS (Optimized)
        Plugin: flutter_printlink
        Connection: Bluetooth
        
        TEXT FORMATTING TESTS:
        Normal text
        """
        testData.append(testContent.data(using: .utf8) ?? Data())
        
        testData.append(Data([0x1B, 0x45, 0x01])) // Bold on
        testData.append("Bold text\n".data(using: .utf8) ?? Data())
        testData.append(Data([0x1B, 0x45, 0x00])) // Bold off
        
        // Size tests
        testData.append(Data([0x1D, 0x21, 0x11])) // Double size
        testData.append("Large text\n".data(using: .utf8) ?? Data())
        testData.append(Data([0x1D, 0x21, 0x00])) // Normal size
        
        // Build remaining content
        let remainingContent = """
        
        ALIGNMENT TESTS:
        """
        testData.append(remainingContent.data(using: .utf8) ?? Data())
        
        testData.append(Data([0x1B, 0x61, 0x00])) // Left
        testData.append("Left aligned\n".data(using: .utf8) ?? Data())
        testData.append(Data([0x1B, 0x61, 0x01])) // Center
        testData.append("Center aligned\n".data(using: .utf8) ?? Data())
        testData.append(Data([0x1B, 0x61, 0x02])) // Right
        testData.append("Right aligned\n".data(using: .utf8) ?? Data())
        testData.append(Data([0x1B, 0x61, 0x00])) // Back to left
        
        // Character sets - build as single string
        let charContent = """
        
        CHARACTER TESTS:
        0123456789
        ABCDEFGHIJKLMNOPQRSTUVWXYZ
        abcdefghijklmnopqrstuvwxyz
        !@#$%^&*()_+-=[]{}|;:,.<>?
        
        QR CODE TEST:
        """
        testData.append(charContent.data(using: .utf8) ?? Data())
        
        // Add QR code efficiently
        testData.append(buildQRCodeData("Self Test QR - Fast"))
        testData.append("\n".data(using: .utf8) ?? Data())
        
        // End of test
        testData.append(Data([0x1B, 0x61, 0x01])) // Center align
        let endContent = """
        ==========================
        END OF SELF TEST (Fast)
        ==========================

        """
        testData.append(endContent.data(using: .utf8) ?? Data())
        
        // Reset formatting
        testData.append(Data([0x1B, 0x61, 0x00])) // Left align
        testData.append(Data([0x1B, 0x45, 0x00])) // Bold off
        testData.append(Data([0x1D, 0x21, 0x00])) // Normal size
        
        // Send all data at once for maximum speed
        sendDataToPrinter(testData)
        result(true)
    }
    
    // Helper method to build QR code data efficiently
    private func buildQRCodeData(_ text: String) -> Data {
        var qrData = Data()
        qrData.append(Data([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00])) // Model
        qrData.append(Data([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x08])) // Size
        qrData.append(Data([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x31])) // Error correction
        
        let qrBytes = text.data(using: .utf8) ?? Data()
        let qrLength = qrBytes.count + 3
        qrData.append(Data([0x1D, 0x28, 0x6B, UInt8(qrLength & 0xFF), UInt8((qrLength >> 8) & 0xFF), 0x31, 0x50, 0x30]))
        qrData.append(qrBytes)
        qrData.append(Data([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30])) // Print
        
        return qrData
    }
    
    // MARK: - Helper Methods
    private func sendDataToPrinter(_ data: Data) {
        // Log the data being sent
        print("Sending \(data.count) bytes to printer")
        
        // If we have a connected peripheral and characteristic, send the data
        if let peripheral = connectedPeripheral,
           let characteristic = printerCharacteristic {
            
            // Optimize chunk size based on printer capability
            let maxChunkSize = min(peripheral.maximumWriteValueLength(for: .withoutResponse), 512)
            let chunkSize = maxChunkSize > 20 ? maxChunkSize : 185 // Use larger chunks
            
            var offset = 0
            
            while offset < data.count {
                let endIndex = min(offset + chunkSize, data.count)
                let chunk = data.subdata(in: offset..<endIndex)
                
                // Use writeWithoutResponse for better performance
                peripheral.writeValue(chunk, for: characteristic, type: .withoutResponse)
                
                offset = endIndex
                
                // Only add minimal delay for large chunks, remove for small data
                if data.count > 1000 && chunk.count > 100 {
                    usleep(1000) // Reduced to 1ms for large data only
                }
            }
        } else {
            print("Warning: No connected peripheral or characteristic available")
        }
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Use the smaller ratio to maintain aspect ratio
        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    private func convertImageToThermalBitmap(_ image: UIImage, width: Int, height: Int) -> Data? {
        // Convert UIImage to 1-bit bitmap data optimized for thermal printing
        guard let cgImage = image.cgImage else { return nil }
        
        let bytesPerRow = (width + 7) / 8
        var bitmapData = Data()
        
        // ESC/POS bitmap command for thermal printers
        bitmapData.append(Data([0x1D, 0x76, 0x30, 0x00])) // GS v 0 - Print raster bitmap
        bitmapData.append(Data([UInt8(bytesPerRow & 0xFF), UInt8((bytesPerRow >> 8) & 0xFF)]))
        bitmapData.append(Data([UInt8(height & 0xFF), UInt8((height >> 8) & 0xFF)]))
        
        // Create a grayscale context (more efficient)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(data: nil, 
                               width: width, 
                               height: height,
                               bitsPerComponent: 8, 
                               bytesPerRow: width,
                               space: colorSpace, 
                               bitmapInfo: CGImageAlphaInfo.none.rawValue)
        
        // Draw the image into the context
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        if let pixelData = context?.data {
            let pixels = pixelData.bindMemory(to: UInt8.self, capacity: width * height)
            
            // Use simple thresholding instead of complex dithering for speed
            // This is much faster and still produces good results for thermal printing
            let threshold: UInt8 = 127
            
            for y in 0..<height {
                var byte: UInt8 = 0
                var bitCount = 0
                
                for x in 0..<width {
                    let pixelIndex = y * width + x
                    let pixelValue = pixels[pixelIndex]
                    
                    // Simple threshold - much faster than dithering
                    if pixelValue < threshold {
                        byte |= (1 << (7 - bitCount))
                    }
                    
                    bitCount += 1
                    if bitCount == 8 || x == width - 1 {
                        bitmapData.append(byte)
                        byte = 0
                        bitCount = 0
                    }
                }
            }
        }
        
        return bitmapData
    }
    
    // High-quality version with dithering (slower but better quality)
    private func convertImageToThermalBitmapWithDithering(_ image: UIImage, width: Int, height: Int) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        
        let bytesPerRow = (width + 7) / 8
        var bitmapData = Data()
        
        // ESC/POS bitmap command for thermal printers
        bitmapData.append(Data([0x1D, 0x76, 0x30, 0x00])) // GS v 0 - Print raster bitmap
        bitmapData.append(Data([UInt8(bytesPerRow & 0xFF), UInt8((bytesPerRow >> 8) & 0xFF)]))
        bitmapData.append(Data([UInt8(height & 0xFF), UInt8((height >> 8) & 0xFF)]))
        
        // Create a grayscale context
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(data: nil, 
                               width: width, 
                               height: height,
                               bitsPerComponent: 8, 
                               bytesPerRow: width,
                               space: colorSpace, 
                               bitmapInfo: CGImageAlphaInfo.none.rawValue)
        
        // Draw the image into the context
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        if let pixelData = context?.data {
            let pixels = pixelData.bindMemory(to: UInt8.self, capacity: width * height)
            
            // Convert to 1-bit data with Floyd-Steinberg dithering (higher quality)
            var errorBuffer = Array(repeating: Array(repeating: 0.0, count: width), count: height)
            
            for y in 0..<height {
                var byte: UInt8 = 0
                var bitCount = 0
                
                for x in 0..<width {
                    let pixelIndex = y * width + x
                    let originalValue = Double(pixels[pixelIndex]) + errorBuffer[y][x]
                    
                    let newValue: UInt8 = originalValue > 127.0 ? 255 : 0
                    let error = originalValue - Double(newValue)
                    
                    // Distribute error using Floyd-Steinberg dithering
                    if x + 1 < width {
                        errorBuffer[y][x + 1] += error * 7.0 / 16.0
                    }
                    if y + 1 < height {
                        if x > 0 {
                            errorBuffer[y + 1][x - 1] += error * 3.0 / 16.0
                        }
                        errorBuffer[y + 1][x] += error * 5.0 / 16.0
                        if x + 1 < width {
                            errorBuffer[y + 1][x + 1] += error * 1.0 / 16.0
                        }
                    }
                    
                    // Set bit if pixel should be black
                    if newValue == 0 {
                        byte |= (1 << (7 - bitCount))
                    }
                    
                    bitCount += 1
                    if bitCount == 8 || x == width - 1 {
                        bitmapData.append(byte)
                        byte = 0
                        bitCount = 0
                    }
                }
            }
        }
        
        return bitmapData
    }
    
    private func sendStatusUpdate() {
        let status: [String: Any] = [
            "isConnected": isConnected,
            "hasError": false,
            "errors": []
        ]
        eventSink?(status)
    }
}

// MARK: - Bluetooth Central Manager Delegate
extension FlutterThermalPrinterPlugin: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: nil, options: nil)
        case .poweredOff, .resetting, .unauthorized, .unsupported, .unknown:
            break
        @unknown default:
            break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredDevices.contains(peripheral) {
            discoveredDevices.append(peripheral)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == connectedPeripheral {
            isConnected = false
            connectedPeripheral = nil
            printerCharacteristic = nil
            sendStatusUpdate()
        }
    }
}

// MARK: - Bluetooth Peripheral Delegate
extension FlutterThermalPrinterPlugin: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                printerCharacteristic = characteristic
                isConnected = true
                sendStatusUpdate()
                break
            }
        }
    }
}

// MARK: - Event Channel Stream Handler
extension FlutterThermalPrinterPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        sendStatusUpdate()
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
