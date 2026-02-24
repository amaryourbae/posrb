import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/dio_service.dart';
import '../../core/providers/auth_provider.dart';
import '../layout/pos_layout.dart';
import '../../core/providers/pos_provider.dart';
import '../../core/utils/app_date_formatter.dart';
import '../widgets/skeleton.dart';
import '../history/history_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {
    'today_sales': 0,
    'transaction_count': 0,
    'cash_in_drawer': 0,
    'pending_count': 0,
  };
  List<dynamic> _recentOrders = [];
  List<dynamic> _alerts = [];

  Timer? _shiftTimer;
  String _shiftDuration = '0h 0m';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _startShiftTimer();
  }

  @override
  void dispose() {
    _shiftTimer?.cancel();
    super.dispose();
  }

  void _startShiftTimer() {
    _shiftTimer?.cancel();
    _shiftTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _updateShiftDuration();
      }
    });
  }

  void _updateShiftDuration() {
    final currentShift = ref.read(posProvider).shift;
    if (currentShift == null) {
      if (_shiftDuration != '0h 0m') setState(() => _shiftDuration = '0h 0m');
      return;
    }
    try {
      final start = DateTime.parse(currentShift['start_time'].toString());
      final now = DateTime.now();
      final difference = now.difference(start);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      setState(() {
        _shiftDuration = '${hours}h ${minutes}m';
      });
    } catch (_) {
      setState(() => _shiftDuration = '0h 0m');
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);

      // Ensure current shift is up to date
      await ref.read(posProvider.notifier).fetchCurrentShift();
      final currentShift = ref.read(posProvider).shift;

      // Fetch stats
      final statsResponse = await dio.get('/admin/pos/stats');
      _stats = statsResponse.data is Map<String, dynamic>
          ? statsResponse.data
          : _stats;

      // Override cash_in_drawer with accurate backend calculation from shift if available
      if (currentShift != null) {
        _stats['cash_in_drawer'] =
            currentShift['expected_cash'] ?? currentShift['starting_cash'];
      }

      // Fetch recent orders
      // Fetch recent orders (Today only)
      final today = DateTime.now().toIso8601String().split('T')[0];
      final ordersResponse = await dio.get(
        '/admin/orders?per_page=5&start_date=$today&end_date=$today',
      );
      final ordersData = ordersResponse.data;
      if (ordersData is Map && ordersData['orders'] != null) {
        _recentOrders = ordersData['orders']['data'] ?? [];
      } else if (ordersData is List) {
        _recentOrders = ordersData;
      }

      // Fetch alerts
      try {
        final alertsResponse = await dio.get('/admin/inventory/alerts');
        _alerts = alertsResponse.data['data'] ?? [];
      } catch (_) {
        _alerts = [];
      }

      setState(() => _loading = false);
      _updateShiftDuration();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _formatCurrency(dynamic amount) {
    final value = double.tryParse(amount?.toString() ?? '0') ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('hh:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  String _formatDate() {
    return DateFormat('EEEE, MMMM d, yyyy', 'en_US').format(DateTime.now());
  }

  String _capitalize(String s) {
    if (s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PosLayout(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 1024;

              return SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 32 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    if (_loading)
                      const DashboardSkeleton()
                    else ...[
                      _buildStatsGrid(isDesktop),
                      const SizedBox(height: 32),
                      if (isDesktop) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildShiftStatusCard()),
                            const SizedBox(width: 24),
                            Expanded(child: _buildAlertsCard()),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildRecentTransactions(),
                      ] else ...[
                        _buildShiftStatusCard(),
                        const SizedBox(height: 24),
                        _buildAlertsCard(),
                        const SizedBox(height: 24),
                        _buildRecentTransactions(),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final authState = ref.watch(authProvider);
    final userName = authState.user?['name'] ?? 'Cashier';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $userName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827), // Gray 900
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280), // Gray 500
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                _fetchDashboardData();
              },
              icon: const Icon(LucideIcons.printer, size: 16),
              label: const Text('Print Report'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151), // Gray 700
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE5E7EB)), // Gray 200
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12),
            const SizedBox(width: 12),
            if (ref.watch(posProvider).shift == null)
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(posProvider.notifier)
                    .toggleShiftModal(true, 'start'),
                icon: const Icon(LucideIcons.monitor, size: 16),
                label: const Text('Open Shift'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5a6c37),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: const Color(0xFF5a6c37).withValues(alpha: 0.3),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(LucideIcons.shoppingCart, size: 16),
                label: const Text('Go to POS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5a6c37),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: const Color(0xFF5a6c37).withValues(alpha: 0.3),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1200
            ? 4
            : (constraints.maxWidth >= 768 ? 2 : 1);

        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _buildStatCardWrapper(
              title: 'Total Sales (Today)',
              value: _formatCurrency(_stats['today_sales']),
              icon: LucideIcons.dollarSign,
              bgClass: const Color(0xFFdcfce7), // Green 100
              textClass: const Color(0xFF16a34a), // Green 600
              width:
                  (constraints.maxWidth - (24 * (crossAxisCount - 1))) /
                  crossAxisCount,
            ),
            _buildStatCardWrapper(
              title: 'Transactions',
              value: '${_stats['transaction_count'] ?? 0}',
              icon: LucideIcons.shoppingBag,
              bgClass: const Color(0xFFdbeafe), // Blue 100
              textClass: const Color(0xFF2563eb), // Blue 600
              width:
                  (constraints.maxWidth - (24 * (crossAxisCount - 1))) /
                  crossAxisCount,
            ),
            _buildStatCardWrapper(
              title: 'Cash in Drawer',
              value: _formatCurrency(_stats['cash_in_drawer']),
              icon: LucideIcons.wallet,
              bgClass: const Color(0xFFf3e8ff), // Purple 100
              textClass: const Color(0xFF9333ea), // Purple 600
              width:
                  (constraints.maxWidth - (24 * (crossAxisCount - 1))) /
                  crossAxisCount,
            ),
            _buildStatCardWrapper(
              title: 'Pending Orders',
              value: '${_stats['pending_count'] ?? 0}',
              icon: LucideIcons.clock,
              bgClass: const Color(0xFFffedd5), // Orange 100
              textClass: const Color(0xFFea580c), // Orange 600
              width:
                  (constraints.maxWidth - (24 * (crossAxisCount - 1))) /
                  crossAxisCount,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCardWrapper({
    required String title,
    required String value,
    required IconData icon,
    required Color bgClass,
    required Color textClass,
    required double width,
  }) {
    // We use a SizedBox to enforce width from Wrap calculation
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF3F4F6)), // Gray 100
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280), // Gray 500
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgClass,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: textClass, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827), // Gray 900
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6)), // Gray 100
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF5a6c37),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_recentOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: Text(
                  'No transactions today',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      horizontalMargin: 24,
                      columnSpacing: 24,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF9FAFB),
                      ), // Gray 50
                      columns: const [
                        DataColumn(
                          label: Text(
                            'ORDER ID',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'CUSTOMER',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'AMOUNT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'STATUS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'TIME',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                      rows: _recentOrders.map((order) {
                        final status =
                            order['payment_status']?.toString().toLowerCase() ??
                            'pending';
                        Color badgeBg, badgeText;

                        switch (status) {
                          case 'paid':
                          case 'completed':
                            badgeBg = const Color(0xFFdcfce7);
                            badgeText = const Color(0xFF15803d);
                            break;
                          case 'pending':
                            badgeBg = const Color(0xFFffedd5);
                            badgeText = const Color(0xFFc2410c);
                            break;
                          case 'failed':
                          case 'cancelled':
                            badgeBg = const Color(0xFFfee2e2);
                            badgeText = const Color(0xFFb91c1c);
                            break;
                          default:
                            badgeBg = const Color(0xFFF3F4F6);
                            badgeText = const Color(0xFF374151);
                        }

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                order['order_number'] ?? '#',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                order['customer_name'] ?? 'Guest',
                                style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatCurrency(order['grand_total']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _capitalize(status),
                                  style: TextStyle(
                                    color: badgeText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                AppDateFormatter.formatTime(
                                  order['created_at'],
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildShiftStatusCard() {
    final posState = ref.watch(posProvider);
    final currentShift = posState.shift;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shift Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 24),

          if (currentShift != null) ...[
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFdcfce7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.clock,
                      color: Color(0xFF16a34a),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clocked In At',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatTime(currentShift['start_time']),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildShiftRow('Duration', _shiftDuration),
            _buildShiftRow(
              'Starting Cash',
              _formatCurrency(currentShift['starting_cash']),
            ),
            _buildShiftRow(
              'Cash Sales',
              '+ ${_formatCurrency(currentShift['current_cash_sales'] ?? 0)}',
              valueColor: const Color(0xFF16a34a),
              isBold: true,
            ),

            // Refunds Row - Only if > 0
            if ((double.tryParse(
                      currentShift['current_cash_refunds']?.toString() ?? '0',
                    ) ??
                    0) >
                0)
              _buildShiftRow(
                'Refunds',
                '- ${_formatCurrency(currentShift['current_cash_refunds'] ?? 0)}',
                valueColor: const Color(0xFFdc2626),
                isBold: true,
              ),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Expected Cash',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _formatCurrency(
                      currentShift['expected_cash'] ??
                          currentShift['starting_cash'],
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                '(Start + Sales - Refunds)',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => ref
                    .read(posProvider.notifier)
                    .toggleShiftModal(true, 'end'),
                icon: const Icon(LucideIcons.logOut, size: 16),
                label: const Text('Close Shift'),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.clock,
                        color: Color(0xFF9CA3AF),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No active shift',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => ref
                          .read(posProvider.notifier)
                          .toggleShiftModal(true, 'start'),
                      icon: const Icon(LucideIcons.clock, size: 16),
                      label: const Text('Start Shift Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5a6c37),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: const Color(
                          0xFF5a6c37,
                        ).withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/pos'),
                    child: const Text(
                      'Go to Register',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShiftRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF111827),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              if (_alerts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFfee2e2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_alerts.length}',
                    style: const TextStyle(
                      color: Color(0xFFb91c1c),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'No active alerts',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _alerts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFfff7ed), // Orange 50
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFffedd5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.alertTriangle,
                        size: 20,
                        color: Color(0xFFf97316),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Low Stock Warning',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF9a3412),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: alert['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' is running low. Only ',
                                  ),
                                  TextSpan(
                                    text:
                                        '${alert['current_stock']} ${alert['unit']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: ' remaining.'),
                                ],
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFea580c),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
