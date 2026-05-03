/// Formats a [DateTime] as a relative timestamp string.
///
/// Returns "Just now" for < 1 minute, "Xm ago" for < 60 minutes,
/// "Xh ago" for < 24 hours, "Xd ago" for < 7 days, and "DD/MM/YYYY" otherwise.
String formatRelativeTimestamp(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
}

/// Truncates [text] to [maxLength] characters.
///
/// Returns the original string if it is already within the limit.
String truncateTitle(String text, {int maxLength = 100}) {
  return text.length > maxLength ? text.substring(0, maxLength) : text;
}

/// Truncates [text] to [maxLength] characters with trailing ellipsis.
///
/// Returns the original string if it is already within the limit.
String truncatePreview(String text, {int maxLength = 120}) {
  return text.length > maxLength ? '${text.substring(0, maxLength)}...' : text;
}
