// Receipt Data Models
// Generated from receipt.json structure

class ReceiptData {
  final Order order;
  final RestaurantInfo restaurantInfo;

  ReceiptData({required this.order, required this.restaurantInfo});

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    // Handle both structures: with or without receiptData wrapper
    Map<String, dynamic> data;

    if (json.containsKey('receiptData')) {
      // Data is wrapped in receiptData object (like receipt.json)
      data = json['receiptData'];
    } else {
      // Data structure has order and restaurantInfo at root level
      data = json;
    }

    return ReceiptData(
      order: Order.fromJson(data['order']),
      restaurantInfo: RestaurantInfo.fromJson(data['restaurantInfo']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'order': order.toJson(), 'restaurantInfo': restaurantInfo.toJson()};
  }
}

class Order {
  final String orderId;
  final String orderNumber;
  final int qNumber;
  final String orderType;
  final List<LineItem> lineItems;
  final Pricing pricing;
  final Timing timing;
  final PaymentInfo paymentInfo;
  final Customer customer;
  final String orderStatus;
  final Staff staff;
  final Transaction transaction;

  Order({
    required this.orderId,
    required this.orderNumber,
    required this.qNumber,
    required this.orderType,
    required this.lineItems,
    required this.pricing,
    required this.timing,
    required this.paymentInfo,
    required this.customer,
    required this.orderStatus,
    required this.staff,
    required this.transaction,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'],
      orderNumber: json['orderNumber'],
      qNumber: json['qNumber'],
      orderType: json['orderType'],
      lineItems: (json['lineItems'] as List)
          .map((item) => LineItem.fromJson(item))
          .toList(),
      pricing: Pricing.fromJson(json['pricing']),
      timing: Timing.fromJson(json['timing']),
      paymentInfo: PaymentInfo.fromJson(json['paymentInfo']),
      customer: Customer.fromJson(json['customer']),
      orderStatus: json['orderStatus'],
      staff: Staff.fromJson(json['staff']),
      transaction: Transaction.fromJson(json['transaction']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'qNumber': qNumber,
      'orderType': orderType,
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
      'pricing': pricing.toJson(),
      'timing': timing.toJson(),
      'paymentInfo': paymentInfo.toJson(),
      'customer': customer.toJson(),
      'orderStatus': orderStatus,
      'staff': staff.toJson(),
      'transaction': transaction.toJson(),
    };
  }
}

class LineItem {
  final String lineItemId;
  final String menuItemId;
  final String name;
  final int quantity;
  final Amount unitPrice;
  final Amount lineTotal;
  final List<dynamic> options;
  final String status;
  final bool promotionApplied;
  final Amount promotionDiscount;
  final PromotionDetails promotionDetails;
  final KitchenInfo kitchenInfo;
  final Cancellation cancellation;
  final String id;
  final List<dynamic> statusHistory;

  LineItem({
    required this.lineItemId,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.options,
    required this.status,
    required this.promotionApplied,
    required this.promotionDiscount,
    required this.promotionDetails,
    required this.kitchenInfo,
    required this.cancellation,
    required this.id,
    required this.statusHistory,
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      lineItemId: json['lineItemId'],
      menuItemId: json['menuItemId'],
      name: json['name'],
      quantity: json['quantity'],
      unitPrice: Amount.fromJson(json['unitPrice']),
      lineTotal: Amount.fromJson(json['lineTotal']),
      options: json['options'] ?? [],
      status: json['status'],
      promotionApplied: json['promotionApplied'],
      promotionDiscount: Amount.fromJson(json['promotionDiscount']),
      promotionDetails: PromotionDetails.fromJson(json['promotionDetails']),
      kitchenInfo: KitchenInfo.fromJson(json['kitchenInfo']),
      cancellation: Cancellation.fromJson(json['cancellation']),
      id: json['_id'],
      statusHistory: json['statusHistory'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lineItemId': lineItemId,
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice.toJson(),
      'lineTotal': lineTotal.toJson(),
      'options': options,
      'status': status,
      'promotionApplied': promotionApplied,
      'promotionDiscount': promotionDiscount.toJson(),
      'promotionDetails': promotionDetails.toJson(),
      'kitchenInfo': kitchenInfo.toJson(),
      'cancellation': cancellation.toJson(),
      '_id': id,
      'statusHistory': statusHistory,
    };
  }
}

class Amount {
  final double amount;
  final String currency;

  Amount({required this.amount, required this.currency});

  factory Amount.fromJson(Map<String, dynamic> json) {
    return Amount(
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'currency': currency};
  }
}

class PromotionDetails {
  final dynamic originalLineTotal;
  final dynamic discountPerUnit;
  final dynamic targetedQuantity;
  final dynamic valueContribution;
  final dynamic proportionalAllocation;

  PromotionDetails({
    this.originalLineTotal,
    this.discountPerUnit,
    this.targetedQuantity,
    this.valueContribution,
    this.proportionalAllocation,
  });

  factory PromotionDetails.fromJson(Map<String, dynamic> json) {
    return PromotionDetails(
      originalLineTotal: json['originalLineTotal'],
      discountPerUnit: json['discountPerUnit'],
      targetedQuantity: json['targetedQuantity'],
      valueContribution: json['valueContribution'],
      proportionalAllocation: json['proportionalAllocation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalLineTotal': originalLineTotal,
      'discountPerUnit': discountPerUnit,
      'targetedQuantity': targetedQuantity,
      'valueContribution': valueContribution,
      'proportionalAllocation': proportionalAllocation,
    };
  }
}

class KitchenInfo {
  final String course;
  final int priority;
  final List<dynamic> allergenInfo;

  KitchenInfo({
    required this.course,
    required this.priority,
    required this.allergenInfo,
  });

  factory KitchenInfo.fromJson(Map<String, dynamic> json) {
    return KitchenInfo(
      course: json['course'],
      priority: json['priority'],
      allergenInfo: json['allergenInfo'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course': course,
      'priority': priority,
      'allergenInfo': allergenInfo,
    };
  }
}

class Cancellation {
  final bool requiresApproval;
  final bool isApproved;

  Cancellation({required this.requiresApproval, required this.isApproved});

  factory Cancellation.fromJson(Map<String, dynamic> json) {
    return Cancellation(
      requiresApproval: json['requiresApproval'],
      isApproved: json['isApproved'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'requiresApproval': requiresApproval, 'isApproved': isApproved};
  }
}

class Pricing {
  final Amount lineItemsTotal;
  final Modifiers modifiers;
  final Amount subtotal;
  final Amount totalDiscount;
  final Amount totalTax;
  final Amount totalFees;
  final Amount totalTip;
  final Amount totalDue;
  final String calculatedAt;
  final String currency;
  final double exchangeRate;

  Pricing({
    required this.lineItemsTotal,
    required this.modifiers,
    required this.subtotal,
    required this.totalDiscount,
    required this.totalTax,
    required this.totalFees,
    required this.totalTip,
    required this.totalDue,
    required this.calculatedAt,
    required this.currency,
    required this.exchangeRate,
  });

  factory Pricing.fromJson(Map<String, dynamic> json) {
    return Pricing(
      lineItemsTotal: Amount.fromJson(json['lineItemsTotal']),
      modifiers: Modifiers.fromJson(json['modifiers']),
      subtotal: Amount.fromJson(json['subtotal']),
      totalDiscount: Amount.fromJson(json['totalDiscount']),
      totalTax: Amount.fromJson(json['totalTax']),
      totalFees: Amount.fromJson(json['totalFees']),
      totalTip: Amount.fromJson(json['totalTip']),
      totalDue: Amount.fromJson(json['totalDue']),
      calculatedAt: json['calculatedAt'],
      currency: json['currency'],
      exchangeRate: (json['exchangeRate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lineItemsTotal': lineItemsTotal.toJson(),
      'modifiers': modifiers.toJson(),
      'subtotal': subtotal.toJson(),
      'totalDiscount': totalDiscount.toJson(),
      'totalTax': totalTax.toJson(),
      'totalFees': totalFees.toJson(),
      'totalTip': totalTip.toJson(),
      'totalDue': totalDue.toJson(),
      'calculatedAt': calculatedAt,
      'currency': currency,
      'exchangeRate': exchangeRate,
    };
  }
}

class Modifiers {
  final List<dynamic> discounts;
  final List<Tax> taxes;
  final List<Fee> fees;
  final List<dynamic> tips;

  Modifiers({
    required this.discounts,
    required this.taxes,
    required this.fees,
    required this.tips,
  });

  factory Modifiers.fromJson(Map<String, dynamic> json) {
    return Modifiers(
      discounts: json['discounts'] ?? [],
      taxes: (json['taxes'] as List).map((tax) => Tax.fromJson(tax)).toList(),
      fees: (json['fees'] as List).map((fee) => Fee.fromJson(fee)).toList(),
      tips: json['tips'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discounts': discounts,
      'taxes': taxes.map((tax) => tax.toJson()).toList(),
      'fees': fees.map((fee) => fee.toJson()).toList(),
      'tips': tips,
    };
  }
}

class Tax {
  final String taxId;
  final String type;
  final String name;
  final int rate;
  final String scope;
  final String calculationMethod;
  final Amount taxableAmount;
  final Amount taxAmount;
  final bool isInclusive;
  final bool isCompounded;
  final String id;

  Tax({
    required this.taxId,
    required this.type,
    required this.name,
    required this.rate,
    required this.scope,
    required this.calculationMethod,
    required this.taxableAmount,
    required this.taxAmount,
    required this.isInclusive,
    required this.isCompounded,
    required this.id,
  });

  factory Tax.fromJson(Map<String, dynamic> json) {
    return Tax(
      taxId: json['taxId'],
      type: json['type'],
      name: json['name'],
      rate: json['rate'],
      scope: json['scope'],
      calculationMethod: json['calculationMethod'],
      taxableAmount: Amount.fromJson(json['taxableAmount']),
      taxAmount: Amount.fromJson(json['taxAmount']),
      isInclusive: json['isInclusive'],
      isCompounded: json['isCompounded'],
      id: json['_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taxId': taxId,
      'type': type,
      'name': name,
      'rate': rate,
      'scope': scope,
      'calculationMethod': calculationMethod,
      'taxableAmount': taxableAmount.toJson(),
      'taxAmount': taxAmount.toJson(),
      'isInclusive': isInclusive,
      'isCompounded': isCompounded,
      '_id': id,
    };
  }
}

class Fee {
  final String feeId;
  final String type;
  final String name;
  final int rate;
  final Amount feeAmount;
  final bool isInclusive;
  final bool taxable;
  final String id;

  Fee({
    required this.feeId,
    required this.type,
    required this.name,
    required this.rate,
    required this.feeAmount,
    required this.isInclusive,
    required this.taxable,
    required this.id,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      feeId: json['feeId'],
      type: json['type'],
      name: json['name'],
      rate: json['rate'],
      feeAmount: Amount.fromJson(json['feeAmount']),
      isInclusive: json['isInclusive'],
      taxable: json['taxable'],
      id: json['_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feeId': feeId,
      'type': type,
      'name': name,
      'rate': rate,
      'feeAmount': feeAmount.toJson(),
      'isInclusive': isInclusive,
      'taxable': taxable,
      '_id': id,
    };
  }
}

class Timing {
  final String orderedAt;
  final String completedAt;

  Timing({required this.orderedAt, required this.completedAt});

  factory Timing.fromJson(Map<String, dynamic> json) {
    return Timing(
      orderedAt: json['orderedAt'],
      completedAt: json['completedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'orderedAt': orderedAt, 'completedAt': completedAt};
  }
}

class PaymentInfo {
  final bool paymentRequired;
  final String paymentStatus;
  final Amount totalDue;
  final Amount amountPaid;
  final Amount balanceDue;
  final List<String> transactionIds;
  final bool readyForPayment;

  PaymentInfo({
    required this.paymentRequired,
    required this.paymentStatus,
    required this.totalDue,
    required this.amountPaid,
    required this.balanceDue,
    required this.transactionIds,
    required this.readyForPayment,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      paymentRequired: json['paymentRequired'],
      paymentStatus: json['paymentStatus'],
      totalDue: Amount.fromJson(json['totalDue']),
      amountPaid: Amount.fromJson(json['amountPaid']),
      balanceDue: Amount.fromJson(json['balanceDue']),
      transactionIds: List<String>.from(json['transactionIds']),
      readyForPayment: json['readyForPayment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentRequired': paymentRequired,
      'paymentStatus': paymentStatus,
      'totalDue': totalDue.toJson(),
      'amountPaid': amountPaid.toJson(),
      'balanceDue': balanceDue.toJson(),
      'transactionIds': transactionIds,
      'readyForPayment': readyForPayment,
    };
  }
}

class Customer {
  final String name;
  final String phone;

  Customer({required this.name, required this.phone});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(name: json['name'], phone: json['phone']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'phone': phone};
  }
}

class Staff {
  final StaffMember createdBy;
  final StaffMember server;
  final StaffMember lastUpdatedBy;

  Staff({
    required this.createdBy,
    required this.server,
    required this.lastUpdatedBy,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      createdBy: StaffMember.fromJson(json['createdBy']),
      server: StaffMember.fromJson(json['server']),
      lastUpdatedBy: StaffMember.fromJson(json['lastUpdatedBy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdBy': createdBy.toJson(),
      'server': server.toJson(),
      'lastUpdatedBy': lastUpdatedBy.toJson(),
    };
  }
}

class StaffMember {
  final String id;
  final String name;

  StaffMember({required this.id, required this.name});

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class Transaction {
  final String transactionId;
  final String transactionStatus;
  final List<Payment> payments;
  final PaymentSummary paymentSummary;

  Transaction({
    required this.transactionId,
    required this.transactionStatus,
    required this.payments,
    required this.paymentSummary,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transactionId'],
      transactionStatus: json['transactionStatus'],
      payments: (json['payments'] as List)
          .map((payment) => Payment.fromJson(payment))
          .toList(),
      paymentSummary: PaymentSummary.fromJson(json['paymentSummary']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'transactionStatus': transactionStatus,
      'payments': payments.map((payment) => payment.toJson()).toList(),
      'paymentSummary': paymentSummary.toJson(),
    };
  }
}

class Payment {
  final String paymentId;
  final String method;
  final String status;
  final Amount customerAmount;
  final Amount tenderedAmount;
  final Amount changeGiven;
  final Amount grossAmount;
  final List<dynamic> processingFees;
  final Amount netAmount;
  final String initiatedAt;
  final String completedAt;

  Payment({
    required this.paymentId,
    required this.method,
    required this.status,
    required this.customerAmount,
    required this.tenderedAmount,
    required this.changeGiven,
    required this.grossAmount,
    required this.processingFees,
    required this.netAmount,
    required this.initiatedAt,
    required this.completedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentId: json['paymentId'],
      method: json['method'],
      status: json['status'],
      customerAmount: Amount.fromJson(json['customerAmount']),
      tenderedAmount: Amount.fromJson(json['tenderedAmount']),
      changeGiven: Amount.fromJson(json['changeGiven']),
      grossAmount: Amount.fromJson(json['grossAmount']),
      processingFees: json['processingFees'] ?? [],
      netAmount: Amount.fromJson(json['netAmount']),
      initiatedAt: json['initiatedAt'],
      completedAt: json['completedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'method': method,
      'status': status,
      'customerAmount': customerAmount.toJson(),
      'tenderedAmount': tenderedAmount.toJson(),
      'changeGiven': changeGiven.toJson(),
      'grossAmount': grossAmount.toJson(),
      'processingFees': processingFees,
      'netAmount': netAmount.toJson(),
      'initiatedAt': initiatedAt,
      'completedAt': completedAt,
    };
  }
}

class PaymentSummary {
  final Amount totalDue;
  final Amount totalPaid;
  final Amount balance;

  PaymentSummary({
    required this.totalDue,
    required this.totalPaid,
    required this.balance,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      totalDue: Amount.fromJson(json['totalDue']),
      totalPaid: Amount.fromJson(json['totalPaid']),
      balance: Amount.fromJson(json['balance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDue': totalDue.toJson(),
      'totalPaid': totalPaid.toJson(),
      'balance': balance.toJson(),
    };
  }
}

class RestaurantInfo {
  final Address address;
  final ContactInfo contactInfo;
  final PackageInfo packageInfo;
  final Settings settings;

  RestaurantInfo({
    required this.address,
    required this.contactInfo,
    required this.packageInfo,
    required this.settings,
  });

  factory RestaurantInfo.fromJson(Map<String, dynamic> json) {
    return RestaurantInfo(
      address: Address.fromJson(json['address']),
      contactInfo: ContactInfo.fromJson(json['contactInfo']),
      packageInfo: PackageInfo.fromJson(json['packageInfo']),
      settings: Settings.fromJson(json['settings']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address.toJson(),
      'contactInfo': contactInfo.toJson(),
      'packageInfo': packageInfo.toJson(),
      'settings': settings.toJson(),
    };
  }
}

class Address {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }
}

class ContactInfo {
  final String phone;

  ContactInfo({required this.phone});

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(phone: json['phone']);
  }

  Map<String, dynamic> toJson() {
    return {'phone': phone};
  }
}

class PackageInfo {
  final Features features;
  final String level;
  final String startDate;
  final String endDate;
  final bool autoRenew;
  final String paymentStatus;

  PackageInfo({
    required this.features,
    required this.level,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    required this.paymentStatus,
  });

  factory PackageInfo.fromJson(Map<String, dynamic> json) {
    return PackageInfo(
      features: Features.fromJson(json['features']),
      level: json['level'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      autoRenew: json['autoRenew'],
      paymentStatus: json['paymentStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'features': features.toJson(),
      'level': level,
      'startDate': startDate,
      'endDate': endDate,
      'autoRenew': autoRenew,
      'paymentStatus': paymentStatus,
    };
  }
}

class Features {
  final int maxBranches;
  final int maxUsers;
  final int maxProducts;
  final int maxTables;
  final int maxOrders;

  Features({
    required this.maxBranches,
    required this.maxUsers,
    required this.maxProducts,
    required this.maxTables,
    required this.maxOrders,
  });

  factory Features.fromJson(Map<String, dynamic> json) {
    return Features(
      maxBranches: json['maxBranches'],
      maxUsers: json['maxUsers'],
      maxProducts: json['maxProducts'],
      maxTables: json['maxTables'],
      maxOrders: json['maxOrders'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxBranches': maxBranches,
      'maxUsers': maxUsers,
      'maxProducts': maxProducts,
      'maxTables': maxTables,
      'maxOrders': maxOrders,
    };
  }
}

class Settings {
  final Currency currency;

  Settings({required this.currency});

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(currency: Currency.fromJson(json['currency']));
  }

  Map<String, dynamic> toJson() {
    return {'currency': currency.toJson()};
  }
}

class Currency {
  final String mainCurrency;
  final List<SupportedCurrency> supportedCurrencies;

  Currency({required this.mainCurrency, required this.supportedCurrencies});

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      mainCurrency: json['mainCurrency'],
      supportedCurrencies: (json['supportedCurrencies'] as List)
          .map((currency) => SupportedCurrency.fromJson(currency))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mainCurrency': mainCurrency,
      'supportedCurrencies': supportedCurrencies
          .map((currency) => currency.toJson())
          .toList(),
    };
  }
}

class SupportedCurrency {
  final String code;
  final String name;
  final bool isActive;

  SupportedCurrency({
    required this.code,
    required this.name,
    required this.isActive,
  });

  factory SupportedCurrency.fromJson(Map<String, dynamic> json) {
    return SupportedCurrency(
      code: json['code'],
      name: json['name'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'name': name, 'isActive': isActive};
  }
}

// Wrapper class for the entire receipt JSON structure
class Receipt {
  final ReceiptData receiptData;

  Receipt({required this.receiptData});

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(receiptData: ReceiptData.fromJson(json['receiptData']));
  }

  Map<String, dynamic> toJson() {
    return {'receiptData': receiptData.toJson()};
  }
}
