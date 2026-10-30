import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart'
    show coinProvider, reviewQueueProvider;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sansu_kore/services/retention_hooks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('initRetention はエラーなく完了し、コイン付与が残高と永続データに反映される', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await initRetention(container);
    await container.read(coinProvider.notifier).load();
    await container.read(coinProvider.notifier).addCoins(20);

    expect(container.read(coinProvider).totalCoins, 20);
    final reloaded = ProviderContainer();
    addTearDown(reloaded.dispose);
    await reloaded.read(coinProvider.notifier).load();
    expect(reloaded.read(coinProvider).totalCoins, 20);
    expect(container.read(reviewQueueProvider), isNotNull);
  });
}
