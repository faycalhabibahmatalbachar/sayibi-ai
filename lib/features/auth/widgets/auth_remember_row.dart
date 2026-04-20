import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class AuthRememberRow extends StatelessWidget {
  const AuthRememberRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onChanged(!value);
              }
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              Switch(
                value: value,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
                onChanged: enabled
                    ? (v) {
                        HapticFeedback.selectionClick();
                        onChanged(v);
                      }
                    : null,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  'Se souvenir de moi',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: enabled ? 0.88 : 0.45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
