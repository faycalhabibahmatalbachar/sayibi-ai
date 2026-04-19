import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_model.dart';

class ProfileState {
  const ProfileState({this.user, this.loading = false, this.error});

  final UserModel? user;
  final bool loading;
  final String? error;
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState());

  void setUser(UserModel? u) => state = ProfileState(user: u);
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) => ProfileNotifier());
