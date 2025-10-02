/// Time formatting utilities for wildfire risk data display
///
/// Provides UTC to local time conversion with compact relative formatting
/// suitable for user interfaces.
library;

/// Formats a UTC datetime to a compact relative time string.
///
/// Converts [updatedUtc] from UTC to local time and returns a human-readable
/// relative time string based on the difference from [utcNow].
///
/// Returns:
/// - "Just now" for differences < 45 seconds
/// - "X min ago" for differences < 60 minutes
/// - "X hour ago" / "X hours ago" for differences < 24 hours
/// - "X day ago" / "X days ago" for differences >= 24 hours
///
/// Both parameters must be in UTC. The function handles timezone conversion
/// internally.
///
/// Example:
/// ```dart
/// final now = DateTime.now().toUtc();
/// final updated = now.subtract(Duration(minutes: 5));
/// print(formatRelativeTime(utcNow: now, updatedUtc: updated)); // "5 min ago"
/// ```
String formatRelativeTime({
  required DateTime utcNow,
  required DateTime updatedUtc,
}) {
  // Calculate the difference in UTC (both params are UTC)
  final difference = utcNow.difference(updatedUtc);

  if (difference.inSeconds < 45) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    return '$minutes min ago';
  } else if (difference.inHours < 24) {
    final hours = difference.inHours;
    return hours == 1 ? '1 hour ago' : '$hours hours ago';
  } else {
    final days = difference.inDays;
    return days == 1 ? '1 day ago' : '$days days ago';
  }
}
