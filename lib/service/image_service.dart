import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  final ImagePicker picker = ImagePicker();
  Future<String?> choose(String uid) async {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
    );
    return file == null ? null : preserve(uid, file);
  }

  Future<String> preserve(String uid, XFile file) async {
    final root = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(root.path, 'photos', uid));
    await folder.create(recursive: true);
    final extension = p.extension(file.path).isEmpty
        ? '.jpg'
        : p.extension(file.path);
    final path = p.join(folder.path, '${const Uuid().v4()}$extension');
    await File(file.path).copy(path);
    return path;
  }

  Future<void> delete(String? path) async {
    if (path != null && await File(path).exists()) {
      await File(path).delete();
    }
  }
}
