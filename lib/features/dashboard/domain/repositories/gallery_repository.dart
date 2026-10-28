/// Outcome of reporting a gallery script.
enum ReportResult { reported, alreadyReported }

/// Thrown when a guest (anonymous) user tries a community action that needs
/// a real account (publishing, reporting).
class GuestAccountRequiredException implements Exception {
  const GuestAccountRequiredException();

  @override
  String toString() => 'Please link a Google, Apple or email account first.';
}

abstract class GalleryRepository {
  Future<List<Map<String, dynamic>>> getTemplates();
  Future<void> submitScript(Map<String, dynamic> submission);

  /// Files a moderation report (one per user per script). The
  /// `onReportCreated` Cloud Function aggregates reports.
  Future<ReportResult> reportScript(String scriptId, {String? reason});
}
