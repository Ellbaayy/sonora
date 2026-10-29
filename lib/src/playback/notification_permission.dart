import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

bool _requested = false;

/// Meminta izin notifikasi sekali sebelum pemutaran pertama.
///
/// Android 13 ke atas memerlukan izin ini agar notifikasi media tampil. Bila
/// ditolak, pemutaran tetap berjalan; hanya notifikasinya tidak muncul.
Future<void> ensureNotificationPermission() async {
  if (_requested || !Platform.isAndroid) return;
  _requested = true;
  try {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  } catch (_) {
    // Izin tidak wajib untuk memutar audio; kegagalan diabaikan.
  }
}
