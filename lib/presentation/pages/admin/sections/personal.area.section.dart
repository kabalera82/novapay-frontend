// lib/presentation/pages/admin/sections/personal.area.section.dart
import 'package:flutter/material.dart';

import '../../../../data/models/user.dart';
import '../../../widgets/profile/profile.form.widget.dart';

class PersonalAreaSection extends StatelessWidget {
  final User user;

  const PersonalAreaSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ProfileFormWidget(user: user);
  }
}
