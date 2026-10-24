import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

abstract class ComplaintRemoteDataSource {
  Future<void> submitComplaint({
    required String subject,
    required String description,
    required String phoneNumber,
    File? imageFile,
  });
}

class ComplaintRemoteDataSourceImpl implements ComplaintRemoteDataSource {
  final DioClient dioClient;

  ComplaintRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<void> submitComplaint({
    required String subject,
    required String description,
    required String phoneNumber,
    File? imageFile,
  }) async {
    try {
      final formData = FormData();

      formData.fields.add(MapEntry('phoneNumber', phoneNumber.trim()));
      formData.fields.add(MapEntry('text', '[$subject] ${description.trim()}'));

      if (imageFile != null) {
        final fileName = imageFile.path.split('/').last;
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              imageFile.path,
              filename: fileName,
            ),
          ),
        );
      }

      final response = await dioClient.dio.post(
        ApiConstants.complaints,
        data: formData,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final message = response.data is Map
            ? response.data['message'] ?? 'Failed to submit complaint'
            : 'Failed to submit complaint';
        throw ApiException(
          message: message,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to submit complaint. Please try again.';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'].toString();
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }
      throw ApiException(message: errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }
}
