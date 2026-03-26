import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:screenshot/screenshot.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import '../receipt/shift_receipt_widget.dart';
import '../../core/providers/auth_provider.dart';
import '../widgets/app_toast.dart';

class ShiftSummaryModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> shift;
  final VoidCallback? onClose;

  const ShiftSummaryModal({super.key, required this.shift, this.onClose});

  @override
  ConsumerState<ShiftSummaryModal> createState() => _ShiftSummaryModalState();
}

class _ShiftSummaryModalState extends ConsumerState<ShiftSummaryModal> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isPrinting = false;

  Future<void> _handlePrint() async {
    if (kIsWeb) {
      AppToast.show(
        context,
        'Printing not supported on web',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isPrinting = true);
    try {
      final settings = ref.read(authProvider).settings;
      final user = ref.read(authProvider).user;
      final userName = user?['name'] ?? 'Staff';

      // Capture the receipt widget as image
      final image = await _screenshotController.captureFromWidget(
        Material(
          color: Colors.white,
          child: ShiftReceiptWidget(
            shift: widget.shift,
            settings: settings,
            userName: userName,
          ),
        ),
        delay: const Duration(milliseconds: 100),
        context: context,
      );

      if (!mounted) return;

      final printer = BlueThermalPrinter.instance;
      // Check connection status
      // In a real app, you might want to manage connection state globally
      final isConnected = await printer.isConnected;

      if (!mounted) return;

      if (isConnected == true) {
        printer.printImageBytes(image);
        AppToast.show(
          context,
          'Printing shift summary...',
          type: ToastType.success,
        );
      } else {
        // Try to connect to first device if possible or warn
        // For now, simpler handling:
        AppToast.show(
          context,
          'Printer not connected',
          type: ToastType.warning,
        );

        // Optional: Open printer settings or connection dialog here
      }
    } catch (e) {
      debugPrint('Print Error: $e');
      if (mounted) {
        AppToast.show(context, 'Failed to print: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(authProvider).settings;
    final user = ref.watch(authProvider).user;
    final userName = user?['name'] ?? 'Staff';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: 380,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Shift Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (widget.onClose != null) widget.onClose!();
                      },
                      icon: const Icon(LucideIcons.x, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Preview Area
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ShiftReceiptWidget(
                      shift: widget.shift,
                      settings: settings,
                      userName: userName,
                    ),
                  ),
                ),
              ),

              const Divider(height: 1),

              // Footer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (widget.onClose != null) widget.onClose!();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isPrinting ? null : _handlePrint,
                        icon: _isPrinting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(LucideIcons.printer, size: 16),
                        label: Text(_isPrinting ? 'Printing...' : 'Print'),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
