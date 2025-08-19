// lib/data/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note_model.dart';

class ApiService {
  static const String baseUrl = 'https://your-api.com/api'; // Replace with your backend URL
  final String userId;
  
  ApiService({required this.userId});
  
  Future<List<NoteModel>> fetchNotes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notes?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NoteModel.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch notes');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<NoteModel> createNote(NoteModel note) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(note.toJson()),
      );
      
      if (response.statusCode == 201) {
        return NoteModel.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to create note');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<NoteModel> updateNote(NoteModel note) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notes/${note.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(note.toJson()),
      );
      
      if (response.statusCode == 200) {
        return NoteModel.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to update note');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<void> deleteNote(String noteId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notes/$noteId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete note');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
