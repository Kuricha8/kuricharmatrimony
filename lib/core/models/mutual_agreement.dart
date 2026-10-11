import 'enums.dart';

class MutualAgreement {
  final String id;
  final String brideId;
  final String groomId;
  final bool brideSigned;
  final bool groomSigned;
  final bool bridePaid;
  final bool groomPaid;
  final int totalEscrowBalance;
  final DisputeStatus disputeStatus;
  final String? cancellationReason;

  const MutualAgreement({
    required this.id,
    required this.brideId,
    required this.groomId,
    this.brideSigned = false,
    this.groomSigned = false,
    this.bridePaid = false,
    this.groomPaid = false,
    this.totalEscrowBalance = 0,
    this.disputeStatus = DisputeStatus.none,
    this.cancellationReason,
  });

  bool get isFullyActive =>
      brideSigned && groomSigned && bridePaid && groomPaid;

  MutualAgreement copyWith({
    String? id,
    String? brideId,
    String? groomId,
    bool? brideSigned,
    bool? groomSigned,
    bool? bridePaid,
    bool? groomPaid,
    int? totalEscrowBalance,
    DisputeStatus? disputeStatus,
    String? cancellationReason,
  }) {
    return MutualAgreement(
      id: id ?? this.id,
      brideId: brideId ?? this.brideId,
      groomId: groomId ?? this.groomId,
      brideSigned: brideSigned ?? this.brideSigned,
      groomSigned: groomSigned ?? this.groomSigned,
      bridePaid: bridePaid ?? this.bridePaid,
      groomPaid: groomPaid ?? this.groomPaid,
      totalEscrowBalance: totalEscrowBalance ?? this.totalEscrowBalance,
      disputeStatus: disputeStatus ?? this.disputeStatus,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
