import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sharing/share_service.dart';

final shareServiceProvider = Provider<ShareService>((ref) => ShareService());

