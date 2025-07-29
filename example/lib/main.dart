import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_printlink/flutter_printlink.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Label Printer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ProductLabelPrinter(),
    );
  }
}

class ProductLabelPrinter extends StatefulWidget {
  const ProductLabelPrinter({super.key});

  @override
  State<ProductLabelPrinter> createState() => _ProductLabelPrinterState();
}

class _ProductLabelPrinterState extends State<ProductLabelPrinter> {
  final TextEditingController _nameController =
      TextEditingController(text: 'Dove Shampoo 180ml');
  final TextEditingController _skuController =
      TextEditingController(text: 'DO-SH-P001');
  final TextEditingController _mrpController =
      TextEditingController(text: '199');
  final TextEditingController _mfgController =
      TextEditingController(text: '06/2024');
  final TextEditingController _expController =
      TextEditingController(text: '06/2026');
  final TextEditingController _qtyController = TextEditingController(text: "1");
  final GlobalKey _previewKey = GlobalKey();

  List<PrinterDevice> _devices = [];
  PrinterDevice? _selectedDevice;
  PrinterInfo? _printerInfo;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _listenToStatusUpdates();
  }

  void _listenToStatusUpdates() {
    FlutterThermalPrinter.onStatusChanged.listen((status) {
      setState(() {
        _isConnected = status.isConnected;
      });

      if (status.hasError) {
        _showSnackBar('Printer Error: ${status.errors.join(', ')}');
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _enumerateDevices(PrinterConnectionType type) async {
    try {
      final devices = await FlutterThermalPrinter.enumeratePrinters(type);

      // Debug logging
      log('Found ${devices.length} devices of type ${type.toString().split('.').last}');
      for (int i = 0; i < devices.length; i++) {
        log('Device $i: name="${devices[i].name}", address="${devices[i].address}"');
      }

      setState(() {
        _devices = devices;
        _selectedDevice = null;
      });
      _showSnackBar(
          'Found ${devices.length} ${type.toString().split('.').last} devices');
    } catch (e) {
      log('Error enumerating devices: $e');
      _showSnackBar('Error enumerating devices: $e');
    }
  }

  Future<void> _connectToPrinter() async {
    if (_selectedDevice == null) {
      _showSnackBar('Please select a device first');
      return;
    }

    try {
      final result = await FlutterThermalPrinter.openPrinter(_selectedDevice!);
      if (result) {
        _showSnackBar('Connected successfully');
        await _getPrinterInfo();
      } else {
        _showSnackBar('Failed to connect');
      }
    } catch (e) {
      _showSnackBar('Connection error: $e');
    }
  }

  Future<void> _disconnect() async {
    try {
      await FlutterThermalPrinter.closePrinter();
      setState(() {
        _isConnected = false;
        _printerInfo = null;
      });
      _showSnackBar('Disconnected');
    } catch (e) {
      _showSnackBar('Disconnect error: $e');
    }
  }

  Future<void> _getPrinterInfo() async {
    try {
      final info = await FlutterThermalPrinter.getPrinterInfo();
      setState(() {
        _printerInfo = info;
      });
    } catch (e) {
      _showSnackBar('Error getting printer info: $e');
    }
  }

  Future<void> _setLabelMode() async {
    try {
      await FlutterThermalPrinter.setLabelMode();
      _showSnackBar('Switched to Label mode');
    } catch (e) {
      _showSnackBar('Error setting label mode: $e');
    }
  }

  Future<void> _setPosMode() async {
    try {
      await FlutterThermalPrinter.setPosMode();
      _showSnackBar('Switched to POS mode');
    } catch (e) {
      _showSnackBar('Error setting POS mode: $e');
    }
  }

  Future<Uint8List> _captureLabelAsImage() async {
    try {
      RenderRepaintBoundary boundary = _previewKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      // Use higher pixel ratio for better QR code quality
      ui.Image image = await boundary.toImage(
          pixelRatio: 3.0); // Increased to 3.0 for even better quality
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      throw Exception("Error capturing image: $e");
    }
  }

  Future<void> _printImageLabel() async {
    if (!_isConnected) {
      _showSnackBar('Please connect to printer first');
      return;
    }

    try {
      // Get quantity
      int quantity = int.tryParse(_qtyController.text) ?? 1;
      if (quantity <= 0) quantity = 1;

      // Switch to label mode first
      await FlutterThermalPrinter.setLabelMode();

      // Small delay to ensure mode switch
      await Future.delayed(const Duration(milliseconds: 200));

      // Print multiple labels
      for (int i = 0; i < quantity; i++) {
        // Capture and print the label (positioning is now done in Java)
        final imageBytes = await _captureLabelAsImage();
        // Specify both width and height to ensure single sticker usage
        await FlutterThermalPrinter.printImage(imageBytes,
            width: 400, height: 200); // Force specific dimensions for 5x2.5cm

        // Add small delay between prints
        if (i < quantity - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      _showSnackBar('$quantity label(s) printed successfully');
    } catch (e) {
      _showSnackBar('Print error: $e');
    }
  }

  Future<void> _printCompactLabel() async {
    if (!_isConnected) {
      _showSnackBar('Please connect to printer first');
      return;
    }

    try {
      // Get quantity
      int quantity = int.tryParse(_qtyController.text) ?? 1;
      if (quantity <= 0) quantity = 1;

      // Switch to label mode for compact printing
      await FlutterThermalPrinter.setLabelMode();

      // Print multiple labels
      for (int i = 0; i < quantity; i++) {
        // Reset printer
        await FlutterThermalPrinter.resetPrinter();

        // Product name (bold and centered)
        await FlutterThermalPrinter.printText(
          '${_nameController.text}\n',
          settings: PrintSettings(
            alignment: PrinterAlignment.center,
            bold: true,
            textSize: PrinterTextSize.size1,
          ),
        );

        // Divider
        await FlutterThermalPrinter.printText('-------------------\n');

        // Product information in compact format
        await FlutterThermalPrinter.printText(
          'Sellable  MRP: Rs.${_mrpController.text}\n'
          'Mfg: ${_mfgController.text}  Exp: ${_expController.text}\n',
          settings: PrintSettings(
            alignment: PrinterAlignment.left,
            textSize: PrinterTextSize.size1,
          ),
        );

        // QR code
        await FlutterThermalPrinter.printQRCode(_skuController.text,
            size: QRCodeSize.size4);

        // SKU (bold and centered)
        await FlutterThermalPrinter.printText(
          '\n${_skuController.text}\n',
          settings: PrintSettings(
            alignment: PrinterAlignment.center,
            bold: true,
            textSize: PrinterTextSize.size1,
          ),
        );

        // Cut paper
        await FlutterThermalPrinter.halfCutPaper();

        // Add small delay between prints
        if (i < quantity - 1) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }

      _showSnackBar('$quantity compact label(s) printed successfully');
    } catch (e) {
      _showSnackBar('Print error: $e');
    }
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _printPosReceipt() async {
    if (!_isConnected) {
      _showSnackBar('Please connect to printer first');
      return;
    }

    try {
      // Switch to POS mode
      await _setPosMode();

      // Reset printer
      await FlutterThermalPrinter.resetPrinter();

      // Print header
      await FlutterThermalPrinter.printText(
        'Sample Store\n',
        settings: PrintSettings(
            alignment: PrinterAlignment.center,
            textSize: PrinterTextSize.size2,
            bold: true),
      );

      await FlutterThermalPrinter.printText(
        '123 Main Street\nCity, State 12345\nTel: (555) 123-4567\n\n',
        settings: PrintSettings(alignment: PrinterAlignment.center),
      );

      // Print product details
      await FlutterThermalPrinter.printText(
        'PRODUCT RECEIPT\n',
        settings: PrintSettings(alignment: PrinterAlignment.center, bold: true),
      );

      await FlutterThermalPrinter.printText(
          '--------------------------------\n');

      await FlutterThermalPrinter.printText('Product: ${_nameController.text}\n'
          'SKU: ${_skuController.text}\n'
          'MRP: Rs.${_mrpController.text}\n'
          'Mfg: ${_mfgController.text}\n'
          'Exp: ${_expController.text}\n\n');

      // Print QR code
      await FlutterThermalPrinter.printQRCode(_skuController.text,
          size: QRCodeSize.size4);

      await FlutterThermalPrinter.printText('\n');
      await FlutterThermalPrinter.printText(
          '--------------------------------\n');
      await FlutterThermalPrinter.printText(
        'Thank you for your purchase!\n\n',
        settings: PrintSettings(alignment: PrinterAlignment.center),
      );

      // Cut paper
      await FlutterThermalPrinter.halfCutPaper();

      _showSnackBar('Receipt printed successfully');
    } catch (e) {
      _showSnackBar('Print error: $e');
    }
  }

  Widget _buildLabelWidget() {
    return Container(
      width: 400, // Back to reasonable size
      height: 200, // Back to reasonable size
      color: Colors.white,
      child: RepaintBoundary(
        key: _previewKey,
        child: ClipRect(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(10), // Reduced padding from 8 to 4
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product name at top - no padding at all
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.black, width: 1)),
                  ),
                  child: Text(
                    _nameController.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Main content row - no spacing
                Expanded(
                  child: Row(
                    children: [
                      // Left side - product details
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const Text(
                                'Sellable',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Mfg. ${_mfgController.text}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Exp. ${_expController.text}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'MRP: ${_mrpController.text}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Right side - QR code with no margin - made larger
                      Container(
                        width: 110, // Slightly reduced from 120
                        height: 110, // Slightly reduced from 120
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: BarcodeWidget(
                          barcode: Barcode.qrCode(
                            errorCorrectLevel: BarcodeQRCorrectionLevel
                                .medium, // Add error correction
                          ),
                          data:
                              _skuController.text, // Simplified - just the SKU
                          width: 110, // Slightly reduced from 120
                          height: 110, // Slightly reduced from 120
                          drawText: false, // Remove text to save space
                        ),
                      ),
                    ],
                  ),
                ),
                // SKU at bottom - no padding
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    border:
                        Border(top: BorderSide(color: Colors.black, width: 1)),
                  ),
                  child: Text(
                    _skuController.text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Label Printer"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Printer Connection',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () => _enumerateDevices(
                                PrinterConnectionType.bluetooth2),
                            child: const Text('BT Classic'),
                          ),
                          ElevatedButton(
                            onPressed: () => _enumerateDevices(
                                PrinterConnectionType.bluetooth4),
                            child: const Text('BT LE'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                _enumerateDevices(PrinterConnectionType.usb),
                            child: const Text('USB'),
                          ),
                          ElevatedButton(
                            onPressed: () => _enumerateDevices(
                                PrinterConnectionType.network),
                            child: const Text('Network'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_devices.isNotEmpty) ...[
                        Text('Found ${_devices.length} devices:',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButton<PrinterDevice>(
                            isExpanded: true,
                            hint: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Select Printer'),
                            ),
                            value: _selectedDevice,
                            underline: Container(),
                            onChanged: (device) {
                              setState(() => _selectedDevice = device);
                              if (device != null) {
                                _showSnackBar('Selected: ${device.name}');
                              }
                            },
                            items: _devices
                                .map((device) => DropdownMenuItem(
                                      value: device,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              device.name.isEmpty
                                                  ? 'Unknown Device'
                                                  : device.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              device.address,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        if (_selectedDevice != null)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              'Selected: ${_selectedDevice!.name.isEmpty ? "Unknown Device" : _selectedDevice!.name}\n'
                              'Address: ${_selectedDevice!.address}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isConnected ? null : _connectToPrinter,
                            icon: const Icon(Icons.bluetooth_connected),
                            label: const Text('Connect'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _isConnected ? _disconnect : null,
                            icon: const Icon(Icons.bluetooth_disabled),
                            label: const Text('Disconnect'),
                          ),
                        ],
                      ),
                      if (_isConnected)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('✓ Connected',
                              style: TextStyle(color: Colors.green.shade800)),
                        ),
                    ],
                  ),
                ),
              ),

              // Product Information Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Product Information',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      _buildTextField(_nameController, "Product Name"),
                      _buildTextField(_skuController, "SKU"),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(_mrpController, "MRP (₹)",
                                keyboardType: TextInputType.number),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(_mfgController, "MFG Date"),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(_expController, "EXP Date"),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(_qtyController, "Quantity",
                                keyboardType: TextInputType.number),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Label Preview Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Label Preview (5cm x 2.5cm sticker - Enhanced QR)',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Center(child: _buildLabelWidget()),
                    ],
                  ),
                ),
              ),

              // Print Actions Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Print Actions',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isConnected ? _printImageLabel : null,
                              icon: const Icon(Icons.print),
                              label: const Text('Print as Image'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isConnected ? _printCompactLabel : null,
                              icon: const Icon(Icons.print),
                              label: const Text('Print Compact'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isConnected ? _printPosReceipt : null,
                              icon: const Icon(Icons.receipt),
                              label: const Text('Print Receipt'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isConnected
                                  ? () async {
                                      try {
                                        await FlutterThermalPrinter
                                            .printSelfTestPage();
                                        _showSnackBar('Self test printed');
                                      } catch (e) {
                                        _showSnackBar('Error: $e');
                                      }
                                    }
                                  : null,
                              icon: const Icon(Icons.bug_report),
                              label: const Text('Self Test'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _isConnected ? _setLabelMode : null,
                            child: const Text('Label Mode'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isConnected ? _setPosMode : null,
                            child: const Text('POS Mode'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Printer Info Section
              if (_printerInfo != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Printer Information',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 10),
                        Text('Firmware: ${_printerInfo!.firmwareVersion}'),
                        Text(
                            'Resolution: ${_printerInfo!.widthMm}x${_printerInfo!.heightMm}mm'),
                        Text('DPI: ${_printerInfo!.dotsPerMm} dots/mm'),
                        Text(
                            'Error Status: 0x${_printerInfo!.errorStatus.toRadixString(16)}'),
                        Text(
                            'Received: ${_printerInfo!.receivedByteCount} bytes'),
                        Text('Printed Pages: ${_printerInfo!.printedPageId}'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
