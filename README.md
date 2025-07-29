# Flutter Thermal Printer

[![pub package](https://img.shields.io/pub/v/flutter_printlink.svg)](https://pub.dev/packages/flutter_printlink)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue.svg)](https://pub.dev/packages/flutter_printlink)

A comprehensive Flutter plugin for thermal printer integration using the AutoReplyPrint library. This plugin provides extensive support for thermal label printing, POS receipt printing, and various printer connection methods with both Android and iOS implementations.

> **Professional Thermal Printing Solution** - Optimized for business use with 5cm x 2.5cm label printing, POS receipts, and multi-connection support.

## Features

- 🖨️ **Multi-Connection Support**: Bluetooth Classic, Bluetooth LE, USB, Network, COM, and WiFi P2P
- 🏷️ **Label Printing**: Optimized for 5cm x 2.5cm thermal stickers with precise positioning
- 📄 **POS Receipt Printing**: Full-featured receipt printing with rich text formatting
- 🔍 **QR Code & Barcode**: High-quality code printing with multiple formats and error correction
- 📱 **Real-time Status**: Live printer status updates via event streams with detailed error reporting
- 🖼️ **Image Printing**: Bitmap image printing with proper scaling, dithering, and alignment
- ⚙️ **Mode Switching**: Seamless switching between Label mode and POS mode
- 🔧 **Advanced Controls**: Paper cutting, density adjustment, speed control, and positioning
- 🎯 **Self-Diagnostics**: Built-in self-test functionality and printer information retrieval
- 🔊 **Audio Feedback**: Printer beep functionality for operation confirmation

## Screenshots

The plugin includes a comprehensive example app demonstrating all features:

- Device enumeration and connection management
- Live label preview with product information
- Multiple printing options (Image, Compact, Receipt)
- Real-time printer status updates
- QR code and barcode generation
- Thermal-optimized image processing

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_printlink: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### Example App

The plugin comes with a comprehensive example app that demonstrates all features. To run the example:

```bash
git clone https://github.com/Shehzaan-Mansuri/flutter_printlink.git
cd flutter_printlink/example
flutter pub get
flutter run
```

The example app includes:

- **Device Scanner**: Discover and connect to thermal printers
- **Label Designer**: Create product labels with live preview
- **Print Options**: Image, compact text, and POS receipt modes
- **Status Monitor**: Real-time printer connection status
- **Settings**: Configure print quality and connection options

## Platform Setup

### Android

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
```

### iOS

Add the following permissions to your `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to thermal printers for printing labels and receipts.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to connect to thermal printers for printing labels and receipts.</string>
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>com.apple.printer</string>
</array>
```

## Quick Start

### 1. Import the plugin

```dart
import 'package:flutter_printlink/flutter_printlink.dart';
```

### 2. Listen to printer status

```dart
FlutterThermalPrinter.onStatusChanged.listen((status) {
  print('Printer connected: ${status.isConnected}');
  if (status.hasError) {
    print('Errors: ${status.errors.join(', ')}');
  }
});
```

### 3. Enumerate and connect to printers

```dart
// Find Bluetooth printers
final devices = await FlutterThermalPrinter.enumeratePrinters(
  PrinterConnectionType.bluetooth2
);

// Connect to selected printer
final success = await FlutterThermalPrinter.openPrinter(devices.first);
```

### 4. Print labels

```dart
// Set label mode
await FlutterThermalPrinter.setLabelMode();

// Print text
await FlutterThermalPrinter.printText(
  'Hello World!\n',
  settings: PrintSettings(
    alignment: PrinterAlignment.center,
    bold: true,
    textSize: PrinterTextSize.size2,
  ),
);

// Print QR code
await FlutterThermalPrinter.printQRCode(
  'SKU123456',
  size: QRCodeSize.size4,
);
```

## API Reference

The plugin provides a comprehensive API for thermal printer integration:

### Connection Types

The plugin supports all major thermal printer connection types:

- **Bluetooth Classic (bluetooth2)**: Traditional Bluetooth 2.0+ connections
- **Bluetooth LE (bluetooth4)**: Low Energy Bluetooth 4.0+ connections
- **USB**: Direct USB connection (Android OTG, iOS MFi accessories)
- **Network**: TCP/IP network printers
- **COM**: Serial port communication (Android)
- **WiFi P2P**: Direct WiFi printer connection (Android)

### Core Methods

#### Connection Management

```dart
// Discover printers
final devices = await FlutterThermalPrinter.enumeratePrinters(
  PrinterConnectionType.bluetooth2
);

// Connect to printer
final success = await FlutterThermalPrinter.openPrinter(
  device,
  baudRate: 115200, // Optional for COM connections
);

// Check connection status
final isValid = await FlutterThermalPrinter.isConnectionValid();

// Disconnect
await FlutterThermalPrinter.closePrinter();
```

#### Printer Information

```dart
// Get detailed printer information
final info = await FlutterThermalPrinter.getPrinterInfo();
print('Firmware: ${info.firmwareVersion}');
print('Paper size: ${info.widthMm}mm x ${info.heightMm}mm');
```

#### Mode Control

```dart
// Switch printing modes
await FlutterThermalPrinter.setLabelMode();  // For stickers
await FlutterThermalPrinter.setPosMode();    // For receipts
```

#### Text Printing

```dart
// Print formatted text
await FlutterThermalPrinter.printText(
  'Hello World!\n',
  settings: PrintSettings(
    alignment: PrinterAlignment.center,
    bold: true,
    textSize: PrinterTextSize.size2,
  ),
);
```

#### QR Code & Barcode Printing

```dart
// Print QR code
await FlutterThermalPrinter.printQRCode(
  'SKU123456',
  size: QRCodeSize.size4,  // size3, size4, size5, size6, size7, size8
);

// Print barcode
await FlutterThermalPrinter.printBarcode(
  '123456789',
  BarcodeType.code128,
  width: 100,
  height: 60,
);
```

#### Image Printing

```dart
// Print image from bytes
await FlutterThermalPrinter.printImage(
  imageBytes,
  width: 400,   // Optimal for 5cm labels
  height: 200,  // Optimal for 2.5cm labels
);
```

#### Paper Control

```dart
// Paper cutting and feeding
await FlutterThermalPrinter.halfCutPaper();
await FlutterThermalPrinter.fullCutPaper();
await FlutterThermalPrinter.feedPaper(lines: 3);

// Printer maintenance
await FlutterThermalPrinter.resetPrinter();
await FlutterThermalPrinter.clearPrinterBuffer();
await FlutterThermalPrinter.clearPrinterError();
```

#### Advanced Features

```dart
// Self-test and diagnostics
await FlutterThermalPrinter.printSelfTestPage();

// Audio feedback
await FlutterThermalPrinter.beep(duration: 200);

// Print settings
await FlutterThermalPrinter.setPrintDensity(10);  // 0-15
await FlutterThermalPrinter.setPrintSpeed(3);     // 1-9

// Position control
await FlutterThermalPrinter.setPrintPosition(x: 50, y: 100);

// Cash drawer control
await FlutterThermalPrinter.kickOutDrawer();
```

## Data Models

### PrintSettings

```dart
PrintSettings(
  alignment: PrinterAlignment.center,  // left, center, right
  bold: true,
  textSize: PrinterTextSize.size2,     // size1, size2, size3, size4
)
```

### PrinterDevice

```dart
PrinterDevice(
  name: 'Printer Name',
  address: 'AA:BB:CC:DD:EE:FF',
  type: 'bluetooth2',
)
```

### PrinterStatus

```dart
PrinterStatus(
  isConnected: true,
  hasError: false,
  errors: [],
)
```

## Example: Product Label Printing

Here's a complete example for printing product labels:

```dart
class ProductLabelPrinter {
  Future<void> printProductLabel({
    required String productName,
    required String sku,
    required String mrp,
    required String mfgDate,
    required String expDate,
  }) async {
    try {
      // Set label mode for sticker printing
      await FlutterThermalPrinter.setLabelMode();

      // Reset printer
      await FlutterThermalPrinter.resetPrinter();

      // Print product name (bold, centered)
      await FlutterThermalPrinter.printText(
        '$productName\n',
        settings: PrintSettings(
          alignment: PrinterAlignment.center,
          bold: true,
          textSize: PrinterTextSize.size1,
        ),
      );

      // Print product details
      await FlutterThermalPrinter.printText(
        'Sellable  MRP: Rs.$mrp\n'
        'Mfg: $mfgDate  Exp: $expDate\n',
        settings: PrintSettings(
          alignment: PrinterAlignment.left,
          textSize: PrinterTextSize.size1,
        ),
      );

      // Print QR code
      await FlutterThermalPrinter.printQRCode(
        sku,
        size: QRCodeSize.size4,
      );

      // Print SKU (bold, centered)
      await FlutterThermalPrinter.printText(
        '\n$sku\n',
        settings: PrintSettings(
          alignment: PrinterAlignment.center,
          bold: true,
          textSize: PrinterTextSize.size1,
        ),
      );

      // Cut paper
      await FlutterThermalPrinter.halfCutPaper();

      print('Label printed successfully!');
    } catch (e) {
      print('Print error: $e');
    }
  }
}
```

## Image Printing Best Practices

For optimal image printing on thermal printers:

1. **Use high contrast images**: Black and white work best
2. **Optimize dimensions**: 400x200 pixels for 5x2.5cm labels
3. **High pixel ratio**: Capture images at 3x pixel ratio for crisp QR codes
4. **Error correction**: Use medium error correction for QR codes
5. **Proper scaling**: Let the plugin handle aspect ratio maintenance

```dart
// Capture widget as high-quality image
Future<Uint8List> captureWidget(GlobalKey key) async {
  RenderRepaintBoundary boundary = key.currentContext!
      .findRenderObject() as RenderRepaintBoundary;

  ui.Image image = await boundary.toImage(pixelRatio: 3.0);
  ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return byteData!.buffer.asUint8List();
}
```

## Troubleshooting

### Common Issues

1. **Printer not found**: Ensure Bluetooth is enabled and printer is in pairing mode
2. **Connection fails**: Check permissions and try restarting the printer
3. **Poor print quality**: Adjust printer density settings or use error diffusion
4. **QR codes unreadable**: Increase image pixel ratio and use medium error correction
5. **Labels using multiple stickers**: Ensure height is limited to 200 pixels for 5x2.5cm labels

### Error Codes

- `NOT_CONNECTED`: Printer not connected
- `ENUMERATION_ERROR`: Device discovery failed
- `CONNECTION_ERROR`: Failed to connect to printer
- `PRINT_ERROR`: Printing operation failed
- `LABEL_PRINT_ERROR`: Label-specific printing error
- `QRCODE_ERROR`: QR code printing failed
- `BARCODE_ERROR`: Barcode printing failed
- `IMAGE_CONVERSION_ERROR`: Image processing failed

### Debug Tips

1. **Enable verbose logging**: Check device logs for detailed error messages
2. **Test with self-test**: Use `printSelfTestPage()` to verify printer functionality
3. **Check printer status**: Monitor status updates via `onStatusChanged` stream
4. **Verify permissions**: Ensure all required permissions are granted
5. **Test different connection types**: Try alternative connection methods if available

### Performance Optimization

1. **Batch operations**: Group multiple print commands together
2. **Image optimization**: Use appropriate image dimensions (400x200 for labels)
3. **Memory management**: Dispose of large images after printing
4. **Connection reuse**: Keep connections open for multiple operations
5. **Background processing**: Use isolates for complex image processing

## Support

This plugin supports thermal printers compatible with the AutoReplyPrint library, including:

- CAYSN thermal printers
- ESC/POS compatible printers
- Label printers with 58mm paper width
- POS receipt printers

### Platform Support

#### Android

- ✅ Bluetooth Classic (Bluetooth 2.0+)
- ✅ Bluetooth LE (Bluetooth 4.0+)
- ✅ USB (OTG supported devices)
- ✅ Network/WiFi printers
- ✅ Full AutoReplyPrint library integration
- ✅ Advanced thermal printer controls

#### iOS

- ✅ Bluetooth Classic (Bluetooth 2.0+)
- ✅ Bluetooth LE (Bluetooth 4.0+)
- ⚠️ USB (Limited to MFi certified accessories)
- ⚠️ Network/WiFi (Basic support)
- ✅ ESC/POS command implementation
- ✅ Core thermal printing features

**Note**: iOS has platform limitations for USB and network printer access compared to Android. Bluetooth connectivity is fully supported on both platforms.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Changelog

### 1.0.0 - Initial Release (2025-01-29)

#### ✨ Features

- **Multi-Platform Support**: Full Android and iOS implementation
- **Multiple Connection Types**: Bluetooth Classic, Bluetooth LE, USB, Network, COM, and WiFi P2P
- **Dual Printing Modes**: Label mode for stickers and POS mode for receipts
- **Rich Content Printing**: Text with formatting, QR codes, barcodes, and images
- **Real-time Status Updates**: Live printer status monitoring via event streams
- **Advanced Controls**: Paper cutting, density adjustment, speed control, and positioning

#### 🔧 Technical Implementation

- **Android**: Full AutoReplyPrint library integration with native performance
- **iOS**: Custom ESC/POS command implementation for maximum compatibility
- **Label Optimization**: Specialized for 5cm x 2.5cm thermal stickers
- **Image Processing**: Optimized bitmap conversion with error diffusion
- **Memory Management**: Efficient resource handling and cleanup

#### 📱 Platform Features

**Android:**

- ✅ Full AutoReplyPrint library integration
- ✅ All connection types supported
- ✅ Advanced thermal printer controls
- ✅ Hardware-accelerated image processing
- ✅ Complete thermal printer management

**iOS:**

- ✅ Native ESC/POS command implementation
- ✅ Bluetooth Classic and LE support
- ✅ Core thermal printing features
- ✅ MFi accessory support for USB
- ⚠️ Limited USB/Network support due to platform restrictions

#### 🎯 Business Features

- **Professional Label Printing**: Optimized for retail and inventory management
- **POS Receipt Support**: Full-featured receipt printing with rich formatting
- **Self-Diagnostics**: Built-in printer testing and information retrieval
- **Error Handling**: Comprehensive error reporting and recovery
- **Multi-Language Support**: UTF-8 text encoding with international characters
- **Production Ready**: Tested with major thermal printer brands

#### 📦 Package Contents

- Complete Flutter plugin with platform interfaces
- Comprehensive example application
- Full API documentation with code samples
- iOS podspec for CocoaPods integration
- Android AAR with AutoReplyPrint library
- Platform-specific permission configurations
