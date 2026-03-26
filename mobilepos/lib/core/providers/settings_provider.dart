import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../services/dio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/hive_service.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/product_helper.dart';

class SettingsState {
  final bool isLoading;
  final bool taxEnabled;
  final bool serviceChargeEnabled;
  final bool soundEnabled;
  final List<BluetoothDevice> devices;
  final BluetoothDevice? connectedDevice;
  final bool isScanning;
  final bool isPrinting;
  final bool autoPrintEnabled;
  final String? error;

  SettingsState({
    this.isLoading = false,
    this.taxEnabled = false,
    this.serviceChargeEnabled = false,
    this.soundEnabled = true,
    this.devices = const [],
    this.connectedDevice,
    this.isScanning = false,
    this.isPrinting = false,
    this.autoPrintEnabled = false,
    this.error,
  });

  SettingsState copyWith({
    bool? isLoading,
    bool? taxEnabled,
    bool? serviceChargeEnabled,
    bool? soundEnabled,
    List<BluetoothDevice>? devices,
    BluetoothDevice? connectedDevice,
    bool? isScanning,
    bool? isPrinting,
    bool? autoPrintEnabled,
    String? error,
    bool clearDevice = false,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      serviceChargeEnabled: serviceChargeEnabled ?? this.serviceChargeEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      devices: devices ?? this.devices,
      connectedDevice: clearDevice
          ? null
          : (connectedDevice ?? this.connectedDevice),
      isScanning: isScanning ?? this.isScanning,
      isPrinting: isPrinting ?? this.isPrinting,
      autoPrintEnabled: autoPrintEnabled ?? this.autoPrintEnabled,
      error: error,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Dio _dio;
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  SettingsNotifier(this._dio) : super(SettingsState()) {
    fetchSettings();
    _loadLocalSettings();
    if (!kIsWeb) {
      _initBluetooth();
    }
  }

  void _loadLocalSettings() {
    final sound = HiveService.getSoundEnabled();
    final autoPrint = HiveService.getAutoPrintEnabled();
    state = state.copyWith(soundEnabled: sound, autoPrintEnabled: autoPrint);
  }

  void _initBluetooth() {
    _bluetooth.onStateChanged().listen((btState) {
      if (btState == BlueThermalPrinter.CONNECTED) {
        // Handle connected
      } else if (btState == BlueThermalPrinter.DISCONNECTED) {
        // Handle disconnected
        super.state = state.copyWith(clearDevice: true);
      }
    });

    // Check if connected
    _bluetooth.isConnected.then((isConnected) {
      if (isConnected == true) {}
    });
  }

  Future<void> fetchSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/public/settings');
      var data = response.data;

      // Unwrap
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }

      if (data is Map) {
        final taxRate =
            double.tryParse(data['tax_rate']?.toString() ?? '0') ?? 0;
        final serviceRate =
            double.tryParse(data['service_charge_rate']?.toString() ?? '0') ??
            0;

        state = state.copyWith(
          isLoading: false,
          taxEnabled: taxRate > 0,
          serviceChargeEnabled: serviceRate > 0,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load settings',
      );
    }
  }

  Future<void> updateSettings({
    required bool taxEnabled,
    required bool serviceChargeEnabled,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // API expects key-value updates? Vue sends loop.
      // We can send multiple requests.

      final taxVal = taxEnabled ? '10' : '0';
      final serviceVal = serviceChargeEnabled ? '5' : '0';

      // Update Settings (Send as direct keys)
      await _dio.post(
        '/admin/settings',
        data: {'tax_rate': taxVal, 'service_charge_rate': serviceVal},
      );

      state = state.copyWith(
        isLoading: false,
        taxEnabled: taxEnabled,
        serviceChargeEnabled: serviceChargeEnabled,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      fetchSettings(); // Revert
    }
  }

  Future<void> toggleSound(bool enabled) async {
    await HiveService.setSoundEnabled(enabled);
    state = state.copyWith(soundEnabled: enabled);
  }

  Future<void> toggleAutoPrint(bool enabled) async {
    await HiveService.setAutoPrintEnabled(enabled);
    state = state.copyWith(autoPrintEnabled: enabled);
  }

  // Bluetooth Actions
  Future<void> scanDevices() async {
    if (kIsWeb) return;

    state = state.copyWith(isScanning: true, error: null);
    try {
      // Request permissions first (Android 12+)
      if (await Permission.bluetoothScan.request().isGranted &&
          await Permission.bluetoothConnect.request().isGranted &&
          await Permission.location.request().isGranted) {
        List<BluetoothDevice> devices = [];
        try {
          devices = await _bluetooth.getBondedDevices();
        } catch (e) {
          // Ignore
        }

        state = state.copyWith(isScanning: false, devices: devices);
      } else {
        state = state.copyWith(
          isScanning: false,
          error: 'Bluetooth permissions denied',
        );
      }
    } catch (e) {
      state = state.copyWith(isScanning: false, error: e.toString());
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    if (kIsWeb) return;

    state = state.copyWith(isLoading: true);
    try {
      bool? isConnected = await _bluetooth.isConnected;
      if (isConnected == true) {
        await _bluetooth.disconnect();
      }

      await _bluetooth.connect(device);
      state = state.copyWith(isLoading: false, connectedDevice: device);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to connect: $e');
    }
  }

  Future<void> disconnect() async {
    if (kIsWeb) return;
    try {
      await _bluetooth.disconnect();
      state = state.copyWith(clearDevice: true);
    } catch (e) {
      // check
    }
  }

  Future<void> testPrint() async {
    if (kIsWeb || state.connectedDevice == null) return;

    state = state.copyWith(isPrinting: true);
    try {
      bool? isConnected = await _bluetooth.isConnected;
      if (isConnected != true) {
        await _bluetooth.connect(state.connectedDevice!);
      }

      _bluetooth.printCustom("TEST PRINT", 3, 1);
      _bluetooth.printNewLine();
      _bluetooth.printCustom("Connected to:", 1, 0);
      _bluetooth.printCustom(state.connectedDevice?.name ?? "Printer", 1, 0);
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.paperCut();
    } catch (e) {
      state = state.copyWith(error: 'Print failed: $e');
    } finally {
      state = state.copyWith(isPrinting: false);
    }
  }

  Future<void> printImage(Uint8List bytes) async {
    if (kIsWeb || state.connectedDevice == null) return;

    state = state.copyWith(isPrinting: true);
    try {
      bool? isConnected = await _bluetooth.isConnected;
      if (isConnected != true) {
        await _bluetooth.connect(state.connectedDevice!);
      }

      await _bluetooth.printImageBytes(bytes);
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.paperCut();
    } catch (e) {
      state = state.copyWith(error: 'Print Image failed: $e');
    } finally {
      state = state.copyWith(isPrinting: false);
    }
  }

  Future<void> printReceipt(
    Map<String, dynamic> order,
    Map<String, dynamic>? settings, {
    Uint8List? screenshot,
  }) async {
    if (kIsWeb || state.connectedDevice == null) return;

    if (screenshot != null) {
      return printImage(screenshot);
    }

    state = state.copyWith(isPrinting: true);
    try {
      bool? isConnected = await _bluetooth.isConnected;
      if (isConnected != true) {
        await _bluetooth.connect(state.connectedDevice!);
      }

      final storeName = settings?['store_name'] ?? 'POS System';
      final storeAddress = settings?['store_address'] ?? '';
      final storePhone = settings?['store_phone'] ?? '';
      final storeLogo = settings?['store_logo'] ?? '';

      _bluetooth.printNewLine();

      // Logo printing
      if (storeLogo.isNotEmpty) {
        await _printLogo(storeLogo);
      } else {
        _bluetooth.printCustom(storeName, 2, 1);
      }
      
      if (storeAddress.isNotEmpty) _bluetooth.printCustom(storeAddress, 1, 1);
      if (storePhone.isNotEmpty) _bluetooth.printCustom(storePhone, 1, 1);
      _bluetooth.printNewLine();

      _bluetooth.printCustom("RECEIPT", 1, 1);
      _bluetooth.printCustom(order['order_number'] ?? 'Order', 1, 1);

      final dateStr = order['created_at'] ?? DateTime.now().toIso8601String();
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();
      final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

      _bluetooth.printCustom(formattedDate, 1, 1);
      _bluetooth.printCustom(
        "Customer: ${order['customer_name'] ?? 'Guest'}",
        1,
        1,
      );
      _bluetooth.printNewLine();

      final formatCurrency = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );

      final items = order['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        String name = item['product_name'] ?? item['name'] ?? 'Item';
        String qty = (item['quantity'] ?? 1).toString();
        // Fallback for sub_total or price
        double total = 0.0;
        if (item['total_price'] != null) {
          total = double.tryParse(item['total_price'].toString()) ?? 0.0;
        } else if (item['price'] != null) {
          total =
              (double.tryParse(item['price'].toString()) ?? 0.0) *
              (item['quantity'] ?? 1);
        }

        // For 58mm (32 chars), we need careful spacing
        String line = "$qty x $name";
        // Manual wrapping for non-screenshot path
        if (line.length > 20) {
           line = "${line.substring(0, 17)}...";
        }
        
        _bluetooth.printLeftRight(
          line,
          formatCurrency.format(total),
          0,
        );

        // Print modifiers if available
        final modifiers = item['modifiers'] as List<dynamic>? ?? [];
        for (var mod in modifiers) {
          String modName = mod['option_name'] ?? '';
          if (modName.isNotEmpty) {
            _bluetooth.printCustom("  - $modName", 0, 0);
          }
        }
      }

      _bluetooth.printNewLine();
      _bluetooth.printLeftRight(
        "Subtotal:",
        formatCurrency.format(order['subtotal'] ?? 0),
        1,
      );
      if ((order['tax_amount'] ?? 0) > 0) {
        _bluetooth.printLeftRight(
          "Tax:",
          formatCurrency.format(order['tax_amount'] ?? 0),
          0,
        );
      }
      _bluetooth.printNewLine();
      _bluetooth.printLeftRight(
        "TOTAL:",
        formatCurrency.format(order['grand_total'] ?? 0),
        1, // This is usually bold if supported
      );
      _bluetooth.printNewLine();

      if (order['payment_method'] != null &&
          order['payment_method'] != 'pending') {
        _bluetooth.printLeftRight(
          "Payment (${order['payment_method']}):",
          formatCurrency.format(
            order['amount_paid'] ?? order['grand_total'] ?? 0,
          ),
          0,
        );
        _bluetooth.printLeftRight(
          "Change:",
          formatCurrency.format(order['change'] ?? 0),
          0,
        );
      }

      _bluetooth.printNewLine();
      _bluetooth.printCustom("Thank you for your visit!", 1, 1);
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();

      _bluetooth.paperCut();
    } catch (e) {
      state = state.copyWith(error: 'Print Receipt failed: $e');
    } finally {
      state = state.copyWith(isPrinting: false);
    }
  }

  Future<void> printOrderTicket(
    Map<String, dynamic> order, {
    bool isAdditional = false,
    Uint8List? screenshot,
  }) async {
    if (kIsWeb || state.connectedDevice == null) return;

    if (screenshot != null) {
      return printImage(screenshot);
    }

    state = state.copyWith(isPrinting: true);
    try {
      bool? isConnected = await _bluetooth.isConnected;
      if (isConnected != true) {
        await _bluetooth.connect(state.connectedDevice!);
      }

      _bluetooth.printNewLine();

      if (isAdditional) {
        _bluetooth.printCustom("ADDITIONAL ORDER", 1, 1);
      } else {
        _bluetooth.printCustom("NEW ORDER", 2, 1);
      }

      _bluetooth.printNewLine();
      _bluetooth.printCustom(
        order['order_number'] ?? 'Order',
        2,
        1,
      ); // Large and Bold ID
      _bluetooth.printNewLine();

      final dateStr = order['created_at'] ?? DateTime.now().toIso8601String();
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();
      final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

      _bluetooth.printCustom("Date: $formattedDate", 1, 0);
      _bluetooth.printCustom(
        "Customer: ${order['customer_name'] ?? 'Guest'}",
        1,
        0,
      );
      
      _bluetooth.printNewLine();
      // Centered Bold Order Type Banner
      final orderType = (order['order_type'] ?? 'Takeaway')
          .toString()
          .replaceAll('_', ' ')
          .toUpperCase();
      _bluetooth.printCustom("--------------------------------", 1, 1);
      _bluetooth.printCustom(orderType, 2, 1);
      _bluetooth.printCustom("--------------------------------", 1, 1);
      _bluetooth.printNewLine();

      final items = order['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        final mods = item['modifiers'] as List<dynamic>? ?? [];
        String name = ProductHelper.getFormattedProductName(
          item['product_name'] ?? item['name'] ?? 'Item',
          mods,
        );
        String qty = (item['quantity'] ?? 1).toString();

        String line = "$qty x $name";
        _bluetooth.printCustom(line, 1, 0); 

        // Print visible modifiers
        final visibleMods = ProductHelper.getVisibleModifiers(mods);
        for (var mod in visibleMods) {
          String modName = ProductHelper.getModifierDisplayName(mod);
          if (modName.isNotEmpty) {
            _bluetooth.printCustom("  - $modName", 1, 0);
          }
        }
        _bluetooth.printNewLine();
      }

      _bluetooth.printCustom("--------------------------------", 1, 1);
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();

      _bluetooth.paperCut();
    } catch (e) {
      state = state.copyWith(error: 'Print Order Ticket failed: $e');
    } finally {
      state = state.copyWith(isPrinting: false);
    }
  }

  Future<void> _printLogo(String logoPath) async {
    try {
      final baseUrl = AppConfig.baseUrl; // e.g. http://192.168.1.5
      final fullUrl = logoPath.startsWith('http')
          ? logoPath
          : "$baseUrl${logoPath.startsWith('/') ? '' : '/'}$logoPath";

      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        Uint8List bytes = response.bodyBytes;
        // The blue_thermal_printer has printImageBytes
        // or we might need to convert it. 
        // Some versions use printImage(path) only.
        // Let's try printImageBytes if available or write to temp file.
        // Based on transaction_detail_sheet.dart, printImageBytes exists.
        await _bluetooth.printImageBytes(bytes);
      }
    } catch (e) {
      debugPrint('Logo Print Error: $e');
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier(ref.watch(dioProvider));
  },
);
