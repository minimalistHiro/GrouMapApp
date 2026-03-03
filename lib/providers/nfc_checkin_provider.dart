import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/nfc_checkin_service.dart';

final nfcCheckinServiceProvider = Provider<NfcCheckinService>((ref) {
  return NfcCheckinService();
});
