import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/history_entry.dart';
import '../../services/history_service.dart';

/// Screen displaying inspection history.
class HistoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNewInspection;

  const HistoryScreen({
    super.key,
    this.onBack,
    this.onNewInspection,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final entries = await HistoryService.getHistory();
    if (mounted) {
      setState(() {
        _history = entries;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEntry(HistoryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text('Delete "${entry.issueTitle}" from history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HistoryService.deleteEntry(entry.id);
      await _loadHistory();
    }
  }

  Future<void> _clearAllHistory() async {
    if (_history.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text('This will permanently delete all inspection history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HistoryService.clearHistory();
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        leading: widget.onBack == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
        actions: [
          if (_history.isNotEmpty && !_isLoading)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllHistory,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmptyState()
              : _buildHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Inspection History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your past inspections will appear here',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          if (widget.onNewInspection != null)
            ElevatedButton.icon(
              onPressed: widget.onNewInspection,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Start Inspection'),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final entry = _history[index];
          return _HistoryCard(
            entry: entry,
            onTap: () => _showEntryDetails(entry),
            onDelete: () => _deleteEntry(entry),
          );
        },
      ),
    );
  }

  void _showEntryDetails(HistoryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildIssueIcon(entry),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.issueTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.relativeTime,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                icon: Icons.verified,
                label: 'Confidence',
                value: entry.confidencePercent,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                icon: entry.completedRepair ? Icons.check_circle : Icons.build,
                label: 'Status',
                value: entry.completedRepair ? 'Repair Completed' : 'Analysis Only',
              ),
              const SizedBox(height: 24),
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.summary,
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssueIcon(HistoryEntry entry) {
    IconData icon;
    Color color;

    switch (entry.issueType) {
      case 'loose_belt':
        icon = Icons.remove;
        color = AppColors.warning;
        break;
      case 'worn_belt':
        icon = Icons.broken_image;
        color = AppColors.error;
        break;
      case 'misaligned_belt':
        icon = Icons.swap_horiz;
        color = AppColors.info;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.issueTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (entry.completedRepair)
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.success,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.relativeTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildConfidenceBadge(),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (entry.issueType) {
      case 'loose_belt':
        icon = Icons.remove;
        color = AppColors.warning;
        break;
      case 'worn_belt':
        icon = Icons.broken_image;
        color = AppColors.error;
        break;
      case 'misaligned_belt':
        icon = Icons.swap_horiz;
        color = AppColors.info;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildConfidenceBadge() {
    Color color;
    if (entry.confidence >= 0.8) {
      color = AppColors.success;
    } else if (entry.confidence >= 0.6) {
      color = AppColors.warning;
    } else {
      color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        entry.confidencePercent,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
