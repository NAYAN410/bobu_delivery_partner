import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../core/constants.dart';
import 'order_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFFF8F0),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final supabaseService = SupabaseService();
    final sw = MediaQuery.of(context).size.width;
    final double scale = (sw.clamp(0.0, 430.0) / 375).clamp(0.85, 1.1);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Column(
        children: [
          // ── Custom header ──
          _buildHeader(authProvider, scale),

          // ── Tab bar ──
          _buildTabBar(scale),

          // ── Content ──
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabaseService
                  .getAssignedOrders(authProvider.user!.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error, scale);
                }
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                final allOrders = snapshot.data ?? [];

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveOrders(allOrders, scale),
                    _buildDeliveredOrders(allOrders, scale),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────

  Widget _buildHeader(AuthProvider authProvider, double scale) {
    final String name =
        authProvider.profile?['full_name'] ?? 'Rider';
    final String firstName = name.split(' ').first;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8F0), Color(0xFFFFE8C8)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20 * scale, 16 * scale, 16 * scale, 16 * scale),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 46 * scale,
                height: 46 * scale,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.tomatoRed,
                      Color.fromARGB(
                        255,
                        (AppColors.tomatoRed.red + 30).clamp(0, 255),
                        AppColors.tomatoRed.green,
                        AppColors.tomatoRed.blue,
                      ),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tomatoRed.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    firstName.isNotEmpty
                        ? firstName[0].toUpperCase()
                        : 'R',
                    style: GoogleFonts.poppins(
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12 * scale),

              // Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: GoogleFonts.poppins(
                        fontSize: 12 * scale,
                        color: const Color(0xFF2D1A0E).withOpacity(0.5),
                      ),
                    ),
                    Text(
                      firstName,
                      style: GoogleFonts.poppins(
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D1A0E),
                      ),
                    ),
                  ],
                ),
              ),

              // Bobu Rider badge
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10 * scale, vertical: 5 * scale),
                decoration: BoxDecoration(
                  color: AppColors.tomatoRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.tomatoRed.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delivery_dining_rounded,
                        color: AppColors.tomatoRed, size: 14 * scale),
                    SizedBox(width: 4 * scale),
                    Text(
                      'Bobu Rider',
                      style: GoogleFonts.poppins(
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tomatoRed,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8 * scale),

              // Logout button
              GestureDetector(
                onTap: () => _showLogoutDialog(
                    context,
                    Provider.of<AuthProvider>(context, listen: false)),
                child: Container(
                  padding: EdgeInsets.all(8 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFE8D5C0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D1A0E).withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 18 * scale,
                    color: const Color(0xFF2D1A0E).withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tab bar ──────────────────────────────────────────────────────

  Widget _buildTabBar(double scale) {
    return Container(
      margin: EdgeInsets.fromLTRB(
          20 * scale, 0, 20 * scale, 12 * scale),
      height: 44 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D5C0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D1A0E).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.tomatoRed,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor:
        const Color(0xFF2D1A0E).withOpacity(0.5),
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.poppins(
            fontSize: 13 * scale, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
        GoogleFonts.poppins(fontSize: 13 * scale),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delivery_dining_rounded, size: 16),
                SizedBox(width: 6),
                Text('Active'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 16),
                SizedBox(width: 6),
                Text('History'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Active orders ────────────────────────────────────────────────

  Widget _buildActiveOrders(
      List<Map<String, dynamic>> orders, double scale) {
    final activeOrders = orders
        .where((o) => ['pending', 'accepted', 'preparing', 'on_the_way']
        .contains(o['status']))
        .toList();

    if (activeOrders.isEmpty) {
      return _buildEmptyState(
        icon: '🛵',
        title: 'No active tasks',
        subtitle: 'Waiting for new orders...',
        scale: scale,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
          16 * scale, 4 * scale, 16 * scale, 24 * scale),
      physics: const BouncingScrollPhysics(),
      itemCount: activeOrders.length,
      itemBuilder: (context, index) =>
          _buildActiveOrderCard(activeOrders[index], scale),
    );
  }

  // ─── Active order card ────────────────────────────────────────────

  Widget _buildActiveOrderCard(
      Map<String, dynamic> order, double scale) {
    final String status = order['status'].toString();
    final statusInfo = _getStatusInfo(status);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(order: order)),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 14 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8D5C0), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D1A0E).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top colored strip based on status
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: statusInfo['color'] as Color,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18)),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(14 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID + status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Order #${order['id']}',
                          style: GoogleFonts.poppins(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D1A0E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(status, scale),
                    ],
                  ),

                  SizedBox(height: 12 * scale),

                  // Address
                  Container(
                    padding: EdgeInsets.all(10 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFE8D5C0), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6 * scale),
                          decoration: BoxDecoration(
                            color:
                            AppColors.tomatoRed.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 14 * scale,
                            color: AppColors.tomatoRed,
                          ),
                        ),
                        SizedBox(width: 10 * scale),
                        Expanded(
                          child: Text(
                            order['address'] ?? 'No address',
                            style: GoogleFonts.poppins(
                              fontSize: 12 * scale,
                              color: const Color(0xFF2D1A0E)
                                  .withOpacity(0.7),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12 * scale),

                  // View details row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status step indicator
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              statusInfo['icon'] as IconData,
                              size: 14 * scale,
                              color: statusInfo['color'] as Color,
                            ),
                            SizedBox(width: 5 * scale),
                            Flexible(
                              child: Text(
                                statusInfo['label'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: statusInfo['color'] as Color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // CTA
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12 * scale,
                            vertical: 6 * scale),
                        decoration: BoxDecoration(
                          color: AppColors.tomatoRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Details',
                              style: GoogleFonts.poppins(
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4 * scale),
                            Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white, size: 10 * scale),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Delivered orders ─────────────────────────────────────────────

  Widget _buildDeliveredOrders(
      List<Map<String, dynamic>> orders, double scale) {
    final deliveredOrders = orders
        .where((o) => o['status'] == 'delivered')
        .toList()
      ..sort((a, b) =>
          (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));

    if (deliveredOrders.isEmpty) {
      return _buildEmptyState(
        icon: '📋',
        title: 'No past deliveries',
        subtitle: 'Your delivery history will appear here',
        scale: scale,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
          16 * scale, 4 * scale, 16 * scale, 24 * scale),
      physics: const BouncingScrollPhysics(),
      itemCount: deliveredOrders.length,
      itemBuilder: (context, index) =>
          _buildHistoryCard(deliveredOrders[index], scale),
    );
  }

  // ─── History card ─────────────────────────────────────────────────

  Widget _buildHistoryCard(
      Map<String, dynamic> order, double scale) {
    final date = DateTime.tryParse(order['created_at'] ?? '');
    final formattedDate = date != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal())
        : 'N/A';

    return Container(
      margin: EdgeInsets.only(bottom: 12 * scale),
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D5C0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D1A0E).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Green check circle
          Container(
            width: 44 * scale,
            height: 44 * scale,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded,
                color: Colors.green[600], size: 22 * scale),
          ),

          SizedBox(width: 12 * scale),

          // Order info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: GoogleFonts.poppins(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D1A0E),
                  ),
                ),
                SizedBox(height: 3 * scale),
                Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 11 * scale,
                    color: const Color(0xFF2D1A0E).withOpacity(0.45),
                  ),
                ),
                SizedBox(height: 3 * scale),
                Text(
                  order['address'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 11 * scale,
                    color: const Color(0xFF2D1A0E).withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Delivered badge
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: 8 * scale, vertical: 4 * scale),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '✅ Done',
              style: GoogleFonts.poppins(
                fontSize: 10 * scale,
                fontWeight: FontWeight.w700,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────

  Widget _buildEmptyState({
    required String icon,
    required String title,
    required String subtitle,
    required double scale,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: TextStyle(fontSize: 56 * scale)),
          SizedBox(height: 16 * scale),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D1A0E),
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13 * scale,
              color: const Color(0xFF2D1A0E).withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading state ────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.tomatoRed,
        strokeWidth: 2.5,
      ),
    );
  }

  // ─── Error state ──────────────────────────────────────────────────

  Widget _buildErrorState(Object? error, double scale) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16 * scale),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 40 * scale, color: Colors.red[400]),
            ),
            SizedBox(height: 16 * scale),
            Text(
              'Connection Error',
              style: GoogleFonts.poppins(
                fontSize: 18 * scale,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D1A0E),
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12 * scale,
                color: const Color(0xFF2D1A0E).withOpacity(0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Status badge ─────────────────────────────────────────────────

  Widget _buildStatusBadge(String status, double scale) {
    final info = _getStatusInfo(status);
    final Color color = info['color'] as Color;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 10 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        (info['label'] as String).toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 9 * scale,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return {
          'color': Colors.orange,
          'label': 'Pending',
          'icon': Icons.hourglass_empty_rounded,
        };
      case 'accepted':
        return {
          'color': Colors.blue,
          'label': 'Accepted',
          'icon': Icons.thumb_up_rounded,
        };
      case 'preparing':
        return {
          'color': const Color(0xFFF57C00),
          'label': 'Preparing',
          'icon': Icons.local_fire_department_rounded,
        };
      case 'on_the_way':
        return {
          'color': AppColors.tomatoRed,
          'label': 'On the Way',
          'icon': Icons.delivery_dining_rounded,
        };
      case 'delivered':
        return {
          'color': Colors.green,
          'label': 'Delivered',
          'icon': Icons.check_circle_rounded,
        };
      default:
        return {
          'color': Colors.grey,
          'label': status,
          'icon': Icons.circle_outlined,
        };
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    if (hour < 21) return 'Good Evening 🌇';
    return 'Good Night 🌙';
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFFFF8F0),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded,
                    color: Colors.red[400], size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Sign Out?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D1A0E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to sign out of Bobu Rider?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF2D1A0E).withOpacity(0.55),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8D5C0)
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D1A0E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        auth.signOut();
                      },
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                              Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Sign Out',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}