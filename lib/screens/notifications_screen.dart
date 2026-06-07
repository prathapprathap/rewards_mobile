import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../constants/app_design.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/ui/rupi_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>().user;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final list = await _api.getUserNotifications(user.id);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openItem(Map<String, dynamic> item) async {
    final user = context.read<UserProvider>().user;
    if (user != null && (item['is_read'] == 0 || item['is_read'] == false)) {
      await _api.markNotificationRead(user.id, item['id'] as int);
      setState(() => item['is_read'] = 1);
    }
    final action = (item['action_url'] ?? '').toString();
    if (action.isNotEmpty) {
      final uri = Uri.tryParse(action);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notifications',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, color: AppColors.onSurface)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceContainerLowest,
        child: _loading
            ? RupiLoader.fullscreen(label: 'Loading…')
            : _items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 60),
                      RupiEmptyState(
                        icon: Icons.notifications_off_rounded,
                        title: 'No notifications yet',
                        subtitle:
                            'Updates, bonuses and reward alerts will appear here.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n = Map<String, dynamic>.from(_items[i] as Map);
                      final isRead = n['is_read'] == 1 || n['is_read'] == true;
                      final created = DateTime.tryParse(
                          n['created_at']?.toString() ?? '');
                      return InkWell(
                        borderRadius: AppDesign.brLg,
                        onTap: () => _openItem(n),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead
                                ? AppColors.surfaceContainerLowest
                                : AppColors.primaryFixed.withValues(alpha: 0.5),
                            borderRadius: AppDesign.brLg,
                            border: Border.all(
                              color: isRead
                                  ? AppColors.outlineVariant
                                      .withValues(alpha: 0.5)
                                  : AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: AppDesign.brMd,
                                ),
                                child: Icon(
                                    Icons.notifications_active_rounded,
                                    color: AppColors.primary,
                                    size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n['title']?.toString() ?? '',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: isRead
                                            ? FontWeight.w600
                                            : FontWeight.w800,
                                        fontSize: 14.5,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n['body']?.toString() ?? '',
                                      style: GoogleFonts.inter(
                                          color: AppColors.onSurfaceVariant,
                                          fontSize: 13,
                                          height: 1.4),
                                    ),
                                    if (created != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        DateFormat('MMM d, h:mm a')
                                            .format(created.toLocal()),
                                        style: GoogleFonts.inter(
                                            color: AppColors.outline,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 9,
                                  height: 9,
                                  margin:
                                      const EdgeInsets.only(top: 4, left: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentPink,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
