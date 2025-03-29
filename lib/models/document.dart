import 'verification_status.dart';

class Document {
  final String hash;
  final String title;
  final String owner;
  final String timestamp;
  final bool exists;
  final VerificationStatus status;
  final List<String> verifiers;
  final String rejectionReason;

  Document({
    required this.hash,
    required this.title,
    required this.owner,
    required this.timestamp,
    required this.exists,
    required this.status,
    required this.verifiers,
    required this.rejectionReason,
  });

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      hash: map['hash'] as String? ?? '',
      title: map['title'] as String? ?? '',
      owner: map['owner'] as String? ?? '',
      timestamp: map['timestamp'] as String? ?? '0',
      exists: map['exists'] as bool? ?? false,
      status: map['status'] as VerificationStatus? ?? VerificationStatus.pending,
      verifiers: List<String>.from(map['verifiers'] ?? []),
      rejectionReason: map['rejectionReason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hash': hash,
      'title': title,
      'owner': owner,
      'timestamp': timestamp,
      'exists': exists,
      'status': status,
      'verifiers': verifiers,
      'rejectionReason': rejectionReason,
    };
  }
} 