abstract class GalleryRepository {
  Future<List<Map<String, dynamic>>> getTemplates();
  Future<void> submitScript(Map<String, dynamic> submission);
}
