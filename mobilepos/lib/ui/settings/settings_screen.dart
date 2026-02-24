import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/pos_provider.dart';
import '../layout/pos_layout.dart';
import '../widgets/app_toast.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch settings on load
    Future.microtask(() => ref.read(settingsProvider.notifier).fetchSettings());
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
                                // 2. Show Toast
                                AppToast.show(
                                  context,
                                  'Alert: Test Order Notification #000',
                                  type: ToastType.info,
                                  duration: const Duration(seconds: 5),
                                );
                              },
                              icon: const Icon(LucideIcons.bellRing, size: 16),
                              label: const Text('Test Notification (UI Only)'),
                            ),
                          ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
