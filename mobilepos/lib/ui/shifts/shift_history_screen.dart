import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/models/shift.dart';
import '../../core/models/cash_movement_item.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/app_date_formatter.dart';
import '../../core/providers/shift_history_provider.dart';
import '../layout/pos_layout.dart';
import '../widgets/skeleton.dart';
import 'widgets/shift_detail_sheet.dart';

class ShiftHistoryScreen extends ConsumerStatefulWidget {
  const ShiftHistoryScreen({super.key});

  @override
  ConsumerState<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}

class _ShiftHistoryScreenState extends ConsumerState<ShiftHistoryScreen> {
  String? _expandedShiftId;
  Shift? _selectedShift;

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
    final bool showSidebar = _selectedShift != null;
    const double sidebarWidth = 380;

    return PosLayout(
      child: Stack(
        children: [
          Row(
            children: [
              // Main List
              Expanded(
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
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
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
                      child: RefreshIndicator(
                        onRefresh: () async {
                          final user = ref.read(authProvider).user;
                          await ref
                              .read(shiftHistoryProvider.notifier)
                              .fetchShifts(userId: user?['id']?.toString());
                        },
                        color: const Color(0xFF5a6c37),
                        child: state.error != null
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    child: Center(
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
                                                  .fetchShifts(
                                                    userId: user?['id']?.toString(),
                                                  );
                                            },
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : state.isLoading && state.shifts.isEmpty
                            ? const ShiftHistorySkeleton()
                            : state.shifts.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    child: _buildEmptyState(),
                                  ),
                                ],
                              )
                            : _buildShiftList(state.shifts),
                      ),
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
                                          final user = ref
                                              .read(authProvider)
                                              .user;
                                          ref
                                              .read(
                                                shiftHistoryProvider.notifier,
                                              )
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
                                          final user = ref
                                              .read(authProvider)
                                              .user;
                                          ref
                                              .read(
                                                shiftHistoryProvider.notifier,
                                              )
                                              .fetchShifts(
                                                userId: user?['id']?.toString(),
                                                page: state.currentPage + 1,
                                              );
                                        }
                                      : null,
                                  icon: const Icon(LucideIcons.chevronRight),
                                ),
                              ], // closes inner Row children
                            ), // closes inner Row
                          ], // closes outer Row children
                        ), // closes outer Row
                      ), // closes Pagination Container
                    // Close the Expanded Column that contains the main list
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
                        child: ShiftDetailSheet(
                          shiftId: _selectedShift!.id,
                          onClose: () => setState(() => _selectedShift = null),
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: shifts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final shift = shifts[index];
        final isOpen = shift.status == 'open';
        final isExpanded = _expandedShiftId == shift.id;
        final hasMovements = shift.cashMovements.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpanded
                  ? const Color(0xFF5a6c37).withValues(alpha: 0.4)
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              Padding(
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
                                  AppDateFormatter.formatDateFull(
                                    shift.startTime,
                                  ),
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
                                      AppDateFormatter.formatDateFull(
                                        shift.endTime!,
                                      ),
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
                            shift.status[0].toUpperCase() +
                                shift.status.substring(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOpen
                                  ? Colors.green[700]
                                  : Colors.grey[700],
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

                    // Expand/Collapse button for cash movements
                    if (hasMovements) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedShiftId = isExpanded ? null : shift.id;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.arrowDownUp,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isExpanded
                                    ? 'Hide Cash Movements'
                                    : 'View Cash Movements (${shift.cashMovements.length})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isExpanded
                                    ? LucideIcons.chevronUp
                                    : LucideIcons.chevronDown,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedShift = shift;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5a6c37).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFF5a6c37,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.fileText,
                              size: 14,
                              color: const Color(0xFF5a6c37),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'View Detailed Report',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5a6c37),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Expanded cash movement details
              if (isExpanded && hasMovements)
                _buildCashMovementDetails(shift.cashMovements),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCashMovementDetails(List<CashMovementItem> movements) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'CASH MOVEMENTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...movements.map((m) => _buildMovementRow(m)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMovementRow(CashMovementItem movement) {
    Color typeColor;
    IconData typeIcon;

    switch (movement.type) {
      case 'pay_in':
        typeColor = Colors.green;
        typeIcon = LucideIcons.arrowDownLeft;
        break;
      case 'pay_out':
        typeColor = Colors.red;
        typeIcon = LucideIcons.arrowUpRight;
        break;
      case 'drop':
        typeColor = Colors.blue;
        typeIcon = LucideIcons.banknote;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = LucideIcons.circle;
    }

    final isNegative = movement.type == 'pay_out' || movement.type == 'drop';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(typeIcon, size: 16, color: typeColor),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        movement.typeLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: typeColor,
                        ),
                      ),
                      Text(
                        '${isNegative ? "- " : "+ "}${_formatCurrency(movement.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isNegative
                              ? Colors.red[700]
                              : Colors.green[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (movement.reason != null &&
                          movement.reason!.isNotEmpty)
                        Expanded(
                          child: Text(
                            movement.reason!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Text(
                        DateFormat('HH:mm').format(movement.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
