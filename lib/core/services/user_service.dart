import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return AppUser.fromMap(doc.data()!, doc.id);
  }

  Stream<AppUser> streamUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (doc) => AppUser.fromMap(doc.data()!, doc.id),
        );
  }
}
