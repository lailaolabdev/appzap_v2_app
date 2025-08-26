import 'package:get/get.dart';
import '../services/printer_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize services
    Get.put<PrinterService>(PrinterService(), permanent: true);

    // Controllers will be initialized when needed
    // Get.lazyPut<WebViewController>(() => WebViewController());
  }
}
