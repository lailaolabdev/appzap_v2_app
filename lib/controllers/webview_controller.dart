import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import '../services/printer_service.dart';

class WebViewController extends GetxController {
  InAppWebViewController? webViewController;
  final printerService = Get.find<PrinterService>();

  // Observable variables
  final isLoading = true.obs;
  final currentUrl = ''.obs;
  final progress = 0.0.obs;
  final canGoBack = false.obs;
  final canGoForward = false.obs;

  // Initial URL
  final String initialUrl = 'https://appzap-v2.appzap.la/';

  @override
  void onInit() {
    super.onInit();
    print('WebViewController initialized');
  }

  /// Called when WebView is created
  void onWebViewCreated(InAppWebViewController controller) {
    webViewController = controller;

    // Add JavaScript handlers for printing
    _addJavaScriptHandlers();

    print('WebView created and JavaScript handlers added');
  }

  /// Add JavaScript handlers for communication with web page
  void _addJavaScriptHandlers() {
    // Handler for printing images
    webViewController?.addJavaScriptHandler(
      handlerName: 'printImage',
      callback: (arguments) async {
        try {
          if (arguments.isNotEmpty) {
            final base64Image = arguments[0] as String;
            final success = await printerService.printImageFromBase64(
              base64Image,
            );

            return {
              "status": success ? "success" : "error",
              "message": success
                  ? "Image printed successfully"
                  : "Failed to print image",
              "timestamp": DateTime.now().toIso8601String(),
            };
          }
          return {"status": "error", "message": "No image data provided"};
        } catch (e) {
          return {"status": "error", "message": e.toString()};
        }
      },
    );

    // Handler for printing receipts with image and text
    webViewController?.addJavaScriptHandler(
      handlerName: 'printReceipt',
      callback: (arguments) async {
        try {
          if (arguments.isNotEmpty) {
            final data = arguments[0] as Map<String, dynamic>;

            log('Received receipt data: ${data.toString()}');

            // Optional: Validate the data structure
            if (data.containsKey('receiptData') || data.containsKey('order')) {
              log("Valid receipt data structure detected");
            } else {
              log("Warning: Unexpected receipt data structure");
            }

            // Use the new JSON-based printing method with parsed data
            // final success = await printerService.printReceiptFromJson(
            //   receiptData: data,
            // );

            log("LOGO9999: ${data['restaurantInfo']?['logo']}");

            // final success = await printerService.printData(receiptData: data);
            final success = await printerService.printBillReceipt(receiptData: data);

            return {
              "status": success ? "success" : "error",
              "message": success
                  ? "Receipt printed successfully"
                  : "Failed to print receipt",
              "timestamp": DateTime.now().toIso8601String(),
            };
          }
          return {
            "status": "error",
            "message": "No receipt data provided",
            "timestamp": DateTime.now().toIso8601String(),
          };
        } catch (e) {
          log('Error in printReceipt handler: $e');
          return {
            "status": "error",
            "message": "Print handler error: ${e.toString()}",
            "timestamp": DateTime.now().toIso8601String(),
          };
        }
      },
    ); // Handler for getting printer status
    webViewController?.addJavaScriptHandler(
      handlerName: 'getPrinterStatus',
      callback: (arguments) async {
        try {
          final status = await printerService.getPrinterStatus();
          return {"status": "success", "data": status};
        } catch (e) {
          return {"status": "error", "message": e.toString()};
        }
      },
    );

    // Handler for printing QR codes
    webViewController?.addJavaScriptHandler(
      handlerName: 'printQRCode',
      callback: (arguments) async {
        try {
          if (arguments.isNotEmpty) {
            final data = arguments[0] as String;
            final size = arguments.length > 1 ? arguments[1] as int : 8;

            await printerService.printQRCode(data, size: size);

            return {
              "status": "success",
              "message": "QR code printed successfully",
              "timestamp": DateTime.now().toIso8601String(),
            };
          }
          return {"status": "error", "message": "No QR data provided"};
        } catch (e) {
          return {"status": "error", "message": e.toString()};
        }
      },
    );

    // Handler for testing printer
    webViewController?.addJavaScriptHandler(
      handlerName: 'testPrinter',
      callback: (arguments) async {
        try {
          final success = await printerService.testPrinter();

          return {
            "status": success ? "success" : "error",
            "message": success
                ? "Printer test completed successfully"
                : "Printer test failed",
            "timestamp": DateTime.now().toIso8601String(),
          };
        } catch (e) {
          return {"status": "error", "message": e.toString()};
        }
      },
    );

    // Handler for testing printer with mock receipt
    webViewController?.addJavaScriptHandler(
      handlerName: 'testMockReceipt',
      callback: (arguments) async {
        try {
          final success = await printerService.testPrinterWithMockReceipt();

          return {
            "status": success ? "success" : "error",
            "message": success
                ? "Mock receipt printed successfully"
                : "Mock receipt print failed",
            "timestamp": DateTime.now().toIso8601String(),
            "data": {
              "receiptType": "Mock MuK Coffee Receipt",
              "items": ["1x Espresso K30.000", "1x Flat White K20.000"],
              "total": "K50.000",
            },
          };
        } catch (e) {
          return {"status": "error", "message": e.toString()};
        }
      },
    );

    // Handler for printing logo with custom size
    webViewController?.addJavaScriptHandler(
      handlerName: 'printLogo',
      callback: (arguments) async {
        try {
          // Extract width and height from arguments if provided
          int? width;
          int? height;

          if (arguments.isNotEmpty && arguments[0] is Map) {
            final Map<String, dynamic> params = Map<String, dynamic>.from(
              arguments[0],
            );
            width = params['width'] as int?;
            height = params['height'] as int?;
          }

          final success = await printerService.printLogoImage(
            width: width ?? 200, // Default to 200px if not specified
            height: height ?? 200, // Default to 200px if not specified
          );

          return {
            "status": success ? "success" : "error",
            "message": success
                ? "Logo printed successfully (${width ?? 200}x${height ?? 200})"
                : "Failed to print logo",
            "timestamp": DateTime.now().toIso8601String(),
          };
        } catch (e) {
          return {"status": "error", "message": e.toString()};
        }
      },
    );
  }

  /// Handle page loading progress
  void onProgressChanged(int progress) {
    this.progress.value = progress / 100.0;
  }

  /// Handle page load start
  void onLoadStart(WebUri? url) {
    isLoading.value = true;
    currentUrl.value = url?.toString() ?? '';
  }

  /// Handle page load stop
  void onLoadStop(WebUri? url) {
    isLoading.value = false;
    currentUrl.value = url?.toString() ?? '';
    _updateNavigationState();
  }

  /// Update navigation state (back/forward buttons)
  void _updateNavigationState() async {
    if (webViewController != null) {
      canGoBack.value = await webViewController!.canGoBack();
      canGoForward.value = await webViewController!.canGoForward();
    }
  }

  /// Navigate back
  void goBack() {
    webViewController?.goBack();
  }

  /// Navigate forward
  void goForward() {
    webViewController?.goForward();
  }

  /// Reload page
  void reload() {
    webViewController?.reload();
  }

  /// Execute JavaScript in the web page
  Future<dynamic> executeJavaScript(String code) async {
    return await webViewController?.evaluateJavascript(source: code);
  }

  /// Handle WebView errors
  void onWebViewError(WebResourceError error, WebResourceRequest request) {
    // Log error for debugging
    log('WebView Error Handled: ${error.description}');
    log('Error Type: ${error.type}');
    log('Failing URL: ${request.url}');
    
    // Update loading state
    isLoading.value = false;
    
    // Determine error type and show appropriate user message
    String userMessage = _getUserFriendlyErrorMessage(error);
    
    // Show error message with retry option for network errors
    if (_isNetworkError(error)) {
      Get.snackbar(
        'Connection Error',
        userMessage,
        duration: Duration(seconds: 10),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.8),
        colorText: Get.theme.colorScheme.onError,
        mainButton: TextButton(
          onPressed: () {
            Get.back(); // Close snackbar
            reload(); // Retry loading
          },
          child: Text(
            'Retry',
            style: TextStyle(color: Get.theme.colorScheme.onError),
          ),
        ),
      );
    } else {
      // Show general error message
      Get.snackbar(
        'Error',
        userMessage,
        duration: Duration(seconds: 8),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.8),
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }
  
  /// Get user-friendly error message based on error type
  String _getUserFriendlyErrorMessage(WebResourceError error) {
    final errorCode = error.type.toString();
    
    if (errorCode.contains('HOST_LOOKUP') || errorCode.contains('NAME_NOT_RESOLVED')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    } else if (errorCode.contains('CONNECT') || errorCode.contains('CONNECTION')) {
      return 'Connection failed. The server might be temporarily unavailable.';
    } else if (errorCode.contains('TIMEOUT')) {
      return 'Request timed out. The server is taking too long to respond.';
    } else if (errorCode.contains('AUTHENTICATION') || errorCode.contains('AUTH')) {
      return 'Authentication required. Please check your credentials.';
    } else if (errorCode.contains('FILE_NOT_FOUND') || errorCode.contains('404')) {
      return 'The requested page was not found.';
    } else if (errorCode.contains('TOO_MANY_REQUESTS') || errorCode.contains('429')) {
      return 'Too many requests. Please wait a moment and try again.';
    } else {
      return 'An error occurred while loading the page: ${error.description}';
    }
  }
  
  /// Check if the error is a network-related error that can be retried
  bool _isNetworkError(WebResourceError error) {
    final errorCode = error.type.toString();
    return errorCode.contains('HOST_LOOKUP') ||
           errorCode.contains('NAME_NOT_RESOLVED') ||
           errorCode.contains('CONNECT') ||
           errorCode.contains('CONNECTION') ||
           errorCode.contains('TIMEOUT');
  }

  /// Show JavaScript communication example
  void showJavaScriptExample() {
    Get.snackbar(
      'JavaScript Communication',
      'Web page can call:\n'
          '• window.flutter_inappwebview.callHandler("printImage", base64Image)\n'
          '• window.flutter_inappwebview.callHandler("printReceipt", {image: base64, text: "Receipt text"})\n'
          '• window.flutter_inappwebview.callHandler("getPrinterStatus")\n'
          '• window.flutter_inappwebview.callHandler("testPrinter")',
      duration: Duration(seconds: 5),
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
