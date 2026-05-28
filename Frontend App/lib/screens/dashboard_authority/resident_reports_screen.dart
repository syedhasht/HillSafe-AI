import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/theme/app_theme.dart';

class ResidentReportsScreen extends StatefulWidget {
  const ResidentReportsScreen({super.key});

  @override
  State<ResidentReportsScreen> createState() => _ResidentReportsScreenState();
}

class _ResidentReportsScreenState extends State<ResidentReportsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _regions = [];
  int? _selectedRegionId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final regions = await _apiService.fetchRegions();
      final reports = await _apiService.fetchAllReports(regionId: _selectedRegionId);
      
      if (mounted) {
        setState(() {
          _regions = regions;
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    }
  }
  
  Future<void> _refreshReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _apiService.fetchAllReports(regionId: _selectedRegionId);
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onRegionChanged(int? regionId) {
    setState(() {
      _selectedRegionId = regionId;
    });
    _refreshReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Resident Reports'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reports.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshReports,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppTheme.spacingMedium),
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            return _buildReportCard(_reports[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.filter, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          const Text(
            'Filter by Region:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedRegionId,
                  hint: const Text('All Regions'),
                  isExpanded: true,
                  icon: const Icon(LucideIcons.chevronDown, size: 16),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('All Regions'),
                    ),
                    ..._regions.map((region) {
                      return DropdownMenuItem<int>(
                        value: region['id'],
                        child: Text(region['name']),
                      );
                    }).toList(),
                  ],
                  onChanged: _onRegionChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, int index) {
    final timestamp = DateTime.parse(report['timestamp']);
    final formattedDate = DateFormat('MMM d, y • h:mm a').format(timestamp);
    final hasImage = report['image'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      radius: 16,
                      child: const Icon(LucideIcons.user, size: 16, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      report['user_name'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        report['region_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report['description'] ?? '',
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppTheme.textPrimary,
              ),
            ),
            if (hasImage) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  '${ApiService.baseUrl}${report['image']}',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.imageOff, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(LucideIcons.clock, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                if (report['is_verified'] == true)
                  const Row(
                    children: [
                      Icon(LucideIcons.checkCircle, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  const Row(
                    children: [
                      Icon(LucideIcons.alertCircle, size: 14, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Pending Verification',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms, delay: (50 * index).ms)
    .slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.fileX, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No reports found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try changing the region filter',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

