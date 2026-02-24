import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/models/shift.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/app_date_formatter.dart';
import '../../core/providers/shift_history_provider.dart';
import '../layout/pos_layout.dart';
import '../widgets/skeleton.dart';

class ShiftHistoryScreen extends ConsumerStatefulWidget {
  const ShiftHistoryScreen({super.key});

  @override
  ConsumerState<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}

class _ShiftHistoryScreenState extends ConsumerState<ShiftHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      ref
          .read(shiftHistoryProvider.notifier)
          .fetchShifts(userId: user?['id']?.toString());
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  Color _getDiffColor(double? diff) {
    if (diff == null || diff == 0) return Colors.grey;
    if (diff > 0) return Colors.green[700]!;
    return Colors.red[700]!;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shiftHistoryProvider);

    return PosLayout(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shift History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Showing your recent shifts',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
                // Could add reload button here
                IconButton(
                  onPressed: () {
                    final user = ref.read(authProvider).user;
                    ref
                        .read(shiftHistoryProvider.notifier)
                        .fetchShifts(
                          userId: user?['id']?.toString(),
                          page: state.currentPage,
                        );
                  },
                  icon: const Icon(
                    LucideIcons.refreshCw,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: state.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error loading shifts: ${state.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final user = ref.read(authProvider).user;
                            ref
                                .read(shiftHistoryProvider.notifier)
                                .fetchShifts(userId: user?['id']?.toString());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : state.isLoading && state.shifts.isEmpty
                ? const ShiftHistorySkeleton()
                : state.shifts.isEmpty
                ? _buildEmptyState()
                : _buildShiftList(state.shifts),
          ),

          // Pagination
          if (state.total > 0)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page ${state.currentPage} of ${state.lastPage}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: state.currentPage > 1
                            ? () {
                                final user = ref.read(authProvider).user;
                                ref
                                    .read(shiftHistoryProvider.notifier)
                                    .fetchShifts(
                                      userId: user?['id']?.toString(),
                                      page: state.currentPage - 1,
                                    );
                              }
                            : null,
                        icon: const Icon(LucideIcons.chevronLeft),
                      ),
                      IconButton(
                        onPressed: state.currentPage < state.lastPage
                            ? () {
                                final user = ref.read(authProvider).user;
                                ref
                                    .read(shiftHistoryProvider.notifier)
                                    .fetchShifts(
                                      userId: user?['id']?.toString(),
                                      page: state.currentPage + 1,
                                    );
                              }
                            : null,
                        icon: const Icon(LucideIcons.chevronRight),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.calendar,
              size: 32,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No shift history found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftList(List<Shift> shifts) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: shifts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final shift = shifts[index];
        final isOpen = shift.status == 'open';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppDateFormatter.formatDateFull(shift.startTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (shift.endTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.arrowRight,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppDateFormatter.formatDateFull(shift.endTime!),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen ? Colors.green[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      shift.status[0].toUpperCase() + shift.status.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isOpen ? Colors.green[700] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Starting Cash',
                      _formatCurrency(shift.startingCash),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Ending Cash',
                      shift.endingCashActual != null
                          ? _formatCurrency(shift.endingCashActual!)
                          : '-',
                      alignRight: true,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Difference',
                      shift.difference != null
                          ? _formatCurrency(shift.difference!)
                          : '-',
                      color: _getDiffColor(shift.difference),
                      alignRight: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(
    String label,
    String value, {
    Color? color,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
            fontFamily: 'monospace', // Use monospace for numbers alignment
          ),
        ),
      ],
    );
  }
}
