import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/complaint_remote_datasource.dart';

final complaintRemoteDataSourceProvider = Provider<ComplaintRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ComplaintRemoteDataSourceImpl(dioClient: dioClient);
});

enum ComplaintStateStatus { initial, loading, success, error }

class ComplaintState {
  final ComplaintStateStatus status;
  final String? errorMessage;
  final String? successMessage;

  const ComplaintState({
    this.status = ComplaintStateStatus.initial,
    this.errorMessage,
    this.successMessage,
  });

  ComplaintState copyWith({
    ComplaintStateStatus? status,
    String? errorMessage,
    String? successMessage,
  }) {
    return ComplaintState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final complaintNotifierProvider =
    NotifierProvider<ComplaintNotifier, ComplaintState>(() => ComplaintNotifier());

class ComplaintNotifier extends Notifier<ComplaintState> {
  @override
  ComplaintState build() {
    return const ComplaintState();
  }

  ComplaintRemoteDataSource get _remoteDataSource =>
      ref.read(complaintRemoteDataSourceProvider);

  Future<bool> submitComplaint({
    required String subject,
    required String description,
    required String phoneNumber,
    File? imageFile,
  }) async {
    state = const ComplaintState(status: ComplaintStateStatus.loading);
    try {
      await _remoteDataSource.submitComplaint(
        subject: subject,
        description: description,
        phoneNumber: phoneNumber,
        imageFile: imageFile,
      );
      state = const ComplaintState(
        status: ComplaintStateStatus.success,
        successMessage: 'Complaint submitted successfully!',
      );
      return true;
    } catch (e) {
      state = ComplaintState(
        status: ComplaintStateStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void reset() {
    state = const ComplaintState();
  }
}
