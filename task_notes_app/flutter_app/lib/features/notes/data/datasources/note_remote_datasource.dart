import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/note_model.dart';

abstract class NoteRemoteDataSource {
  Future<List<NoteModel>> getNotes();
  Future<NoteModel> createNote(Map<String, dynamic> payload);
  Future<NoteModel> updateNote(String id, Map<String, dynamic> payload);
  Future<void> deleteNote(String id);
}

class NoteRemoteDataSourceImpl implements NoteRemoteDataSource {
  final DioClient dioClient;

  NoteRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<NoteModel>> getNotes() async {
    try {
      final response = await dioClient.dio.get('/notes');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => NoteModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to fetch notes',
        statusCode: e.response?.statusCode,
        errorCode: e.response?.data['errorCode'],
      );
    }
  }

  @override
  Future<NoteModel> createNote(Map<String, dynamic> payload) async {
    try {
      final response = await dioClient.dio.post('/notes', data: payload);
      return NoteModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to create note',
        statusCode: e.response?.statusCode,
        errorCode: e.response?.data['errorCode'],
      );
    }
  }

  @override
  Future<NoteModel> updateNote(String id, Map<String, dynamic> payload) async {
    try {
      final response = await dioClient.dio.put('/notes/$id', data: payload);
      return NoteModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw ConflictException(
          e.response?.data['message'] ?? 'Conflict detected',
          e.response?.data['details']?['serverRecord'] ?? {},
        );
      }
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to update note',
        statusCode: e.response?.statusCode,
        errorCode: e.response?.data['errorCode'],
      );
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    try {
      await dioClient.dio.delete('/notes/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to delete note',
        statusCode: e.response?.statusCode,
        errorCode: e.response?.data['errorCode'],
      );
    }
  }
}
