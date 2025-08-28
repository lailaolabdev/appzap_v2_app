import 'dart:convert';
import '../models/print_models.dart';

class ReceiptFormatter {
  static const int _receiptWidth = 32; // Standard thermal printer width
  static const String _dotLine = '................................';
  static const String _doubleLine = '================================';
  
  // Sunmi POS specific formatting constants
  static const int _sunmiMaxWidth = 32;
  static const int _sunmiLineSpacing = 1;
  static const String _sunmiCenterPadding = '        '; // 8 spaces for centering
  
  /// Format receipt data from JSON structure to printable text
  static String formatReceiptFromJson(Map<String, dynamic> receiptData) {
    try {
      final order = receiptData['receiptData']?['order'];
      final restaurantInfo = receiptData['receiptData']?['restaurantInfo'];
      
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
  static void _addHeader(StringBuffer receipt, Map<String, dynamic>? restaurantInfo) {
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
    if (order['qNumber'] != null) {
      receipt.writeln('Q: ${order['qNumber']}');
      receipt.writeln();
    }
    
    // Format date/time
    if (order['timing']?['orderedAt'] != null) {
      final dateTime = DateTime.parse(order['timing']['orderedAt']);
      final formattedDate = '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      receipt.writeln('Date/Time: $formattedDate');
    }
    
    if (order['staff']?['server']?['name'] != null) {
      receipt.writeln('Served by: ${order['staff']['server']['name']}');
    }
    
    if (order['orderId'] != null) {
      final shortOrderId = order['orderId'].toString().length > 8 
          ? order['orderId'].toString().substring(0, 8)
          : order['orderId'].toString();
      receipt.writeln('Order ID: $shortOrderId');
    }
    
    if (order['transaction']?['transactionId'] != null) {
      final shortTxnId = order['transaction']['transactionId'].toString().length > 8
          ? order['transaction']['transactionId'].toString().substring(0, 8)
          : order['transaction']['transactionId'].toString();
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
      final unitPrice = item['unitPrice']?['amount'] ?? 0.0;
      final lineTotal = item['lineTotal']?['amount'] ?? 0.0;
      final currency = item['lineTotal']?['currency'] ?? 'LAK';
      
      // Format item line
      final itemLine = '$quantity x $name';
      final priceText = _formatCurrency(lineTotal, currency);
      
      receipt.writeln(_formatItemLine(itemLine, priceText));
    }
    
    receipt.writeln();
  }
  
  /// Add pricing summary section
  static void _addPricingSummary(StringBuffer receipt, Map<String, dynamic>? pricing) {
    if (pricing == null) return;
    
    receipt.writeln(_dotLine);
    
    // Subtotal
    if (pricing['subtotal'] != null) {
      final subtotal = pricing['subtotal']['amount'] ?? 0.0;
      final currency = pricing['subtotal']['currency'] ?? 'LAK';
      receipt.writeln(_formatSummaryLine('Subtotal', _formatCurrency(subtotal, currency)));
    }
    
    // Taxes
    if (pricing['modifiers']?['taxes'] != null) {
      for (var tax in pricing['modifiers']['taxes']) {
        final taxName = tax['name'] ?? 'Tax';
        final taxAmount = tax['taxAmount']?['amount'] ?? 0.0;
        final currency = tax['taxAmount']?['currency'] ?? 'LAK';
        receipt.writeln(_formatSummaryLine(taxName, _formatCurrency(taxAmount, currency)));
      }
    }
    
    // Fees
    if (pricing['modifiers']?['fees'] != null) {
      for (var fee in pricing['modifiers']['fees']) {
        final feeName = fee['name'] ?? 'Fee';
        final feeAmount = fee['feeAmount']?['amount'] ?? 0.0;
        final currency = fee['feeAmount']?['currency'] ?? 'LAK';
        receipt.writeln(_formatSummaryLine(feeName, _formatCurrency(feeAmount, currency)));
      }
    }
    
    // Total
    if (pricing['totalDue'] != null) {
      final total = pricing['totalDue']['amount'] ?? 0.0;
      final currency = pricing['totalDue']['currency'] ?? 'LAK';
      receipt.writeln(_formatSummaryLine('Total', _formatCurrency(total, currency)));
    }
    
    receipt.writeln();
  }
  
  /// Add payment information section
  static void _addPaymentInfo(StringBuffer receipt, Map<String, dynamic>? paymentInfo, Map<String, dynamic>? transaction) {
    if (transaction?['payments'] != null && transaction!['payments'].isNotEmpty) {
      final payment = transaction['payments'][0];
      final method = _formatPaymentMethod(payment['method'] ?? 'CASH');
      final amount = payment['customerAmount']?['amount'] ?? 0.0;
      final currency = payment['customerAmount']?['currency'] ?? 'LAK';
      
      receipt.writeln(_formatSummaryLine(method, _formatCurrency(amount, currency)));
      
      // Exchange rate info for LAK
      if (currency == 'LAK') {
        receipt.writeln('Exchange Rate${' ' * 15}1 LAK = K1.00');
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
    final timestamp = '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    receipt.writeln(_centerText('Printed: $timestamp'));
    receipt.writeln();
  }
  
  /// Helper method to center text
  static String _centerText(String text) {
    if (text.length >= _receiptWidth) return text;
    final padding = (_receiptWidth - text.length) ~/ 2;
    return ' ' * padding + text;
  }
  
  /// Helper method to repeat characters
  static String _repeatChar(String char, int count) {
    return char * count;
  }
  
  /// Helper method to format item lines with proper spacing
  static String _formatItemLine(String itemText, String priceText) {
    final maxItemLength = _receiptWidth - priceText.length;
    String truncatedItem = itemText.length > maxItemLength 
        ? itemText.substring(0, maxItemLength - 3) + '...'
        : itemText;
    
    final spacingNeeded = _receiptWidth - truncatedItem.length - priceText.length;
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
  static PrintRequest createPrintRequest(Map<String, dynamic> receiptData, {bool cutPaper = true}) {
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
  static String formatReceiptForSunmi(Map<String, dynamic> receiptData) {
    try {
      final order = receiptData['receiptData']?['order'];
      final restaurantInfo = receiptData['receiptData']?['restaurantInfo'];
      
      if (order == null) {
        throw Exception('Order data not found in receipt');
      }
      
      StringBuffer receipt = StringBuffer();
      
      // Enhanced header with better spacing for Sunmi
      receipt.writeln();
      receipt.writeln(_doubleLine);
      receipt.writeln(_centerText('MuK COFFEE'));
      receipt.writeln(_centerText('ร้านกาแฟเมืองเก่า'));
      
      if (restaurantInfo?['contactInfo']?['phone'] != null) {
        receipt.writeln(_centerText(restaurantInfo!['contactInfo']['phone']));
      }
      
      receipt.writeln(_doubleLine);
      receipt.writeln();
      receipt.writeln(_centerText('APPZAP V2 PROD'));
      receipt.writeln(_centerText('*ทดสอบใช้งานระบบ*'));
      receipt.writeln();
      
      // Order info with enhanced formatting
      if (order['qNumber'] != null) {
        receipt.writeln(_centerText('Q: ${order['qNumber']}'));
        receipt.writeln();
      }
      
      // Date/time with better formatting
      if (order['timing']?['orderedAt'] != null) {
        final dateTime = DateTime.parse(order['timing']['orderedAt']);
        final formattedDate = '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
        receipt.writeln('Date/Time: $formattedDate');
      }
      
      if (order['staff']?['server']?['name'] != null) {
        receipt.writeln('Served by: ${order['staff']['server']['name']}');
      }
      
      if (order['orderId'] != null) {
        final shortOrderId = order['orderId'].toString().length > 8 
            ? order['orderId'].toString().substring(0, 8)
            : order['orderId'].toString();
        receipt.writeln('Order ID: $shortOrderId');
      }
      
      if (order['transaction']?['transactionId'] != null) {
        final shortTxnId = order['transaction']['transactionId'].toString().length > 8
            ? order['transaction']['transactionId'].toString().substring(0, 8)
            : order['transaction']['transactionId'].toString();
        receipt.writeln('Txt ID: $shortTxnId');
      }
      
      receipt.writeln();
      receipt.writeln(_doubleLine);
      receipt.writeln(_centerText('ORDER ITEMS'));
      receipt.writeln(_doubleLine);
      
      // Enhanced line items formatting
      final lineItems = order['lineItems'] ?? [];
      for (var item in lineItems) {
        final name = item['name'] ?? 'Unknown Item';
        final quantity = item['quantity'] ?? 1;
        final lineTotal = item['lineTotal']?['amount'] ?? 0.0;
        final currency = item['lineTotal']?['currency'] ?? 'LAK';
        
        final itemLine = '$quantity x $name';
        final priceText = _formatCurrency(lineTotal, currency);
        
        receipt.writeln(_formatItemLine(itemLine, priceText));
      }
      
      receipt.writeln();
      receipt.writeln(_doubleLine);
      
      // Enhanced pricing summary
      final pricing = order['pricing'];
      if (pricing != null) {
        if (pricing['subtotal'] != null) {
          final subtotal = pricing['subtotal']['amount'] ?? 0.0;
          final currency = pricing['subtotal']['currency'] ?? 'LAK';
          receipt.writeln(_formatSummaryLine('Subtotal', _formatCurrency(subtotal, currency)));
        }
        
        if (pricing['totalDue'] != null) {
          final total = pricing['totalDue']['amount'] ?? 0.0;
          final currency = pricing['totalDue']['currency'] ?? 'LAK';
          receipt.writeln(_formatSummaryLine('TOTAL', _formatCurrency(total, currency)));
        }
      }
      
      receipt.writeln();
      receipt.writeln(_doubleLine);
      
      // Enhanced payment info
      final transaction = order['transaction'];
      if (transaction?['payments'] != null && transaction!['payments'].isNotEmpty) {
        final payment = transaction['payments'][0];
        final method = _formatPaymentMethod(payment['method'] ?? 'CASH');
        final amount = payment['customerAmount']?['amount'] ?? 0.0;
        final currency = payment['customerAmount']?['currency'] ?? 'LAK';
        
        receipt.writeln(_formatSummaryLine(method, _formatCurrency(amount, currency)));
        
        if (currency == 'LAK') {
          receipt.writeln('Exchange Rate: 1 LAK = K1.00');
        }
      }
      
      receipt.writeln(_doubleLine);
      receipt.writeln();
      receipt.writeln(_centerText('Thank you for your business!'));
      receipt.writeln(_centerText('Please come again'));
      receipt.writeln();
      
      // Enhanced footer with timestamp
      final now = DateTime.now();
      final timestamp = '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      receipt.writeln(_centerText('Printed: $timestamp'));
      receipt.writeln();
      receipt.writeln(_doubleLine);
      receipt.writeln();
      
      return receipt.toString();
    } catch (e) {
      print('Error formatting receipt for Sunmi: $e');
      return formatReceiptFromJson(receiptData); // Fallback to standard formatting
    }
  }
}