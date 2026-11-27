import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api.dart';
import 'order_shared_widgets.dart';
import 'product_card.dart';
import 'seller_dashboard_widgets.dart';

/// Halaman Manajemen Pesanan & Kurasi Custom Pre-Order untuk Penjual (Tab 3).
///
/// Penjual dapat:
/// - Melihat & memfilter seluruh pesanan masuk (`GET /api/orders`)
/// - Mencari pesanan berdasarkan nama pembeli, kue, atau deskripsi custom
/// - Meninjau foto referensi custom cake dan menetapkan harga final (`PUT /api/orders/:id/price`)
/// - Memperbarui status produksi pesanan (`PUT /api/orders/:id/status`)
class SellerOrdersView extends StatefulWidget {
  const SellerOrdersView({
    super.key,
    this.initialOrders,
    this.onUpdatePrice,
    this.onUpdateStatus,
  });

  /// Opsional untuk pengujian widget tanpa memanggil API langsung.
  final List<Map<String, dynamic>>? initialOrders;
  final Future<Map<String, dynamic>> Function(int orderId, double price)?
  onUpdatePrice;
  final Future<Map<String, dynamic>> Function(int orderId, String status)?
  onUpdateStatus;

  @override
  State<SellerOrdersView> createState() => _SellerOrdersViewState();
}

class _SellerOrdersViewState extends State<SellerOrdersView> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;
  String _selectedStatus = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialOrders != null) {
      _orders = widget.initialOrders!
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _loading = false;
    } else {
      _loadOrders();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (widget.initialOrders != null && widget.onUpdateStatus != null) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final endpoint = _selectedStatus == 'all'
          ? '/orders'
          : '/orders?status=$_selectedStatus';
      final res = await ApiService.get(endpoint);
      final list =
          ((res as Map<String, dynamic>?)?['orders'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      if (!mounted) return;
      setState(() {
        _orders = list.map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat pesanan masuk. Periksa koneksi Anda.';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filteredOrders() {
    final q = _query.trim().toLowerCase();
    return _orders.where((order) {
      final status = order['status'] as String? ?? 'pending';
      if (_selectedStatus != 'all' && status != _selectedStatus) {
        return false;
      }
      if (q.isEmpty) return true;
      final buyer = (order['buyer_name'] as String? ?? '').toLowerCase();
      final cake = (order['cake_name'] as String? ?? '').toLowerCase();
      final desc = (order['custom_description'] as String? ?? '').toLowerCase();
      final note = (order['decoration_note'] as String? ?? '').toLowerCase();
      final idStr = '${order['id'] ?? ''}';
      return buyer.contains(q) ||
          cake.contains(q) ||
          desc.contains(q) ||
          note.contains(q) ||
          idStr.contains(q);
    }).toList();
  }

  Future<Map<String, dynamic>> _callUpdatePrice(
    int orderId,
    double price,
  ) async {
    if (widget.onUpdatePrice != null) {
      return widget.onUpdatePrice!(orderId, price);
    }
    final res = await ApiService.put('/orders/$orderId/price', {
      'agreed_price': price,
    });
    return ((res as Map<String, dynamic>?)?['order']
            as Map<String, dynamic>?) ??
        <String, dynamic>{'id': orderId, 'agreed_price': price};
  }

  Future<Map<String, dynamic>> _callUpdateStatus(
    int orderId,
    String status,
  ) async {
    if (widget.onUpdateStatus != null) {
      return widget.onUpdateStatus!(orderId, status);
    }
    final res = await ApiService.put('/orders/$orderId/status', {
      'status': status,
    });
    return ((res as Map<String, dynamic>?)?['order']
            as Map<String, dynamic>?) ??
        <String, dynamic>{'id': orderId, 'status': status};
  }

  Future<void> _openOrderCuration(Map<String, dynamic> summary) async {
    Map<String, dynamic> detail = summary;
    final orderId = summary['id'];

    if (widget.initialOrders == null && orderId != null) {
      try {
        final res = await ApiService.get('/orders/$orderId');
        final fetched = (res as Map<String, dynamic>?)?['order'];
        if (fetched is Map<String, dynamic>) {
          detail = Map<String, dynamic>.from(fetched);
        }
      } catch (_) {
        // Tetap tampilkan data ringkasan jika refresh detail gagal
      }
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SellerOrderCurationSheet(
        order: detail,
        onUpdatePrice: _callUpdatePrice,
        onUpdateStatus: _callUpdateStatus,
        onOrderUpdated: (updated) {
          setState(() {
            final idx = _orders.indexWhere((o) => o['id'] == updated['id']);
            if (idx != -1) {
              _orders[idx] = updated;
            }
          });
          if (widget.initialOrders == null) {
            _loadOrders();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SellerCurvedHeader(
          title: 'Pesanan Masuk',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x2EFFFFFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${filtered.length} Order',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFAF7F2),
              ),
            ),
          ),
          bottomChild: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val),
              cursorColor: const Color(0xFF8C4A27),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF2B2118),
              ),
              decoration: InputDecoration(
                hintText: 'Cari pembeli, kue, atau catatan...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFFA79A8C),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF6E5D4F),
                  size: 22,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 48,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        tooltip: 'Hapus pencarian',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF6E5D4F),
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OrderFilterChipsRow(
            selectedStatus: _selectedStatus,
            onSelected: (statusKey) {
              setState(() => _selectedStatus = statusKey);
              if (widget.initialOrders == null) {
                _loadOrders();
              }
            },
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadOrders,
            color: const Color(0xFF8C4A27),
            backgroundColor: const Color(0xFFFFFFFF),
            child: _buildListBody(filtered),
          ),
        ),
      ],
    );
  }

  Widget _buildListBody(List<Map<String, dynamic>> filtered) {
    if (_loading && _orders.isEmpty) {
      return const DashboardSkeleton(itemCount: 4);
    }

    if (_error != null && _orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          DashboardErrorState(message: _error!, onRetry: _loadOrders),
        ],
      );
    }

    if (filtered.isEmpty) {
      final hasFilter = _selectedStatus != 'all' || _query.trim().isNotEmpty;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          DashboardEmptyState(
            icon: hasFilter
                ? Icons.filter_list_off_rounded
                : Icons.receipt_long_outlined,
            title: hasFilter ? 'Pesanan Tidak Ditemukan' : 'Belum Ada Pesanan',
            message: hasFilter
                ? 'Coba ubah filter status atau kata kunci pencarian.'
                : 'Pesanan siap saji dan custom pre-order dari pembeli akan tampil di sini.',
            actionLabel: hasFilter ? 'Reset Filter' : null,
            onAction: hasFilter
                ? () {
                    _searchController.clear();
                    setState(() {
                      _selectedStatus = 'all';
                      _query = '';
                    });
                    if (widget.initialOrders == null) {
                      _loadOrders();
                    }
                  }
                : null,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = filtered[index];
        return OrderSummaryCard(
          order: order,
          showBuyerName: true,
          onTap: () => _openOrderCuration(order),
        );
      },
    );
  }
}

class _SellerOrderCurationSheet extends StatefulWidget {
  const _SellerOrderCurationSheet({
    required this.order,
    required this.onUpdatePrice,
    required this.onUpdateStatus,
    required this.onOrderUpdated,
  });

  final Map<String, dynamic> order;
  final Future<Map<String, dynamic>> Function(int orderId, double price)
  onUpdatePrice;
  final Future<Map<String, dynamic>> Function(int orderId, String status)
  onUpdateStatus;
  final ValueChanged<Map<String, dynamic>> onOrderUpdated;

  @override
  State<_SellerOrderCurationSheet> createState() =>
      _SellerOrderCurationSheetState();
}

class _SellerOrderCurationSheetState extends State<_SellerOrderCurationSheet> {
  late Map<String, dynamic> _order;
  late final TextEditingController _priceController;
  bool _saving = false;
  String? _priceError;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    final initialPrice = _order['agreed_price'];
    final initialText = initialPrice is num ? '${initialPrice.round()}' : '';
    _priceController = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  int? get _orderId => (_order['id'] as num?)?.toInt();
  bool get _isCustom => (_order['order_type'] as String?) == 'custom';
  String get _status => _order['status'] as String? ?? 'pending';

  double? _validatePriceInput() {
    final raw = _priceController.text.trim();
    if (raw.isEmpty) {
      setState(() => _priceError = 'Harga final wajib diisi');
      return null;
    }
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      setState(() => _priceError = 'Harga harus lebih dari 0');
      return null;
    }
    setState(() => _priceError = null);
    return parsed;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFF991B1B)
            : const Color(0xFF166534),
      ),
    );
  }

  Future<void> _saveCustomPrice() async {
    final id = _orderId;
    if (id == null) return;
    final price = _validatePriceInput();
    if (price == null) return;

    setState(() => _saving = true);
    try {
      final priced = await widget.onUpdatePrice(id, price);
      if (!mounted) return;
      final merged = {..._order, ...priced, 'agreed_price': price};
      setState(() => _order = merged);
      widget.onOrderUpdated(merged);
      _showSnack('Harga final dikirim, menunggu keputusan pembeli');
    } on ApiException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (_) {
      _showSnack('Gagal menyimpan harga final.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _transitionStatus(String nextStatus, String successMsg) async {
    final id = _orderId;
    if (id == null) return;

    if (nextStatus == 'rejected') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Tolak Pesanan?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2B2118),
            ),
          ),
          content: Text(
            'Pesanan #${_order['id']} akan ditolak dan tidak dapat diproses lagi.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF6E5D4F),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 44),
                foregroundColor: const Color(0xFF6E5D4F),
              ),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: FilledButton.styleFrom(
                minimumSize: const Size(84, 44),
                backgroundColor: const Color(0xFF991B1B),
                foregroundColor: const Color(0xFFFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tolak'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      final updated = await widget.onUpdateStatus(id, nextStatus);
      final merged = {..._order, ...updated, 'status': nextStatus};
      if (!mounted) return;
      widget.onOrderUpdated(merged);
      _showSnack(successMsg);
      Navigator.pop(context);
    } on ApiException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (_) {
      _showSnack('Gagal memperbarui status pesanan.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final title = _isCustom
        ? 'Custom Cake Pre-Order'
        : (_order['cake_name'] as String? ?? 'Pesanan Kue');
    final buyerName = _order['buyer_name'] as String? ?? 'Pembeli';
    final customImageUrl = _order['custom_image_url'] as String?;
    final customDesc = _order['custom_description'] as String?;
    final note = _order['decoration_note'] as String?;
    final pickup = _order['pickup_date']?.toString();
    final agreedPrice = _order['agreed_price'];
    final canEditCustomPrice =
        _isCustom && (_status == 'pending' || _status == 'approved');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6DDD0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pesanan #${_order['id'] ?? '-'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6E5D4F),
                    ),
                  ),
                  OrderStatusBadge(status: _status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2B2118),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pembeli: $buyerName',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6E5D4F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                agreedPrice != null
                    ? 'Harga: ${formatRupiah(agreedPrice)}'
                    : 'Harga final belum ditetapkan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: agreedPrice != null
                      ? const Color(0xFF8C4A27)
                      : const Color(0xFF92400E),
                ),
              ),

              if (customImageUrl != null && customImageUrl.isNotEmpty) ...[
                const SizedBox(height: 14),
                OrderCustomImagePreview(imageUrl: customImageUrl),
              ],
              if (customDesc != null && customDesc.isNotEmpty) ...[
                const SizedBox(height: 12),
                OrderDetailBlock(label: 'Deskripsi Custom', value: customDesc),
              ],
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 10),
                OrderDetailBlock(label: 'Catatan Dekorasi', value: note),
              ],
              if (pickup != null && pickup.isNotEmpty) ...[
                const SizedBox(height: 10),
                OrderDetailBlock(
                  label: 'Jadwal Ambil',
                  value: formatOrderDate(pickup),
                ),
              ],

              if (canEditCustomPrice) ...[
                const SizedBox(height: 16),
                Text(
                  'Harga Final Custom (Rp)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2B2118),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _priceController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2B2118),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 250000',
                    prefixText: 'Rp ',
                    prefixStyle: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF8C4A27),
                      fontWeight: FontWeight.w700,
                    ),
                    errorText: _priceError,
                    filled: true,
                    fillColor: const Color(0xFFFDFBF7),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE6DDD0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE6DDD0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF8C4A27),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),
              ..._buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    if (_status == 'pending' && _isCustom) {
      return [
        FilledButton(
          onPressed: _saving ? null : _saveCustomPrice,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: const Color(0xFF8C4A27),
            foregroundColor: const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Kirim Harga ke Pembeli'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _saving
              ? null
              : () => _transitionStatus('rejected', 'Pesanan ditolak'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: const Color(0xFF991B1B),
            side: const BorderSide(color: Color(0xFF991B1B)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Tolak Pesanan'),
        ),
      ];
    }

    if (_status == 'pending') {
      return [
        FilledButton(
          onPressed: _saving
              ? null
              : () => _transitionStatus(
                  'processing',
                  'Pesanan mulai diproses',
                ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: const Color(0xFF8C4A27),
            foregroundColor: const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Terima & Proses'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _saving
              ? null
              : () => _transitionStatus('rejected', 'Pesanan ditolak'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: const Color(0xFF991B1B),
            side: const BorderSide(color: Color(0xFF991B1B)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Tolak Pesanan'),
        ),
      ];
    }

    if (_status == 'approved') {
      return [
        FilledButton(
          onPressed: _saving
              ? null
              : () => _transitionStatus(
                  'processing',
                  'Pesanan mulai diproses',
                ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: const Color(0xFF8C4A27),
            foregroundColor: const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Mulai Proses'),
        ),
      ];
    }

    if (_status == 'processing') {
      return [
        FilledButton(
          onPressed: _saving
              ? null
              : () => _transitionStatus('ready', 'Pesanan siap diambil'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: const Color(0xFF166534),
            foregroundColor: const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Tandai Siap Diambil'),
        ),
      ];
    }

    if (_status == 'ready') {
      return [
        FilledButton(
          onPressed: _saving
              ? null
              : () => _transitionStatus('completed', 'Pesanan selesai'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: const Color(0xFF166534),
            foregroundColor: const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Selesaikan Pesanan'),
        ),
      ];
    }

    return [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: const Color(0xFF8C4A27),
          foregroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text('Tutup'),
      ),
    ];
  }
}
