import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:appzap_v2_app/widgets/blutooth_widget.dart';

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
      final gen = Generator(PaperSize.mm58, await CapabilityProfile.load());
      final printer = BluePrint();
      printer.add(gen.qrcode('https://altospos.com'));
      printer.add(gen.text('Hello'));
      printer.add(gen.text('World', styles: const PosStyles(bold: true)));
      printer.add(gen.feed(1));

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
