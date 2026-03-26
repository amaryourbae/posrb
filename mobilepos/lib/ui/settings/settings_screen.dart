import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/pos_provider.dart';
import '../../core/services/sync_service.dart';
import '../layout/pos_layout.dart';
import '../widgets/app_toast.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/update_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';
  String _buildNumber = '';
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    // Fetch settings on load
    Future.microtask(() => ref.read(settingsProvider.notifier).fetchSettings());
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);

    return PosLayout(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: const Row(
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Notifications
                  _buildSectionHeader('NOTIFICATIONS'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _buildToggleItem(
                          title: 'Notification Sound',
                          subtitle: 'Play sound when new order arrives',
                          value: state.soundEnabled,
                          onChanged: (val) {
                            ref
                                .read(settingsProvider.notifier)
                                .toggleSound(val);
                          },
                        ),
                        const Divider(height: 1),
                        _buildToggleItem(
                          title: 'Auto-print Online Orders',
                          subtitle: 'Automatically print paid orders from app',
                          value: state.autoPrintEnabled,
                          onChanged: (val) {
                            ref
                                .read(settingsProvider.notifier)
                                .toggleAutoPrint(val);
                          },
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // 1. Play Sound
                                if (state.soundEnabled && !kIsWeb) {
                                  FlutterRingtonePlayer().playNotification();
                                } else if (kIsWeb) {
                                  debugPrint("Sound skipped on Web");
                                }
                                // 2. Show Real System Notification
                                if (!kIsWeb) {
                                  NotificationService.showNotification(
                                    id:
                                        DateTime.now().millisecondsSinceEpoch ~/
                                        1000,
                                    title: 'Test Order Notification',
                                    body: 'Order #TEST-000 is waiting for you.',
                                    payload: 'test',
                                  );
                                }
                                // 3. Show Toast
                                AppToast.show(
                                  context,
                                  'Alert: Test Order Notification #000',
                                  type: ToastType.info,
                                  duration: const Duration(seconds: 5),
                                );
                              },
                              icon: const Icon(LucideIcons.bellRing, size: 16),
                              label: const Text('Test Notification'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  _buildSectionHeader('DATA SYNCHRONIZATION'),
                  const SizedBox(height: 12),

                  // Sync Offline Orders Action
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Consumer(
                          builder: (context, ref, _) {
                            final posState = ref.watch(posProvider);
                            final pendingOffline = posState.offlinePendingCount;

                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: pendingOffline > 0
                                          ? Colors.orange[50]
                                          : Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      LucideIcons.refreshCcw,
                                      color: pendingOffline > 0
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Sync Offline Orders',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          pendingOffline > 0
                                              ? '$pendingOffline orders waiting to sync'
                                              : 'All data is up to date',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: pendingOffline > 0
                                                ? Colors.orange[800]
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (pendingOffline > 0)
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (mounted) {
                                          AppToast.show(
                                            context,
                                            'Syncing offline orders...',
                                            type: ToastType.info,
                                          );
                                        }
                                        await SyncService().syncPendingOrders();
                                        if (context.mounted) {
                                          AppToast.show(
                                            context,
                                            'Sync process completed!',
                                            type: ToastType.success,
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF5a6c37,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Sync Now'),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  _buildSectionHeader('PAYMENT SETTINGS'),
                  const SizedBox(height: 12),

                  // Tax & Service
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tax Toggle
                        _buildToggleItem(
                          title: 'Tax (PPN)',
                          subtitle: 'Enable 10% tax calculation',
                          value: state.taxEnabled,
                          onChanged: (val) {
                            ref
                                .read(settingsProvider.notifier)
                                .updateSettings(
                                  taxEnabled: val,
                                  serviceChargeEnabled:
                                      state.serviceChargeEnabled,
                                );
                            // Refresh POS settings to apply changes immediately
                            ref.read(posProvider.notifier).fetchSettings();
                          },
                        ),
                        const Divider(height: 1),
                        // Service Toggle
                        _buildToggleItem(
                          title: 'Service Charge',
                          subtitle: 'Enable 5% service charge',
                          value: state.serviceChargeEnabled,
                          onChanged: (val) async {
                            await ref
                                .read(settingsProvider.notifier)
                                .updateSettings(
                                  taxEnabled: state.taxEnabled,
                                  serviceChargeEnabled: val,
                                );
                            // Refresh POS settings
                            ref.read(posProvider.notifier).fetchSettings();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (!kIsWeb) ...[
                    _buildSectionHeader('CONNECTED DEVICE'),
                    const SizedBox(height: 12),

                    // Connected Printer Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: state.connectedDevice != null
                          ? _buildConnectedDevice(state)
                          : _buildNoDevice(state),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('ADD NEW DEVICE'),
                    const SizedBox(height: 12),

                    // Scan Button / Available List
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              ref.read(settingsProvider.notifier).scanDevices();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      LucideIcons.bluetooth,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Scan for Bluetooth Printers',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'Click to search paired devices...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    LucideIcons.chevronRight,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (state.isScanning)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),

                          if (state.devices.isNotEmpty)
                            ...state.devices.map(
                              (device) => Column(
                                children: [
                                  const Divider(height: 1),
                                  ListTile(
                                    onTap: () {
                                      ref
                                          .read(settingsProvider.notifier)
                                          .connect(device);
                                    },
                                    leading: const Icon(LucideIcons.printer),
                                    title: Text(
                                      device.name ?? "Unknown Device",
                                    ),
                                    subtitle: Text(device.address ?? ""),
                                    trailing:
                                        state.isLoading &&
                                            state.connectedDevice?.address ==
                                                device.address
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ] else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Printer settings are only available on Mobile App',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                  const SizedBox(height: 48),

                  // App Version Info
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'RB POS v$_appVersion',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Build Line: $_buildNumber',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isCheckingUpdate ? null : _handleManualUpdateCheck,
                          icon: _isCheckingUpdate
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(LucideIcons.refreshCw, size: 14),
                          label: Text(_isCheckingUpdate ? 'Checking...' : 'Check for Update'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5a6c37),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final url = Uri.parse('https://instagram.com/amaryourbae');
                            if (await canopyLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              children: [
                                const TextSpan(text: 'Made with love by '),
                                TextSpan(
                                  text: '@amaryourbae',
                                  style: TextStyle(
                                    color: const Color(0xFF5a6c37),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleManualUpdateCheck() async {
    setState(() => _isCheckingUpdate = true);
    
    try {
      final updateService = UpdateService();
      final updateInfo = await updateService.checkForUpdate();
      
      if (!mounted) return;
      
      if (updateInfo != null) {
        UpdateService.showUpdateDialog(context, updateInfo, updateService);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda sudah menggunakan versi terbaru.'),
            backgroundColor: Color(0xFF5a6c37),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memeriksa update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  Future<bool> canopyLaunchUrl(Uri url) async {
    try {
      return await canLaunchUrl(url);
    } catch (e) {
      return false;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF5a6c37),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDevice(SettingsState state) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.printer, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              state.error ?? 'No printer connected',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedDevice(SettingsState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.printer, color: Colors.green[700]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.connectedDevice?.name ?? 'Unknown Printer',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(
                          LucideIcons.dot,
                          color: Colors.green,
                          size: 16,
                        ), // Pulse indicator
                        SizedBox(width: 4),
                        Text(
                          'Connected • Ready',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.read(settingsProvider.notifier).disconnect();
                },
                icon: const Icon(LucideIcons.logOut, color: Colors.grey),
                tooltip: 'Disconnect',
              ),
            ],
          ),
        ),

        // Quick Action
        Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.isPrinting
                      ? null
                      : () => ref.read(settingsProvider.notifier).testPrint(),
                  icon: state.isPrinting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.printer, size: 16),
                  label: Text(state.isPrinting ? 'Printing...' : 'Test Print'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5a6c37),
                    side: const BorderSide(color: Color(0xFF5a6c37)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
