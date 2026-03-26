import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/providers/history_provider.dart';
import '../../core/models/order.dart';
import '../widgets/skeleton.dart';
import 'widgets/transaction_detail_sheet.dart';
import '../layout/pos_layout.dart';
import '../../core/utils/app_date_formatter.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Order? _selectedOrder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).fetchOrders(refresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final state = ref.read(historyProvider);
        if (!state.loading && state.currentPage < state.lastPage) {
          ref.read(historyProvider.notifier).fetchOrders();
        }
      }
    });
  }

  void _onSearchChanged(String query) {
    ref.read(historyProvider.notifier).setSearch(query);
  }

  void _selectOrder(Order order) {
    setState(() => _selectedOrder = order);
  }

  void _closeDetail() {
    setState(() => _selectedOrder = null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyProvider);
    final bool showSidebar = _selectedOrder != null;
    const double sidebarWidth = 380;

    return PosLayout(
      child: Stack(
        children: [
          Row(
            children: [
              // Main List Area
              Expanded(
                child: Column(
                  children: [
                    // Header (Search & Date)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFEEEEEE)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Search Bar
                              Expanded(
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      border: InputBorder.none,
                                      hintText: 'Search orders...',
                                      prefixIcon: Icon(
                                        LucideIcons.search,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    onSubmitted: _onSearchChanged,
                                    textInputAction: TextInputAction.search,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Period Filter Chips
                              _buildPeriodChip('Hari Ini', 'today', state.periodFilter),
                              const SizedBox(width: 6),
                              _buildPeriodChip('Mingguan', 'week', state.periodFilter),
                              const SizedBox(width: 6),
                              _buildPeriodChip('Bulanan', 'month', state.periodFilter),
                              const SizedBox(width: 6),
                              _buildPeriodChip('Tahunan', 'year', state.periodFilter),
                              const SizedBox(width: 8),

                              // Date Range Navigator
                              Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // Previous Button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                        ),
                                        onTap: () => ref
                                            .read(historyProvider.notifier)
                                            .shiftPeriod(-1),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 12),
                                          child: Icon(LucideIcons.chevronLeft, size: 18, color: Colors.black87),
                                        ),
                                      ),
                                    ),
                                    
                                    // Date Label / Calendar Button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () async {
                                          final initialDate =
                                              state.startDate ?? DateTime.now();
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: initialDate,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now(),
                                            builder: (context, child) {
                                              return Theme(
                                                data: Theme.of(context).copyWith(
                                                  colorScheme:
                                                      const ColorScheme.light(
                                                        primary: Color(0xFF5a6c37),
                                                        onPrimary: Colors.white,
                                                        onSurface: Colors.black,
                                                      ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );
                                          if (picked != null) {
                                            ref
                                                .read(historyProvider.notifier)
                                                .setDateFilter(picked, picked);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Row(
                                            children: [
                                              Icon(LucideIcons.calendar, size: 14, color: Colors.grey[600]),
                                              const SizedBox(width: 6),
                                              Text(
                                                _getDateRangeLabel(state.startDate, state.endDate),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Next Button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                        onTap: () => ref
                                            .read(historyProvider.notifier)
                                            .shiftPeriod(1),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 12),
                                          child: Icon(LucideIcons.chevronRight, size: 18, color: Colors.black87),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Filters (Chips)
                    Container(
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFEEEEEE)),
                        ),
                      ),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildFilterChip('All', 'all', state.statusFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Completed',
                            'completed',
                            state.statusFilter,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Pending',
                            'pending',
                            state.statusFilter,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Cancelled',
                            'cancelled',
                            state.statusFilter,
                          ),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await ref.read(historyProvider.notifier).fetchOrders(refresh: true);
                        },
                        color: const Color(0xFF5a6c37),
                        child: state.loading && state.orders.isEmpty
                            ? _buildSkeletonList()
                            : state.orders.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    child: _buildEmptyState(),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount:
                                    state.orders.length + (state.loading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == state.orders.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final order = state.orders[index];
                                  final isSelected =
                                      _selectedOrder?.id == order.id;
                                  return _buildOrderCard(order, isSelected);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Detail Sidebar
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: showSidebar ? sidebarWidth : 0,
                child: showSidebar
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            left: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: TransactionDetailSheet(
                          order: _selectedOrder!,
                          onClose: _closeDetail,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current) {
    final isSelected = current == value;
    return Center(
      child: GestureDetector(
        onTap: () => ref.read(historyProvider.notifier).setStatusFilter(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF005c4b) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey[200]!,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF005c4b).withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value, String current) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => ref.read(historyProvider.notifier).setPeriodFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5a6c37) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5a6c37).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order, bool isSelected) {
    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    Color amountColor;

    switch (order.status.toLowerCase()) {
      case 'completed':
      case 'paid':
        statusColor = const Color(0xFF00B14F);
        statusBg = const Color(0xFFE8F5E9);
        statusIcon = LucideIcons.receipt;
        amountColor = Colors.black87;
        break;
      case 'cancelled':
        statusColor = Colors.red[600]!;
        statusBg = Colors.red[50]!;
        statusIcon = LucideIcons.x;
        amountColor = Colors.grey;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange[600]!;
        statusBg = Colors.orange[50]!;
        statusIcon = LucideIcons.clock;
        amountColor = Colors.black87;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF005c4b) : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectOrder(order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppDateFormatter.formatTime(order.createdAt)} • ${order.orderType?.replaceAll('_', ' ').toUpperCase() ?? 'DINE IN'} • ${order.customerName ?? 'Guest'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Amount & Status Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(
                        locale: 'id',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(order.totalPrice),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                        decoration: order.status == 'cancelled'
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            (order.status == 'completed'
                                    ? 'Paid'
                                    : order.status)
                                .replaceFirst(
                                  order.status[0],
                                  order.status[0].toUpperCase(),
                                ),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Skeleton.circle(size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(height: 14, borderRadius: 4),
                  const SizedBox(height: 8),
                  Skeleton(width: 120, height: 12, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Skeleton(width: 70, height: 14, borderRadius: 4),
                const SizedBox(height: 8),
                Skeleton(width: 45, height: 16, borderRadius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDateRangeLabel(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'Pilih Tanggal';
    final formatter = DateFormat('dd MMM yyyy', 'id_ID');
    final startStr = formatter.format(start);
    final endStr = formatter.format(end);
    
    if (startStr == endStr) return startStr;
    
    // If same month and year, shorten: 12 - 14 Mar 2026
    if (start.month == end.month && start.year == end.year) {
      return '${start.day} - $endStr';
    }
    
    // If same year, shorten: 28 Feb - 3 Mar 2026
    if (start.year == end.year) {
      return '${DateFormat('dd MMM').format(start)} - $endStr';
    }
    
    return '$startStr - $endStr';
  }
}

