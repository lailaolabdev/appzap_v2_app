class PrintRequest {
  final String? base64Image;
  final String? text;
  final bool cutPaper;
  final PrintSettings? settings;

  PrintRequest({
    this.base64Image,
    this.text,
    this.cutPaper = true,
    this.settings,
  });

  factory PrintRequest.fromJson(Map<String, dynamic> json) {
    return PrintRequest(
      base64Image: json['image'] as String?,
      text: json['text'] as String?,
      cutPaper: json['cutPaper'] as bool? ?? true,
      settings: json['settings'] != null
          ? PrintSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': base64Image,
      'text': text,
      'cutPaper': cutPaper,
      'settings': settings?.toJson(),
    };
  }
}

class PrintSettings {
  final int? fontSize;
  final bool? bold;
  final bool? underline;
  final PrintAlignment? alignment;
  final int? lineSpacing;

  PrintSettings({
    this.fontSize,
    this.bold,
    this.underline,
    this.alignment,
    this.lineSpacing,
  });

  factory PrintSettings.fromJson(Map<String, dynamic> json) {
    return PrintSettings(
      fontSize: json['fontSize'] as int?,
      bold: json['bold'] as bool?,
      underline: json['underline'] as bool?,
      alignment: json['alignment'] != null
          ? PrintAlignment.values.firstWhere(
              (e) => e.name == json['alignment'],
              orElse: () => PrintAlignment.left,
            )
          : null,
      lineSpacing: json['lineSpacing'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'bold': bold,
      'underline': underline,
      'alignment': alignment?.name,
      'lineSpacing': lineSpacing,
    };
  }
}

enum PrintAlignment { left, center, right }

class PrintResponse {
  final bool success;
  final String message;
  final String timestamp;
  final Map<String, dynamic>? data;

  PrintResponse({
    required this.success,
    required this.message,
    required this.timestamp,
    this.data,
  });

  factory PrintResponse.success({String? message, Map<String, dynamic>? data}) {
    return PrintResponse(
      success: true,
      message: message ?? 'Operation completed successfully',
      timestamp: DateTime.now().toIso8601String(),
      data: data,
    );
  }

  factory PrintResponse.error({
    required String message,
    Map<String, dynamic>? data,
  }) {
    return PrintResponse(
      success: false,
      message: message,
      timestamp: DateTime.now().toIso8601String(),
      data: data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': success ? 'success' : 'error',
      'message': message,
      'timestamp': timestamp,
      if (data != null) 'data': data,
    };
  }
}

class QRCodeRequest {
  final String data;
  final int size;

  QRCodeRequest({required this.data, this.size = 8});

  factory QRCodeRequest.fromJson(Map<String, dynamic> json) {
    return QRCodeRequest(
      data: json['data'] as String,
      size: json['size'] as int? ?? 8,
    );
  }

  Map<String, dynamic> toJson() {
    return {'data': data, 'size': size};
  }
}

class BarcodeRequest {
  final String data;
  final BarcodeType type;
  final int height;
  final int width;

  BarcodeRequest({
    required this.data,
    this.type = BarcodeType.code128,
    this.height = 162,
    this.width = 2,
  });

  factory BarcodeRequest.fromJson(Map<String, dynamic> json) {
    return BarcodeRequest(
      data: json['data'] as String,
      type: BarcodeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BarcodeType.code128,
      ),
      height: json['height'] as int? ?? 162,
      width: json['width'] as int? ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {'data': data, 'type': type.name, 'height': height, 'width': width};
  }
}

enum BarcodeType { code128, code39, ean13, ean8, upca, upce }
