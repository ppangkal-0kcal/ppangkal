import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';

enum FoodPhotoResult { saved, cancelled, failed }

/// Consumption photo (FRONTEND_API_GUIDE.md §4): camera → device gallery
/// only. Nothing is uploaded — `food_logs` has no photo field by design.
class FoodPhotoService {
  static const _album = '빵칼';

  final ImagePicker _picker;

  FoodPhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<FoodPhotoResult> captureAndSave() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo == null) return FoodPhotoResult.cancelled;

      if (!await Gal.hasAccess(toAlbum: true) && !await Gal.requestAccess(toAlbum: true)) {
        return FoodPhotoResult.failed;
      }
      await Gal.putImage(photo.path, album: _album);
      return FoodPhotoResult.saved;
    } catch (_) {
      return FoodPhotoResult.failed;
    }
  }
}
