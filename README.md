# AppZap V2 WebView App

A Flutter WebView application designed for Sunmi V2 devices with integrated printing capabilities.

## Features

- **WebView Integration**: Loads and displays web content from https://appzap-v2.appzap.la/
- **Sunmi Printer Support**: Native printing capabilities for Sunmi V2 devices
- **Base64 Image Printing**: Receives base64 images from web and prints them as receipts
- **MVC Architecture**: Clean separation of concerns using Model-View-Controller pattern
- **GetX State Management**: Reactive state management for smooth user experience

## Architecture

### MVC Structure
- **Models** (`lib/models/`): Data models for print requests and web messages
- **Views** (`lib/views/`): UI components and screens
- **Controllers** (`lib/controllers/`): Business logic and state management
- **Services** (`lib/services/`): External service integrations (printer)
- **Utils** (`lib/utils/`): Utility classes and bindings

### Key Components

1. **WebViewController**: Manages WebView interactions and JavaScript communication
2. **PrinterService**: Handles Sunmi printer operations and base64 image printing
3. **WebViewScreen**: Main UI with WebView and navigation controls

## Dependencies

- `flutter_inappwebview: ^6.1.5` - WebView implementation
- `sunmi_printer_plus: ^4.1.0` - Sunmi printer integration
- `get: ^4.6.6` - State management
- `permission_handler: ^11.3.1` - Permission handling

## Usage

### JavaScript Interface

The app exposes a JavaScript interface to the web page:

```javascript
// Print a base64 image
window.nativeApp.print(base64ImageString, "Optional Title");

// Check printer status
window.nativeApp.checkPrinterStatus();

// Test print functionality
window.nativeApp.testPrint();

// Send custom messages
window.nativeApp.sendMessage("messageType", { data: "value" });
```

### Web Integration

Your web application can communicate with the native app using the provided JavaScript interface:

```javascript
// Wait for native app to be ready
window.onNativeAppReady = function() {
    console.log("Native app is ready!");
    
    // Now you can use the native functions
    window.nativeApp.checkPrinterStatus();
};

// Listen for responses from native app
window.receiveNativeMessage = function(message) {
    console.log("Received from native:", message);
    
    if (message.type === 'printResult') {
        if (message.success) {
            console.log("Print successful!");
        } else {
            console.log("Print failed:", message.error);
        }
    }
};

// Example: Print an image
function printReceipt(imageBase64) {
    if (window.nativeApp) {
        window.nativeApp.print(imageBase64, "Receipt");
    }
}
```

## Setup and Installation

1. **Clone the repository**
2. **Install dependencies**: `flutter pub get`
3. **Run on Sunmi device**: `flutter run`

## Sunmi V2 Device Setup

1. Ensure the device has the Sunmi printer service installed
2. The app will automatically detect and connect to the built-in printer
3. Use the "Test Print" option in the app menu to verify printer functionality

## Permissions

The app requires the following permissions on Android:
- Internet access for WebView
- Bluetooth permissions for printer communication
- Storage permissions for image processing

## Troubleshooting

### Printer Issues
- Check if the Sunmi printer service is running
- Use "Printer Status" from the app menu to diagnose issues
- Try "Test Print" to verify basic functionality

### WebView Issues
- Ensure internet connectivity
- Check if the target URL is accessible
- Clear app data if WebView becomes unresponsive

## Development

### Adding New Features
1. Create models in `lib/models/`
2. Add business logic to controllers in `lib/controllers/`
3. Create UI components in `lib/views/`
4. Register dependencies in `lib/utils/app_bindings.dart`

### JavaScript Communication
- Add new handlers in `WebViewController._setupJavaScriptHandlers()`
- Update the injected JavaScript in `WebViewController._injectJavaScript()`
- Handle messages in `WebViewController._handleWebViewMessage()`

## License

This project is licensed under the MIT License.
