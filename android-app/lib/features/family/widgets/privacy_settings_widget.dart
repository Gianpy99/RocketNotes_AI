import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../services/privacy_controls_service.dart';

/// Privacy settings management widget
class PrivacySettingsWidget extends ConsumerStatefulWidget {
  const PrivacySettingsWidget({super.key});

  @override
  ConsumerState<PrivacySettingsWidget> createState() => _PrivacySettingsWidgetState();
}

class _PrivacySettingsWidgetState extends ConsumerState<PrivacySettingsWidget> {
  late PrivacySettings _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Get current user ID from auth service
      const userId = 'current_user_id'; // Replace with actual user ID
      final settings = await ref.read(privacyControlsServiceProvider).getPrivacySettings(userId);
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load privacy settings: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      // TODO: Get current user ID from auth service
      const userId = 'current_user_id'; // Replace with actual user ID
      await ref.read(privacyControlsServiceProvider).updatePrivacySettings(userId, _settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save privacy settings: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Data Privacy Levels'),
            const SizedBox(height: 16),

            _buildPrivacyLevelSelector(
              'Family Data',
              'Data shared with family members',
              _settings.familyDataLevel,
              (value) => setState(() => _settings = _settings.copyWith(familyDataLevel: value)),
            ),

            _buildPrivacyLevelSelector(
              'Personal Data',
              'Your personal information',
              _settings.personalDataLevel,
              (value) => setState(() => _settings = _settings.copyWith(personalDataLevel: value)),
            ),

            _buildPrivacyLevelSelector(
              'Financial Data',
              'Banking and financial information',
              _settings.financialDataLevel,
              (value) => setState(() => _settings = _settings.copyWith(financialDataLevel: value)),
            ),

            _buildPrivacyLevelSelector(
              'Medical Data',
              'Health and medical information',
              _settings.medicalDataLevel,
              (value) => setState(() => _settings = _settings.copyWith(medicalDataLevel: value)),
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Security Settings'),
            const SizedBox(height: 16),

            _buildSwitchSetting(
              'Biometric Authentication',
              'Require biometric authentication for sensitive data access',
              _settings.enableBiometricForSensitive,
              (value) => setState(() => _settings = _settings.copyWith(enableBiometricForSensitive: value)),
            ),

            _buildSwitchSetting(
              'Data Anonymization',
              'Anonymize data for analytics and reporting',
              _settings.enableDataAnonymization,
              (value) => setState(() => _settings = _settings.copyWith(enableDataAnonymization: value)),
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Data Retention'),
            const SizedBox(height: 16),

            _buildRetentionSelector(),

            const SizedBox(height: 32),
            _buildSectionHeader('Data Management'),
            const SizedBox(height: 16),

            _buildActionButton(
              'Export My Data',
              'Download a copy of all your data',
              Icons.download,
              _exportData,
            ),

            _buildActionButton(
              'Clear All Data',
              'Permanently delete all your data (irreversible)',
              Icons.delete_forever,
              _showClearDataDialog,
              isDestructive: true,
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Privacy Information'),
            const SizedBox(height: 16),

            _buildInfoCard(
              'Data Encryption',
              'All sensitive data is encrypted using AES-256 encryption with unique keys stored securely on your device.',
            ),

            _buildInfoCard(
              'Access Logging',
              'All access to your data is logged for security and compliance purposes.',
            ),

            _buildInfoCard(
              'GDPR Compliance',
              'We comply with GDPR and other privacy regulations. You have full control over your data.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildPrivacyLevelSelector(
    String title,
    String subtitle,
    PrivacyLevel currentLevel,
    ValueChanged<PrivacyLevel> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: PrivacyLevel.values.map((level) {
                final isSelected = level == currentLevel;
                return ChoiceChip(
                  label: Text(_getPrivacyLevelLabel(level)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onChanged(level);
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionSelector() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Retention Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Automatically delete old data after this period',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _settings.dataRetentionDays,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 days')),
                DropdownMenuItem(value: 90, child: Text('90 days')),
                DropdownMenuItem(value: 180, child: Text('6 months')),
                DropdownMenuItem(value: 365, child: Text('1 year')),
                DropdownMenuItem(value: 730, child: Text('2 years')),
                DropdownMenuItem(value: -1, child: Text('Never delete')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _settings = _settings.copyWith(dataRetentionDays: value));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? Colors.red : AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? Colors.red : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[800],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPrivacyLevelLabel(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return 'Public';
      case PrivacyLevel.private:
        return 'Private';
      case PrivacyLevel.sensitive:
        return 'Sensitive';
    }
  }

  Future<void> _exportData() async {
    // TODO: Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export feature coming soon')),
    );
  }

  Future<void> _showClearDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This action will permanently delete all your data from the app. This cannot be undone. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _clearAllData();
    }
  }

  Future<void> _clearAllData() async {
    try {
      // TODO: Get current user ID from auth service
      const userId = 'current_user_id'; // Replace with actual user ID
      await ref.read(privacyControlsServiceProvider).clearAllUserData(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data has been cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear data: $e')),
        );
      }
    }
  }
}

extension PrivacySettingsExtension on PrivacySettings {
  PrivacySettings copyWith({
    PrivacyLevel? familyDataLevel,
    PrivacyLevel? personalDataLevel,
    PrivacyLevel? financialDataLevel,
    PrivacyLevel? medicalDataLevel,
    bool? enableBiometricForSensitive,
    bool? enableDataAnonymization,
    int? dataRetentionDays,
  }) {
    return PrivacySettings(
      familyDataLevel: familyDataLevel ?? this.familyDataLevel,
      personalDataLevel: personalDataLevel ?? this.personalDataLevel,
      financialDataLevel: financialDataLevel ?? this.financialDataLevel,
      medicalDataLevel: medicalDataLevel ?? this.medicalDataLevel,
      enableBiometricForSensitive: enableBiometricForSensitive ?? this.enableBiometricForSensitive,
      enableDataAnonymization: enableDataAnonymization ?? this.enableDataAnonymization,
      dataRetentionDays: dataRetentionDays ?? this.dataRetentionDays,
    );
  }
}
