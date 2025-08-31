// test/unit/models/note_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rocketnotes_ai/data/models/note.dart';

void main() {
  group('Note Model Tests', () {
    late Note testNote;

    setUp(() {
      testNote = Note(
        id: 'test-id',
        title: 'Test Note',
        content: 'This is a test note content',
        tags: ['test', 'flutter'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );
    });

    group('Constructor and Properties', () {
      test('should create note with all properties', () {
        expect(testNote.id, equals('test-id'));
        expect(testNote.title, equals('Test Note'));
        expect(testNote.content, equals('This is a test note content'));
        expect(testNote.tags, equals(['test', 'flutter']));
        expect(testNote.createdAt, equals(DateTime(2024, 1, 1)));
        expect(testNote.updatedAt, equals(DateTime(2024, 1, 2)));
      });

      test('should create note with minimal properties', () {
        final minimalNote = Note(
          id: 'minimal-id',
          title: 'Minimal',
          content: 'Content',
        );

        expect(minimalNote.id, equals('minimal-id'));
        expect(minimalNote.title, equals('Minimal'));
        expect(minimalNote.content, equals('Content'));
        expect(minimalNote.tags, isEmpty);
        expect(minimalNote.createdAt, isNull);
        expect(minimalNote.updatedAt, isNull);
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        final json = testNote.toJson();

        expect(json['id'], equals('test-id'));
        expect(json['title'], equals('Test Note'));
        expect(json['content'], equals('This is a test note content'));
        expect(json['tags'], equals(['test', 'flutter']));
        expect(json['createdAt'], equals('2024-01-01T00:00:00.000'));
        expect(json['updatedAt'], equals('2024-01-02T00:00:00.000'));
      });

      test('should create from JSON correctly', () {
        final json = {
          'id': 'json-id',
          'title': 'JSON Note',
          'content': 'JSON content',
          'tags': ['json', 'test'],
          'createdAt': '2024-01-01T00:00:00.000',
          'updatedAt': '2024-01-02T00:00:00.000',
        };

        final note = Note.fromJson(json);

        expect(note.id, equals('json-id'));
        expect(note.title, equals('JSON Note'));
        expect(note.content, equals('JSON content'));
        expect(note.tags, equals(['json', 'test']));
        expect(note.createdAt, equals(DateTime(2024, 1, 1)));
        expect(note.updatedAt, equals(DateTime(2024, 1, 2)));
      });

      test('should handle null dates in JSON', () {
        final json = {
          'id': 'null-dates',
          'title': 'Title',
          'content': 'Content',
          'tags': <String>[],
        };

        final note = Note.fromJson(json);

        expect(note.createdAt, isNull);
        expect(note.updatedAt, isNull);
      });
    });

    group('Utility Methods', () {
      test('should calculate word count correctly', () {
        expect(testNote.wordCount, equals(6)); // "This is a test note content"
      });

      test('should handle empty content word count', () {
        final emptyNote = Note(id: '1', title: 'Title', content: '');
        expect(emptyNote.wordCount, equals(0));
      });

      test('should check if note is recent (within 24 hours)', () {
        final recentNote = Note(
          id: '1',
          title: 'Recent',
          content: 'Content',
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        );

        final oldNote = Note(
          id: '2',
          title: 'Old',
          content: 'Content',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        );

        expect(recentNote.isRecent, isTrue);
        expect(oldNote.isRecent, isFalse);
      });

      test('should handle null createdAt for isRecent', () {
        final noDateNote = Note(id: '1', title: 'Title', content: 'Content');
        expect(noDateNote.isRecent, isFalse);
      });

      test('should check if note matches search query', () {
        expect(testNote.matchesSearch('test'), isTrue);
        expect(testNote.matchesSearch('Note'), isTrue);
        expect(testNote.matchesSearch('content'), isTrue);
        expect(testNote.matchesSearch('flutter'), isTrue);
        expect(testNote.matchesSearch('nonexistent'), isFalse);
      });

      test('should be case insensitive for search', () {
        expect(testNote.matchesSearch('TEST'), isTrue);
        expect(testNote.matchesSearch('note'), isTrue);
        expect(testNote.matchesSearch('FLUTTER'), isTrue);
      });

      test('should handle empty search query', () {
        expect(testNote.matchesSearch(''), isTrue);
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when all properties match', () {
        final note1 = Note(
          id: 'same-id',
          title: 'Same Title',
          content: 'Same Content',
          tags: ['tag1', 'tag2'],
          createdAt: DateTime(2024, 1, 1),
        );

        final note2 = Note(
          id: 'same-id',
          title: 'Same Title',
          content: 'Same Content',
          tags: ['tag1', 'tag2'],
          createdAt: DateTime(2024, 1, 1),
        );

        expect(note1, equals(note2));
        expect(note1.hashCode, equals(note2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final note1 = Note(id: '1', title: 'Title 1', content: 'Content');
        final note2 = Note(id: '2', title: 'Title 2', content: 'Content');

        expect(note1, isNot(equals(note2)));
        expect(note1.hashCode, isNot(equals(note2.hashCode)));
      });
    });

    group('CopyWith Method', () {
      test('should copy with new values', () {
        final updatedNote = testNote.copyWith(
          title: 'Updated Title',
          content: 'Updated Content',
        );

        expect(updatedNote.id, equals(testNote.id)); // unchanged
        expect(updatedNote.title, equals('Updated Title')); // changed
        expect(updatedNote.content, equals('Updated Content')); // changed
        expect(updatedNote.tags, equals(testNote.tags)); // unchanged
      });

      test('should keep original values when not specified', () {
        final copiedNote = testNote.copyWith();

        expect(copiedNote.id, equals(testNote.id));
        expect(copiedNote.title, equals(testNote.title));
        expect(copiedNote.content, equals(testNote.content));
        expect(copiedNote.tags, equals(testNote.tags));
      });
    });

    group('Edge Cases', () {
      test('should handle very long content', () {
        final longContent = 'word ' * 1000; // 1000 words
        final longNote = Note(id: '1', title: 'Long', content: longContent);

        expect(longNote.wordCount, equals(1000));
        expect(longNote.matchesSearch('word'), isTrue);
      });

      test('should handle special characters in content', () {
        final specialNote = Note(
          id: '1',
          title: 'Special @#$%',
          content: 'Content with émojis 🚀 and spëcial chars',
          tags: ['special-chars'],
        );

        expect(specialNote.matchesSearch('émojis'), isTrue);
        expect(specialNote.matchesSearch('🚀'), isTrue);
        expect(specialNote.matchesSearch('spëcial'), isTrue);
      });

      test('should handle empty and whitespace-only content', () {
        final emptyNote = Note(id: '1', title: 'Empty', content: '');
        final whitespaceNote = Note(id: '2', title: 'Whitespace', content: '   \n\t  ');

        expect(emptyNote.wordCount, equals(0));
        expect(whitespaceNote.wordCount, equals(0));
      });
    });
  });
}
