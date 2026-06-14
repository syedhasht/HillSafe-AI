import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/services/date_helper.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';

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
      final reports =
          await _apiService.fetchAllReports(regionId: _selectedRegionId);

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
      final reports =
          await _apiService.fetchAllReports(regionId: _selectedRegionId);
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

  Future<void> _showClearReportsConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.red, size: 24),
            const SizedBox(width: 10),
            const Text('Clear All Reports',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure? This will permanently delete all incident reports '
          'and residents won\'t be able to see them.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await _apiService.clearAllReports();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Reports cleared' : 'Failed to clear reports')),
      );
      if (success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _refreshReports();
        });
      }
    }
  }

  Future<void> _reviewReport(
    Map<String, dynamic> report, {
    required String action,
    String? hazardLevel,
    String? reviewNotes,
  }) async {
    try {
      await _apiService.reviewIncidentReport(
        (report['id'] as num).toInt(),
        action: action,
        hazardLevel: hazardLevel,
        reviewNotes: reviewNotes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                action == 'APPROVE' ? 'Report approved' : 'Report declined')),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshReports();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to review report: $e')),
      );
    }
  }

  void _showApproveDialog(Map<String, dynamic> report) {
    String level = 'MEDIUM';
    final rawDesc = report['description']?.toString() ?? '';
    final parts = rawDesc.split(': ');
    final userDesc = parts.length >= 2 ? parts.sublist(1).join(': ').trim() : rawDesc;
    final notesController = TextEditingController(text: userDesc);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Approve Hazard Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Choose the hazard classification. It will appear on maps for 12 hours.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: level,
                decoration: const InputDecoration(labelText: 'Hazard level'),
                items: const ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
                    .map((value) =>
                        DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => level = value ?? level),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Edit the description or leave as-is...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  notesController.dispose();
                  Navigator.pop(ctx);
                },
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final notes = notesController.text.trim();
                notesController.dispose();
                Navigator.pop(ctx);
                _reviewReport(
                  report,
                  action: 'APPROVE',
                  hazardLevel: level,
                  reviewNotes: notes.isNotEmpty ? notes : null,
                );
              },
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _declineReport(Map<String, dynamic> report) async {
    await _reviewReport(report, action: 'DECLINE');
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Resident Reports'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: () => _showClearReportsConfirmation(),
            icon: Icon(LucideIcons.trash2, size: 16, color: AppTheme.textSecondary),
            label: Text('Clear All',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentTeal,
                    ),
                  )
                : _reports.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshReports,
                        color: AppTheme.accentTeal,
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
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.filter, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(
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
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
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
    final timestamp = DateHelper.toPakistanTime(report['timestamp']);
    final formattedDate = DateFormat('MMM d, y • h:mm a').format(timestamp);
    final imageUrl = _imageUrl(report['image']);
    final hasImage = imageUrl != null;
    final areaName = (report['area_name'] as String?)?.trim();
    final placeName = areaName != null && areaName.isNotEmpty
        ? areaName
        : report['region_name'] ?? 'Unknown';
    final radiusKm = (report['report_radius_km'] as num?)?.toDouble();
    final reviewStatus = report['review_status']?.toString() ?? 'PENDING';
    final phoneNumber = report['phone_number']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      elevation: 0,
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showReportDetail(report),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.accentTealLight,
                          radius: 16,
                          child: Icon(LucideIcons.user,
                              size: 16, color: AppTheme.accentTeal),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            report['user_name'] ?? 'Unknown User',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Region badge — keep orange status color (warning constant)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.mapPin,
                              size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              report['region_name'] ?? 'Your Location',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(LucideIcons.mapPinned,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Place: $placeName',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (phoneNumber != null && phoneNumber.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(LucideIcons.phone,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(phoneNumber,
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (radiusKm != null) ...[
                Row(
                  children: [
                    Icon(LucideIcons.radar,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Radius: ${radiusKm.toStringAsFixed(radiusKm.truncateToDouble() == radiusKm ? 0 : 1)} km',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                report['description'] ?? '',
                style: TextStyle(
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
                    imageUrl!,
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
              Divider(height: 1, color: AppTheme.borderColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(LucideIcons.clock,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  // Status badges — keep success/warning semantic colors
                  Row(
                    children: [
                      Icon(
                        reviewStatus == 'APPROVED'
                            ? LucideIcons.checkCircle
                            : reviewStatus == 'DECLINED'
                                ? LucideIcons.xCircle
                                : LucideIcons.clock,
                        size: 14,
                        color: reviewStatus == 'APPROVED'
                            ? Colors.green
                            : reviewStatus == 'DECLINED'
                                ? Colors.red
                                : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reviewStatus,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (reviewStatus == 'PENDING') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _declineReport(report),
                        icon: const Icon(LucideIcons.x),
                        label: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showApproveDialog(report),
                        icon: const Icon(LucideIcons.check),
                        label: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (50 * index).ms)
        .slideY(begin: 0.1, end: 0);
  }

  void _showReportDetail(Map<String, dynamic> report) {
    final lat = _asDouble(report['latitude']);
    final lon = _asDouble(report['longitude']);
    final timeLabel =
        DateHelper.format(report['timestamp'], pattern: 'MMM d, yyyy • h:mm a');
    final name = report['user_name']?.toString() ?? 'Unknown resident';
    final areaName = report['area_name']?.toString().trim();
    final regionName = report['region_name']?.toString() ?? 'Your Location';
    final district = report['region_district']?.toString();
    final placeName =
        areaName != null && areaName.isNotEmpty ? areaName : regionName;
    final description =
        report['description']?.toString() ?? 'No description provided.';
    final radiusKm = _asDouble(report['report_radius_km']);
    final isVerified = report['is_verified'] == true;
    final phoneNumber = report['phone_number']?.toString();
    final reviewStatus = report['review_status']?.toString() ?? 'PENDING';
    final hazardLevel = report['hazard_level']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF92400E),
                      Color(0xFFF59E0B),
                      Color(0xFFFBBF24)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white.withOpacity(0.45)),
                      ),
                      child: const Icon(LucideIcons.fileWarning,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resident Report',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.1),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            timeLabel,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.88),
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(LucideIcons.x, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _detailTile(
                          icon: LucideIcons.user,
                          label: 'Resident',
                          value: name,
                          accentColor: Colors.orange),
                      if (phoneNumber != null && phoneNumber.isNotEmpty)
                        _detailTile(
                            icon: LucideIcons.phone,
                            label: 'Phone',
                            value: phoneNumber,
                            accentColor: Colors.orange),
                      _detailTile(
                        icon: LucideIcons.mapPin,
                        label: 'Place',
                        value: (district == null ||
                                district.isEmpty ||
                                district == '50 km radius')
                            ? placeName
                            : '$placeName, $district',
                        accentColor: Colors.orange,
                      ),
                      if (radiusKm != null)
                        _detailTile(
                          icon: LucideIcons.radar,
                          label: 'Report Radius',
                          value:
                              '${radiusKm.toStringAsFixed(radiusKm.truncateToDouble() == radiusKm ? 0 : 1)} km',
                          accentColor: Colors.orange,
                        ),
                      _detailTile(
                        icon: LucideIcons.messageSquareText,
                        label: 'Description',
                        value: description,
                        accentColor: Colors.orange,
                      ),
                      _detailTile(
                        icon: isVerified
                            ? LucideIcons.checkCircle
                            : LucideIcons.alertCircle,
                        label: 'Status',
                        value: reviewStatus,
                        accentColor: isVerified ? Colors.green : Colors.orange,
                      ),
                      if (reviewStatus == 'APPROVED' && hazardLevel != null)
                        _detailTile(
                          icon: LucideIcons.triangleAlert,
                          label: 'Hazard Classification',
                          value: hazardLevel,
                          accentColor: Colors.red,
                        ),
                      if (lat != null && lon != null)
                        _coordsTile(
                          dialogContext: ctx,
                          lat: lat,
                          lon: lon,
                          residentName: name,
                        ),
                    ],
                  ),
                ),
              ),
              if (reviewStatus == 'PENDING')
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                              Navigator.pop(ctx);
                              _declineReport(report);
                            },
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showApproveDialog(report),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _dialogButton(ctx: ctx),
            ],
          ),
        ),
      ),
    );
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String? _imageUrl(dynamic value) {
    final path = value?.toString();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${ApiService.baseUrl}$path';
  }

  Widget _detailTile({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coordsTile({
    required BuildContext dialogContext,
    required double lat,
    required double lon,
    required String residentName,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pop(dialogContext);
          Navigator.pushNamed(
            context,
            '/authority_map',
            arguments: {
              'latitude': lat,
              'longitude': lon,
              'name': residentName,
              'type': 'REPORT',
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                    color: Colors.orange, shape: BoxShape.circle),
                child: const Icon(LucideIcons.crosshair,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exact Coordinates (Tap to Verify)',
                      style: TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 11,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
                      style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 14,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.map, color: Color(0xFF92400E), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogButton({required BuildContext ctx}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Close',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
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
          Text(
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
