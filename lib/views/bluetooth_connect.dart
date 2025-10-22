import 'package:appzap_v2_app/controllers/bluetooth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrintingWidget extends StatelessWidget {
  const PrintingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BluetoothController controller = Get.put(BluetoothController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Printers'),
        actions: [
          // Connection status indicator
          Obx(() {
            if (controller.connectedDevice.value != null) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Chip(
                    avatar: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Connected',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: Colors.green,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() {
            if (controller.isConnecting.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(
            () => IconButton(
              icon: Icon(
                controller.showAllDevices.value
                    ? Icons.filter_list_off
                    : Icons.filter_list,
              ),
              tooltip: controller.showAllDevices.value
                  ? 'Show only printers'
                  : 'Show all devices',
              onPressed: controller.toggleShowAllDevices,
            ),
          ),
          Obx(
            () => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.isScanning.value
                  ? null
                  : controller.findDevices,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter info banner
          Obx(() {
            if (controller.scanResult.isNotEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.blue.shade50,
                child: Text(
                  controller.showAllDevices.value
                      ? '📱 Showing all ${controller.scanResult.length} device(s)'
                      : '🖨️ Showing ${controller.filteredResults.length} printer(s) of ${controller.scanResult.length} device(s)',
                  style: TextStyle(color: Colors.blue.shade900),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Main content
          Expanded(
            child: Obx(() {
              // Show scanning indicator
              if (controller.isScanning.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Scanning for Bluetooth printers...'),
                      SizedBox(height: 8),
                      Text(
                        'Make sure your printer is ON and discoverable',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              // Show empty state
              if (controller.filteredResults.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        controller.showAllDevices.value
                            ? Icons.bluetooth_disabled
                            : Icons.print_disabled,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.showAllDevices.value
                            ? 'No Bluetooth devices found'
                            : 'No printers found',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      if (!controller.showAllDevices.value)
                        TextButton.icon(
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Show all devices'),
                          onPressed: controller.toggleShowAllDevices,
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Again'),
                        onPressed: controller.findDevices,
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Tips:\n• Turn ON your Bluetooth printer\n• Make sure it\'s in pairing mode\n• Stay close to the printer',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Show device list
              return ListView.separated(
                itemBuilder: (context, index) {
                  final device = controller.filteredResults[index].device;
                  print('device: ${device.platformName}');
                  final deviceName = device.platformName.isNotEmpty
                      ? device.platformName
                      : 'Unknown Device';
                  final isPrinter = controller.isPrinterDevice(deviceName);
                  final isThisDeviceConnected =
                      controller.connectedDevice.value?.remoteId ==
                      device.remoteId;

                  return ListTile(
                    leading: Icon(
                      isPrinter ? Icons.print : Icons.bluetooth,
                      color: isThisDeviceConnected
                          ? Colors.green
                          : (isPrinter ? Colors.blue : Colors.grey),
                      size: 32,
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(deviceName)),
                        if (isThisDeviceConnected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: Colors.green.shade800,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'CONNECTED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isPrinter)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'PRINTER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      device.remoteId.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isThisDeviceConnected
                        ? IconButton(
                            icon: const Icon(Icons.link_off, color: Colors.red),
                            tooltip: 'Disconnect',
                            onPressed: controller.disconnectDevice,
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: isThisDeviceConnected
                        ? null // Don't reconnect if already connected
                        : () => controller.printWithDevice(device),
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
                itemCount: controller.filteredResults.length,
              );
            }),
          ),
        ],
      ),
    );
  }
}
