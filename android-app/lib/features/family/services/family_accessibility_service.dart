import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../../core/constants/app_colors.dart';

/// Accessibility service for family screens
class FamilyAccessibilityService {
  /// Create accessible button with proper semantics
  static Widget accessibleButton({
    required Widget child,
    required VoidCallback onPressed,
    required String label,
    String? hint,
    bool enabled = true,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      enabled: enabled,
      button: true,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }

  /// Create accessible text field
  static Widget accessibleTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? errorText,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      textField: true,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
        ),
      ),
    );
  }

  /// Create accessible card with proper semantics
  static Widget accessibleCard({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: onTap != null,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Create accessible list item
  static Widget accessibleListItem({
    required Widget child,
    required String label,
    String? hint,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      selected: selected,
      button: onTap != null,
      child: ListTile(
        onTap: onTap,
        title: child,
        selected: selected,
        selectedTileColor: AppColors.primaryBlue.withValues(alpha: 0.1),
      ),
    );
  }

  /// Create accessible dialog
  static Future<T?> showAccessibleDialog<T>({
    required BuildContext context,
    required Widget title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: AlertDialog(
          title: title,
          content: content,
          actions: actions,
          semanticLabel: _getTextFromWidget(title) ?? 'Dialog',
        ),
      ),
    );
  }

  /// Create accessible loading indicator
  static Widget accessibleLoadingIndicator({
    String label = 'Loading',
    double size = 24,
  }) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
        ),
      ),
    );
  }

  /// Create accessible switch
  static Widget accessibleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String label,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      toggled: value,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primaryBlue,
      ),
    );
  }

  /// Create accessible checkbox
  static Widget accessibleCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      checked: value,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryBlue,
      ),
    );
  }

  /// Create accessible radio button
  static Widget accessibleRadio<T>({
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
    required String label,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      checked: value == groupValue,
      child: Radio<T>(
        value: value,
        groupValue: groupValue, // ignore: deprecated_member_use
        onChanged: onChanged, // ignore: deprecated_member_use
        activeColor: AppColors.primaryBlue,
      ),
    );
  }

  /// Create accessible tab bar
  static Widget accessibleTabBar({
    required List<Widget> tabs,
    required TabController controller,
    required String label,
  }) {
    return Semantics(
      label: label,
      child: TabBar(
        controller: controller,
        tabs: tabs,
        labelColor: AppColors.primaryBlue,
        indicatorColor: AppColors.primaryBlue,
      ),
    );
  }

  /// Create accessible app bar
  static PreferredSizeWidget accessibleAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    return AppBar(
      title: Semantics(
        header: true,
        child: Text(title),
      ),
      actions: actions?.map((action) => Semantics(
        button: true,
        child: action,
      )).toList(),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
    );
  }

  /// Create accessible floating action button
  static Widget accessibleFAB({
    required VoidCallback onPressed,
    required Widget child,
    required String label,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        child: child,
      ),
    );
  }

  /// Create accessible dropdown
  static Widget accessibleDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required String label,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
        ),
      ),
    );
  }

  /// Announce content changes for screen readers
  static void announceContentChange(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Create accessible image
  static Widget accessibleImage({
    required String imageUrl,
    required String label,
    String? hint,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      image: true,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return accessibleLoadingIndicator(label: 'Loading image');
        },
        errorBuilder: (context, error, stackTrace) {
          return Semantics(
            label: 'Image failed to load',
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  /// Create accessible avatar
  static Widget accessibleAvatar({
    required String name,
    String? imageUrl,
    double radius = 24,
  }) {
    return Semantics(
      label: 'Avatar for $name',
      image: imageUrl != null,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
        child: imageUrl == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.6,
                ),
              )
            : null,
      ),
    );
  }

  /// Create accessible chip
  static Widget accessibleChip({
    required String label,
    VoidCallback? onDeleted,
    bool selected = false,
  }) {
    return Semantics(
      label: label,
      button: onDeleted != null,
      selected: selected,
      child: Chip(
        label: Text(label),
        onDeleted: onDeleted,
        backgroundColor: selected ? AppColors.primaryBlue.withValues(alpha: 0.1) : null,
        deleteIconColor: Colors.red,
      ),
    );
  }

  /// Create accessible expansion tile
  static Widget accessibleExpansionTile({
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Semantics(
      label: title,
      child: ExpansionTile(
        title: Text(title),
        initiallyExpanded: initiallyExpanded,
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.grey[50],
        children: children,
      ),
    );
  }

  /// Helper method to safely extract text from a widget
  static String? _getTextFromWidget(Widget? widget) {
    if (widget is Text) {
      return widget.data;
    }
    return null;
  }
}

/// Extension methods for accessibility
extension AccessibilityExtensions on Widget {
  /// Add accessibility label
  Widget withAccessibilityLabel(String label, {String? hint}) {
    return Semantics(
      label: label,
      hint: hint,
      child: this,
    );
  }

  /// Mark as button for accessibility
  Widget asAccessibilityButton({String? label, String? hint}) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      child: this,
    );
  }

  /// Mark as heading for accessibility
  Widget asAccessibilityHeading(int level, {String? label}) {
    return Semantics(
      header: true,
      namesRoute: true,
      label: label,
      child: this,
    );
  }

  /// Mark as image for accessibility
  Widget asAccessibilityImage({String? label, String? hint}) {
    return Semantics(
      label: label,
      hint: hint,
      image: true,
      child: this,
    );
  }
}
