import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService(this._storage);

  Future<String> uploadImage(File file, String path) async {
    final fileName = '${const Uuid().v4()}.jpg';
    final ref = _storage.ref().child(path).child(fileName);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<List<String>> uploadMultipleImages(List<File> files, String path) async {
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
