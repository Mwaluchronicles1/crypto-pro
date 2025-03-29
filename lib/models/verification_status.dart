enum VerificationStatus {
  pending(0),
  approved(1),
  rejected(2);

  final int value;
  const VerificationStatus(this.value);

  static VerificationStatus fromInt(int value) {
    return VerificationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => VerificationStatus.pending,
    );
  }

  String get name {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.approved:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }
} 