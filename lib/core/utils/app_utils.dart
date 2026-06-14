import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppUtils {
  AppUtils._();

  // ── Date helpers ─────────────────────────────────────
  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String monthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  static String monthKeyFor(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
  }

  static String formatDate(DateTime dt, {String locale = 'ar'}) {
    return DateFormat('yyyy/MM/dd', locale).format(dt);
  }

  static String formatTime(DateTime dt, {String locale = 'ar'}) {
    return DateFormat('HH:mm', locale).format(dt);
  }

  static String formatDateTime(DateTime dt, {String locale = 'ar'}) {
    return DateFormat('yyyy/MM/dd HH:mm', locale).format(dt);
  }

  static DateTime? parseDate(String? str) {
    if (str == null || str.isEmpty) return null;
    try {
      return DateTime.parse(str);
    } catch (_) {
      return null;
    }
  }

  static int weekNumber(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(jan1).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  // ── Color helpers ─────────────────────────────────────
  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  static Color lightenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightened = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return lightened.toColor();
  }

  // ── Fitness calculators ───────────────────────────────
  /// Epley 1RM formula
  static double epley(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }

  /// Mifflin-St Jeor BMR
  static double calcBMR({
    required double weight,
    required double height,
    required int age,
    required String gender,
  }) {
    if (gender == 'male') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  static double calcTDEE(double bmr, double activityFactor) {
    return bmr * activityFactor;
  }

  static double calcBodyFatNavy({
    required String gender,
    required double waist,
    required double neck,
    double hip = 0,
    required double height,
  }) {
    if (gender == 'male') {
      return 495 / (1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)) - 450;
    } else {
      return 495 / (1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(height)) - 450;
    }
  }

  static double log10(double x) => log(x) / ln10;

  /// Volume = sets * weight * reps
  static double calcVolume(List<Map<String, dynamic>> sets) {
    return sets.fold(0.0, (sum, s) {
      final w = (s['w'] as num?)?.toDouble() ?? 0;
      final r = (s['r'] as num?)?.toInt() ?? 0;
      return sum + w * r;
    });
  }

  // ── Text helpers ──────────────────────────────────────
  static String initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  static String greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️ صباح الخير';
    if (hour < 17) return '🌤 مساء الخير';
    return '🌙 مساء النور';
  }

  // ── Validation helpers ────────────────────────────────
  static bool isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^[\d+\-\s()]+$').hasMatch(phone) && phone.length >= 8;
  }

  static bool isValidPassword(String pass) {
    return pass.length >= 8 &&
        RegExp(r'[A-Za-z]').hasMatch(pass) &&
        RegExp(r'\d').hasMatch(pass);
  }

  // ── Format duration ───────────────────────────────────
  static String formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String formatRestRange(String range) {
    // "3~5" → "3-5 دقائق"
    return range.replaceAll('~', '-');
  }

  // ── Snackbar helper ───────────────────────────────────
  static void showSnack(
    BuildContext context,
    String msg, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    final color = isError
        ? const Color(0xFFF44336)
        : isSuccess
            ? const Color(0xFF4CAF50)
            : const Color(0xFF424242);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Number formatting ─────────────────────────────────
  static String formatCalories(double cal) => cal.toStringAsFixed(0);
  static String formatMacro(double g) => '${g.toStringAsFixed(1)}g';
  static String formatWeight(double kg) => '${kg.toStringAsFixed(1)} kg';

  // ── Random ────────────────────────────────────────────
  static String generateId() {
    final r = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (_) => chars[r.nextInt(chars.length)]).join();
  }

  // ── Streak calculation ────────────────────────────────
  static int calcStreak(Map<String, String> attendance) {
    if (attendance.isEmpty) return 0;
    final today = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final d = today.subtract(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final val = attendance[key];
      if (val == 'GYM') {
        streak++;
      } else if (val == null && i == 0) {
        // today not marked yet, keep going
        continue;
      } else {
        break;
      }
    }
    return streak;
  }
}
