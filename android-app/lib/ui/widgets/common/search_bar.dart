// lib/ui/widgets/common/search_bar.dart
import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
