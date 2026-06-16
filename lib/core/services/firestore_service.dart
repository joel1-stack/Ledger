import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';
import '../models/member_model.dart';
import '../models/contribution_type_model.dart';
import '../models/contribution_record_model.dart';
import '../models/event_model.dart';
import '../models/approval_model.dart';
import '../models/timeline_event_model.dart';
import '../models/document_model.dart';
import '../models/announcement_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _groups => _firestore.collection('groups');

  DocumentReference groupDoc(String groupId) => _groups.doc(groupId);
  CollectionReference membersRef(String groupId) => _groups.doc(groupId).collection('members');
  CollectionReference contributionTypesRef(String groupId) => _groups.doc(groupId).collection('contributionTypes');
  CollectionReference contributionsRef(String groupId) => _groups.doc(groupId).collection('contributions');
  CollectionReference eventsRef(String groupId) => _groups.doc(groupId).collection('events');
  CollectionReference approvalsRef(String groupId) => _groups.doc(groupId).collection('approvals');
  CollectionReference timelineRef(String groupId) => _groups.doc(groupId).collection('timeline');
  CollectionReference documentsRef(String groupId) => _groups.doc(groupId).collection('documents');
  CollectionReference announcementsRef(String groupId) => _groups.doc(groupId).collection('announcements');

  Future<GroupModel> createGroup(Map<String, dynamic> data) async {
    final doc = await _groups.add(data);
    final snapshot = await doc.get();
    return GroupModel.fromMap(snapshot.data()! as Map<String, dynamic>, doc.id);
  }

  Stream<GroupModel?> streamGroup(String groupId) {
    return _groups.doc(groupId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return GroupModel.fromMap(snap.data()! as Map<String, dynamic>, snap.id);
    });
  }

  Future<List<GroupModel>> getUserGroups(String userId) async {
    final memberSnap = await _firestore.collectionGroup('members')
        .where('userId', isEqualTo: userId)
        .get();
    if (memberSnap.docs.isEmpty) return [];
    final groupIds = memberSnap.docs.map((doc) => doc.reference.parent.parent!.id).toSet().toList();
    final groupSnap = await _groups.where(FieldPath.documentId, whereIn: groupIds).get();
    return groupSnap.docs.map((doc) => GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Stream<List<GroupModel>> streamUserGroups(List<String> groupIds) {
    if (groupIds.isEmpty) return Stream.value([]);
    return _groups.where(FieldPath.documentId, whereIn: groupIds).snapshots().map((snap) {
      return snap.docs.map((doc) => GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<GroupModel?> getGroupByInviteCode(String code) async {
    final snap = await _groups.where('inviteCode', isEqualTo: code.toUpperCase()).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return GroupModel.fromMap(snap.docs.first.data() as Map<String, dynamic>, snap.docs.first.id);
  }

  Future<List<GroupModel>> searchGroupsByName(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    final snap = await _groups
        .where('nameSearch', isGreaterThanOrEqualTo: q)
        .where('nameSearch', isLessThan: '$q\u{f8ff}')
        .orderBy('nameSearch')
        .limit(20)
        .get();
    return snap.docs.map((d) => GroupModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
  }

  Future<void> sendJoinRequest(String groupId, String userId, String name, String phone) async {
    await _groups.doc(groupId).collection('joinRequests').doc(userId).set({
      'userId': userId,
      'name': name,
      'phone': phone,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGroup(String groupId, Map<String, dynamic> data) async {
    await _groups.doc(groupId).update(data);
  }

  Future<MemberModel> addMember(String groupId, Map<String, dynamic> data) async {
    final memberId = data['userId'] as String;
    await membersRef(groupId).doc(memberId).set(data);
    await _groups.doc(groupId).update({'stats.totalMembers': FieldValue.increment(1)});
    final snapshot = await membersRef(groupId).doc(memberId).get();
    return MemberModel.fromMap(snapshot.data()! as Map<String, dynamic>, memberId);
  }

  Future<void> addMembersBulk(String groupId, List<Map<String, dynamic>> members) async {
    final batch = _firestore.batch();
    for (final member in members) {
      final memberId = member['userId'] as String;
      final docRef = membersRef(groupId).doc(memberId);
      batch.set(docRef, member);
    }
    batch.update(_groups.doc(groupId), {'stats.totalMembers': FieldValue.increment(members.length)});
    await batch.commit();
  }

  Stream<List<MemberModel>> streamMembers(String groupId) {
    return membersRef(groupId).snapshots().map((snap) {
      return snap.docs.map((doc) => MemberModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Stream<MemberModel?> streamMember(String groupId, String memberId) {
    return membersRef(groupId).doc(memberId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return MemberModel.fromMap(snap.data()! as Map<String, dynamic>, snap.id);
    });
  }

  Future<void> updateMember(String groupId, String memberId, Map<String, dynamic> data) async {
    await membersRef(groupId).doc(memberId).update(data);
  }

  Future<ContributionTypeModel> addContributionType(String groupId, Map<String, dynamic> data) async {
    final doc = await contributionTypesRef(groupId).add(data);
    final snapshot = await doc.get();
    return ContributionTypeModel.fromMap(snapshot.data()! as Map<String, dynamic>, doc.id);
  }

  Stream<List<ContributionTypeModel>> streamContributionTypes(String groupId) {
    return contributionTypesRef(groupId).snapshots().map((snap) {
      return snap.docs.map((doc) => ContributionTypeModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> recordContribution(String groupId, Map<String, dynamic> data) async {
    final doc = await contributionsRef(groupId).add(data);
    final amount = (data['amount'] as num).toDouble();
    await _groups.doc(groupId).update({
      'stats.totalCollected': FieldValue.increment(amount),
    });
    await timelineRef(groupId).add({
      'groupId': groupId,
      'type': 'payment',
      'actorMemberId': data['recordedBy'],
      'actorName': data['recordedByName'] ?? data['recordedBy'],
      'description': '${data['memberName']} paid KES ${amount.toStringAsFixed(0)} - ${data['typeName']}',
      'targetType': 'contribution',
      'targetId': doc.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ContributionRecordModel>> streamContributions(String groupId) {
    return contributionsRef(groupId).orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => ContributionRecordModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Stream<List<ContributionRecordModel>> streamMemberContributions(String groupId, String memberId) {
    return contributionsRef(groupId)
        .where('memberId', isEqualTo: memberId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => ContributionRecordModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<EventModel> createEvent(String groupId, Map<String, dynamic> data) async {
    final doc = await eventsRef(groupId).add(data);
    final snapshot = await doc.get();
    await _groups.doc(groupId).update({'stats.activeEvents': FieldValue.increment(1)});
    await timelineRef(groupId).add({
      'groupId': groupId,
      'type': 'event',
      'actorMemberId': data['createdBy'],
      'actorName': data['createdByName'] ?? data['createdBy'],
      'description': 'Event created: ${data['title']}',
      'targetType': 'event',
      'targetId': doc.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return EventModel.fromMap(snapshot.data()! as Map<String, dynamic>, doc.id);
  }

  Stream<List<EventModel>> streamEvents(String groupId) {
    return eventsRef(groupId).orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> updateEvent(String groupId, String eventId, Map<String, dynamic> data) async {
    await eventsRef(groupId).doc(eventId).update(data);
  }

  Future<ApprovalModel> createApproval(String groupId, Map<String, dynamic> data) async {
    final doc = await approvalsRef(groupId).add(data);
    final snapshot = await doc.get();
    await timelineRef(groupId).add({
      'groupId': groupId,
      'type': 'approval_request',
      'actorMemberId': data['requestedBy'],
      'actorName': data['requestedByName'] ?? data['requestedBy'],
      'description': 'Approval requested: ${data['description']}',
      'targetType': 'approval',
      'targetId': doc.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ApprovalModel.fromMap(snapshot.data()! as Map<String, dynamic>, doc.id);
  }

  Stream<List<ApprovalModel>> streamApprovals(String groupId) {
    return approvalsRef(groupId).orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => ApprovalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Stream<List<ApprovalModel>> streamPendingApprovals(String groupId) {
    return approvalsRef(groupId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => ApprovalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> voteOnApproval(String groupId, String approvalId, String memberId, bool approve, {String? memberName}) async {
    final field = approve ? 'approvedBy' : 'rejectedBy';
    await approvalsRef(groupId).doc(approvalId).update({
      field: FieldValue.arrayUnion([memberId]),
    });
    final doc = await approvalsRef(groupId).doc(approvalId).get();
    final data = doc.data()! as Map<String, dynamic>;
    final approvedBy = List<String>.from(data['approvedBy'] ?? []);
    final requiredCount = (data['requiredCount'] ?? 2) as int;
    if (approvedBy.length >= requiredCount) {
      await approvalsRef(groupId).doc(approvalId).update({
        'status': 'approved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      await timelineRef(groupId).add({
        'groupId': groupId,
        'type': 'approval_resolved',
        'actorMemberId': memberId,
        'actorName': memberName ?? memberId,
        'description': 'Approval resolved: ${data['description']} - Approved',
        'targetType': 'approval',
        'targetId': approvalId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<TimelineEventModel>> streamTimeline(String groupId) {
    return timelineRef(groupId).orderBy('createdAt', descending: true).limit(50).snapshots().map((snap) {
      return snap.docs.map((doc) => TimelineEventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> addDocument(String groupId, Map<String, dynamic> data) async {
    await documentsRef(groupId).add(data);
  }

  Stream<List<DocumentModel>> streamDocuments(String groupId) {
    return documentsRef(groupId).orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => DocumentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> sendAnnouncement(String groupId, Map<String, dynamic> data) async {
    final doc = await announcementsRef(groupId).add(data);
    await timelineRef(groupId).add({
      'groupId': groupId,
      'type': 'announcement',
      'actorMemberId': data['sentBy'],
      'actorName': data['sentByName'],
      'description': 'Announcement: ${data['title']}',
      'targetType': 'announcement',
      'targetId': doc.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AnnouncementModel>> streamAnnouncements(String groupId) {
    return announcementsRef(groupId).orderBy('sentAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => AnnouncementModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
