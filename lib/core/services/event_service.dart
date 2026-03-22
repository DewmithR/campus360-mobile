import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream all upcoming/ongoing events
  Stream<QuerySnapshot> streamEvents() {
    return _firestore
        .collection('events')
        .where('status', whereIn: ['upcoming', 'ongoing'])
        .orderBy('date', descending: false)
        .snapshots();
  }

  // Stream a single event
  Stream<DocumentSnapshot> streamEvent(String eventId) {
    return _firestore.collection('events').doc(eventId).snapshots();
  }

  // Stream the current user's bookings
  Stream<QuerySnapshot> streamMyBookings(String uid) {
    return _firestore
        .collection('bookings')
        .where('uid', isEqualTo: uid)
        .orderBy('bookedAt', descending: true)
        .snapshots();
  }

  // Stream the current user's active upcoming bookings
  Stream<QuerySnapshot> streamMyUpcomingBookings(String uid) {
    return _firestore
        .collection('bookings')
        .where('uid', isEqualTo: uid)
        .where('status', whereIn: ['reserved', 'collected'])
        .snapshots();
  }

  // Check if user has already booked an event
  Future<bool> hasBooking(String eventId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final query = await _firestore
        .collection('bookings')
        .where('uid', isEqualTo: uid)
        .where('eventId', isEqualTo: eventId)
        .where('status', whereIn: ['reserved', 'collected'])
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  //  Get booking for a specific event
  Future<DocumentSnapshot?> getBooking(String eventId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final query = await _firestore
        .collection('bookings')
        .where('uid', isEqualTo: uid)
        .where('eventId', isEqualTo: eventId)
        .where('status', whereIn: ['reserved', 'collected'])
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first;
  }

  //  Book an event
  Future<void> bookEvent({
  required String eventId,
  required String eventTitle,
  required Timestamp eventDate,
  required String userName,
  required String userEmail,
  required String venue,
  required String type,
  required double ticketPrice,
}) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final eventRef = _firestore.collection('events').doc(eventId);
  final bookRef = _firestore.collection('bookings').doc();

  try {
    await _firestore.runTransaction((txn) async {
      final eventSnap = await txn.get(eventRef);
      if (!eventSnap.exists) throw Exception('Event not found');

      final data = eventSnap.data() as Map<String, dynamic>;
      final totalSeats = (data['totalSeats'] as num?)?.toInt() ?? 0;
      final bookedSeats = (data['bookedSeats'] as num?)?.toInt() ?? 0;

      if (bookedSeats >= totalSeats) throw Exception('No seats available');

      txn.set(bookRef, {
        'eventId': eventId,
        'eventTitle': eventTitle,
        'eventDate': eventDate,
        'venue': venue,
        'type': type,
        'ticketPrice': ticketPrice,
        'uid': uid,
        'userName': userName,
        'userEmail': userEmail,
        'status': 'reserved',
        'bookedAt': FieldValue.serverTimestamp(),
        'collectedAt': null,
        'cancelledAt': null,
        'cancelledBy': null,
        'adminNote': null,
      });

      txn.update(eventRef, {
        'bookedSeats': FieldValue.increment(1),
      });
    });
  } catch (e) {
    rethrow;
  }
}

  // Cancel a booking
  Future<void> cancelBooking(String bookingId, String eventId) async {
    final eventRef = _firestore.collection('events').doc(eventId);
    final bookingRef = _firestore.collection('bookings').doc(bookingId);

    final batch = _firestore.batch();

    batch.update(bookingRef, {
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': 'student',
    });

    batch.update(eventRef, {
      'bookedSeats': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  // Check if cancellation is allowed
  // Students can cancel up to 5 days before the event date
  bool canCancel(Timestamp eventDate) {
    final now = DateTime.now();

    final daysUntil = eventDate.toDate().difference(now).inDays;
    return daysUntil >= 5;
  }
}