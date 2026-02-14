import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService(this._storage);

  Future<String> uploadImage(XFile file, String path) async {
    final fileName = '${const Uuid().v4()}.jpg';
    final ref = _storage.ref().child(path).child(fileName);
    
    // Using putData is safer for Web compatibility than putFile
    final bytes = await file.readAsBytes();
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    
    return await uploadTask.ref.getDownloadURL();
  }

  Future<List<String>> uploadMultipleImages(List<XFile> files, String path) async {
    final List<String> urls = [];
    for (final file in files) {
      final url = await uploadImage(file, path);
      urls.add(url);
    }
    return urls;
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(FirebaseStorage.instance);
});
