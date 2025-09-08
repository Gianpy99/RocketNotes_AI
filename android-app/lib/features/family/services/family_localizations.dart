import 'package:flutter/material.dart';

/// Localization strings for family features
class FamilyLocalizations {
  static const Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      // General
      'family': 'Family',
      'members': 'Members',
      'notes': 'Notes',
      'settings': 'Settings',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'remove': 'Remove',
      'confirm': 'Confirm',
      'retry': 'Retry',

      // Family creation
      'create_family': 'Create Family',
      'family_name': 'Family Name',
      'family_description': 'Description (optional)',
      'create_family_hint': 'Enter a name for your family',
      'creating_family': 'Creating family...',
      'family_created': 'Family created successfully!',

      // Member management
      'invite_member': 'Invite Member',
      'member_email': 'Email Address',
      'member_role': 'Role',
      'member_permissions': 'Permissions',
      'send_invitation': 'Send Invitation',
      'invitation_sent': 'Invitation sent successfully!',
      'member_added': 'Member added to family',
      'member_removed': 'Member removed from family',
      'role_admin': 'Admin',
      'role_member': 'Member',
      'role_viewer': 'Viewer',

      // Permissions
      'can_view': 'Can view notes',
      'can_edit': 'Can edit notes',
      'can_comment': 'Can comment on notes',
      'can_delete': 'Can delete notes',
      'can_share': 'Can share notes',
      'can_export': 'Can export notes',
      'can_invite': 'Can invite members',

      // Notes sharing
      'share_note': 'Share Note',
      'shared_notes': 'Shared Notes',
      'note_shared': 'Note shared successfully!',
      'note_permissions': 'Note Permissions',
      'select_members': 'Select family members',
      'all_members': 'All Members',
      'my_shares': 'My Shares',
      'received': 'Received',

      // Comments
      'comments': 'Comments',
      'add_comment': 'Add a comment...',
      'comment_added': 'Comment added',
      'reply': 'Reply',
      'like': 'Like',
      'unlike': 'Unlike',
      'edit_comment': 'Edit comment',
      'delete_comment': 'Delete comment',

      // Settings
      'family_settings': 'Family Settings',
      'privacy_settings': 'Privacy Settings',
      'notification_settings': 'Notification Settings',
      'delete_family': 'Delete Family',
      'leave_family': 'Leave Family',
      'confirm_delete_family': 'Are you sure you want to delete this family? This action cannot be undone.',
      'confirm_leave_family': 'Are you sure you want to leave this family?',

      // Error messages
      'network_error': 'Network connection error. Please check your internet connection.',
      'permission_denied': 'You don\'t have permission to perform this action.',
      'invalid_input': 'Please check your input and try again.',
      'server_error': 'Server is temporarily unavailable. Please try again later.',
      'family_not_found': 'Family not found.',
      'member_not_found': 'Member not found.',
      'note_not_found': 'Note not found.',
      'invitation_expired': 'Invitation has expired.',
      'invitation_already_used': 'Invitation has already been used.',

      // Accessibility
      'accessibility_family_list': 'List of family members',
      'accessibility_member_card': 'Family member information',
      'accessibility_invite_button': 'Invite new family member',
      'accessibility_settings_button': 'Family settings',
      'accessibility_back_button': 'Go back',
      'accessibility_menu_button': 'Open menu',

      // Empty states
      'no_members': 'No members yet. Invite someone to get started!',
      'no_shared_notes': 'No shared notes yet. Share a note to get started!',
      'no_comments': 'No comments yet. Be the first to comment!',
      'no_invitations': 'No pending invitations.',

      // Time
      'just_now': 'Just now',
      'minutes_ago': 'minutes ago',
      'hours_ago': 'hours ago',
      'days_ago': 'days ago',
      'today': 'Today',
      'yesterday': 'Yesterday',
    },
    'it': {
      // General
      'family': 'Famiglia',
      'members': 'Membri',
      'notes': 'Note',
      'settings': 'Impostazioni',
      'loading': 'Caricamento...',
      'error': 'Errore',
      'success': 'Successo',
      'cancel': 'Annulla',
      'save': 'Salva',
      'delete': 'Elimina',
      'edit': 'Modifica',
      'add': 'Aggiungi',
      'remove': 'Rimuovi',
      'confirm': 'Conferma',
      'retry': 'Riprova',

      // Family creation
      'create_family': 'Crea Famiglia',
      'family_name': 'Nome Famiglia',
      'family_description': 'Descrizione (opzionale)',
      'create_family_hint': 'Inserisci un nome per la tua famiglia',
      'creating_family': 'Creazione famiglia...',
      'family_created': 'Famiglia creata con successo!',

      // Member management
      'invite_member': 'Invita Membro',
      'member_email': 'Indirizzo Email',
      'member_role': 'Ruolo',
      'member_permissions': 'Permessi',
      'send_invitation': 'Invia Invito',
      'invitation_sent': 'Invito inviato con successo!',
      'member_added': 'Membro aggiunto alla famiglia',
      'member_removed': 'Membro rimosso dalla famiglia',
      'role_admin': 'Amministratore',
      'role_member': 'Membro',
      'role_viewer': 'Visualizzatore',

      // Permissions
      'can_view': 'Può visualizzare le note',
      'can_edit': 'Può modificare le note',
      'can_comment': 'Può commentare le note',
      'can_delete': 'Può eliminare le note',
      'can_share': 'Può condividere le note',
      'can_export': 'Può esportare le note',
      'can_invite': 'Può invitare membri',

      // Notes sharing
      'share_note': 'Condividi Nota',
      'shared_notes': 'Note Condivise',
      'note_shared': 'Nota condivisa con successo!',
      'note_permissions': 'Permessi Nota',
      'select_members': 'Seleziona membri della famiglia',
      'all_members': 'Tutti i Membri',
      'my_shares': 'Le Mie Condivisioni',
      'received': 'Ricevute',

      // Comments
      'comments': 'Commenti',
      'add_comment': 'Aggiungi un commento...',
      'comment_added': 'Commento aggiunto',
      'reply': 'Rispondi',
      'like': 'Mi piace',
      'unlike': 'Non mi piace più',
      'edit_comment': 'Modifica commento',
      'delete_comment': 'Elimina commento',

      // Settings
      'family_settings': 'Impostazioni Famiglia',
      'privacy_settings': 'Impostazioni Privacy',
      'notification_settings': 'Impostazioni Notifiche',
      'delete_family': 'Elimina Famiglia',
      'leave_family': 'Lascia Famiglia',
      'confirm_delete_family': 'Sei sicuro di voler eliminare questa famiglia? Questa azione non può essere annullata.',
      'confirm_leave_family': 'Sei sicuro di voler lasciare questa famiglia?',

      // Error messages
      'network_error': 'Errore di connessione di rete. Controlla la tua connessione internet.',
      'permission_denied': 'Non hai il permesso di eseguire questa azione.',
      'invalid_input': 'Controlla i tuoi dati inseriti e riprova.',
      'server_error': 'Il server è temporaneamente non disponibile. Riprova più tardi.',
      'family_not_found': 'Famiglia non trovata.',
      'member_not_found': 'Membro non trovato.',
      'note_not_found': 'Nota non trovata.',
      'invitation_expired': 'L\'invito è scaduto.',
      'invitation_already_used': 'L\'invito è già stato utilizzato.',

      // Accessibility
      'accessibility_family_list': 'Elenco dei membri della famiglia',
      'accessibility_member_card': 'Informazioni membro della famiglia',
      'accessibility_invite_button': 'Invita nuovo membro della famiglia',
      'accessibility_settings_button': 'Impostazioni famiglia',
      'accessibility_back_button': 'Torna indietro',
      'accessibility_menu_button': 'Apri menu',

      // Empty states
      'no_members': 'Ancora nessun membro. Invita qualcuno per iniziare!',
      'no_shared_notes': 'Ancora nessuna nota condivisa. Condividi una nota per iniziare!',
      'no_comments': 'Ancora nessun commento. Sii il primo a commentare!',
      'no_invitations': 'Nessun invito in sospeso.',

      // Time
      'just_now': 'Proprio ora',
      'minutes_ago': 'minuti fa',
      'hours_ago': 'ore fa',
      'days_ago': 'giorni fa',
      'today': 'Oggi',
      'yesterday': 'Ieri',
    },
  };

  /// Get localized string
  static String get(BuildContext context, String key, [List<String>? args]) {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;

    final strings = _localizedStrings[languageCode] ?? _localizedStrings['en']!;
    var result = strings[key] ?? key;

    // Replace arguments if provided
    if (args != null) {
      for (var i = 0; i < args.length; i++) {
        result = result.replaceAll('{$i}', args[i]);
      }
    }

    return result;
  }

  /// Get pluralized string
  static String plural(BuildContext context, String key, int count, [List<String>? args]) {
    final singular = get(context, key, args);
    if (count == 1) return singular;

    // Try to find plural version
    final pluralKey = '${key}_plural';
    final plural = get(context, pluralKey, args);
    return plural != pluralKey ? plural : '$singular ($count)';
  }

  /// Format time ago
  static String timeAgo(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return get(context, 'just_now');
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} ${get(context, 'minutes_ago')}';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ${get(context, 'hours_ago')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${get(context, 'days_ago')}';
    } else if (difference.inDays == 0) {
      return get(context, 'today');
    } else if (difference.inDays == 1) {
      return get(context, 'yesterday');
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Check if locale is supported
  static bool isSupported(Locale locale) {
    return _localizedStrings.containsKey(locale.languageCode);
  }

  /// Get supported locales
  static List<Locale> get supportedLocales {
    return _localizedStrings.keys.map((code) => Locale(code)).toList();
  }
}

/// Extension for easy access to localizations
extension FamilyLocalizationExtension on BuildContext {
  String getLocalized(String key, [List<String>? args]) {
    return FamilyLocalizations.get(this, key, args);
  }

  String getPlural(String key, int count, [List<String>? args]) {
    return FamilyLocalizations.plural(this, key, count, args);
  }

  String formatTimeAgo(DateTime dateTime) {
    return FamilyLocalizations.timeAgo(this, dateTime);
  }
}

/// Delegate for Flutter's localization system
class FamilyLocalizationsDelegate extends LocalizationsDelegate<FamilyLocalizations> {
  const FamilyLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return FamilyLocalizations.isSupported(locale);
  }

  @override
  Future<FamilyLocalizations> load(Locale locale) async {
    // Since FamilyLocalizations is not a real widget, we return a dummy instance
    return FamilyLocalizations as FamilyLocalizations;
  }

  @override
  bool shouldReload(FamilyLocalizationsDelegate old) => false;
}
