import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> uploadClothingItem({
    required XFile imageFile,
    required String brand,
    required String title,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print("❌ 로그인이 되어있지 않습니다.");
        return false;
      }

      String uid = user.uid;
      String itemId = DateTime.now().millisecondsSinceEpoch.toString();

      // 1. Storage 업로드 (이건 지금 잘 되는 부분)
      Reference ref = _storage.ref().child('items').child(uid).child('$itemId.jpg');
      final Uint8List bytes = await imageFile.readAsBytes();

      print("🚀 Storage 업로드 시작...");
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      print("✅ Storage 업로드 완료!");

      // 2. 이미지 URL 가져오기 (여기서 멈추는지 확인 필요)
      String imageUrl = await ref.getDownloadURL();
      print("🔗 이미지 URL 획득: $imageUrl");

      // 3. Firestore 저장 (이 부분이 실행되어야 컬렉션이 생깁니다)
      print("📝 Firestore 저장 시도...");
      await _db.collection('items').doc(itemId).set({
        'id': itemId,
        'ownerUid': uid,
        'brand': brand,
        'title': title,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("✅ Firestore 컬렉션 생성 및 저장 완료!");

      return true;
    } catch (e) {
      print("🔥🔥 최종 에러 발생: $e");
      return false;
    }
  }
}