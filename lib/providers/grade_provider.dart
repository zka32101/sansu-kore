import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart' show profileProvider, ProfileDataMigration;
import 'package:shared_preferences/shared_preferences.dart';
const _gradeBaseKey = 'selected_grade';

class GradeNotifier extends Notifier<int> {
  bool _isFirstLaunch = false;

  bool get isFirstLaunch => _isFirstLaunch;

  String _getGradeKey(String profileId) {
    return ProfileDataMigration.profileScopedKey(profileId, _gradeBaseKey);
  }

  @override
  int build() => 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final profileState = ref.watch(profileProvider);
    final profileId = profileState.currentProfileId;

    if (profileId == null) {
      _isFirstLaunch = true;
      state = 0;
      return;
    }

    final gradeKey = _getGradeKey(profileId);
    final saved = prefs.getInt(gradeKey);
    _isFirstLaunch = saved == null;
    state = saved ?? 0;
  }

  Future<void> setGrade(int grade) async {
    state = grade;
    final prefs = await SharedPreferences.getInstance();
    final profileState = ref.watch(profileProvider);
    final profileId = profileState.currentProfileId;

    if (profileId == null) return;

    final gradeKey = _getGradeKey(profileId);
    await prefs.setInt(gradeKey, grade);
  }
}

final gradeProvider = NotifierProvider<GradeNotifier, int>(GradeNotifier.new);
