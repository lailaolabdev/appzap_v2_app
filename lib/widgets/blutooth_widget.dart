import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluePrint {
  BluePrint({
    this.chunkLen = 180,
  }); // Reduced from 512 to 180 to stay under 200 byte limit

  final int chunkLen;
  final _data = List<int>.empty(growable: true);

  void add(List<int> data) {
    _data.addAll(data);
  }

  List<List<int>> getChunks() {
    final chunks = List<List<int>>.empty(growable: true);
    for (var i = 0; i < _data.length; i += chunkLen) {
      chunks.add(_data.sublist(i, min(i + chunkLen, _data.length)));
    }
    return chunks;
  }

  Future<void> printData(BluetoothDevice device) async {
    print('📄 Preparing print data... ${device.platformName}');
    final data = getChunks();
    print('📦 Data chunks: ${data.length}, Total bytes: ${_data.length}');

    final characs = await _getCharacteristics(device);
    print('🔍 Found ${characs.length} characteristics');

    if (characs.isEmpty) {
      throw Exception('No characteristics found on device');
    }

    bool printed = false;
    for (var i = 0; i < characs.length; i++) {
      print(
        '🔄 Trying characteristic ${i + 1}/${characs.length}: ${characs[i].uuid}',
      );
      if (await _tryPrint(characs[i], data)) {
        print(
          '✅ Successfully printed using characteristic: ${characs[i].uuid}',
        );
        printed = true;
        break;
      }
    }

    if (!printed) {
      throw Exception('Failed to print: All characteristics failed');
    }
  }

  Future<bool> _tryPrint(
    BluetoothCharacteristic charac,
    List<List<int>> data,
  ) async {
    // Try with response first
    try {
      for (var i = 0; i < data.length; i++) {
        await charac.write(data[i], withoutResponse: false);
        print(
          '  ✓ Sent chunk ${i + 1}/${data.length} (${data[i].length} bytes)',
        );
      }
      return true;
    } catch (e) {
      print('  ✗ Failed with response: $e');

      // Try without response as fallback if characteristic supports it
      if (charac.properties.writeWithoutResponse) {
        try {
          print('  🔄 Retrying without response...');
          for (var i = 0; i < data.length; i++) {
            await charac.write(data[i], withoutResponse: true);
            print(
              '  ✓ Sent chunk ${i + 1}/${data.length} (${data[i].length} bytes) [no response]',
            );
            // Small delay to prevent overwhelming the printer
            await Future.delayed(const Duration(milliseconds: 10));
          }
          return true;
        } catch (e2) {
          print('  ✗ Failed without response: $e2');
        }
      }

      return false;
    }
  }

  Future<List<BluetoothCharacteristic>> _getCharacteristics(
    BluetoothDevice device,
  ) async {
    final services = await device.discoverServices();
    final res = List<BluetoothCharacteristic>.empty(growable: true);
    for (var i = 0; i < services.length; i++) {
      // Only add writable characteristics
      for (var charac in services[i].characteristics) {
        if (charac.properties.write || charac.properties.writeWithoutResponse) {
          res.add(charac);
          print(
            '  ➕ Found writable characteristic: ${charac.uuid} (write: ${charac.properties.write}, writeNoResp: ${charac.properties.writeWithoutResponse})',
          );
        }
      }
    }
    return res;
  }
}
