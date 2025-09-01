import 'dart:convert';
import 'dart:developer';
import '../models/print_models.dart';

class ReceiptFormatter {
  static const int _receiptWidth = 32; // Standard thermal printer width
  static const String _dotLine = '................................';

  // Sunmi POS specific formatting constants
  static const int _sunmiLineSpacing = 1;

  /// Helper method to safely convert numeric values to double
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Format receipt data from JSON structure to printable text
  static String formatReceiptFromJson(Map<String, dynamic> receiptData) {
    try {
      // Handle both data structures: with or without receiptData wrapper
      Map<String, dynamic>? order;
      Map<String, dynamic>? restaurantInfo;

      if (receiptData.containsKey('receiptData')) {
        // Data is wrapped in receiptData object (like receipt.json)
        order = receiptData['receiptData']?['order'];
        restaurantInfo = receiptData['receiptData']?['restaurantInfo'];
      } else if (receiptData.containsKey('order')) {
        // Data structure has order at root level
        order = receiptData['order'];
        restaurantInfo = receiptData['restaurantInfo'];
      } else {
        // Assume the entire data is the order object
        order = receiptData;
        restaurantInfo = null;
      }

      if (order == null) {
        throw Exception('Order data not found in receipt');
      }

      StringBuffer receipt = StringBuffer();

      // Header - Restaurant Info
      _addHeader(receipt, restaurantInfo);

      // Order Information
      _addOrderInfo(receipt, order);

      // Line Items
      _addLineItems(receipt, order['lineItems'] ?? []);

      // Pricing Summary
      _addPricingSummary(receipt, order['pricing']);

      // Payment Information
      _addPaymentInfo(receipt, order['paymentInfo'], order['transaction']);

      // Footer
      _addFooter(receipt);

      return receipt.toString();
    } catch (e) {
      print('Error formatting receipt: $e');
      return 'Error formatting receipt: $e';
    }
  }

  /// Add restaurant header information
  static void _addHeader(
    StringBuffer receipt,
    Map<String, dynamic>? restaurantInfo,
  ) {
    receipt.writeln();
    receipt.writeln(_centerText('MuK COFFEE'));
    receipt.writeln(_centerText('ร้านกาแฟเมืองเก่า'));

    if (restaurantInfo?['contactInfo']?['phone'] != null) {
      receipt.writeln(_centerText(restaurantInfo!['contactInfo']['phone']));
    }

    receipt.writeln();
    receipt.writeln(_centerText('APPZAP V2 PROD'));
    receipt.writeln(_centerText('*ทดสอบใช้งานระบบ*'));
    receipt.writeln();
  }

  /// Add order information section
  static void _addOrderInfo(StringBuffer receipt, Map<String, dynamic> order) {
    // Queue number
    if (order['qNumber'] != null) {
      receipt.writeln('Q: ${order['qNumber']}');
      receipt.writeln();
    }

    // Order type (takeaway, dine-in, etc.)
    if (order['orderType'] != null) {
      receipt.writeln(
        'Order Type: ${order['orderType'].toString().toUpperCase()}',
      );
    }

    // Format date/time
    if (order['timing']?['orderedAt'] != null) {
      final dateTime = DateTime.parse(order['timing']['orderedAt']);
      final formattedDate =
          '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      receipt.writeln('Date/Time: $formattedDate');
    }

    // Server information
    if (order['staff']?['server']?['name'] != null) {
      receipt.writeln('Served by: ${order['staff']['server']['name']}');
    }

    // Customer information
    if (order['customer']?['name'] != null &&
        order['customer']['name'] != 'Walk-in Customer') {
      receipt.writeln('Customer: ${order['customer']['name']}');
      if (order['customer']?['phone'] != null &&
          order['customer']['phone'] != '000-000-0000') {
        receipt.writeln('Phone: ${order['customer']['phone']}');
      }
    }

    // Order ID (shortened for receipt)
    if (order['orderId'] != null) {
      final orderId = order['orderId'].toString();
      final shortOrderId = orderId.length > 12
          ? orderId.substring(orderId.length - 12)
          : orderId;
      receipt.writeln('Order ID: $shortOrderId');
    }

    // Order number if different from order ID
    if (order['orderNumber'] != null &&
        order['orderNumber'] != order['orderId']) {
      receipt.writeln('Order #: ${order['orderNumber']}');
    }

    // Transaction ID (shortened for receipt)
    if (order['transaction']?['transactionId'] != null) {
      final txnId = order['transaction']['transactionId'].toString();
      final shortTxnId = txnId.length > 12
          ? txnId.substring(txnId.length - 12)
          : txnId;
      receipt.writeln('Txt ID: $shortTxnId');
    }

    receipt.writeln();
  }

  /// Add line items section
  static void _addLineItems(StringBuffer receipt, List<dynamic> lineItems) {
    receipt.writeln(_dotLine);
    receipt.writeln(_centerText('Order Items'));
    receipt.writeln(_dotLine);

    for (var item in lineItems) {
      final name = item['name'] ?? 'Unknown Item';
      final quantity = item['quantity'] ?? 1;
      final unitPrice = _toDouble(item['unitPrice']?['amount']);
      final lineTotal = _toDouble(item['lineTotal']?['amount']);
      final currency = item['lineTotal']?['currency'] ?? 'LAK';

      // Main item line
      final itemLine = '$quantity x $name';
      final priceText = _formatCurrency(lineTotal, currency);
      receipt.writeln(_formatItemLine(itemLine, priceText));

      // Show unit price if different from line total (for quantities > 1)
      if (quantity > 1) {
        final unitPriceText =
            '   @ ${_formatCurrency(unitPrice, currency)} each';
        receipt.writeln(unitPriceText);
      }

      // Add options/modifiers if present
      if (item['options'] != null && item['options'].isNotEmpty) {
        for (var option in item['options']) {
          final optionName = option['name'] ?? '';
          final optionPrice = _toDouble(option['price']?['amount']);
          if (optionName.isNotEmpty) {
            String optionLine = '   + $optionName';
            if (optionPrice > 0) {
              optionLine += ' ${_formatCurrency(optionPrice, currency)}';
            }
            receipt.writeln(optionLine);
          }
        }
      }

      // Add promotion info if applied
      if (item['promotionApplied'] == true &&
          item['promotionDiscount']?['amount'] != null) {
        final discountAmount = _toDouble(item['promotionDiscount']['amount']);
        if (discountAmount > 0) {
          receipt.writeln(
            '   Discount: -${_formatCurrency(discountAmount, currency)}',
          );
        }
      }
    }

    receipt.writeln();
  }

  /// Add pricing summary section
  static void _addPricingSummary(
    StringBuffer receipt,
    Map<String, dynamic>? pricing,
  ) {
    if (pricing == null) return;

    receipt.writeln(_dotLine);

    // Line items total
    if (pricing['lineItemsTotal'] != null) {
      final lineItemsTotal = _toDouble(pricing['lineItemsTotal']['amount']);
      final currency = pricing['lineItemsTotal']['currency'] ?? 'LAK';
      receipt.writeln(
        _formatSummaryLine(
          'Items Total',
          _formatCurrency(lineItemsTotal, currency),
        ),
      );
    }

    // Subtotal (before taxes and fees)
    if (pricing['subtotal'] != null) {
      final subtotal = _toDouble(pricing['subtotal']['amount']);
      final currency = pricing['subtotal']['currency'] ?? 'LAK';
      receipt.writeln(
        _formatSummaryLine('Subtotal', _formatCurrency(subtotal, currency)),
      );
    }

    // Discounts
    if (pricing['totalDiscount'] != null &&
        _toDouble(pricing['totalDiscount']['amount']) > 0) {
      final discount = _toDouble(pricing['totalDiscount']['amount']);
      final currency = pricing['totalDiscount']['currency'] ?? 'LAK';
      receipt.writeln(
        _formatSummaryLine(
          'Discount',
          '-${_formatCurrency(discount, currency)}',
        ),
      );
    }

    // Taxes with details
    if (pricing['modifiers']?['taxes'] != null) {
      for (var tax in pricing['modifiers']['taxes']) {
        final taxName = tax['name'] ?? 'Tax';
        final taxRate = tax['rate'] ?? 0;
        final taxAmount = _toDouble(tax['taxAmount']?['amount']);
        final currency = tax['taxAmount']?['currency'] ?? 'LAK';
        final isInclusive = tax['isInclusive'] ?? false;

        String taxLabel = '$taxName';
        if (taxRate > 0) {
          taxLabel += ' ($taxRate%)';
        }
        if (isInclusive) {
          taxLabel += ' (inc)';
        }

        receipt.writeln(
          _formatSummaryLine(taxLabel, _formatCurrency(taxAmount, currency)),
        );
      }
    }

    // Fees
    if (pricing['modifiers']?['fees'] != null) {
      for (var fee in pricing['modifiers']['fees']) {
        final feeName = fee['name'] ?? 'Fee';
        final feeRate = fee['rate'] ?? 0;
        final feeAmount = _toDouble(fee['feeAmount']?['amount']);
        final currency = fee['feeAmount']?['currency'] ?? 'LAK';

        String feeLabel = feeName;
        if (feeRate > 0) {
          feeLabel += ' ($feeRate%)';
        }

        receipt.writeln(
          _formatSummaryLine(feeLabel, _formatCurrency(feeAmount, currency)),
        );
      }
    }

    // Tips
    if (pricing['totalTip'] != null &&
        _toDouble(pricing['totalTip']['amount']) > 0) {
      final tip = _toDouble(pricing['totalTip']['amount']);
      final currency = pricing['totalTip']['currency'] ?? 'LAK';
      receipt.writeln(
        _formatSummaryLine('Tip', _formatCurrency(tip, currency)),
      );
    }

    receipt.writeln(_dotLine);

    // Total Due
    if (pricing['totalDue'] != null) {
      final total = _toDouble(pricing['totalDue']['amount']);
      final currency = pricing['totalDue']['currency'] ?? 'LAK';
      receipt.writeln(
        _formatSummaryLine('TOTAL', _formatCurrency(total, currency)),
      );
    }

    receipt.writeln();
  }

  /// Add payment information section
  static void _addPaymentInfo(
    StringBuffer receipt,
    Map<String, dynamic>? paymentInfo,
    Map<String, dynamic>? transaction,
  ) {
    receipt.writeln(_dotLine);
    receipt.writeln(_centerText('Payment Details'));
    receipt.writeln(_dotLine);

    // Payment status
    if (paymentInfo?['paymentStatus'] != null) {
      String status = paymentInfo!['paymentStatus'].toString().toUpperCase();
      receipt.writeln('Status: $status');
    }

    // Process each payment method
    if (transaction?['payments'] != null &&
        transaction!['payments'].isNotEmpty) {
      for (var payment in transaction['payments']) {
        final method = _formatPaymentMethod(payment['method'] ?? 'CASH');
        final amount = _toDouble(payment['customerAmount']?['amount']);
        final currency = payment['customerAmount']?['currency'] ?? 'LAK';
        final tenderedAmount =
            _toDouble(payment['tenderedAmount']?['amount']) != 0
            ? _toDouble(payment['tenderedAmount']?['amount'])
            : amount;
        final changeGiven = _toDouble(payment['changeGiven']?['amount']);

        receipt.writeln(
          _formatSummaryLine(method, _formatCurrency(amount, currency)),
        );

        // Show tendered amount and change if different
        if (tenderedAmount != amount || changeGiven > 0) {
          receipt.writeln(
            _formatSummaryLine(
              'Tendered',
              _formatCurrency(tenderedAmount, currency),
            ),
          );
          if (changeGiven > 0) {
            receipt.writeln(
              _formatSummaryLine(
                'Change',
                _formatCurrency(changeGiven, currency),
              ),
            );
          }
        }

        // Payment timing
        if (payment['completedAt'] != null) {
          final completedAt = DateTime.parse(payment['completedAt']);
          final timeStr =
              '${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')}';
          receipt.writeln('Paid at: $timeStr');
        }
      }
    }

    // Payment summary
    if (transaction?['paymentSummary'] != null) {
      final summary = transaction!['paymentSummary'];

      if (summary['balance']?['amount'] != null) {
        final balance = _toDouble(summary['balance']['amount']);
        final currency = summary['balance']['currency'] ?? 'LAK';

        if (balance > 0) {
          receipt.writeln(
            _formatSummaryLine(
              'Balance Due',
              _formatCurrency(balance, currency),
            ),
          );
        } else if (balance == 0) {
          receipt.writeln('Payment: COMPLETE');
        }
      }
    }

    // Exchange rate info for LAK
    if (transaction?['payments'] != null &&
        transaction!['payments'].isNotEmpty) {
      final firstPayment = transaction['payments'][0];
      final currency = firstPayment['customerAmount']?['currency'] ?? 'LAK';
      if (currency == 'LAK') {
        receipt.writeln();
        receipt.writeln('Exchange Rate: 1 LAK = K1.00');
      }
    }

    receipt.writeln(_dotLine);
    receipt.writeln();
  }

  /// Add footer section
  static void _addFooter(StringBuffer receipt) {
    receipt.writeln(_centerText('Thank you for your business!'));
    receipt.writeln(_centerText('Please come again'));
    receipt.writeln();

    // Add timestamp
    final now = DateTime.now();
    final timestamp =
        '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    receipt.writeln(_centerText('Printed: $timestamp'));
    receipt.writeln();
  }

  /// Helper method to center text
  static String _centerText(String text) {
    if (text.length >= _receiptWidth) return text;
    final padding = (_receiptWidth - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  /// Helper method to format item lines with proper spacing
  static String _formatItemLine(String itemText, String priceText) {
    final maxItemLength = _receiptWidth - priceText.length;
    String truncatedItem = itemText.length > maxItemLength
        ? itemText.substring(0, maxItemLength - 3) + '...'
        : itemText;

    final spacingNeeded =
        _receiptWidth - truncatedItem.length - priceText.length;
    return truncatedItem + ' ' * spacingNeeded + priceText;
  }

  /// Helper method to format summary lines
  static String _formatSummaryLine(String label, String value) {
    final spacingNeeded = _receiptWidth - label.length - value.length;
    return label + ' ' * spacingNeeded + value;
  }

  /// Helper method to format currency
  static String _formatCurrency(double amount, String currency) {
    if (currency == 'LAK') {
      return 'K${amount.toStringAsFixed(3)}';
    }
    return '$currency${amount.toStringAsFixed(2)}';
  }

  /// Helper method to format payment method names
  static String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'bank_transfer':
        return 'BANK_TRANSFER';
      case 'cash':
        return 'CASH';
      case 'card':
        return 'CARD';
      default:
        return method.toUpperCase();
    }
  }

  /// Create a PrintRequest object from receipt data
  static PrintRequest createPrintRequest(
    Map<String, dynamic> receiptData, {
    bool cutPaper = true,
  }) {
    final formattedText = formatReceiptFromJson(receiptData);

    return PrintRequest(
      text: formattedText,
      cutPaper: cutPaper,
      settings: PrintSettings(
        fontSize: 12,
        alignment: PrintAlignment.left,
        lineSpacing: 1,
      ),
    );
  }

  /// Create optimized print settings for Sunmi POS printers
  static PrintSettings createSunmiPrintSettings({
    int fontSize = 12,
    bool bold = false,
    bool underline = false,
    PrintAlignment alignment = PrintAlignment.left,
  }) {
    return PrintSettings(
      fontSize: fontSize,
      bold: bold,
      underline: underline,
      alignment: alignment,
      lineSpacing: _sunmiLineSpacing,
    );
  }

  /// Format receipt specifically for Sunmi POS with enhanced formatting
  /// Following the exact structure from receipt.json
  static String formatReceiptForSunmi(Map<String, dynamic> receiptData) {
    try {
      // Handle both data structures: with or without receiptData wrapper
      Map<String, dynamic>? order;
      Map<String, dynamic>? restaurantInfo;
      Map<String, dynamic>? transaction;

      if (receiptData.containsKey('receiptData')) {
        // Data is wrapped in receiptData object (like receipt.json)
        order = receiptData['receiptData']?['order'];
        restaurantInfo = receiptData['restaurantInfo'];
        transaction = receiptData['receiptData']?['transaction'];
      } else {
        // Data structure has order at root level
        order = receiptData['order'] ?? receiptData;
        restaurantInfo = receiptData['restaurantInfo'];
        transaction = receiptData['transaction'];
      }

      if (order == null) {
        throw Exception('Order data not found in receipt');
      }

      StringBuffer receipt = StringBuffer();

      // Business Header - Following the exact format from receipt image
      receipt.writeln();
      receipt.writeln(_centerText(restaurantInfo?['name'] ?? 'MuK COFFEE'));
      receipt.writeln(
        _centerText(restaurantInfo?['slogan'] ?? 'ຮ້ານກາແຟອົງການ'),
      );

      // Phone number
      final phone = restaurantInfo?['contactInfo']?['phone'] ?? '0205107679';
      receipt.writeln(_centerText(phone));
      receipt.writeln();

      // System information (commented in the original receipt)
      // receipt.writeln(_centerText('APPZAP V2 PROD'));
      // receipt.writeln(_centerText('*ທົດສອບໃຊ້ງານລະບົບ*'));
      // receipt.writeln(_centerText(phone));
      // receipt.writeln();

      // Queue number - exact format from receipt
      final qNumber = order['qNumber'] ?? 25;
      receipt.writeln('Q: $qNumber');
      receipt.writeln();

      // Date/Time and order information - exact format from receipt
      String dateTime;
      if (order['timing']?['orderedAt'] != null) {
        final orderDateTime = DateTime.parse(order['timing']['orderedAt']);
        dateTime =
            '${orderDateTime.day}/${orderDateTime.month}/${orderDateTime.year} ${orderDateTime.hour}:${orderDateTime.minute.toString().padLeft(2, '0')}';
      } else {
        final now = DateTime.now();
        dateTime =
            '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      }
      receipt.writeln('Date/Time: $dateTime');

      // Served by
      final serverName = order['staff']?['server']?['name'] ?? 'appzapv2';
      receipt.writeln('Served by: $serverName');

      // Order ID - using the exact format from receipt
      final orderId = order['orderId'] ?? order['orderNumber'] ?? '45000eed';
      receipt.writeln('Order ID: $orderId');

      // Transaction ID - using the exact format from receipt
      final transactionId =
          transaction?['transactionId'] ??
          order['paymentInfo']?['transactionIds']?.first ??
          'b2a4e360';
      receipt.writeln('Txt ID: $transactionId');
      receipt.writeln();

      // Order Items section with exact dots format
      receipt.writeln('.........................................');
      receipt.writeln(_centerText('Order Items'));
      receipt.writeln('.........................................');

      // Line items processing - following exact format from receipt
      double calculatedSubtotal = 0.0;
      final lineItems = order['lineItems'] ?? [];

      for (var item in lineItems) {
        final name = item['name'] ?? 'Unknown Item';
        final quantity = item['quantity'] ?? 1;
        final unitPrice = _toDouble(
          item['unitPrice']?['amount'] ?? item['lineTotal']?['amount'],
        );
        final lineTotal = quantity * unitPrice;
        final currency =
            item['lineTotal']?['currency'] ??
            item['unitPrice']?['currency'] ??
            'LAK';

        calculatedSubtotal += lineTotal;

        // Format item line - exact spacing from receipt (approx 40 chars width)
        final itemLine = '$quantity x $name';
        final priceText = _formatCurrency(lineTotal, currency);

        // Calculate spacing to align price to the right
        final spacingNeeded = 40 - itemLine.length - priceText.length;
        final spacing = spacingNeeded > 0 ? ' ' * spacingNeeded : ' ';

        receipt.writeln('$itemLine$spacing$priceText');

        // Add modifiers/options if any
        if (item['options'] != null && item['options'].isNotEmpty) {
          for (var option in item['options']) {
            final optionName = option['name'] ?? '';
            final optionPrice = _toDouble(option['price']?['amount']);
            if (optionName.isNotEmpty) {
              receipt.writeln('   + $optionName');
              if (optionPrice > 0) {
                receipt.writeln(
                  '     ${_formatCurrency(optionPrice, currency)}',
                );
              }
            }
          }
        }
      }

      receipt.writeln();
      receipt.writeln('.........................................');

      // Pricing summary - following exact format from receipt
      final pricing = order['pricing'];
      if (pricing != null) {
        // Subtotal
        final subtotal =
            _toDouble(
                  pricing['subtotal']?['amount'] ??
                      pricing['lineItemsTotal']?['amount'],
                ) !=
                0
            ? _toDouble(
                pricing['subtotal']?['amount'] ??
                    pricing['lineItemsTotal']?['amount'],
              )
            : calculatedSubtotal;
        final currency =
            pricing['subtotal']?['currency'] ?? pricing['currency'] ?? 'LAK';

        receipt.writeln(
          _formatSummaryLine('Subtotal', _formatCurrency(subtotal, currency)),
        );

        // Total
        final totalDue = _toDouble(pricing['totalDue']?['amount']);
        receipt.writeln(
          _formatSummaryLine('Total', _formatCurrency(totalDue, currency)),
        );
      }

      receipt.writeln();

      // Payment information - following exact format from receipt
      if (transaction?['payments'] != null &&
          transaction!['payments'].isNotEmpty) {
        final payment = transaction['payments'][0];
        final method = _formatPaymentMethod(
          payment['method'] ?? 'BANK_TRANSFER',
        );
        final amount = _toDouble(
          payment['customerAmount']?['amount'] ??
              payment['netAmount']?['amount'],
        );
        final currency = payment['customerAmount']?['currency'] ?? 'LAK';

        receipt.writeln(
          _formatSummaryLine(method, _formatCurrency(amount, currency)),
        );
      } else if (order['paymentInfo'] != null) {
        // Fallback to order payment info
        final paymentInfo = order['paymentInfo'];
        final method = 'BANK_TRANSFER'; // Default from receipt example
        final amount = _toDouble(paymentInfo['totalDue']?['amount']);
        final currency = paymentInfo['totalDue']?['currency'] ?? 'LAK';

        receipt.writeln(
          _formatSummaryLine(method, _formatCurrency(amount, currency)),
        );
      }

      receipt.writeln();

      // Footer - following exact format from receipt
      final footerMessage = restaurantInfo?['shortDescription'] ?? '-';
      receipt.writeln(_centerText(footerMessage));
      receipt.writeln(_centerText('ໂອກາດໝ້າເຊີນໃໝ່'));

      // Add extra spacing for paper cutting
      receipt.writeln();
      receipt.writeln();

      return receipt.toString();
    } catch (e) {
      print('Error formatting receipt for Sunmi: $e');
      log('Receipt data structure: ${receiptData.toString()}');
      return formatReceiptFromJson(
        receiptData,
      ); // Fallback to standard formatting
    }
  }
}
