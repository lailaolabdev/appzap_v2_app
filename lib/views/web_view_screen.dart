import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import '../controllers/webview_controller.dart';

class WebViewScreen extends StatelessWidget {
  const WebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WebViewController());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Navigation buttons
            //
            // WebView
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(controller.initialUrl),
                ),
                onWebViewCreated: (webViewController) {
                  // Use the controller's onWebViewCreated method to set up all JavaScript handlers
                  controller.onWebViewCreated(webViewController);
                },
                onProgressChanged: (webController, progress) {
                  controller.onProgressChanged(progress);
                },
                onLoadStart: (webController, url) {
                  controller.onLoadStart(url);
                },
                onLoadStop: (webController, url) {
                  controller.onLoadStop(url);
                },
                onReceivedError: (webController, request, error) {
                  print('WebView Error: ${error.description}');
                },
                onConsoleMessage: (webController, consoleMessage) {
                  print('Console: ${consoleMessage.message}');
                },
                initialSettings: InAppWebViewSettings(
                  // Enable JavaScript
                  javaScriptEnabled: true,
                  // Allow access to device features
                  mediaPlaybackRequiresUserGesture: false,
                  // Enable zoom
                  supportZoom: true,
                  builtInZoomControls: true,
                  displayZoomControls: false,
                  // Enable navigation gestures
                  allowsBackForwardNavigationGestures: true,
                  // Clear cache on start
                  clearCache: true,
                  // Enable mixed content
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  // Enable geolocation
                  geolocationEnabled: true,
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating action button for printer status
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () async {
      //     final controller = Get.find<WebViewController>();
      //     await controller.printerService.printLogoImage();
      //     // final status = await controller.printerService.getPrinterStatus();

      //     // Get.dialog(
      //     //   AlertDialog(
      //     //     title: const Text('Printer Status'),
      //     //     content: Column(
      //     //       mainAxisSize: MainAxisSize.min,
      //     //       crossAxisAlignment: CrossAxisAlignment.start,
      //     //       children: [
      //     //         Text('Connected: ${status['isConnected'] ? 'Yes' : 'No'}'),
      //     //         if (status['error'] != null)
      //     //           Text('Error: ${status['error']}'),
      //     //         Text('Last checked: ${status['timestamp']}'),
      //     //       ],
      //     //     ),
      //     //     actions: [
      //     //       TextButton(
      //     //         onPressed: () => Get.back(),
      //     //         child: const Text('Close'),
      //     //       ),
      //     //     ],
      //     //   ),
      //     // );
      //   },
      //   icon: const Icon(Icons.print),
      //   label: const Text('Printer'),
      //   backgroundColor: Colors.green,
      // ),
    );
  }
}
