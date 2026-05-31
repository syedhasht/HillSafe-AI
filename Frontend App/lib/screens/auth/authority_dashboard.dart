import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Accent colours (same in light & dark) ───────────────────────────────────
const _kTeal    = Color(0xFF2A7D6F); // Premium Teal accent matching the sign-in button
const _kRed     = Color(0xFFFF3B3B);
const _kAmber   = Color(0xFFFFB800);
const _kGreen   = Color(0xFF00E676);

// ── Per-mode colour helpers ──────────────────────────────────────────────────
// These are functions so they read AppTheme.isDark at build time, not compile time.
Color _bg()         => AppTheme.isDark ? const Color(0xFF0D0F14)  : const Color(0xFFF5F4F0);
Color _surface()    => AppTheme.isDark ? const Color(0xFF161A22)  : Colors.white;
Color _border()     => AppTheme.isDark ? const Color(0xFF252B38)  : const Color(0xFFE5E7EB);
Color _textPri()    => AppTheme.isDark ? const Color(0xFFEAECF0)  : const Color(0xFF111827);
Color _textSec()    => AppTheme.isDark ? const Color(0xFF6B7280)  : const Color(0xFF6B7280);

Color _redDim()     => AppTheme.isDark ? const Color(0xFF3B0B0B)  : const Color(0xFFFEF2F2);
Color _amberDim()   => AppTheme.isDark ? const Color(0xFF3B2A00)  : const Color(0xFFFFFBEB);
Color _greenDim()   => AppTheme.isDark ? const Color(0xFF003B1A)  : const Color(0xFFF0FDF4);
Color _tealDim()    => AppTheme.isDark ? const Color(0xFF003D36)  : const Color(0xFFE8F5F2);

// ── Per-mode font helpers ────────────────────────────────────────────────────
TextStyle _popStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
  List<Shadow>? shadows,
}) {
  return GoogleFonts.poppins(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    shadows: shadows,
  );
}

TextStyle _interStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
  List<Shadow>? shadows,
}) {
  return GoogleFonts.inter(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    shadows: shadows,
  );
}

/// Authority Dashboard — Command Center theme that respects light/dark mode
class AuthorityDashboard extends StatefulWidget {
  const AuthorityDashboard({super.key});

  @override
  State<AuthorityDashboard> createState() => _AuthorityDashboardState();
}

class _AuthorityDashboardState extends State<AuthorityDashboard> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _safetyStatusFuture;
  late Future<List<Map<String, dynamic>>> _regionsFuture;
  late Future<List<Map<String, dynamic>>> _alertsFuture;
  late Future<List<Map<String, dynamic>>> _sosRequestsFuture;
  late Future<List<dynamic>> _quickStatsFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    _safetyStatusFuture = _apiService.fetchSafetyStatus();
    _regionsFuture = _apiService.fetchRegionsCached();
    _alertsFuture = _apiService.fetchAlerts();
    _sosRequestsFuture = _apiService.fetchSOSRequests();
    _quickStatsFuture = Future.wait<dynamic>([
      _safetyStatusFuture,
      _regionsFuture,
      _alertsFuture,
      _sosRequestsFuture,
    ]);
  }

  Future<void> _refreshDashboardData() async {
    setState(_loadDashboardData);
    try {
      await _quickStatsFuture;
    } catch (_) {
      // The dashboard widgets render their own error states.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch ThemeProvider so every rebuild picks up the new AppTheme.isDark value
    context.watch<ThemeProvider>();

    final brightness = Theme.of(context).brightness;
    final overlayStyle = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: const Color(0xFF0D0F14),
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: const Color(0xFF0D0F14),
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.white,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: const Color(0xFFF5F4F0),
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: _bg(),
        body: RefreshIndicator(
          color: _kTeal,
          onRefresh: _refreshDashboardData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                child: _buildHeader(context),
              ),
            ),

            // ── Situation Overview ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildQuickStats()
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.08, end: 0),
              ),
            ),

            // ── Recent Safety Check-ins ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildRecentSafetyCheckins()
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 80.ms)
                    .slideY(begin: 0.08, end: 0),
              ),
            ),

            // ── SOS Requests ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildSOSRequests()
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 160.ms)
                    .slideY(begin: 0.08, end: 0),
              ),
            ),

            // ── Quick Access ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: _sectionLabel('QUICK ACCESS'),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.15,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildListDelegate([
                  _buildMenuItem(context, 'War Room',         'Live map',              LucideIcons.map,        _kTeal,              '/authority_map',    0),
                  _buildMenuItem(context, 'Regional Summary', 'District risk scores',  LucideIcons.barChart3,  const Color(0xFF8B5CF6), '/regional_summary', 1),
                  _buildMenuItem(context, 'Analytics',        'Trends & forecasts',    LucideIcons.trendingUp, const Color(0xFF06B6D4), '/analytics_trends', 2),
                  _buildMenuItem(context, 'Alert Residents',  'Create & broadcast',    LucideIcons.megaphone,  _kRed,               '/alert_management', 3),
                  _buildMenuItem(context, 'Alert History',    'Past warnings',         LucideIcons.history,    _kAmber,             '/alert_feed',       4),
                  _buildMenuItem(context, 'Resident Reports', 'View community alerts', LucideIcons.fileText,   _kGreen,             '/resident_reports', 5),
                ]),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 16, 18),
      decoration: BoxDecoration(
        color: _surface(),
        border: Border(bottom: BorderSide(color: _border(), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: single-line title + shield subtitle ──────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // COMMAND CENTER on ONE line
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'COMMAND ',
                        style: _popStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: _textPri(),
                        ),
                      ),
                      TextSpan(
                        text: 'CENTER',
                        style: _popStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: _kTeal,
                          shadows: [
                            Shadow(color: _kTeal.withOpacity(0.45), blurRadius: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Shield icon + DISASTER MANAGEMENT
                Row(
                  children: [
                    Icon(LucideIcons.shieldCheck, size: 11, color: _kTeal),
                    const SizedBox(width: 5),
                    Text(
                      'DISASTER MANAGEMENT',
                      style: _popStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                        color: _textSec(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Right: Settings button ────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/settings'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _border(),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border()),
              ),
              child: Icon(LucideIcons.settings, color: _textPri(), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTION LABEL ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 3.5, height: 16,
          decoration: BoxDecoration(color: _kTeal, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text,
          style: _popStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: _kTeal,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }

  // ── QUICK STATS ───────────────────────────────────────────────────────────
  Widget _buildQuickStats() {
    return FutureBuilder<List<dynamic>>(
      future: _quickStatsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border()),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionLabel('SITUATION OVERVIEW'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(LucideIcons.wifiOff, color: _kRed, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connection Timeout / Error',
                            style: _popStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPri()),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'The live Render server might still be booting up from sleep mode.',
                            style: _popStyle(fontSize: 11, color: _textSec()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _refreshDashboardData(),
                  icon: const Icon(LucideIcons.refreshCw, size: 14),
                  label: Text('Retry Connection', style: _popStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        }

        final safetyData = (snapshot.data?[0] as Map<String, dynamic>?) ?? {};
        final regions    = (snapshot.data?[1] as List<dynamic>?) ?? [];
        final alerts     = (snapshot.data?[2] as List<dynamic>?) ?? [];
        final sosReqs    = (snapshot.data != null && snapshot.data!.length > 3)
            ? (snapshot.data?[3] as List<dynamic>? ?? [])
            : [];

        final totalSafe        = safetyData['total_safe']  ?? 0;
        final totalUsers       = safetyData['total_users'] ?? 0;
        final highRiskCount    = regions.where((r) => ((r['current_risk_score'] as num?)?.toDouble() ?? 0) >= 0.5).length;
        final alertCount       = alerts.length;
        final activeSosCount   = sosReqs.where((s) => s['status'] != 'RESOLVED').length;
        final loading          = snapshot.connectionState == ConnectionState.waiting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _sectionLabel('SITUATION OVERVIEW')),
                if (loading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _kTeal),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Waking server...',
                    style: _popStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTeal),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Row 1 — equal height via IntrinsicHeight
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _StatCard(
                    label: 'HIGH RISK',
                    value: loading ? '–' : '$highRiskCount',
                    icon: LucideIcons.alertTriangle,
                    iconColor: _kRed, // Total red theme: red icon and left capsule
                    valueColor: _kRed,
                    dimColor: _redDim(),
                    borderColor: _kRed.withOpacity(0.35),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    label: 'ACTIVE ALERTS',
                    value: loading ? '–' : '$alertCount',
                    icon: LucideIcons.bell,
                    iconColor: _kAmber,
                    valueColor: _kAmber,
                    dimColor: _amberDim(),
                    borderColor: _kAmber.withOpacity(0.3),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Row 2 — equal height via IntrinsicHeight
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _StatCard(
                    label: 'USERS SAFE',
                    value: loading ? '–' : '$totalSafe / $totalUsers',
                    icon: LucideIcons.shieldCheck,
                    iconColor: _kTeal,
                    valueColor: _textPri(),
                    dimColor: _tealDim(),
                    borderColor: _kTeal.withOpacity(0.25),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    label: 'ACTIVE SOS',
                    value: loading ? '–' : '$activeSosCount',
                    subtitle: activeSosCount > 0 ? 'Require response' : 'No active SOS',
                    icon: LucideIcons.siren,
                    iconColor: _kRed,
                    valueColor: _kRed,
                    dimColor: _redDim(),
                    borderColor: _kRed.withOpacity(0.35),
                  )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── RECENT SAFETY CHECK-INS ───────────────────────────────────────────────
  Widget _buildRecentSafetyCheckins() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _safetyStatusFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('RECENT SAFETY CHECK-INS'),
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(LucideIcons.alertCircle, color: _kRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Failed to connect to safety status database.',
                      style: TextStyle(fontSize: 13, color: _kRed)),
                  ),
                ]),
              ],
            ),
          );
        }

        final checkins = (snapshot.data?['recent_checkins'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(
                'RECENT SAFETY CHECK-INS',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _greenDim(),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kGreen.withOpacity(0.4)),
                  ),
                  child: Text('${checkins.length}',
                    style: const TextStyle(color: _kGreen, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (loading)
                LinearProgressIndicator(minHeight: 2, color: _kTeal, backgroundColor: _border())
              else if (checkins.isEmpty)
                Row(children: [
                  Icon(LucideIcons.shieldCheck, size: 16, color: _textSec()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('No active safety check-ins in the last 30 minutes.',
                      style: TextStyle(fontSize: 13, color: _textSec())),
                  ),
                ])
              else
                ...checkins.take(3).map((checkin) {
                  final lat       = (checkin['latitude']  as num?)?.toDouble();
                  final lon       = (checkin['longitude'] as num?)?.toDouble();
                  final timestamp = DateTime.tryParse('${checkin['last_marked_at']}');
                  final timeLabel = timestamp == null
                      ? 'Unknown time'
                      : DateFormat('MMM d, h:mm a').format(timestamp.toLocal());
                  final area = (checkin['area_name'] as String?)?.trim();

                  return GestureDetector(
                    onTap: () => _showSafetyCheckinDetail(checkin),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _greenDim(),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kGreen.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _kGreen.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.shieldCheck, color: _kGreen, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${checkin['user_name'] ?? 'Resident'} marked safe',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPri()),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (area != null && area.isNotEmpty) area,
                                  checkin['region_name'] ?? 'Unknown region',
                                  if (lat != null && lon != null)
                                    '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
                                  timeLabel,
                                ].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: _textSec()),
                              ),
                            ],
                          ),
                        ),
                        Icon(LucideIcons.chevronRight, color: _textSec(), size: 16),
                      ]),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // ── SOS REQUESTS ──────────────────────────────────────────────────────────
  Widget _buildSOSRequests() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _sosRequestsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _DarkCard(
            borderColor: _kRed.withOpacity(0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('SOS REQUESTS'),
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(LucideIcons.alertCircle, color: _kRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Failed to connect to SOS database.',
                      style: TextStyle(fontSize: 13, color: _kRed)),
                  ),
                ]),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];
        final loading  = snapshot.connectionState == ConnectionState.waiting;

        return _DarkCard(
          borderColor: _kRed.withOpacity(0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(
                'SOS REQUESTS',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _redDim(),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kRed.withOpacity(0.5)),
                  ),
                  child: Text('${requests.length}',
                    style: const TextStyle(color: _kRed, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (loading)
                LinearProgressIndicator(minHeight: 2, color: _kRed, backgroundColor: _border())
              else if (requests.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No emergency SOS requests received.',
                      style: TextStyle(color: _textSec(), fontSize: 13)),
                  ),
                )
              else
                ...requests.take(5).map((request) {
                  final timestamp = DateTime.tryParse('${request['timestamp']}');
                  final timeAgo   = timestamp == null ? '' : _formatTimeAgo(timestamp);
                  final name      = request['name'] ?? 'Unknown';
                  final location  = request['region_name'] ?? request['area_name'] ?? 'Unknown location';

                  return GestureDetector(
                    onTap: () => _showSOSDetail(request),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _redDim(),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kRed.withOpacity(0.25)),
                      ),
                      child: Row(children: [
                        // Avatar
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _kRed.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: _kRed.withOpacity(0.4), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: _kRed, fontWeight: FontWeight.w900, fontSize: 17),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPri()),
                              ),
                              const SizedBox(height: 3),
                              Text(location,
                                style: TextStyle(fontSize: 12, color: _textSec()),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              if (timeAgo.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(timeAgo, style: TextStyle(fontSize: 11, color: _textSec())),
                              ],
                            ],
                          ),
                        ),
                        // NEEDS HELP button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _kTeal, width: 1.5),
                          ),
                          child: const Text('NEEDS HELP',
                            style: TextStyle(color: _kTeal, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ),
                      ]),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // ── MENU ITEM ─────────────────────────────────────────────────────────────
  Widget _buildMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String route,
    int index,
  ) {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, route);
        if (!mounted) return;
        if (route == '/alert_management' || route == '/alert_feed') {
          await _refreshDashboardData();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border()),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(title,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: _textPri(), letterSpacing: -0.2, height: 1.2,
              ),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(subtitle,
              style: TextStyle(fontSize: 11, color: _textSec()),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 500.ms, delay: (80 * index).ms)
          .scale(begin: const Offset(0.88, 0.88), end: const Offset(1, 1)),
    );
  }

  // ── UTILITIES ─────────────────────────────────────────────────────────────
  String _formatTimeAgo(DateTime dateTime) {
    final d = DateTime.now().difference(dateTime);
    if (d.inDays    > 0) return '${d.inDays}d ago';
    if (d.inHours   > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'Just now';
  }

  // ── DIALOGS ───────────────────────────────────────────────────────────────
  void _showSafetyCheckinDetail(Map<String, dynamic> checkin) {
    final lat       = (checkin['latitude']  as num?)?.toDouble();
    final lon       = (checkin['longitude'] as num?)?.toDouble();
    final timestamp = DateTime.tryParse('${checkin['last_marked_at']}');
    final timeLabel = timestamp == null
        ? 'Unknown time'
        : DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toLocal());
    final name     = checkin['user_name']?.toString() ?? 'Resident';
    final region   = checkin['region_name']?.toString() ?? 'Unknown region';
    final district = checkin['district']?.toString();
    final area     = checkin['area_name']?.toString();

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
                    colors: [Color(0xFF065F46), Color(0xFF16A34A), Color(0xFF22C55E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.45)),
                    ),
                    child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Safety Check-in',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1)),
                      const SizedBox(height: 5),
                      Text(timeLabel,
                        style: TextStyle(color: Colors.white.withOpacity(0.86), fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  )),
                  IconButton(tooltip: 'Close', onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(LucideIcons.x, color: Colors.white)),
                ]),
              ),
              Flexible(child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _detailTile(icon: LucideIcons.user,   label: 'Resident', value: name,    accentColor: const Color(0xFF16A34A)),
                    _detailTile(
                      icon: LucideIcons.mapPin, label: 'Region',
                      value: (district == null || district.isEmpty) ? region : '$region, $district',
                      accentColor: const Color(0xFF16A34A),
                    ),
                    if (area != null && area.isNotEmpty)
                      _detailTile(icon: LucideIcons.navigation, label: 'Area', value: area, accentColor: const Color(0xFF16A34A)),
                    if (lat != null && lon != null)
                      _coordsTile(
                        context: context,
                        lat: lat,
                        lon: lon,
                        residentName: name,
                        type: 'SAFE',
                        accentColor: const Color(0xFF16A34A),
                        bgColor: const Color(0xFFF0FDF4),
                        borderColor: const Color(0xFFBBF7D0),
                        labelColor: const Color(0xFF14532D),
                      ),
                  ],
                ),
              )),
              _dialogButton(ctx: ctx, color: const Color(0xFF16A34A)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSOSDetail(Map<String, dynamic> request) {
    final lat         = (request['latitude']  as num?)?.toDouble();
    final lon         = (request['longitude'] as num?)?.toDouble();
    final name        = request['name']?.toString() ?? 'Unknown resident';
    final location    = request['region_name']?.toString() ?? request['area_name']?.toString() ?? 'Unknown location';
    final statusLabel = request['status_label']?.toString() ?? 'Needs Help';
    final timestamp   = request['timestamp']?.toString() ?? 'Unknown time';
    final areaName    = request['area_name']?.toString();

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
                    colors: [Color(0xFF991B1B), Color(0xFFDC2626), Color(0xFFEF4444)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.45)),
                        ),
                        child: const Icon(LucideIcons.siren, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SOS Request',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1)),
                          const SizedBox(height: 5),
                          Text(timestamp,
                            style: TextStyle(color: Colors.white.withOpacity(0.86), fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      )),
                      IconButton(tooltip: 'Close', onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(LucideIcons.x, color: Colors.white)),
                    ]),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withOpacity(0.28)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(LucideIcons.activity, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(statusLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ],
                ),
              ),
              Flexible(child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _detailTile(icon: LucideIcons.user,   label: 'Resident',          value: name,     accentColor: const Color(0xFFDC2626)),
                    _detailTile(icon: LucideIcons.mapPin, label: 'Reported Location', value: location, accentColor: const Color(0xFFDC2626)),
                    if (areaName != null && areaName.isNotEmpty)
                      _detailTile(icon: LucideIcons.navigation, label: 'Area', value: areaName, accentColor: const Color(0xFFDC2626)),
                    if (lat != null && lon != null)
                      _coordsTile(
                        context: context,
                        lat: lat,
                        lon: lon,
                        residentName: name,
                        type: 'SOS',
                        accentColor: const Color(0xFFDC2626),
                        bgColor: const Color(0xFFFFF1F2),
                        borderColor: const Color(0xFFFECACA),
                        labelColor: const Color(0xFF7F1D1D),
                      ),
                  ],
                ),
              )),
              _dialogButton(ctx: ctx, color: const Color(0xFFDC2626)),
            ],
          ),
        ),
      ),
    );
  }

  // Shared detail tile for both dialogs
  Widget _detailTile({required IconData icon, required String label, required String value, required Color accentColor}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, height: 1.25)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _coordsTile({
    required BuildContext context,
    required double lat,
    required double lon,
    required String residentName,
    required String type, // 'SOS' or 'SAFE'
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
    required Color labelColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: InkWell(
          onTap: () {
            // Dismiss the modal dialog first
            Navigator.pop(context);
            // Navigate to War Room Map Screen with coordinates verification arguments
            Navigator.pushNamed(
              context,
              '/authority_map',
              arguments: {
                'latitude': lat,
                'longitude': lon,
                'name': residentName,
                'type': type,
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.crosshair, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exact Coordinates (Tap to Verify)',
                      style: _popStyle(color: labelColor, fontSize: 11, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
                      style: _interStyle(color: const Color(0xFF111827), fontSize: 14, fontWeight: FontWeight.w800)),
                  ],
                )),
                const SizedBox(width: 8),
                Icon(LucideIcons.map, color: labelColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogButton({required BuildContext ctx, required Color color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(ctx),
          icon: const Icon(LucideIcons.check, size: 18),
          label: const Text('Viewed'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

// ── STAT CARD ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color valueColor;
  final Color dimColor;
  final Color borderColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.valueColor,
    required this.dimColor,
    required this.borderColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark  = AppTheme.isDark;
    final surface = isDark ? const Color(0xFF161A22) : Colors.white;
    final textSec = const Color(0xFF6B7280);

    // Always white in light mode — colour is carried by the left bar + border only
    final cardBg = isDark ? surface : Colors.white;

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20), // Highly-rounded corners (20px) matching the photo
        border: Border.all(
          color: isDark ? borderColor : const Color(0xFFE5E7EB), // Clean light-gray border in light mode
        ),
        boxShadow: isDark
            ? [BoxShadow(color: valueColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07), // Elevated premium gray shadow (slightly more pronounced)
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? dimColor : iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value,
            style: _interStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1,
              shadows: isDark
                  ? [Shadow(color: valueColor.withOpacity(0.4), blurRadius: 12)]
                  : [],
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
            style: _popStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: isDark ? textSec : iconColor.withOpacity(0.7),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: _interStyle(
                fontSize: 10,
                color: isDark ? valueColor.withOpacity(0.7) : valueColor.withOpacity(0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    // In light mode, overlay a thin coloured left accent bar using a Stack.
    // We CANNOT use non-uniform Border widths with borderRadius — Flutter asserts.
    if (isDark) return card;

    return Stack(
      fit: StackFit.expand,
      children: [
        card,
        Positioned(
          left: 0,
          top: 24, // Separated from the top edge to look like a clean capsule
          bottom: 24, // Separated from the bottom edge to look like a clean capsule
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── CARD WRAPPER ──────────────────────────────────────────────────────────────
class _DarkCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _DarkCard({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.isDark ? const Color(0xFF161A22) : Colors.white;
    final border  = borderColor ?? (AppTheme.isDark ? const Color(0xFF252B38) : const Color(0xFFE5E7EB));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20), // Highly rounded (20px) like the other cards
        border: Border.all(color: border),
        boxShadow: AppTheme.isDark
            ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6))]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06), // Elevated matching soft shadow
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: child,
    );
  }
}
