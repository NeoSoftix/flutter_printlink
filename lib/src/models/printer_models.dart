import 'printer_enums.dart';

class PrinterDevice {
  final String name;
  final String address;
  final PrinterConnectionType type;

  PrinterDevice({
    required this.name,
    required this.address,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'type': type.toString().split('.').last,
    };
  }

  factory PrinterDevice.fromMap(Map<String, dynamic> map) {
    return PrinterDevice(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      type: PrinterConnectionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => PrinterConnectionType.bluetooth2,
      ),
    );
  }
}

class PrinterInfo {
  final String firmwareVersion;
  final int widthMm;
  final int heightMm;
  final int dotsPerMm;
  final int errorStatus;
  final int infoStatus;
  final int receivedByteCount;
  final int printedPageId;
  final DateTime statusTimestamp;
  final DateTime receivedTimestamp;
  final DateTime printedTimestamp;

  PrinterInfo({
    required this.firmwareVersion,
    required this.widthMm,
    required this.heightMm,
    required this.dotsPerMm,
    required this.errorStatus,
    required this.infoStatus,
    required this.receivedByteCount,
    required this.printedPageId,
    required this.statusTimestamp,
    required this.receivedTimestamp,
    required this.printedTimestamp,
  });

  factory PrinterInfo.fromMap(Map<String, dynamic> map) {
    return PrinterInfo(
      firmwareVersion: map['firmwareVersion'] ?? '',
      widthMm: map['widthMm']?.toInt() ?? 0,
      heightMm: map['heightMm']?.toInt() ?? 0,
      dotsPerMm: map['dotsPerMm']?.toInt() ?? 0,
      errorStatus: map['errorStatus']?.toInt() ?? 0,
      infoStatus: map['infoStatus']?.toInt() ?? 0,
      receivedByteCount: map['receivedByteCount']?.toInt() ?? 0,
      printedPageId: map['printedPageId']?.toInt() ?? 0,
      statusTimestamp: DateTime.fromMillisecondsSinceEpoch(
        map['statusTimestamp'] ?? 0,
      ),
      receivedTimestamp: DateTime.fromMillisecondsSinceEpoch(
        map['receivedTimestamp'] ?? 0,
      ),
      printedTimestamp: DateTime.fromMillisecondsSinceEpoch(
        map['printedTimestamp'] ?? 0,
      ),
    );
  }
}

class PrinterStatus {
  final bool isConnected;
  final bool hasError;
  final List<PrinterErrorStatus> errors;

  PrinterStatus({
    required this.isConnected,
    required this.hasError,
    required this.errors,
  });

  factory PrinterStatus.fromMap(Map<String, dynamic> map) {
    List<PrinterErrorStatus> errorList = [];
    int errorCode = map['errorCode'] ?? 0;

    // Parse error codes based on the Android implementation
    if (errorCode & 0x0001 != 0) errorList.add(PrinterErrorStatus.cutter);
    if (errorCode & 0x0002 != 0) errorList.add(PrinterErrorStatus.flash);
    if (errorCode & 0x0004 != 0) errorList.add(PrinterErrorStatus.noPaper);
    if (errorCode & 0x0008 != 0) errorList.add(PrinterErrorStatus.voltage);
    if (errorCode & 0x0010 != 0) errorList.add(PrinterErrorStatus.overHeat);
    if (errorCode & 0x0020 != 0) errorList.add(PrinterErrorStatus.coverOpen);
    if (errorCode & 0x0040 != 0) errorList.add(PrinterErrorStatus.feedButton);

    return PrinterStatus(
      isConnected: map['isConnected'] ?? false,
      hasError: errorList.isNotEmpty,
      errors: errorList,
    );
  }
}

class PrintSettings {
  final PrinterAlignment alignment;
  final PrinterTextSize textSize;
  final bool bold;
  final bool underline;
  final int leftMargin;
  final int printAreaWidth;

  PrintSettings({
    this.alignment = PrinterAlignment.left,
    this.textSize = PrinterTextSize.size1,
    this.bold = false,
    this.underline = false,
    this.leftMargin = 0,
    this.printAreaWidth = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'alignment': alignment.toString().split('.').last,
      'textSize': textSize.toString().split('.').last,
      'bold': bold,
      'underline': underline,
      'leftMargin': leftMargin,
      'printAreaWidth': printAreaWidth,
    };
  }
}
