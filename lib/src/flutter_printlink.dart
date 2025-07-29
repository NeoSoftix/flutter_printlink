import 'package:flutter/services.dart';
import 'models/printer_enums.dart';
import 'models/printer_models.dart';

class FlutterThermalPrinter {
  static const MethodChannel _channel = MethodChannel(
    'flutter_printlink',
  );

  static const EventChannel _statusChannel = EventChannel(
    'flutter_printlink/status',
  );

  /// Stream for printer status updates
  static Stream<PrinterStatus>? _statusStream;

  /// Get printer status updates stream
  static Stream<PrinterStatus> get onStatusChanged {
    _statusStream ??= _statusChannel.receiveBroadcastStream().map(
          (data) => PrinterStatus.fromMap(Map<String, dynamic>.from(data)),
        );
    return _statusStream!;
  }

  /// Enumerate available printers by connection type
  static Future<List<PrinterDevice>> enumeratePrinters(
    PrinterConnectionType type,
  ) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'enumeratePrinters',
        {'type': type.toString().split('.').last},
      );

      return result
          .map(
            (device) =>
                PrinterDevice.fromMap(Map<String, dynamic>.from(device)),
          )
          .toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to enumerate printers: ${e.message}');
    }
  }

  /// Open connection to a printer
  static Future<bool> openPrinter(PrinterDevice device, {int? baudRate}) async {
    try {
      final bool result = await _channel.invokeMethod('openPrinter', {
        'device': device.toMap(),
        'baudRate': baudRate,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to open printer: ${e.message}');
    }
  }

  /// Close printer connection
  static Future<bool> closePrinter() async {
    try {
      final bool result = await _channel.invokeMethod('closePrinter');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to close printer: ${e.message}');
    }
  }

  /// Check if printer connection is valid
  static Future<bool> isConnectionValid() async {
    try {
      final bool result = await _channel.invokeMethod('isConnectionValid');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to check connection: ${e.message}');
    }
  }

  /// Get printer information
  static Future<PrinterInfo> getPrinterInfo() async {
    try {
      final dynamic result = await _channel.invokeMethod('getPrinterInfo');
      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);
      return PrinterInfo.fromMap(resultMap);
    } on PlatformException catch (e) {
      throw Exception('Failed to get printer info: ${e.message}');
    }
  }

  /// Switch to POS mode
  static Future<bool> setPosMode() async {
    try {
      final bool result = await _channel.invokeMethod('setPosMode');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to set POS mode: ${e.message}');
    }
  }

  /// Switch to Label mode
  static Future<bool> setLabelMode() async {
    try {
      final bool result = await _channel.invokeMethod('setLabelMode');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to set label mode: ${e.message}');
    }
  }

  /// Reset printer
  static Future<bool> resetPrinter() async {
    try {
      final bool result = await _channel.invokeMethod('resetPrinter');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to reset printer: ${e.message}');
    }
  }

  /// Clear printer buffer
  static Future<bool> clearPrinterBuffer() async {
    try {
      final bool result = await _channel.invokeMethod('clearPrinterBuffer');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to clear printer buffer: ${e.message}');
    }
  }

  /// Clear printer error
  static Future<bool> clearPrinterError() async {
    try {
      final bool result = await _channel.invokeMethod('clearPrinterError');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to clear printer error: ${e.message}');
    }
  }

  /// Print text
  static Future<bool> printText(String text, {PrintSettings? settings}) async {
    try {
      final bool result = await _channel.invokeMethod('printText', {
        'text': text,
        'settings': settings?.toMap() ?? PrintSettings().toMap(),
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to print text: ${e.message}');
    }
  }

  /// Print barcode
  static Future<bool> printBarcode(
    String data,
    BarcodeType type, {
    int? width,
    int? height,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('printBarcode', {
        'data': data,
        'type': type.toString().split('.').last,
        'width': width ?? 100,
        'height': height ?? 60,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to print barcode: ${e.message}');
    }
  }

  /// Print QR code
  static Future<bool> printQRCode(String data, {QRCodeSize? size}) async {
    try {
      final bool result = await _channel.invokeMethod('printQRCode', {
        'data': data,
        'size': size?.toString().split('.').last ?? 'size4',
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to print QR code: ${e.message}');
    }
  }

  /// Print image from bytes
  static Future<bool> printImage(
    Uint8List imageBytes, {
    int? width,
    int? height,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('printImage', {
        'imageBytes': imageBytes,
        'width': width,
        'height': height,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to print image: ${e.message}');
    }
  }

  /// Feed paper
  static Future<bool> feedPaper(int lines) async {
    try {
      final bool result = await _channel.invokeMethod('feedPaper', {
        'lines': lines,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to feed paper: ${e.message}');
    }
  }

  /// Set print position (x: horizontal, y: vertical position in dots)
  static Future<bool> setPrintPosition({int? x, int? y}) async {
    try {
      final bool result = await _channel.invokeMethod('setPrintPosition', {
        if (x != null) 'x': x,
        if (y != null) 'y': y,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to set print position: ${e.message}');
    }
  }

  /// Cut paper (full cut)
  static Future<bool> fullCutPaper() async {
    try {
      final bool result = await _channel.invokeMethod('fullCutPaper');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to cut paper: ${e.message}');
    }
  }

  /// Cut paper (half cut)
  static Future<bool> halfCutPaper() async {
    try {
      final bool result = await _channel.invokeMethod('halfCutPaper');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to half cut paper: ${e.message}');
    }
  }

  /// Kick out drawer
  static Future<bool> kickOutDrawer() async {
    try {
      final bool result = await _channel.invokeMethod('kickOutDrawer');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to kick out drawer: ${e.message}');
    }
  }

  /// Beep
  static Future<bool> beep(int count, {int duration = 100}) async {
    try {
      final bool result = await _channel.invokeMethod('beep', {
        'count': count,
        'duration': duration,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to beep: ${e.message}');
    }
  }

  /// Query print result (for POS mode)
  static Future<bool> queryPrintResult({int timeoutMs = 30000}) async {
    try {
      final bool result = await _channel.invokeMethod('queryPrintResult', {
        'timeoutMs': timeoutMs,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to query print result: ${e.message}');
    }
  }

  /// Print self test page
  static Future<bool> printSelfTestPage() async {
    try {
      final bool result = await _channel.invokeMethod('printSelfTestPage');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to print self test page: ${e.message}');
    }
  }

  /// Set print density (0-15)
  static Future<bool> setPrintDensity(int density) async {
    try {
      final bool result = await _channel.invokeMethod('setPrintDensity', {
        'density': density.clamp(0, 15),
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to set print density: ${e.message}');
    }
  }

  /// Set print speed
  static Future<bool> setPrintSpeed(int speed) async {
    try {
      final bool result = await _channel.invokeMethod('setPrintSpeed', {
        'speed': speed,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to set print speed: ${e.message}');
    }
  }
}
