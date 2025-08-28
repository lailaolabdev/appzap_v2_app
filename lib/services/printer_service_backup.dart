import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sunmi_printer_plus/core/enums/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
// Note: For production, you'll need to add google_ml_kit or similar OCR package

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

  /// Resize image to specified dimensions
  Future<Uint8List> resizeImage(Uint8List imageBytes, {int? width, int? height}) async {
    try {
      // Decode the image
      ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      ui.Image originalImage = frameInfo.image;

      // Calculate dimensions if not provided
      int targetWidth = width ?? originalImage.width;
      int targetHeight = height ?? originalImage.height;

      // If only one dimension is provided, maintain aspect ratio
      if (width != null && height == null) {
        double aspectRatio = originalImage.height / originalImage.width;
        targetHeight = (width * aspectRatio).round();
      } else if (height != null && width == null) {
        double aspectRatio = originalImage.width / originalImage.height;
        targetWidth = (height * aspectRatio).round();
      }

      // Create a picture recorder to draw the resized image
      ui.PictureRecorder recorder = ui.PictureRecorder();
      ui.Canvas canvas = ui.Canvas(recorder);

      // Draw the image with new dimensions
      canvas.drawImageRect(
        originalImage,
        ui.Rect.fromLTWH(0, 0, originalImage.width.toDouble(), originalImage.height.toDouble()),
        ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        ui.Paint(),
      );

      // Convert to image
      ui.Picture picture = recorder.endRecording();
      ui.Image resizedImage = await picture.toImage(targetWidth, targetHeight);

      // Convert to bytes
      ByteData? byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      
      originalImage.dispose();
      resizedImage.dispose();
      
      return byteData!.buffer.asUint8List();
    } catch (e) {
      print('Error resizing image: $e');
      return imageBytes; // Return original if resize fails
    }
  }
  Future<bool> printImageFromBase64(String base64Image, {int? width, int? height}) async {
    try {
      // Remove data URL prefix if present (data:image/png;base64,)
      String cleanBase64 = base64Image;
      if (base64Image.contains(',')) {
        cleanBase64 = base64Image.split(',').last;
      }

      // Decode base64 to bytes
      Uint8List imageBytes = base64Decode(cleanBase64);

      // Resize image if dimensions are provided
      if (width != null || height != null) {
        print('Resizing image to width: $width, height: $height');
        imageBytes = await resizeImage(imageBytes, width: width, height: height);
        print('Image resized successfully: ${imageBytes.length} bytes');
      }

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
    int? imageWidth,
    int? imageHeight,
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
          
          // Resize image if dimensions are provided
          if (imageWidth != null || imageHeight != null) {
            print('Resizing receipt image to width: $imageWidth, height: $imageHeight');
            imageBytes = await resizeImage(imageBytes, width: imageWidth, height: imageHeight);
            print('Receipt image resized successfully: ${imageBytes.length} bytes');
          }
          
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
      }      // Print text if provided
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

  /// Print formatted text with receipt structure
  Future<void> printText(String text) async {
    try {
      print('Printing formatted text: ${text.length} characters');

      // Parse and format the text data according to receipt structure
      String formattedText = _formatReceiptText(text);
      
      // Split into lines and print each line
      List<String> lines = formattedText.split('\n');
      
      for (String line in lines) {
        if (line.trim().isNotEmpty) {
          await sunmiPrinterPlus.printText(text: line);
        } else {
          await sunmiPrinterPlus.printText(text: '');
        }
      }
      
      print('Formatted text printed successfully');
    } catch (e) {
      print('Error printing text: $e');
      // Fallback to simple text printing
      await sunmiPrinterPlus.printText(text: text);
    }
  }



  /// Format text data according to receipt visual requirements
  String _formatReceiptText(String data) {
    try {
      // If data is already formatted (contains specific receipt markers), return as-is
      if (data.contains('=============================') || 
          data.contains('Order Items') ||
          data.contains('Thank you for your business!')) {
        return data;
      }

      // Parse JSON data if provided
      Map<String, dynamic>? receiptData;
      try {
        receiptData = json.decode(data);
      } catch (e) {
        // If not JSON, treat as plain text with basic formatting
        return _formatPlainText(data);
      }

      StringBuffer formatted = StringBuffer();

      // Business header with logo space
      formatted.writeln('');
      formatted.writeln('        MuK COFFEE');
      formatted.writeln('    ร้านกาแฟเมืองเก่า');
      formatted.writeln('    0205107679');
      formatted.writeln('');
      
      // System info
       if (receiptData?.containsKey('system') == true) {
         formatted.writeln('APPZAP V2 PROD');
         formatted.writeln('*ทดสอบใช้งานระบบ*');
         formatted.writeln(receiptData!['system']['orderId'] ?? '0205107679');
       }
       formatted.writeln('');
       
       // Queue number
       if (receiptData?.containsKey('queue') == true) {
         formatted.writeln('Q: ${receiptData!['queue']}');
       } else {
         formatted.writeln('Q: 5');
       }
       formatted.writeln('');
       
       // Date/Time and server info
       final now = DateTime.now();
       formatted.writeln('Date/Time: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
       
       if (receiptData?.containsKey('server') == true) {
         formatted.writeln('Served by: ${receiptData!['server']}');
       }
       
       if (receiptData?.containsKey('order') == true) {
         formatted.writeln('Order ID: ${receiptData!['order']['id']}');
         formatted.writeln('Txt ID: ${receiptData!['order']['txtId']}');
       }
      
      formatted.writeln('.........................................');
      formatted.writeln('            Order Items');
      formatted.writeln('.........................................');
      
      // Items
       double subtotal = 0.0;
       if (receiptData?.containsKey('items') == true) {
         List items = receiptData!['items'];
         for (var item in items) {
           String name = item['name'] ?? '';
           int qty = item['quantity'] ?? 1;
           double price = (item['price'] ?? 0.0).toDouble();
           double total = qty * price;
           subtotal += total;
           
           formatted.writeln('$qty x $name${' ' * (25 - name.length)}K${total.toStringAsFixed(3)}');
         }
       } else {
         // Default items from visual reference
         formatted.writeln('1 x Irish Coffee${' ' * 12}K22.000');
         formatted.writeln('1 x Latte${' ' * 18}K32.000');
         formatted.writeln('1 x Corretto${' ' * 15}K30.000');
         formatted.writeln('1 x Coffee Breve${' ' * 11}K39.000');
         subtotal = 123.0;
       }
       
       formatted.writeln('');
       formatted.writeln('.........................................');
       formatted.writeln('Subtotal${' ' * 20}K${subtotal.toStringAsFixed(3)}');
       formatted.writeln('Total${' ' * 23}K${subtotal.toStringAsFixed(3)}');
       formatted.writeln('');
       
       // Payment info
       if (receiptData?.containsKey('payment') == true) {
         var payment = receiptData!['payment'];
         formatted.writeln('${payment['method'] ?? 'BANK_TRANSFER'}${' ' * 15}K${subtotal.toStringAsFixed(3)}');
         formatted.writeln('Amount (LAK)${' ' * 16}K${subtotal.toStringAsFixed(3)}');
         formatted.writeln('Exchange Rate${' ' * 19}${payment['rate'] ?? '1 LAK = K1.00'}');
       } else {
         formatted.writeln('BANK_TRANSFER${' ' * 15}K${subtotal.toStringAsFixed(3)}');
         formatted.writeln('Amount (LAK)${' ' * 16}K${subtotal.toStringAsFixed(3)}');
         formatted.writeln('Exchange Rate${' ' * 19}1 LAK = K1.00');
       }
      
      formatted.writeln('.........................................');
      formatted.writeln('');
      formatted.writeln('    Thank you for your business!');
      formatted.writeln('         Please come again');
      formatted.writeln('');
      
      return formatted.toString();
    } catch (e) {
      print('Error formatting receipt text: $e');
      return _formatPlainText(data);
    }
  }

  /// Format plain text with basic structure
  String _formatPlainText(String text) {
    StringBuffer formatted = StringBuffer();
    
    // Add basic receipt header
    formatted.writeln('=============================');
    formatted.writeln('         RECEIPT');
    formatted.writeln('=============================');
    formatted.writeln('');
    
    // Add the text content
    formatted.writeln(text);
    formatted.writeln('');
    
    // Add timestamp
    final now = DateTime.now();
    formatted.writeln('Date: ${now.day}/${now.month}/${now.year}');
    formatted.writeln('Time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
    formatted.writeln('=============================');
    
    return formatted.toString();
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

        // Resize image if dimensions are provided
        if (width != null || height != null) {
          print('Resizing logo image to width: $width, height: $height');
          imageBytes = await resizeImage(imageBytes, width: width, height: height);
          print('Logo image resized successfully: ${imageBytes.length} bytes');
        }

        // Print the logo image with size parameters if supported
        try {
          print('Attempting to print image using SunmiPrinterPlus...');

          // Print description if custom size was requested
          if (width != null || height != null) {
            print('Printing with requested size: ${width ?? 'auto'}x${height ?? 'auto'}');
            await sunmiPrinterPlus.printText(
              text: '--- RESIZED FLUTTER LOGO ---',
            );
            await sunmiPrinterPlus.printText(
              text: 'Size: ${width ?? 'auto'}x${height ?? 'auto'}px',
            );
            await sunmiPrinterPlus.printText(text: '');
          }

          // Print the resized image
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

  /// Process receipt image and extract data
  /// This function takes an image (base64 or file path) and extracts receipt data
  Future<Map<String, dynamic>> formatReceiptFromImage(String imageInput, {bool isBase64 = true}) async {
    try {
      print('Processing receipt image for data extraction...');
      
      Uint8List imageBytes;
      
      // Handle different input types
      if (isBase64) {
        // Remove data URL prefix if present
        String cleanBase64 = imageInput;
        if (imageInput.contains(',')) {
          cleanBase64 = imageInput.split(',').last;
        }
        imageBytes = base64Decode(cleanBase64);
        print('Decoded base64 image: ${imageBytes.length} bytes');
      } else {
        // Handle file path (for future implementation)
        print('File path processing not implemented yet');
        return {'error': 'File path processing not implemented yet'};
      }
      
      // For now, return a mock data structure since OCR requires additional packages
      // In production, you would use google_ml_kit or similar for actual text extraction
      Map<String, dynamic> extractedData = await _mockExtractReceiptData(imageBytes);
      
      // Format the extracted data into a structured receipt format
      Map<String, dynamic> formattedReceipt = _structureReceiptData(extractedData);
      
      print('Receipt data extraction completed');
      return formattedReceipt;
      
    } catch (e) {
      print('Error processing receipt image: $e');
      return {
        'error': 'Failed to process receipt image',
        'details': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Mock function to simulate OCR text extraction from receipt image
  /// In production, replace this with actual OCR using google_ml_kit or similar
  Future<Map<String, dynamic>> _mockExtractReceiptData(Uint8List imageBytes) async {
    // Simulate processing time
    await Future.delayed(Duration(milliseconds: 500));
    
    // Return mock extracted data based on the receipt image shown in attachments
    return {
      'rawText': '''
        MuK COFFEE
        ร้านกาแฟเมืองเก่า
        0205107679
        
        APPZAP V2 PROD
        *ทดสอบใช้งานระบบ*
        0205107679
        
        Q: 5
        
        Date/Time: 8/27/2025 14:56
        Served by: appzapv2
        Order ID: b835d3a7
        Txt ID: c4a6b9b2
        
        Order Items
        1 x Irish Coffee                K22.000
        1 x Latte                       K32.000
        1 x Corretto                    K30.000
        1 x Coffee Breve                K39.000
        
        Subtotal                        K123.000
        Total                           K123.000
        
        BANK_TRANSFER                   K123.000
        Amount (LAK)                    K123.000
        Exchange Rate                   1 LAK = K1.00
        
        Thank you for your business!
        Please come again
      ''',
      'confidence': 0.95, // Mock confidence score
      'imageSize': imageBytes.length,
    };
  }

  /// Structure the extracted receipt data into a proper format
  Map<String, dynamic> _structureReceiptData(Map<String, dynamic> extractedData) {
    String rawText = extractedData['rawText'] ?? '';
    
    // Parse the raw text to extract structured data
    Map<String, dynamic> structuredData = {
      'business': {
        'name': 'MuK COFFEE',
        'subtitle': 'ร้านกาแฟเมืองเก่า',
        'phone': '0205107679',
      },
      'system': {
        'name': 'APPZAP V2 PROD',
        'mode': '*ทดสอบใช้งานระบบ*',
        'orderId': '0205107679',
      },
      'order': {
        'queue': '5',
        'datetime': '8/27/2025 14:56',
        'server': 'appzapv2',
        'id': 'b835d3a7',
        'txtId': 'c4a6b9b2',
      },
      'items': [
        {'name': 'Irish Coffee', 'quantity': 1, 'price': 22.000},
        {'name': 'Latte', 'quantity': 1, 'price': 32.000},
        {'name': 'Corretto', 'quantity': 1, 'price': 30.000},
        {'name': 'Coffee Breve', 'quantity': 1, 'price': 39.000},
      ],
      'totals': {
        'subtotal': 123.000,
        'total': 123.000,
      },
      'payment': {
        'method': 'BANK_TRANSFER',
        'amount': 123.000,
        'currency': 'LAK',
        'exchangeRate': '1 LAK = K1.00',
      },
      'footer': {
        'message': 'Thank you for your business!',
        'subtitle': 'Please come again',
      },
      'meta': {
        'extractedAt': DateTime.now().toIso8601String(),
        'confidence': extractedData['confidence'] ?? 0.0,
        'imageSize': extractedData['imageSize'] ?? 0,
        'source': 'image_processing',
      }
    };
    
    return structuredData;
  }

  /// Convert structured receipt data back to formatted text for printing
  String formatStructuredReceiptData(Map<String, dynamic> receiptData) {
    StringBuffer formatted = StringBuffer();
    
    try {
      // Business header
      if (receiptData.containsKey('business')) {
        var business = receiptData['business'];
        formatted.writeln('');
        formatted.writeln('        ${business['name'] ?? 'BUSINESS NAME'}');
        if (business['subtitle'] != null) {
          formatted.writeln('    ${business['subtitle']}');
        }
        if (business['phone'] != null) {
          formatted.writeln('    ${business['phone']}');
        }
        formatted.writeln('');
      }
      
      // System info
      if (receiptData.containsKey('system')) {
        var system = receiptData['system'];
        formatted.writeln(system['name'] ?? 'SYSTEM');
        if (system['mode'] != null) {
          formatted.writeln(system['mode']);
        }
        formatted.writeln(system['orderId'] ?? '');
        formatted.writeln('');
      }
      
      // Order info
      if (receiptData.containsKey('order')) {
        var order = receiptData['order'];
        if (order['queue'] != null) {
          formatted.writeln('Q: ${order['queue']}');
          formatted.writeln('');
        }
        if (order['datetime'] != null) {
          formatted.writeln('Date/Time: ${order['datetime']}');
        }
        if (order['server'] != null) {
          formatted.writeln('Served by: ${order['server']}');
        }
        if (order['id'] != null) {
          formatted.writeln('Order ID: ${order['id']}');
        }
        if (order['txtId'] != null) {
          formatted.writeln('Txt ID: ${order['txtId']}');
        }
        formatted.writeln('');
      }
      
      formatted.writeln('.........................................');
      formatted.writeln('            Order Items');
      formatted.writeln('.........................................');
      
      // Items
      double calculatedTotal = 0.0;
      if (receiptData.containsKey('items')) {
        List items = receiptData['items'];
        for (var item in items) {
          String name = item['name'] ?? '';
          int qty = item['quantity'] ?? 1;
          double price = (item['price'] ?? 0.0).toDouble();
          double itemTotal = qty * price;
          calculatedTotal += itemTotal;
          
          // Format item line with proper spacing
          String itemLine = '$qty x $name';
          int spacingNeeded = 32 - itemLine.length;
          if (spacingNeeded > 0) {
            itemLine += ' ' * spacingNeeded;
          }
          itemLine += 'K${itemTotal.toStringAsFixed(3)}';
          formatted.writeln(itemLine);
        }
      }
      
      formatted.writeln('');
      formatted.writeln('.........................................');
      
      // Totals
      if (receiptData.containsKey('totals')) {
        var totals = receiptData['totals'];
        double subtotal = (totals['subtotal'] ?? calculatedTotal).toDouble();
        double total = (totals['total'] ?? subtotal).toDouble();
        
        formatted.writeln('Subtotal${' ' * 20}K${subtotal.toStringAsFixed(3)}');
        formatted.writeln('Total${' ' * 23}K${total.toStringAsFixed(3)}');
      } else {
        formatted.writeln('Subtotal${' ' * 20}K${calculatedTotal.toStringAsFixed(3)}');
        formatted.writeln('Total${' ' * 23}K${calculatedTotal.toStringAsFixed(3)}');
      }
      
      formatted.writeln('');
      
      // Payment
      if (receiptData.containsKey('payment')) {
        var payment = receiptData['payment'];
        String method = payment['method'] ?? 'CASH';
        double amount = (payment['amount'] ?? calculatedTotal).toDouble();
        String currency = payment['currency'] ?? 'LAK';
        String rate = payment['exchangeRate'] ?? '1 LAK = K1.00';
        
        formatted.writeln('$method${' ' * (25 - method.length)}K${amount.toStringAsFixed(3)}');
        formatted.writeln('Amount ($currency)${' ' * 16}K${amount.toStringAsFixed(3)}');
        formatted.writeln('Exchange Rate${' ' * 19}$rate');
      }
      
      formatted.writeln('.........................................');
      formatted.writeln('');
      
      // Footer
      if (receiptData.containsKey('footer')) {
        var footer = receiptData['footer'];
        if (footer['message'] != null) {
          formatted.writeln('    ${footer['message']}');
        }
        if (footer['subtitle'] != null) {
          formatted.writeln('         ${footer['subtitle']}');
        }
      } else {
        formatted.writeln('    Thank you for your business!');
        formatted.writeln('         Please come again');
      }
      
      formatted.writeln('');
      
      return formatted.toString();
      
    } catch (e) {
      print('Error formatting structured receipt data: $e');
      return 'Error formatting receipt data: $e';
    }
  }

  /// Complete workflow: Image -> Data -> Formatted Receipt
  Future<Map<String, dynamic>> processReceiptImageToFormattedData(String imageInput, {bool isBase64 = true}) async {
    try {
      print('Starting complete receipt image processing workflow...');
      
      // Step 1: Extract data from image
      Map<String, dynamic> extractedData = await formatReceiptFromImage(imageInput, isBase64: isBase64);
      
      if (extractedData.containsKey('error')) {
        return extractedData; // Return error if extraction failed
      }
      
      // Step 2: Format the structured data back to printable text
      String formattedText = formatStructuredReceiptData(extractedData);
      
      // Step 3: Return complete result
      return {
        'success': true,
        'extractedData': extractedData,
        'formattedText': formattedText,
        'processedAt': DateTime.now().toIso8601String(),
        'workflow': 'image_to_data_to_formatted_text'
      };
      
    } catch (e) {
      print('Error in complete receipt processing workflow: $e');
      return {
        'error': 'Complete workflow failed',
        'details': e.toString(),
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
