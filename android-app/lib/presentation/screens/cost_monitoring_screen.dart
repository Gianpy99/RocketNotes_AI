// ==========================================
// lib/presentation/screens/cost_monitoring_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/cost_monitoring_service.dart';

class CostMonitoringScreen extends ConsumerStatefulWidget {
  const CostMonitoringScreen({super.key});

  @override
  ConsumerState<CostMonitoringScreen> createState() => _CostMonitoringScreenState();
}

class _CostMonitoringScreenState extends ConsumerState<CostMonitoringScreen> {
  final CostMonitoringService _costService = CostMonitoringService();
  Map<String, dynamic>? _costSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCostSummary();
  }

  Future<void> _loadCostSummary() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _costService.getCostSummary();
      setState(() {
        _costSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel caricamento dei dati: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Monitoraggio Costi AI'),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCostSummary,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _costSummary == null
              ? const Center(child: Text('Errore nel caricamento dei dati'))
              : RefreshIndicator(
                  onRefresh: _loadCostSummary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCostOverview(),
                        const SizedBox(height: 24),
                        _buildDailyUsage(),
                        const SizedBox(height: 24),
                        _buildMonthlyUsage(),
                        const SizedBox(height: 24),
                        _buildProviderBreakdown(),
                        const SizedBox(height: 24),
                        _buildOptimizationTips(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCostOverview() {
    final summary = _costSummary!;
    final dailyCost = summary['dailyCost'] as double;
    final monthlyCost = summary['monthlyCost'] as double;
    final isNearDailyLimit = summary['isNearDailyLimit'] as bool;
    final isNearMonthlyLimit = summary['isNearMonthlyLimit'] as bool;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Panoramica Costi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCostCard(
                    'Oggi',
                    '\$${dailyCost.toStringAsFixed(4)}',
                    '\$${summary['dailyLimit']}',
                    summary['dailyPercentage'] as double,
                    isNearDailyLimit ? Colors.orange : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCostCard(
                    'Questo Mese',
                    '\$${monthlyCost.toStringAsFixed(2)}',
                    '\$${summary['monthlyLimit']}',
                    summary['monthlyPercentage'] as double,
                    isNearMonthlyLimit ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostCard(String title, String current, String limit, double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            current,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            'di $limit',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyUsage() {
    final summary = _costSummary!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Utilizzo Giornaliero',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildUsageRow('Richieste Totali', '${summary['totalRequests']}', Icons.api),
            _buildUsageRow('Gemini (Gratuito)', '${summary['geminiRequests']} / 25', Icons.flash_on),
            _buildUsageRow('Grounding Gemini', '${summary['geminiGrounding']} / 1500', Icons.public),
            _buildUsageRow('OpenAI', '${summary['openaiRequests']}', Icons.psychology),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyUsage() {
    final summary = _costSummary!;
    final shouldSwitchToFree = summary['shouldSwitchToFree'] as bool;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Utilizzo Mensile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildUsageRow(
              'Costo Totale',
              '\$${summary['monthlyCost'].toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            _buildUsageRow(
              'Budget Rimanente',
              '\$${summary['monthlyRemaining'].toStringAsFixed(2)}',
              Icons.savings,
            ),
            if (shouldSwitchToFree) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Si consiglia di passare ai modelli gratuiti per evitare di superare il budget.',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderBreakdown() {
    final summary = _costSummary!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Breakdown per Provider',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProviderCard(
              'Gemini',
              '${summary['geminiRequests']} richieste',
              '\$0.00 (Gratuito)',
              Colors.blue,
              '${summary['geminiFreeLimitRemaining']} richieste rimanenti oggi',
            ),
            const SizedBox(height: 12),
            _buildProviderCard(
              'OpenAI',
              '${summary['openaiRequests']} richieste',
              '\$${(summary['dailyCost'] as double).toStringAsFixed(4)}',
              Colors.green,
              'Tier attivo: Flex',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Suggerimenti per Ottimizzare i Costi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTip('💡', 'Usa Gemini 2.5 Flash per le richieste gratuite (25/giorno)'),
            _buildTip('⚡', 'Passa a Gemini Flash Lite per analisi semplici'),
            _buildTip('🎯', 'Abilita l\'ottimizzazione automatica dei costi'),
            _buildTip('📊', 'Monitora l\'utilizzo per evitare sorprese'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showSettingsDialog(),
                icon: const Icon(Icons.tune),
                label: const Text('Configura Limiti e Ottimizzazione'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(String name, String requests, String cost, Color color, String details) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                cost,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(requests, style: Theme.of(context).textTheme.bodyMedium),
          Text(details, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => CostSettingsDialog(
        onSettingsUpdated: _loadCostSummary,
      ),
    );
  }
}

class CostSettingsDialog extends StatefulWidget {
  final VoidCallback onSettingsUpdated;

  const CostSettingsDialog({
    super.key,
    required this.onSettingsUpdated,
  });

  @override
  State<CostSettingsDialog> createState() => _CostSettingsDialogState();
}

class _CostSettingsDialogState extends State<CostSettingsDialog> {
  final CostMonitoringService _costService = CostMonitoringService();
  final _dailyLimitController = TextEditingController();
  final _monthlyLimitController = TextEditingController();
  bool _enableOptimization = true;
  bool _preferFreeTier = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final summary = await _costService.getCostSummary();
      setState(() {
        _dailyLimitController.text = summary['dailyLimit'].toString();
        _monthlyLimitController.text = summary['monthlyLimit'].toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _dailyLimitController.dispose();
    _monthlyLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Impostazioni Costi'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _dailyLimitController,
                    decoration: const InputDecoration(
                      labelText: 'Limite Giornaliero (\$)',
                      prefixIcon: Icon(Icons.today),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _monthlyLimitController,
                    decoration: const InputDecoration(
                      labelText: 'Limite Mensile (\$)',
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Ottimizzazione Automatica'),
                    subtitle: const Text('Passa automaticamente ai modelli più economici'),
                    value: _enableOptimization,
                    onChanged: (value) => setState(() => _enableOptimization = value),
                  ),
                  SwitchListTile(
                    title: const Text('Preferisci Tier Gratuiti'),
                    subtitle: const Text('Usa modelli gratuiti quando possibile'),
                    value: _preferFreeTier,
                    onChanged: (value) => setState(() => _preferFreeTier = value),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: _saveSettings,
          child: const Text('Salva'),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    try {
      final dailyLimit = double.tryParse(_dailyLimitController.text) ?? 5.0;
      final monthlyLimit = double.tryParse(_monthlyLimitController.text) ?? 100.0;

      await _costService.updateSpendingLimits(
        dailyLimit: dailyLimit,
        monthlyLimit: monthlyLimit,
      );

      await _costService.updateOptimizationSettings(
        enableCostOptimization: _enableOptimization,
        preferFreeTier: _preferFreeTier,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impostazioni salvate con successo')),
        );
        widget.onSettingsUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel salvare le impostazioni: $e')),
        );
      }
    }
  }
}
