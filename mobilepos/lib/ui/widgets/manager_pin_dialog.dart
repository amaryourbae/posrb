import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ManagerPinDialog extends StatefulWidget {
  const ManagerPinDialog({super.key});

  @override
  State<ManagerPinDialog> createState() => _ManagerPinDialogState();
}

class _ManagerPinDialogState extends State<ManagerPinDialog> {
  String _pin = '';

  void _onDigit(String digit) {
    if (_pin.length < 6) {
      setState(() => _pin += digit);
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _onClear() {
    setState(() => _pin = '');
  }

  void _onSubmit() {
    if (_pin.isEmpty) return;
    Navigator.of(context).pop(_pin);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manager PIN',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Center(
                child: Text(
                  _pin.isEmpty ? 'Enter PIN' : '•' * _pin.length,
                  style: TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    color: _pin.isEmpty ? Colors.grey[400] : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Numpad
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index == 9) {
                  return _buildKey('C', onTap: _onClear, isAction: true);
                }
                if (index == 10) {
                  return _buildKey('0', onTap: () => _onDigit('0'));
                }
                if (index == 11) {
                  return _buildKey(
                    'back',
                    icon: LucideIcons.delete,
                    onTap: _onBackspace,
                    isAction: true,
                  );
                }
                return _buildKey(
                  '${index + 1}',
                  onTap: () => _onDigit('${index + 1}'),
                );
              },
            ),

            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _pin.isNotEmpty ? _onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5a6c37),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(
    String label, {
    IconData? icon,
    required VoidCallback onTap,
    bool isAction = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isAction ? Colors.orange[50] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isAction ? Colors.orange[100]! : Colors.grey[200]!,
            ),
          ),
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    color: isAction ? Colors.orange[700] : Colors.black,
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isAction ? Colors.orange[700] : Colors.black,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
