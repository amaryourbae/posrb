import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Provider for the UpdateService
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

class UpdateService {
  final Dio _dio = Dio();

  /// Check for available updates from the backend.
  /// Returns a Map with update info, or null if no update.
  Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.parse(packageInfo.buildNumber);

      final response = await _dio.get('${AppConfig.apiUrl}/app-version/latest');

      if (response.statusCode == 200) {
        final data = response.data['data'];

        if (data == null || data['has_update'] != true) {
          return null;
        }

        final serverVersionCode = data['version_code'] as int;

        if (serverVersionCode > currentVersionCode) {
          // Check for snooze
          final prefs = await SharedPreferences.getInstance();
          final snoozedVersion = prefs.getInt('last_snoozed_version');
          
          final isMandatory = data['is_mandatory'] == true;

          if (!isMandatory && snoozedVersion == serverVersionCode) {
            debugPrint('UpdateService: Version $serverVersionCode is snoozed.');
            return null;
          }

          return {
            'version_name': data['version_name'],
            'version_code': serverVersionCode,
            'current_code': currentVersionCode,
            'apk_url': data['apk_url'],
            'release_notes': data['release_notes'] ?? '',
            'is_mandatory': isMandatory,
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('UpdateService: Error checking for update: $e');
      return null;
    }
  }

  /// Download the APK file and open it for installation.
  Future<void> downloadAndInstall(
    String apkUrl, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/update.apk';

      await _dio.download(apkUrl, filePath, onReceiveProgress: onProgress);

      final result = await OpenFilex.open(filePath);
      debugPrint('OpenFilex result: ${result.type} - ${result.message}');
    } catch (e) {
      debugPrint('UpdateService: Error downloading APK: $e');
      rethrow;
    }
  }

  /// Show the update dialog to the user.
  static void showUpdateDialog(
    BuildContext context,
    Map<String, dynamic> updateInfo,
    UpdateService service,
  ) {
    final isMandatory = updateInfo['is_mandatory'] == true;

    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (ctx) => _UpdateDialog(
        updateInfo: updateInfo,
        service: service,
        isMandatory: isMandatory,
      ),
    ).then((_) async {
      // When dialog is closed (dismissed), if it's not mandatory, we snooze it
      if (!isMandatory) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_snoozed_version', updateInfo['version_code']);
        debugPrint('UpdateService: Snoozing version ${updateInfo['version_code']}');
      }
    });
  }
}

class _UpdateDialog extends StatefulWidget {
  final Map<String, dynamic> updateInfo;
  final UpdateService service;
  final bool isMandatory;

  const _UpdateDialog({
    required this.updateInfo,
    required this.service,
    required this.isMandatory,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  void _startDownload() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });

    try {
      await widget.service.downloadAndInstall(
        widget.updateInfo['apk_url'],
        onProgress: (received, total) {
          if (total > 0) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );
      // Close dialog after install prompt is triggered
      if (mounted && !widget.isMandatory) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = 'Download gagal. Silakan coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isMandatory,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.system_update,
                color: Colors.green.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Update Tersedia!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    'Versi ${widget.updateInfo['version_name']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.updateInfo['current_code']} → ${widget.updateInfo['version_code']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.isMandatory)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'WAJIB',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.updateInfo['release_notes']?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              const Text(
                'Yang baru:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.updateInfo['release_notes'],
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (_downloading) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.green.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mengunduh... ${(_progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          if (!widget.isMandatory && !_downloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Nanti Saja'),
            ),
          if (!_downloading)
            ElevatedButton.icon(
              onPressed: _startDownload,
              icon: const Icon(Icons.download, size: 20),
              label: Text(_error != null ? 'Coba Lagi' : 'Update Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
