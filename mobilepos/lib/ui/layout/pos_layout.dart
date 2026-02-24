import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/pos_provider.dart';
import '../../core/utils/app_date_formatter.dart';
import '../../core/services/dio_service.dart';
import 'pos_sidebar.dart';
import '../modals/pending_bills_modal.dart';
import '../modals/shift_modal.dart';
import '../../core/providers/settings_provider.dart';
import '../widgets/manager_pin_dialog.dart';
import '../widgets/app_toast.dart';
import '../modals/shift_summary_modal.dart';
import '../../core/providers/echo_provider.dart';
import '../../core/services/notification_service.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class PosLayout extends ConsumerStatefulWidget {
  final Widget child;

  const PosLayout({super.key, required this.child});

  @override
  ConsumerState<PosLayout> createState() => _PosLayoutState();
}

class _PosLayoutState extends ConsumerState<PosLayout> {
  bool _sidebarOpen = false;
  bool _userDropdownOpen = false;

  bool _isLoggingOut = false;
  bool _shiftLoading = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posProvider.notifier).fetchPendingCount();
      _initEcho();
    });
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      ref.read(posProvider.notifier).fetchPendingCount();
    });
  }

  void _initEcho() {
    final echo = ref.read(echoServiceProvider);
    echo.init();
    echo.listenToOrders((data) {
      if (!mounted) return;

      // Refresh pending count
      ref.read(posProvider.notifier).fetchPendingCount();

      // Show System Notification (Local)
      NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'New Order Received!',
        body:
            'Order #${data['order']['order_number'] ?? 'N/A'} is waiting for you.',
        payload: data['order']['id']?.toString(),
      );

      // Play Sound if enabled (In-App)
      final soundEnabled = ref.read(settingsProvider).soundEnabled;
      if (soundEnabled && !kIsWeb) {
        FlutterRingtonePlayer().playNotification();
      }

      // Show Toast
      final orderNumber = data['order']['order_number'] ?? 'New Order';
      AppToast.show(
        context,
        'Alert: New Order Received #$orderNumber',
        type: ToastType.info,
        duration: const Duration(seconds: 5),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // ref.read(echoServiceProvider).disconnect(); // Optional, depending on lifecycle
    super.dispose();
  }

  Future<void> _handleCancelBill(Map<String, dynamic> bill) async {
    // 1. Close Pending Bills Modal
    ref.read(posProvider.notifier).togglePendingBills(false);

    // 2. Wait for the widget tree to rebuild after modal closes
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    // 3. Ask for Manager PIN
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const ManagerPinDialog(),
    );

    if (pin == null || pin.isEmpty) {
      return;
    }

    // 3. Send Cancel Request
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/admin/orders/${bill['id']}/cancel',
        data: {
          'manager_pin': pin,
          'reason': 'Cancelled from POS', // Optional info
        },
      );
      ref.read(posProvider.notifier).fetchPendingCount();

      if (!mounted) return;
      AppToast.show(
        context,
        'Order cancelled successfully',
        type: ToastType.success,
      );

      ref.read(posProvider.notifier).togglePendingBills(false);
    } catch (e) {
      if (!mounted) return;
      // Extract error message
      String message = 'Failed to cancel order';
      if (e.toString().contains('403')) {
        message = 'Invalid Manager PIN';
      } else if (e.toString().contains('422')) {
        message = 'Validation Error: Check PIN';
      }

      AppToast.show(context, message, type: ToastType.error);
    }
  }

  void _handleLogout() {
    setState(() {
      _sidebarOpen = false;
      _userDropdownOpen = false;
    });

    final posState = ref.read(posProvider);
    if (posState.shift != null) {
      setState(() => _isLoggingOut = true);
      ref.read(posProvider.notifier).toggleShiftModal(true, 'end');
    } else {
      ref.read(authProvider.notifier).logout();
    }
  }

  Future<void> _handleShiftSubmit(double amount, String note) async {
    setState(() => _shiftLoading = true);
    final notifier = ref.read(posProvider.notifier);
    final mode = ref.read(posProvider).shiftModalMode;

    try {
      if (mode == 'start') {
        await notifier.startShift(amount);
        if (mounted) {
          AppToast.show(
            context,
            'Shift started successfully',
            type: ToastType.success,
          );
        }
      } else {
        final closedShift = await notifier.endShift(amount, note);
        if (mounted) {
          AppToast.show(
            context,
            'Shift closed successfully',
            type: ToastType.success,
          );
        }

        if (closedShift != null && mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => ShiftSummaryModal(shift: closedShift),
          );
        }

        if (_isLoggingOut) {
          ref.read(authProvider.notifier).logout();
          setState(() => _isLoggingOut = false);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          'Failed to update shift: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _shiftLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final posState = ref.watch(posProvider);
    final settings = authState.settings;

    final userName = authState.user?['name'] ?? 'Guest';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'G';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // bg-gray-50
      body: Stack(
        children: [
          // Main Container
          Positioned.fill(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Left: Menu Toggle + Logo
                      Row(
                        children: [
                          Builder(
                            builder: (context) {
                              final String currentPath = GoRouterState.of(
                                context,
                              ).uri.path;
                              final bool isRootOrDashboard =
                                  currentPath == '/' ||
                                  currentPath == '/dashboard';

                              if (!isRootOrDashboard) {
                                return Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        if (Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        } else {
                                          context.go('/');
                                        }
                                      },
                                      icon: const Icon(LucideIcons.arrowLeft),
                                      color: Colors.grey[600],
                                      tooltip: 'Back',
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  // Hamburger Menu
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => _sidebarOpen = true),
                                    icon: const Icon(LucideIcons.menu),
                                    color: Colors.grey[600],
                                    tooltip: 'Menu',
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              );
                            },
                          ),
                          // Logo Area
                          _buildLogoArea(settings),
                        ],
                      ),

                      const Spacer(),

                      // Right: Notifications + User
                      Row(
                        children: [
                          // DateTime Clock
                          const HeaderClockWidget(),
                          const SizedBox(width: 16),

                          // Notification Bell (Pending Bills)
                          Stack(
                            children: [
                              IconButton(
                                onPressed: () {
                                  ref
                                      .read(posProvider.notifier)
                                      .togglePendingBills(true);
                                },
                                icon: const Icon(LucideIcons.bell),
                                color: Colors.grey[400],
                                tooltip: 'Pending Bills',
                              ),
                              if (posState.pendingCount > 0)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${posState.pendingCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          Container(
                            height: 32,
                            width: 1,
                            color: Colors.grey[200],
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),

                          // User Dropdown
                          GestureDetector(
                            onTap: () => setState(
                              () => _userDropdownOpen = !_userDropdownOpen,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF5a6c37),
                                  child: Text(
                                    userInitial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  userName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Icon(
                                  LucideIcons.chevronDown,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(child: widget.child),
              ],
            ),
          ),

          // User Dropdown Menu
          if (_userDropdownOpen) ...[
            // Backdrop
            GestureDetector(
              onTap: () => setState(() => _userDropdownOpen = false),
              child: Container(color: Colors.transparent),
            ),
            // Dropdown
            Positioned(
              top: 64,
              right: 24,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          LucideIcons.logOut,
                          color: Colors.red,
                          size: 20,
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                        dense: true,
                        onTap: _handleLogout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Sidebar
          PosSidebar(
            isOpen: _sidebarOpen,
            onClose: () => setState(() => _sidebarOpen = false),
            userName: userName,
            userInitial: userInitial,
            storeLogo: settings?['store_logo'],
            storeName: settings?['store_name'] ?? 'POS System',
            onLogout: _handleLogout,
          ),

          // Pending Bills Modal
          PendingBillsModal(
            isOpen: posState.isPendingBillsOpen,
            onClose: () {
              ref.read(posProvider.notifier).togglePendingBills(false);
              ref
                  .read(posProvider.notifier)
                  .fetchPendingCount(); // Refresh count when closing
            },
            onLoad: (bill) {
              // Load bill into cart
              final notifier = ref.read(posProvider.notifier);
              notifier.loadBillToCart(bill);
              // Also close modal
              notifier.togglePendingBills(false);
            },
            onCancel: _handleCancelBill,
            onPrint: (bill) {
              AppToast.show(
                context,
                'Printing order #${bill['order_number']}...',
                type: ToastType.info,
              );
              ref.read(posProvider.notifier).fetchPendingCount();
            },
          ),

          // Global Shift Modal
          ShiftModal(
            isOpen: posState.isShiftModalOpen,
            mode: posState.shiftModalMode,
            loading: _shiftLoading,
            expectedCash:
                posState.shiftModalMode == 'end' && posState.shift != null
                ? (posState.shift!['expected_cash'] is num
                      ? (posState.shift!['expected_cash'] as num).toDouble()
                      : double.tryParse(
                          posState.shift!['expected_cash'].toString(),
                        ))
                : null,
            onClose: () {
              ref.read(posProvider.notifier).toggleShiftModal(false);
              setState(() => _isLoggingOut = false);
            },
            onSubmit: _handleShiftSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoArea(Map<String, dynamic>? settings) {
    final storeName = settings?['store_name'] ?? 'POS System';
    final nameParts = storeName.split(' ');
    final firstLine = nameParts.isNotEmpty
        ? nameParts[0].toUpperCase()
        : storeName.toUpperCase();
    final secondLine = nameParts.length > 1
        ? nameParts.sublist(1).join(' ').toUpperCase()
        : '';

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Store name first line
            Text(
              firstLine,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF5a6c37),
                height: 1.1,
              ),
            ),
            if (secondLine.isNotEmpty)
              Text(
                secondLine,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5a6c37),
                  height: 1.1,
                ),
              ),
            Text(
              'Point of Sale',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class HeaderClockWidget extends StatefulWidget {
  const HeaderClockWidget({super.key});

  @override
  State<HeaderClockWidget> createState() => _HeaderClockWidgetState();
}

class _HeaderClockWidgetState extends State<HeaderClockWidget> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now().toUtc();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now().toUtc();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Current Time
    // We pass UTC time to AppDateFormatter, which handles the +7 conversion
    final dateStr = AppDateFormatter.formatDayDate(
      _currentTime,
    ); // Saturday, 31 Jan 2026
    final timeStr = AppDateFormatter.formatTime(_currentTime); // 14:30

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          timeStr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            height: 1.1,
          ),
        ),
        Text(
          dateStr,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
