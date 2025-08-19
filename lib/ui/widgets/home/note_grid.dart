// lib/ui/widgets/home/note_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../data/models/note_model.dart';
import '../notes/note_card.dart';

class NoteGrid extends StatelessWidget {
  final List<Note> notes;

  const NoteGrid({
    super.key,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 600),
              columnCount: 2,
              child: SlideAnimation(
                verticalOffset: 30.0,
                child: FadeInAnimation(
                  child: NoteCard(
                    note: notes[index],
                    onTap: () => Navigator.of(context).pushNamed(
                      '/note-editor',
                      arguments: notes[index].id,
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: notes.length,
        ),
      ),
    );
  }
}
