import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/utils/app_date_formatter.dart';
import '../../core/services/dio_service.dart';
import '../widgets/app_toast.dart';
import '../../core/utils/product_helper.dart';
import '../../core/providers/pos_provider.dart';

class PendingBillsModal extends ConsumerStatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final Function(Map<String, dynamic> bill) onLoad;
  final Function(Map<String, dynamic> bill) onCancel;
  final Function(Map<String, dynamic> bill)? onPrint;

  const PendingBillsModal({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onLoad,
    required this.onCancel,
    this.onPrint,
  });

  @override
  ConsumerState<PendingBillsModal> createState() => _PendingBillsModalState();
}

class _PendingBillsModalState extends ConsumerState<PendingBillsModal> {
  bool _loading = false;
  List<dynamic> _pendingBills = [];
  int? _notificationOpenId;
  final TextEditingController _phoneController = TextEditingController();
  bool _sending = false;

  String formatCurrency(double? amount) {
    if (amount == null) return 'Rp 0';
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  @override
  void didUpdateWidget(covariant PendingBillsModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _fetchPendingBills();
    }
  }

  Future<void> _fetchPendingBills() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/admin/orders/pending');
      final resData = response.data;
      List<dynamic> bills = [];

      if (resData is Map<String, dynamic> && resData['data'] is List) {
        bills = resData['data'];
      } else if (resData is List) {
        bills = resData;
      }

      setState(() {
        _pendingBills = bills;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleProcess(
    Map<String, dynamic> bill, {
    String? customPhone,
  }) async {
    setState(() => _sending = true);
    try {
      final dio = ref.read(dioProvider);

      // 1. Mark as Processed (order_status = completed)
      await dio.post('/admin/orders/${bill['id']}/process');

      // 2. Send WhatsApp Notification if phone is available
      final phone =
          customPhone ?? bill['customer_phone'] ?? bill['customer']?['phone'];
      if (phone != null && phone.toString().isNotEmpty) {
        try {
          // Send request to notify endpoint (queues on backend)
          await dio.post(
            '/admin/orders/${bill['id']}/notify',
            data: {'phone': phone},
          );
        } catch (e) {
          // Non-blocking error for notification
          debugPrint('WhatsApp notification failed: $e');
        }
      }

      // 3. Trigger Print (Local)
      widget.onPrint?.call(bill);

      // 4. Update UI
      if (mounted) {
        setState(() {
          _notificationOpenId = null;
          _sending = false;
        });

        // Clear Unseen Status
        ref.read(posProvider.notifier).markOrderAsSeen(bill['id'].toString());

        AppToast.show(
          context,
          'Order processed successfully',
          type: ToastType.success,
        );
      }

      // 5. Refresh List
      _fetchPendingBills();
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        AppToast.show(
          context,
          'Failed to process order',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.5)),
        ),

        // Modal
        Center(
          child: Container(
            width: 480,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[100]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pending Bills',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: Icon(LucideIcons.x, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: _loading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Loading bills...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _pendingBills.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.receipt,
                                  size: 48,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No pending bills found',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          shrinkWrap: true,
                          itemCount: _pendingBills.length,
                          itemBuilder: (context, index) {
                            final bill =
                                _pendingBills[index] as Map<String, dynamic>;
                            return _buildBillCard(bill);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
    final isPaid = bill['payment_status'] == 'paid';
    final isPendingConfirmation = bill['payment_status'] == 'pending_confirmation';
    final isActionable = isPaid || isPendingConfirmation;
    final items = bill['items'] as List<dynamic>? ?? [];
    final orderType = (bill['order_type'] ?? '')
        .toString()
        .replaceAll('_app', '')
        .replaceAll('_', ' ')
        .toUpperCase();
    final isUnseen = ref
        .watch(posProvider)
        .unseenOrderIds
        .contains(bill['id'].toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        bill['order_number'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isUnseen)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPendingConfirmation
                              ? Colors.purple[100]
                              : isPaid
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPendingConfirmation
                              ? 'Konfirmasi'
                              : isPaid ? 'Paid / App' : 'Pending',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPendingConfirmation
                                ? Colors.purple[700]
                                : isPaid
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                          ),
                        ),
                      ),
                      if (orderType.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            orderType,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bill['customer_name'] ?? 'Walk-in',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
              Text(
                formatCurrency(
                  double.tryParse(bill['grand_total']?.toString() ?? '0'),
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5a6c37),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${items.length} items',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              Text(
                AppDateFormatter.formatTime(bill['created_at']),
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),

          // Items Summary
          if (items.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[200]!,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
            ),
            ...items.map((item) => _buildItemRow(item)),
          ],

          // Note
          if (bill['note'] != null &&
              ![
                'pickup',
                'pickup_app',
                'dine_in',
              ].contains(bill['note'].toString().toLowerCase())) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Text(
                'Note: ${bill['note']}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action Buttons
          if (isActionable) _buildPaidActions(bill) else _buildPendingActions(bill),
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    final visibleModifiers = ProductHelper.getVisibleModifiers(
      item['modifiers'] as List<dynamic>? ?? [],
    );
    String productName = ProductHelper.getFormattedProductName(
      item['product_name'] ?? item['name'] ?? '',
      item['modifiers'] as List<dynamic>? ?? [],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: '${item['quantity']}x ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: productName),
                    ],
                  ),
                ),
                if (visibleModifiers.isNotEmpty)
                  ...visibleModifiers.map((mod) {
                    final displayName = ProductHelper.getModifierDisplayName(
                      mod,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(left: 20, top: 2),
                      child: Text(
                        '+ $displayName',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidActions(Map<String, dynamic> bill) {
    final hasPhone =
        bill['customer_phone'] != null || bill['customer']?['phone'] != null;

    return Column(
      children: [
        Row(
          children: [
            if (!hasPhone)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      if (_notificationOpenId == bill['id']) {
                        _notificationOpenId = null;
                      } else {
                        _notificationOpenId = bill['id'];
                        _phoneController.text =
                            bill['customer']?['phone'] ?? '';
                      }
                    });
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: _notificationOpenId == bill['id']
                        ? Colors.green[200]
                        : Colors.green[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    LucideIcons.messageCircle,
                    color: Colors.green[700],
                    size: 20,
                  ),
                ),
              ),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _sending ? null : () => _handleProcess(bill),
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.printer, size: 16),
                label: Text(hasPhone ? 'Selesai & Notify' : 'Process / Print'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5a6c37),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),

        // WhatsApp Input
        if (_notificationOpenId == bill['id']) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'KIRIM NOTIFIKASI WHATSAPP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 1,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _notificationOpenId = null),
                      child: Icon(
                        LucideIcons.x,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            prefixText: '+62 ',
                            prefixStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            hintText: '812...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _sending
                          ? null
                          : () {
                              if (_phoneController.text.isNotEmpty) {
                                _handleProcess(
                                  bill,
                                  customPhone: _phoneController.text,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5a6c37),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Send'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPendingActions(Map<String, dynamic> bill) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Clear Unseen Status
              ref
                  .read(posProvider.notifier)
                  .markOrderAsSeen(bill['id'].toString());
              widget.onLoad(bill);
              widget.onClose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5a6c37),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Resume Payment',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => widget.onCancel(bill),
          style: IconButton.styleFrom(
            backgroundColor: Colors.red[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: Icon(LucideIcons.xCircle, color: Colors.red[600]),
        ),
      ],
    );
  }
}
