import 'package:appzap_v2_app/views/bluetooth_connect.dart';
import 'package:appzap_v2_app/controllers/bluetooth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import '../controllers/webview_controller.dart';

class WebViewScreen extends StatelessWidget {
  const WebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WebViewController());
    final bluetoothController = Get.put(BluetoothController());

    return Scaffold(

      floatingActionButton: Obx(() {
        // Determine icon and color based on connection status
        IconData icon;
        Color? backgroundColor;

        if (bluetoothController.isConnecting.value) {
          icon = Icons.bluetooth_searching;
          backgroundColor = Colors.orange;
        } else if (bluetoothController.isConnected) {
          icon = Icons.bluetooth_connected;
          backgroundColor = Colors.green;
        } else {
          icon = Icons.bluetooth;
          backgroundColor = null; // Default theme color
        }

        return FloatingActionButton(
          onPressed: () {
            Get.to(() => PrintingWidget());
          },
          backgroundColor: backgroundColor,
          child: Icon(icon),
        );
      }),
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
    );
  }
}
