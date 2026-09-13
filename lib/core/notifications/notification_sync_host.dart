import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/item/domain/entities/item_entity.dart';
import '../../features/item/presentation/providers/item_provider.dart';
import '../../features/settings/domain/entities/app_settings.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';
import 'local_notification_service.dart';

class NotificationSyncHost extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationSyncHost({super.key, required this.child});

  @override
  ConsumerState<NotificationSyncHost> createState() =>
      _NotificationSyncHostState();
}

class _NotificationSyncHostState extends ConsumerState<NotificationSyncHost> {
  late final ProviderSubscription<AppSettings> _settingsSubscription;
  late final ProviderSubscription<AsyncValue<List<ItemEntity>>>
  _itemsSubscription;
  bool _syncing = false;
  bool _syncAgain = false;

  @override
  void initState() {
    super.initState();
    LocalNotificationService.instance.initialize();
    _settingsSubscription = ref.listenManual<AppSettings>(
      settingsNotifierProvider,
      (_, __) => _sync(),
    );
    _itemsSubscription = ref.listenManual<AsyncValue<List<ItemEntity>>>(
      itemNotifierProvider,
      (_, __) => _sync(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _settingsSubscription.close();
    _itemsSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<void> _sync() async {
    if (_syncing) {
      _syncAgain = true;
      return;
    }

    _syncing = true;
    try {
      do {
        _syncAgain = false;
        final settings = ref.read(settingsNotifierProvider);
        final items =
            ref.read(itemNotifierProvider).value ?? const <ItemEntity>[];
        await LocalNotificationService.instance.syncItems(
          items: items,
          notificationsEnabled: settings.notificationsEnabled,
        );
      } while (_syncAgain && mounted);
    } finally {
      _syncing = false;
    }
  }
}
