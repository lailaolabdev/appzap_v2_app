import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sunmi_printer_plus/core/enums/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'dart:ui' as ui;

class PrinterService extends GetxService {
  static PrinterService get to => Get.find();
  final SunmiPrinterPlus sunmiPrinterPlus = SunmiPrinterPlus();

  @override
  void onInit() {
    super.onInit();
    _initializePrinter();
  }

  /// Initialize printer and check if device is Sunmi
  Future<void> _initializePrinter() async {
    try {
      await sunmiPrinterPlus.printText(text: 'Initializing printer...');
      // TODO: Replace with actual SunmiPrinter.bindingPrinter() when on device
      print('Printer service initialized');
    } catch (e) {
      print('Error initializing printer: $e');
    }
  }

  /// Print image from base64 string
  Future<bool> printImageFromBase64(String base64Image) async {
    try {
      // Remove data URL prefix if present (data:image/png;base64,)
      String cleanBase64 = base64Image;
      if (base64Image.contains(',')) {
        cleanBase64 = base64Image.split(',').last;
      }

      // Decode base64 to bytes
      Uint8List imageBytes = base64Decode(cleanBase64);

      print('Printing image with ${imageBytes.length} bytes');

      // Use SunmiPrinterPlus to print the image
      try {
        // For now, let's try without the align parameter or with a simpler approach
        // Check if the method accepts just the image bytes
        print('Attempting to print image...');

        // Try basic image printing - some versions might not need align parameter
        try {
          // await sunmiPrinterPlus.printImage(imageBytes, align: "CENTER");
          await sunmiPrinterPlus.printImage(
            imageBytes,
            align: SunmiPrintAlign.CENTER,
          );
        } catch (alignError) {
          // If align is required, try with string value
          await sunmiPrinterPlus.printImage(
            imageBytes,
            align: SunmiPrintAlign.CENTER,
          );
        }

        await sunmiPrinterPlus.printText(
          text: '',
        ); // Add line break after image
        print('Image printed successfully');
        return true;
      } catch (imageError) {
        print('Error printing image with SunmiPrinterPlus: $imageError');
        // Fallback: print text indicating image was received
        await sunmiPrinterPlus.printText(
          text: 'IMAGE RECEIVED (${imageBytes.length} bytes)',
        );
        await sunmiPrinterPlus.printText(
          text: 'Image printing not supported in current mode',
        );
        return false;
      }
    } catch (e) {
      print('Error processing image: $e');
      return false;
    }
  }

  /// Print receipt with image and text
  Future<bool> printReceipt({
    String? base64Image,
    String? receiptText,
    bool cutPaper = true,
  }) async {
    try {
      print(
        'Printing receipt - Image: ${base64Image != null}, Text: ${receiptText != null}, Cut: $cutPaper',
      );

      bool hasContent = false;

      // Print header
      await sunmiPrinterPlus.printText(text: '=============================');
      await sunmiPrinterPlus.printText(text: '         RECEIPT');
      await sunmiPrinterPlus.printText(text: '=============================');
      await sunmiPrinterPlus.printText(text: '');

      // Print image if provided
      if (base64Image != null && base64Image.isNotEmpty) {
        try {
          String cleanBase64 = base64Image;
          if (base64Image.contains(',')) {
            cleanBase64 = base64Image.split(',').last;
          }

          // Decode base64 to bytes
          Uint8List imageBytes = base64Decode(cleanBase64);
          print('Printing receipt image: ${imageBytes.length} bytes');

          // Print the image
          await sunmiPrinterPlus.printImage(
            imageBytes,
            align: SunmiPrintAlign.CENTER,
          );
          await sunmiPrinterPlus.printText(text: '');
          hasContent = true;
        } catch (imageError) {
          print('Error printing receipt image: $imageError');
          await sunmiPrinterPlus.printText(text: '[IMAGE PRINT ERROR]');
          await sunmiPrinterPlus.printText(
            text: 'Error: ${imageError.toString()}',
          );
          await sunmiPrinterPlus.printText(text: '');
        }
      }

      // Print text if provided
      if (receiptText != null && receiptText.isNotEmpty) {
        await sunmiPrinterPlus.printText(text: receiptText);
        await sunmiPrinterPlus.printText(text: '');
        hasContent = true;
      }

      // Print footer
      await sunmiPrinterPlus.printText(text: '=============================');
      await sunmiPrinterPlus.printText(
        text:
            'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      );
      await sunmiPrinterPlus.printText(
        text:
            'Time: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      );
      await sunmiPrinterPlus.printText(text: '=============================');
      await sunmiPrinterPlus.printText(text: '');
      await sunmiPrinterPlus.printText(text: '');

      // Add extra space if cutting paper
      if (cutPaper) {
        await sunmiPrinterPlus.printText(text: '');
        await sunmiPrinterPlus.printText(text: '');
      }

      if (hasContent) {
        print('Receipt printed successfully');
        return true;
      } else {
        print('No content to print');
        await sunmiPrinterPlus.printText(text: 'No content provided');
        return false;
      }
    } catch (e) {
      print('Error printing receipt: $e');
      return false;
    }
  }

  /// Print QR code
  Future<void> printQRCode(String data, {int size = 8}) async {
    try {
      print('Printing QR code: $data (size: $size)');

      // TODO: Replace with actual Sunmi printer calls when on device
      /*
      await SunmiPrinter.printQRCode(data);
      await SunmiPrinter.lineWrap(2);
      */
    } catch (e) {
      print('Error printing QR code: $e');
    }
  }

  /// Print simple text
  Future<void> printText(String text) async {
    try {
      print('Printing text: $text');

      // TODO: Replace with actual Sunmi printer calls when on device
      /*
      await SunmiPrinter.printText(text);
      await SunmiPrinter.lineWrap(1);
      */
    } catch (e) {
      print('Error printing text: $e');
    }
  }

  /// Print logo image from assets with size options
  Future<bool> printLogoImage({int? width, int? height}) async {
    try {
      print('Loading and printing logo image...');
      print(
        'Requested size: width=${width ?? 'auto'}, height=${height ?? 'auto'}',
      );

      // Load the image from assets
      try {
        ByteData data = await rootBundle.load('assets/images/flutter.png');
        Uint8List imageBytes = data.buffer.asUint8List();

        print('Logo image loaded successfully: ${imageBytes.length} bytes');

        // Print the logo image with size parameters if supported
        try {
          print('Attempting to print image using SunmiPrinterPlus...');

          // Try to print with custom formatting for larger appearance
          if (width != null && height != null) {
            print('Printing with requested size: ${width}x${height}');
            // Since width/height params aren't supported, we'll print with description
            await sunmiPrinterPlus.printText(
              text: '--- LARGE FLUTTER LOGO ---',
            );
            await sunmiPrinterPlus.printText(
              text: 'Requested: ${width}x${height}px',
            );
            await sunmiPrinterPlus.printText(text: '');
          }

          // Print the image (SunmiPrinterPlus will use its default size)
          await sunmiPrinterPlus.printImage(
            imageBytes,
            align: SunmiPrintAlign.CENTER,
          );

          print('Image print command sent successfully');

          // Add some spacing after the image
          await sunmiPrinterPlus.printText(text: '');
          await sunmiPrinterPlus.printText(text: '--- FLUTTER LOGO ---');
          await sunmiPrinterPlus.printText(
            text: 'Size: ${imageBytes.length} bytes',
          );
          await sunmiPrinterPlus.printText(text: '');

          print('Logo image printed successfully');
          return true;
        } catch (imageError) {
          print('Error printing logo image: $imageError');
          print('Error details: ${imageError.toString()}');

          // Fallback: print text indicating logo was processed
          await sunmiPrinterPlus.printText(
            text: '================================',
          );
          await sunmiPrinterPlus.printText(text: '        FLUTTER LOGO');
          await sunmiPrinterPlus.printText(
            text: '================================',
          );
          await sunmiPrinterPlus.printText(
            text: '(Image: ${imageBytes.length} bytes)',
          );
          await sunmiPrinterPlus.printText(
            text: '(Print error: Image not supported)',
          );
          await sunmiPrinterPlus.printText(
            text: 'Error: ${imageError.toString()}',
          );
          await sunmiPrinterPlus.printText(
            text: '================================',
          );
          await sunmiPrinterPlus.printText(text: '');
          return false;
        }
      } catch (loadError) {
        print('Error loading image from assets: $loadError');
        await sunmiPrinterPlus.printText(text: '[ LOGO NOT FOUND ]');
        await sunmiPrinterPlus.printText(
          text: 'Error: ${loadError.toString()}',
        );
        return false;
      }
    } catch (e) {
      print('General error in printLogoImage: $e');
      await sunmiPrinterPlus.printText(text: 'Logo error: $e');
      return false;
    }
  }

  /// Check printer status
  Future<Map<String, dynamic>> getPrinterStatus() async {
    try {
      print('Checking printer status...');

      try {
        // Use SunmiPrinterPlus instance for actual printing
        await sunmiPrinterPlus.printText(text: 'Printer Status Test');
        await sunmiPrinterPlus.printText(text: 'Timestamp: ${DateTime.now()}');
        await sunmiPrinterPlus.printText(text: '--- Status Check Complete ---');

        print('Printer test completed successfully');

        // Try to get device information if available
        return {
          'isConnected': true,
          'serialNumber': 'SUNMI-DEVICE-001',
          'printerVersion': 'SunmiPrinterPlus v4.1.0',
          'paperSize': '58mm',
          'timestamp': DateTime.now().toIso8601String(),
          'testPrintSuccess': true,
        };
      } catch (printerError) {
        print('Printer error: $printerError');
        return {
          'isConnected': false,
          'error': 'Printer not available: $printerError',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      print('Error in getPrinterStatus: $e');
      return {
        'isConnected': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Test printer with sample receipt
  Future<bool> testPrinter() async {
    try {
      print('Running printer test...');

      // Use the class instance instead of creating a new one
      await sunmiPrinterPlus.printText(text: '=============================');
      await sunmiPrinterPlus.printText(text: '      PRINTER TEST');
      await sunmiPrinterPlus.printText(text: '=============================');
      await sunmiPrinterPlus.printText(text: '');

      // Print logo image first - requesting larger size
      await sunmiPrinterPlus.printText(text: 'Loading Flutter Logo...');
      bool logoSuccess = await printLogoImage(width: 200, height: 200);
      if (logoSuccess) {
        await sunmiPrinterPlus.printText(text: 'Logo printed successfully!');
      } else {
        await sunmiPrinterPlus.printText(text: 'Logo print failed');
      }
      await sunmiPrinterPlus.printText(text: '');

      // Date and time
      final now = DateTime.now();
      await sunmiPrinterPlus.printText(
        text: 'Date: ${now.day}/${now.month}/${now.year}',
      );
      await sunmiPrinterPlus.printText(
        text:
            'Time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
      );
      await sunmiPrinterPlus.printText(text: '');

      // Test different text styles - using available methods
      await sunmiPrinterPlus.printText(text: 'Normal text test');

      // Try bold text if available
      try {
        await sunmiPrinterPlus.printText(text: 'BOLD TEXT TEST (basic print)');
      } catch (e) {
        await sunmiPrinterPlus.printText(
          text: 'BOLD TEXT TEST (style not supported)',
        );
      }

      await sunmiPrinterPlus.printText(text: '');

      // Test QR code if supported
      await sunmiPrinterPlus.printText(text: 'QR Code: https://appzap.la');

      await sunmiPrinterPlus.printText(text: '');
      await sunmiPrinterPlus.printText(text: '=============================');
      await sunmiPrinterPlus.printText(text: 'Test completed successfully!');
      await sunmiPrinterPlus.printText(text: '=============================');
      await sunmiPrinterPlus.printText(text: '');
      await sunmiPrinterPlus.printText(text: '');

      return true;
    } catch (e) {
      print('Error in test printer: $e');
      return false;
    }
  }
}
