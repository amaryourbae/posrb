import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../services/dio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/hive_service.dart';

class SettingsState {
  final bool isLoading;
  final bool taxEnabled;
  final bool serviceChargeEnabled;
  final bool soundEnabled;
  final List<BluetoothDevice> devices;
  final BluetoothDevice? connectedDevice;
  final bool isScanning;
  final bool isPrinting;
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
    state = state.copyWith(soundEnabled: sound);
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
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier(ref.watch(dioProvider));
  },
);
