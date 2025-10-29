import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:appzap_v2_app/widgets/blutooth_widget.dart';
import 'package:image/image.dart' as img;

class BluetoothController extends GetxController {
  // Observable connection status
  Rx<BluetoothDevice?> connectedDevice = Rx<BluetoothDevice?>(null);
  RxBool isConnecting = false.obs;

  // Scanning state
  RxList<ScanResult> scanResult = <ScanResult>[].obs;
  RxBool isScanning = false.obs;
  RxBool showAllDevices = false.obs;

  // Computed property for connection status
  bool get isConnected => connectedDevice.value != null;

  @override
  void onInit() {
    super.onInit();
    findDevices();
    print('BluetoothController onInit');
  }

  // Check if device name suggests it's a printer
  bool isPrinterDevice(String name) {
    if (name.isEmpty) return false;

    final nameLower = name.toLowerCase();
    final printerKeywords = [
      'print',
      'printer',
      'pos',
      'receipt',
      'thermal',
      'rpp',
      'mpt',
      'bluetooth printer',
      'star',
      'epson',
      'citizen',
      'bixolon',
      'zebra',
      'sunmi',
      'rongta',
      'xprinter',
    ];

    return printerKeywords.any((keyword) => nameLower.contains(keyword));
  }

  // Get filtered results
  List<ScanResult> get filteredResults {
    if (showAllDevices.value) return scanResult;
    return scanResult.where((result) {
      return isPrinterDevice(result.device.platformName);
    }).toList();
  }

  // Listen to device connection state
  void listenToConnectionState(BluetoothDevice device) {
    device.connectionState.listen((state) {
      print('📡 Connection state changed: $state');
      if (state == BluetoothConnectionState.connected) {
        connectedDevice.value = device;
        isConnecting.value = false;
      } else if (state == BluetoothConnectionState.disconnected) {
        if (connectedDevice.value?.remoteId == device.remoteId) {
          connectedDevice.value = null;
        }
        isConnecting.value = false;
      }
    });
  }

  Future<void> findDevices() async {
    print('🔍 Starting device scan...');

    // Check if Bluetooth is available and turned on
    try {
      bool isSupported = await FlutterBluePlus.isSupported;
      print('📱 Bluetooth supported: $isSupported');

      if (!isSupported) {
        print('❌ Bluetooth not supported');
        Get.snackbar(
          'Bluetooth Not Supported',
          'Bluetooth is not supported on this device',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Check Bluetooth adapter state
      var adapterState = await FlutterBluePlus.adapterState.first;
      print('📡 Bluetooth state: $adapterState');

      if (adapterState != BluetoothAdapterState.on) {
        print('❌ Bluetooth is OFF');
        Get.snackbar(
          'Bluetooth Off',
          'Please turn on Bluetooth in your device settings',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      print('✅ Bluetooth is ON');
    } catch (e) {
      print('❌ Error checking Bluetooth state: $e');
      Get.snackbar(
        'Bluetooth Error',
        'Error checking Bluetooth: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Request permissions based on platform
    print('🔐 Requesting permissions...');
    bool hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      print('❌ Permissions denied');
      return;
    }
    print('✅ Permissions granted');

    // Start scanning
    isScanning.value = true;

    try {
      print('🔎 Starting Bluetooth scan (10 seconds)...');
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      FlutterBluePlus.scanResults.listen((results) {
        print('📱 Found ${results.length} device(s)');

        int printerCount = 0;
        for (var result in results) {
          final name = result.device.platformName.isNotEmpty
              ? result.device.platformName
              : "Unknown";
          final isPrinter = isPrinterDevice(name);
          if (isPrinter) printerCount++;

          print(
            '  - $name (${result.device.remoteId}) ${isPrinter ? "🖨️ PRINTER" : ""}',
          );
        }

        print('🖨️ Detected $printerCount printer device(s)');
        scanResult.value = results;
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 10));
      await FlutterBluePlus.stopScan();
      print('✅ Scan completed. Total devices: ${scanResult.length}');

      if (scanResult.isEmpty) {
        print('⚠️ No devices found. Make sure:');
        print('  1. Bluetooth printer is turned ON');
        print('  2. Printer is in pairing/discoverable mode');
        print('  3. You are close to the printer');
      }
    } catch (e) {
      print('❌ Error during scan: $e');
      Get.snackbar(
        'Scan Error',
        'Error scanning: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isScanning.value = false;
      print('🏁 Scan process finished');
    }
  }

  Future<bool> requestPermissions() async {
    // iOS doesn't need location permissions for Bluetooth
    // Android needs location permissions for Bluetooth scanning
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS only needs bluetooth permissions (already in Info.plist)
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
      ].request();

      bool allGranted = statuses.values.every(
        (status) => status.isGranted || status.isLimited,
      );

      if (!allGranted) {
        print('Bluetooth permissions not granted on iOS');
        showPermissionDeniedDialog();
      }
      return allGranted;
    } else {
      // Android needs location + bluetooth permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      bool allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        print('Permissions not granted on Android');
        Get.snackbar(
          'Permissions Required',
          'Bluetooth and Location permissions are required to scan devices',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
      return allGranted;
    }
  }

  void showPermissionDeniedDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Bluetooth Permission Required'),
        content: const Text(
          'This app needs Bluetooth permission to scan and connect to printers. '
          'Please enable Bluetooth permission in Settings.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings(); // Opens iOS Settings for this app
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> printWithDevice(BluetoothDevice device) async {
    print('🖨️ Attempting to print to: ${device.platformName}');

    isConnecting.value = true;

    try {
      // Show loading
      Get.snackbar(
        'Connecting',
        'Connecting to ${device.platformName.isNotEmpty ? device.platformName : "printer"}...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      print('📡 Connecting to device...');
      // Start listening to connection state
      listenToConnectionState(device);

      await device.connect(timeout: const Duration(seconds: 10));
      print('✅ Connected successfully');

      print('📄 Preparing print data...');
      final gen = Generator(PaperSize.mm80, await CapabilityProfile.load());
      final printer = BluePrint();
      printer.add(gen.qrcode('https://altospos.com'));
      printer.add(gen.text('Hello'));
      printer.add(gen.text('World', styles: const PosStyles(bold: true)));
      printer.add(gen.feed(1));
      printer.add(gen.cut());
      print('🖨️ Sending data to printer...');
      await printer.printData(device);
      print('✅ Print completed');

      Get.snackbar(
        'Success',
        'Print successful!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Keep connection alive - don't disconnect automatically
      print('✅ Connection maintained');
    } catch (e) {
      print('❌ Print error: $e');
      isConnecting.value = false;

      Get.snackbar(
        'Print Failed',
        'Print failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Try to disconnect on error
      try {
        await device.disconnect();
        connectedDevice.value = null;
      } catch (disconnectError) {
        print('⚠️ Error disconnecting: $disconnectError');
      }
    }
  }

  Future<void> printBluetoothReceipt({
    Map<String, dynamic>? receiptData,
  }) async {
    if (connectedDevice.value == null) {
      Get.snackbar(
        'No Printer Connected',
        'Please connect to a Bluetooth printer first',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    log('Receipt data: ${receiptData.toString()}');
    log('name12345: ${receiptData?['restaurantInfo']}');

    print(
      '🖨️ Attempting to print receipt to: ${connectedDevice.value!.platformName}',
    );

    try {
      final gen = Generator(PaperSize.mm80, await CapabilityProfile.load());
      final printer = BluePrint();

      // Extract data from receiptData
      Map<String, dynamic>? order;
      Map<String, dynamic>? restaurantInfo;
      String? paymentMethod;
      if (receiptData?.containsKey('receiptData') ?? false) {
        order = receiptData?['receiptData']?['data']?['data']?['order'];
        restaurantInfo = receiptData?['restaurantInfo'];
        paymentMethod = receiptData?['receiptData']?['data']?['data']?['pricing']?['payments'][0]?['method'] ?? '-';
      } else {
        order = receiptData?['data']?['data']?['order'] ?? receiptData;
        restaurantInfo = receiptData?['restaurantInfo'];
        paymentMethod = receiptData?['data']?['data'] ?? '-';
      }

      log('order1234: ${receiptData?['receiptData']?['data']?['data']}');
      log('restaurantInfo123: $restaurantInfo');
      // Header - Restaurant Info
      printer.add(gen.feed(1));
      // printer.add(
      //   gen.text(
      //     restaurantInfo?['name'] ?? 'Restaurant Name',
      //     styles: PosStyles(align: PosAlign.center, bold: true),
      //   ),
      // );
      await _addText(
        gen,
        printer,
        restaurantInfo?['name'] ?? 'Restaurant Name',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
        ),
      );
      // printer.add(
      //   gen.text(
      //     restaurantInfo?['slogan'] ?? '',
      //     styles: const PosStyles(align: PosAlign.center),
      //   ),
      // );
      await _addText(
        gen,
        printer,
        restaurantInfo?['slogan'] ?? '',
        styles: const PosStyles(align: PosAlign.center),
      );
      await _addText(
        gen,
        printer,
        restaurantInfo?['contactInfo']?['phone'] ?? '',
        styles: const PosStyles(align: PosAlign.center),
      );
      printer.add(gen.feed(1));
      await _addText(
        gen,
        printer,
        'Q: ${order?['qNumber'] ?? ''}',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      printer.add(gen.feed(1));

      // Bill Header
      // printer.add(
      //   gen.text(
      //     '============= ລາຍການ ============',
      //     styles: const PosStyles(align: PosAlign.center, bold: true),
      //   ),
      // );

      // Order Info
      if (order != null) {
        final customer = order['customer']?['name'] ?? '-';
        final phone = order['customer']?['phone'] ?? '-';

        await _addText(
          gen,
          printer,
          'order type: ${order['orderType'] ?? '-'}',
          styles: const PosStyles(align: PosAlign.left),
        );
        await _addText(
          gen,
          printer,
          'customer: $customer',
          styles: const PosStyles(align: PosAlign.left),
        );
        await _addText(
          gen,
          printer,
          'phone: $phone',
          styles: const PosStyles(align: PosAlign.left),
        );
        printer.add(gen.feed(1));
      }

      // Line Items
      printer.add(
        gen.text(
          '================================================',
          styles: const PosStyles(bold: true, align: PosAlign.center,),
        ),
      );
      printer.add(
        gen.text(
          'ORDERS',
          styles: const PosStyles(bold: true, align: PosAlign.center),
        ),
      );
      printer.add(
        gen.text(
          '================================================',
          styles: const PosStyles(bold: true, align: PosAlign.center),
        ),
      );

      if (order != null && order['lineItems'] != null) {
        for (var item in order['lineItems']) {
          final name = item['name'] ?? 'Item';
          final qty = item['quantity'] ?? 1;
          final price = _toDouble(item['unitPrice']?['amount']);
          final total = _toDouble(item['lineTotal']?['amount']);

          // Print item name (with Lao support) - Bold
          await _addText(
            gen,
            printer,
            name,
            styles: const PosStyles(bold: true),
          );

          // Print quantity, price and total in row format
          printer.add(
            gen.row([
              PosColumn(
                text: '$qty x ${_formatCurrency(price)}',
                width: 8,
                styles: const PosStyles(align: PosAlign.left),
              ),
              PosColumn(
                text: _formatCurrency(total),
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true),
              ),
            ]),
          );

          // Print modifiers if any
          if (item['options'] != null && item['options'].isNotEmpty) {
            for (var modifier in item['options']) {
              final modifierName = modifier['name'] ?? '';
              await _addText(
                gen,
                printer,
                '  + $modifierName',
                styles: const PosStyles(width: PosTextSize.size1),
              );
            }
          }
        }
      }

      printer.add(gen.feed(1));
      printer.add(gen.text('================================================',styles: const PosStyles(align: PosAlign.center)));

      // Pricing Summary
      if (order != null && order['pricing'] != null) {
        final pricing = order['pricing'];

        printer.add(gen.row([
          PosColumn(text: 'Subtotal:', width: 8),
          PosColumn(text: _formatCurrency(_toDouble(pricing['lineItemsTotal']?['amount'])), width: 4, styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
        );

        // Discount
        if (pricing['discount'] != null && _toDouble(pricing['discount']) > 0) {
          printer.add(
            gen.row([
              PosColumn(text: 'Discount:', width: 8),
              PosColumn(
                text: '-${_formatCurrency(_toDouble(pricing['discount']))}',
                width: 4,
                styles: const PosStyles(align: PosAlign.right),
              ),
            ]),
          );
        }

        // Service Charge
        if (pricing['serviceCharge'] != null &&
            _toDouble(pricing['serviceCharge']) > 0) {
          printer.add(
            gen.row([
              PosColumn(text: 'Service Charge:', width: 8),
              PosColumn(
                text: _formatCurrency(_toDouble(pricing['serviceCharge'])),
                width: 4,
                styles: const PosStyles(align: PosAlign.right),
              ),
            ]),
          );
        }

        // Tax
        if (pricing['tax'] != null && _toDouble(pricing['tax']) > 0) {
          printer.add(
            gen.row([
              PosColumn(text: 'Tax:', width: 8),
              PosColumn(
                text: _formatCurrency(_toDouble(pricing['tax'])),
                width: 4,
                styles: const PosStyles(align: PosAlign.right),
              ),
            ]),
          );
        }

        printer.add(gen.row([
          PosColumn(text: 'Payment Method:', width: 8),
          PosColumn(text: paymentMethod ?? '-', width: 4, styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
        ); 

        printer.add(gen.text('================================================',styles: const PosStyles(align: PosAlign.center)));
        printer.add(gen.feed(1));

        // Total
        printer.add(
          gen.row([
            PosColumn(
              text: 'Total:',
              width: 8,
              styles: const PosStyles(bold: true, height: PosTextSize.size2),
            ),
            PosColumn(
              text: _formatCurrency(_toDouble(pricing['lineItemsTotal']?['amount'])),
              width: 4,
              styles: const PosStyles(
                align: PosAlign.right,
                bold: true,
                height: PosTextSize.size2,
              ),
            ),
          ]),
        );
      }

      printer.add(gen.feed(1));
      printer.add(gen.text('================================================',styles: const PosStyles(align: PosAlign.center)));
      printer.add(gen.feed(1));

      // Footer

      await _addText(
        gen,
        printer,
        restaurantInfo?['shortDescription'] ?? '',
        styles: const PosStyles(align: PosAlign.center),
      );
      
      printer.add(gen.feed(2));

      // QR Code (optional)
      if (order != null && order['id'] != null) {
        printer.add(
          gen.qrcode(
            'ORDER:${order['id']}',
            size: QRSize.size5,
            align: PosAlign.center,
          ),
        );
        printer.add(gen.feed(1));
      }

      printer.add(gen.cut());

      // Send to printer
      print('🖨️ Sending receipt data to Bluetooth printer...');
      await printer.printData(connectedDevice.value!);
      print('✅ Receipt printed successfully');

      Get.snackbar(
        'Success',
        'Receipt printed successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ Error printing Bluetooth receipt: $e');
      Get.snackbar(
        'Print Failed',
        'Failed to print receipt: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> printBluetoothReceiptImage() async {
    try {
      print(
        '🖨️ Attempting to print receipt to: ${connectedDevice.value!.platformName}',
      );
      final gen = Generator(PaperSize.mm80, await CapabilityProfile.load());
      final printer = BluePrint();

      printer.add(gen.feed(1));

      // Header - will auto-detect ASCII/non-ASCII
      await _addText(
        gen,
        printer,
        'APPZAP STORE',
        styles: const PosStyles(align: PosAlign.center, bold: true),
        linesAfter: 1,
      );

      await _addText(
        gen,
        printer,
        'smell coffee',
        styles: const PosStyles(align: PosAlign.center),
        linesAfter: 1,
      );

      printer.add(gen.feed(1));

      // Bill Header
      printer.add(
        gen.text(
          '============= BILL ============',
          styles: const PosStyles(align: PosAlign.center, bold: true),
          linesAfter: 1,
        ),
      );

      // Item 1 - Lao text (will be rendered as image)
      // await _addText(
      //   gen,
      //   printer,
      //   'ຕຳໝາກຮຸ່ງ',
      //   styles: const PosStyles(bold: true),
      // );
      printer.add(
        gen.row([
          PosColumn(
            text: 'papaya smoothie',
            width: 3,
            styles: PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: '1 x 10000',
            width: 8,
            styles: PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: '10000',
            width: 4,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]),
      );

      // Item 2 - ASCII text
      // printer.add(gen.text('Latte', styles: const PosStyles(bold: true)));
      // printer.add(gen.row([PosColumn(text: '1 x 10000')]));
      // printer.add(
      //   gen.row([
      //     PosColumn(
      //       text: '10000',
      //       styles: const PosStyles(align: PosAlign.right),
      //     ),
      //   ]),
      // );
      printer.add(
        gen.row([
          PosColumn(
            text: 'Latte',
            width: 3,
            styles: PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: '1 x 10000',
            width: 6,
            styles: PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: '10000',
            width: 3,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]),
      );

      printer.add(gen.feed(1));
      printer.add(
        gen.text(
          '================================',
          linesAfter: 1,
          styles: const PosStyles(align: PosAlign.center),
        ),
      );
      printer.add(gen.feed(1));
      printer.add(
        gen.text(
          'Total: 20000',
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      );
      printer.add(gen.feed(1));

      // await _addText(
      //   gen,
      //   printer,
      //   'ຂອບໃຈສໍາລັບການຊື້ສິນຄ້າຂອງທ່ານ!',
      //   styles: const PosStyles(align: PosAlign.center, bold: true),
      //   linesAfter: 1,
      // );

      printer.add(gen.feed(1));
      printer.add(gen.text('Thank you for your business!'));
      // await _addText(
      //   gen,
      //   printer,
      //   'Thank you for your business!',
      //   styles: const PosStyles(align: PosAlign.center),
      // );

      printer.add(gen.feed(2));
      printer.add(gen.cut());

      await printer.printData(connectedDevice.value!);
      print('✅ Print completed');

      Get.snackbar(
        'Success',
        'Receipt printed successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ Error printing Bluetooth receipt: $e');
      Get.snackbar(
        'Print Failed',
        'Failed to print receipt: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Helper method to check if text contains non-ASCII characters (like Lao)
  bool _containsNonASCII(String text) {
    return text.codeUnits.any((unit) => unit > 127);
  }

  // Helper method to render text as image for non-ASCII characters
  Future<img.Image?> _renderTextAsImage(
    String text, {
    double fontSize = 26,
    bool bold = false,
    TextAlign align = TextAlign.left,
    int width = 570, // 👈 Adjust for your printer (try 570–580px for 80mm)
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Lao-capable font (must be loaded beforehand)
      final textStyle = TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontFamily: 'NotoSansLao',
        height: 1, // 👈 line height consistency
      );

      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: align,
      );

      textPainter.layout(maxWidth: width.toDouble());

      final imageWidth = width;
      final imageHeight = (textPainter.height + 20).toInt();

      // Draw background
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, imageWidth.toDouble(), imageHeight.toDouble()),
        bgPaint,
      );

      // Calculate alignment offset
      double xOffset;
      final textWidth = textPainter.width;
      const double padding = 20.0;
      switch (align) {
        case TextAlign.center:
          xOffset = (imageWidth - textWidth) / 2;
          break;
        case TextAlign.right:
          xOffset = imageWidth - textWidth - padding;
          break;
        default:
          xOffset = padding;
          break;
      }

      // Draw Lao text
      textPainter.paint(canvas, Offset(xOffset, 10));

      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(imageWidth, imageHeight);

      final byteData = await uiImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      final image = img.Image(width: imageWidth, height: imageHeight);

      // Convert RGBA → grayscale
      int i = 0;
      for (int y = 0; y < imageHeight; y++) {
        for (int x = 0; x < imageWidth; x++) {
          final r = bytes[i];
          final g = bytes[i + 1];
          final b = bytes[i + 2];
          final a = bytes[i + 3];
          final gray = (0.299 * r + 0.587 * g + 0.114 * b).round();
          image.setPixelRgba(x, y, gray, gray, gray, a);
          i += 4;
        }
      }

      return img.contrast(image, contrast: 160);
    } catch (e, st) {
      print('❌ _renderTextAsImage error: $e\n$st');
      return null;
    }
  }

  // Helper method to add text (auto-detect and use image if needed)
  Future<void> _addText(
    Generator gen,
    BluePrint printer,
    String text, {
    PosStyles? styles,
    int? linesAfter,
  }) async {
    if (_containsNonASCII(text)) {
      // Render as image
      print(
        '🖼️ Rendering non-ASCII text as image: "$text" (${text.length} chars)',
      );
      try {
        final image = await _renderTextAsImage(
          text,
          fontSize: styles?.height == PosTextSize.size2 ? 32 : 24,
          bold: styles?.bold ?? false,
          align: styles?.align == PosAlign.center
              ? TextAlign.center
              : styles?.align == PosAlign.right
              ? TextAlign.right
              : TextAlign.left,
        );

        if (image == null) {
          print('⚠️ Image rendering returned null, using placeholder');
          printer.add(gen.text('[$text]'));
          return;
        }

        // Try to print the image
        print(
          '✅ Image rendered successfully, size: ${image.width}x${image.height}',
        );
        try {
          // Use imageRaster for better quality
          printer.add(
            gen.imageRaster(image, align: styles?.align ?? PosAlign.left),
          );
          if (linesAfter != null && linesAfter > 0) {
            printer.add(gen.feed(linesAfter));
          }
          print('✅ Image added to print queue using imageRaster');
        } catch (e) {
          print('⚠️ Error with imageRaster, trying image(): $e');
          try {
            // Fallback to image() method
            printer.add(
              gen.image(image, align: styles?.align ?? PosAlign.left),
            );
            if (linesAfter != null && linesAfter > 0) {
              printer.add(gen.feed(linesAfter));
            }
            print('✅ Image added to print queue using image()');
          } catch (e2) {
            print('⚠️ Both image methods failed: $e2');
            // Last resort: print placeholder
            printer.add(gen.text('[$text]'));
          }
        }
      } catch (e) {
        print('❌ Error in _addText image processing: $e');
        printer.add(gen.text('[$text]'));
      }
    } else {
      // Normal ASCII text
      if (styles != null) {
        if (linesAfter != null) {
          printer.add(gen.text(text, styles: styles, linesAfter: linesAfter));
        } else {
          printer.add(gen.text(text, styles: styles));
        }
      } else {
        if (linesAfter != null) {
          printer.add(gen.text(text, linesAfter: linesAfter));
        } else {
          printer.add(gen.text(text));
        }
      }
    }
  }

  Future<void> _addLaoRow({
  required Generator gen,
  required BluePrint printer,
  required String laoText,
  required String price,
}) async {
  try {
    // Render Lao text to image
    final laoImage = await _renderTextAsImage(
      laoText,
      fontSize: 28,
      bold: true,
      align: TextAlign.left,
      width: 380, // For 80mm paper
    );

    if (laoImage != null) {
      printer.add(gen.imageRaster(laoImage, align: PosAlign.left));
    } else {
      printer.add(gen.text(laoText, styles: const PosStyles(align: PosAlign.left)));
    }

    // Add the price column aligned right
    printer.add(
      gen.row([
        PosColumn(
          text: '',
          width: 8, // Lao part handled by image
        ),
        PosColumn(
          text: price,
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
  } catch (e) {
    print('❌ Error printing Lao row: $e');
  }
}


  // Helper method to format currency
  String _formatCurrency(double amount) {
    return 'K${amount.toStringAsFixed(0)}';
  }

  // Helper method to convert to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper method to format date time
  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '-';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  // Manual disconnect method
  Future<void> disconnectDevice() async {
    if (connectedDevice.value != null) {
      try {
        print(
          '🔌 Disconnecting from ${connectedDevice.value!.platformName}...',
        );
        await connectedDevice.value!.disconnect();
        connectedDevice.value = null;
        print('✅ Disconnected');
      } catch (e) {
        print('❌ Error disconnecting: $e');
      }
    }
  }

  void toggleShowAllDevices() {
    showAllDevices.value = !showAllDevices.value;
  }

  @override
  void onClose() {
    disconnectDevice();
    super.onClose();
  }
}
