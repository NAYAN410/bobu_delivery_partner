import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../core/constants.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  bool _isUpdating = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── Actions ──────────────────────────────────────────────────────

  Future<void> _updateStatus(String newStatus) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isUpdating = true);
    try {
      await _supabaseService.updateOrderStatus(
          widget.order['id'].toString(), newStatus);
      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Order updated to $newStatus',
                style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) _showSnack('Could not launch dialer', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: isError ? Colors.red[400] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final double scale = (sw.clamp(0.0, 430.0) / 375).clamp(0.85, 1.1);
    final String status = widget.order['status'] ?? '';
    final statusInfo = _getStatusInfo(status);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Column(
        children: [

          // ── Custom AppBar ──
          _buildAppBar(scale, status, statusInfo),

          // ── Scrollable content ──
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                      16 * scale, 8 * scale, 16 * scale, 24 * scale),
                  child: Column(
                    children: [

                      // Status timeline
                      _buildStatusTimeline(status, scale),

                      SizedBox(height: 16 * scale),

                      // Customer details
                      _buildCustomerCard(scale),

                      SizedBox(height: 12 * scale),

                      // Order items
                      _buildOrderItemsCard(scale),

                      SizedBox(height: 12 * scale),

                      // Bill summary
                      _buildBillCard(scale),

                      SizedBox(height: 24 * scale),

                      // Action button
                      _isUpdating
                          ? _buildLoadingButton(scale)
                          : _buildActionButton(status, scale),

                      SizedBox(height: 16 * scale),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────

  Widget _buildAppBar(double scale, String status,
      Map<String, dynamic> statusInfo) {
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
              8 * scale, 8 * scale, 16 * scale, 14 * scale),
          child: Row(
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: EdgeInsets.all(6 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFE8D5C0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D1A0E).withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16 * scale,
                      color: const Color(0xFF2D1A0E)),
                ),
              ),

              SizedBox(width: 4 * scale),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${widget.order['id']}',
                      style: GoogleFonts.poppins(
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D1A0E),
                      ),
                    ),
                    Text(
                      'Tap to see full details',
                      style: GoogleFonts.poppins(
                        fontSize: 11 * scale,
                        color: const Color(0xFF2D1A0E).withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10 * scale, vertical: 5 * scale),
                decoration: BoxDecoration(
                  color: (statusInfo['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                    (statusInfo['color'] as Color).withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusInfo['icon'] as IconData,
                        size: 12 * scale,
                        color: statusInfo['color'] as Color),
                    SizedBox(width: 4 * scale),
                    Text(
                      statusInfo['label'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w700,
                        color: statusInfo['color'] as Color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Status timeline ──────────────────────────────────────────────

  Widget _buildStatusTimeline(String status, double scale) {
    final steps = [
      {'key': 'preparing',  'label': 'Preparing',  'icon': Icons.local_fire_department_rounded},
      {'key': 'on_the_way', 'label': 'Picked Up',  'icon': Icons.delivery_dining_rounded},
      {'key': 'delivered',  'label': 'Delivered',  'icon': Icons.check_circle_rounded},
    ];

    final currentStep = steps.indexWhere((s) => s['key'] == status);

    return Container(
      padding: EdgeInsets.all(16 * scale),
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
        children: List.generate(steps.length, (i) {
          final isDone = i <= currentStep;
          final isLast = i == steps.length - 1;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 36 * scale,
                      height: 36 * scale,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.tomatoRed
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone
                              ? AppColors.tomatoRed
                              : const Color(0xFFE8D5C0),
                          width: 1.5,
                        ),
                        boxShadow: isDone
                            ? [
                          BoxShadow(
                            color: AppColors.tomatoRed
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                            : [],
                      ),
                      child: Icon(
                        steps[i]['icon'] as IconData,
                        size: 16 * scale,
                        color: isDone
                            ? Colors.white
                            : const Color(0xFF2D1A0E).withOpacity(0.25),
                      ),
                    ),
                    SizedBox(height: 6 * scale),
                    Text(
                      steps[i]['label'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 9 * scale,
                        fontWeight: isDone
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isDone
                            ? AppColors.tomatoRed
                            : const Color(0xFF2D1A0E).withOpacity(0.3),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: EdgeInsets.only(bottom: 20 * scale),
                      color: i < currentStep
                          ? AppColors.tomatoRed
                          : const Color(0xFFE8D5C0),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Customer card ────────────────────────────────────────────────

  Widget _buildCustomerCard(double scale) {
    return Container(
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
      child: Column(
        children: [

          // Header
          _buildCardHeader('Customer Details',
              Icons.person_outline_rounded, scale),

          Divider(
              height: 1,
              color: const Color(0xFF2D1A0E).withOpacity(0.07)),

          // Address row
          Padding(
            padding: EdgeInsets.all(14 * scale),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8 * scale),
                  decoration: BoxDecoration(
                    color: AppColors.tomatoRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.location_on_rounded,
                      color: AppColors.tomatoRed, size: 18 * scale),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Address',
                        style: GoogleFonts.poppins(
                          fontSize: 11 * scale,
                          color: const Color(0xFF2D1A0E).withOpacity(0.45),
                        ),
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        widget.order['address'] ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D1A0E),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
              height: 1,
              indent: 14 * scale,
              endIndent: 14 * scale,
              color: const Color(0xFF2D1A0E).withOpacity(0.07)),

          // Phone row
          Padding(
            padding: EdgeInsets.all(14 * scale),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8 * scale),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.phone_rounded,
                      color: Colors.green[600], size: 18 * scale),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mobile Number',
                        style: GoogleFonts.poppins(
                          fontSize: 11 * scale,
                          color: const Color(0xFF2D1A0E).withOpacity(0.45),
                        ),
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        widget.order['mobile'] ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D1A0E),
                        ),
                      ),
                    ],
                  ),
                ),

                // Call button
                GestureDetector(
                  onTap: () =>
                      _makeCall(widget.order['mobile'] ?? ''),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14 * scale, vertical: 8 * scale),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.call_rounded,
                            color: Colors.white, size: 14 * scale),
                        SizedBox(width: 5 * scale),
                        Text(
                          'Call',
                          style: GoogleFonts.poppins(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Order items card ─────────────────────────────────────────────

  Widget _buildOrderItemsCard(double scale) {
    return Container(
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
      child: Column(
        children: [
          _buildCardHeader(
              'Order Items', Icons.receipt_long_rounded, scale),
          Divider(
              height: 1,
              color: const Color(0xFF2D1A0E).withOpacity(0.07)),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _supabaseService
                .getOrderItems(widget.order['id'].toString()),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.all(20 * scale),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.tomatoRed, strokeWidth: 2),
                  ),
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(20 * scale),
                  child: Text(
                    'No items found',
                    style: GoogleFonts.poppins(
                        fontSize: 13 * scale,
                        color: const Color(0xFF2D1A0E).withOpacity(0.4)),
                  ),
                );
              }
              return Column(
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final isLast = i == items.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14 * scale,
                            vertical: 12 * scale),
                        child: Row(
                          children: [
                            // Pizza emoji box
                            Container(
                              width: 38 * scale,
                              height: 38 * scale,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0DC),
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text('🍕',
                                    style: TextStyle(
                                        fontSize: 20 * scale)),
                              ),
                            ),
                            SizedBox(width: 12 * scale),
                            // Name + price
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['pizzas']['name'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13 * scale,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2D1A0E),
                                    ),
                                  ),
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    '₹${item['price']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12 * scale,
                                      color: AppColors.tomatoRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Qty badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10 * scale,
                                  vertical: 4 * scale),
                              decoration: BoxDecoration(
                                color: AppColors.tomatoRed
                                    .withOpacity(0.08),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: Text(
                                '×${item['quantity']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13 * scale,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.tomatoRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          indent: 14 * scale,
                          endIndent: 14 * scale,
                          color: const Color(0xFF2D1A0E)
                              .withOpacity(0.06),
                        ),
                    ],
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Bill card ────────────────────────────────────────────────────

  Widget _buildBillCard(double scale) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: AppColors.tomatoRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.currency_rupee_rounded,
                    color: AppColors.tomatoRed, size: 18 * scale),
              ),
              SizedBox(width: 12 * scale),
              Text(
                'Total Amount',
                style: GoogleFonts.poppins(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D1A0E),
                ),
              ),
            ],
          ),
          Text(
            '₹${widget.order['total_amount']}',
            style: GoogleFonts.poppins(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w900,
              color: AppColors.tomatoRed,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Card header ──────────────────────────────────────────────────

  Widget _buildCardHeader(
      String title, IconData icon, double scale) {
    return Padding(
      padding: EdgeInsets.all(14 * scale),
      child: Row(
        children: [
          Icon(icon, color: AppColors.tomatoRed, size: 18 * scale),
          SizedBox(width: 8 * scale),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15 * scale,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D1A0E),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading button ───────────────────────────────────────────────

  Widget _buildLoadingButton(double scale) {
    return Container(
      width: double.infinity,
      height: 54 * scale,
      decoration: BoxDecoration(
        color: AppColors.tomatoRed.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2.5),
        ),
      ),
    );
  }

  // ─── Action button ────────────────────────────────────────────────

  Widget _buildActionButton(String status, double scale) {
    if (status == 'preparing') {
      return _buildPrimaryActionBtn(
        label: '🛵  Pick Up Order',
        onTap: () => _updateStatus('on_the_way'),
        color: AppColors.tomatoRed,
        scale: scale,
      );
    } else if (status == 'on_the_way') {
      return _buildPrimaryActionBtn(
        label: '✅  Mark Delivered (Enter PIN)',
        onTap: _showPinDialog,
        color: Colors.green[600]!,
        scale: scale,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPrimaryActionBtn({
    required String label,
    required VoidCallback onTap,
    required Color color,
    required double scale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54 * scale,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ─── PIN dialog ───────────────────────────────────────────────────

  Future<void> _showPinDialog() async {
    final TextEditingController pinController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFFFF8F0),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.pin_outlined,
                    color: Colors.green[600], size: 28),
              ),
              const SizedBox(height: 16),

              Text(
                'Verify Delivery PIN',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D1A0E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask the customer for their 6-digit delivery PIN to confirm.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF2D1A0E).withOpacity(0.55),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // PIN field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFE8D5C0), width: 1.2),
                ),
                child: TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D1A0E),
                    letterSpacing: 10,
                  ),
                  decoration: InputDecoration(
                    hintText: '• • • • • •',
                    hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF2D1A0E).withOpacity(0.25),
                      fontSize: 18,
                      letterSpacing: 6,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Buttons
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
                      onTap: () async {
                        final pin = pinController.text.trim();
                        if (pin.length < 6) return;

                        final messenger =
                        ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        navigator.pop(); // close dialog
                        setState(() => _isUpdating = true);

                        try {
                          await _supabaseService
                              .verifyPinAndDeliver(
                            widget.order['id'].toString(),
                            pin,
                          );
                          if (mounted) {
                            navigator.pop(); // back to home
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✅ Order Delivered Successfully!',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13),
                                ),
                                backgroundColor: Colors.green[600],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            _showSnack(
                              '❌ ${e.toString().replaceAll('PostgrestException(', '').replaceAll(')', '')}',
                              isError: true,
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isUpdating = false);
                          }
                        }
                      },
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Verify & Deliver',
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

  // ─── Helpers ──────────────────────────────────────────────────────

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return {'color': Colors.orange,      'label': 'Pending',    'icon': Icons.hourglass_empty_rounded};
      case 'accepted':
        return {'color': Colors.blue,        'label': 'Accepted',   'icon': Icons.thumb_up_rounded};
      case 'preparing':
        return {'color': const Color(0xFFF57C00), 'label': 'Preparing', 'icon': Icons.local_fire_department_rounded};
      case 'on_the_way':
        return {'color': AppColors.tomatoRed,'label': 'On the Way', 'icon': Icons.delivery_dining_rounded};
      case 'delivered':
        return {'color': Colors.green,       'label': 'Delivered',  'icon': Icons.check_circle_rounded};
      default:
        return {'color': Colors.grey,        'label': status,       'icon': Icons.circle_outlined};
    }
  }
}