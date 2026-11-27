import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api.dart';
import '../widgets/image_picker_field.dart';
import '../widgets/product_card.dart';

/// Halaman pembuatan pesanan pembeli:
/// - Jika `cake != null`: Pesanan ready-stock (`order_type: 'ready_stock'`).
/// - Jika `cake == null`: Pesanan custom pre-order (`order_type: 'custom'`).
class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({
    super.key,
    this.cake,
    this.embedded = false,
    this.onOrderCreated,
  });

  final Map<String, dynamic>? cake;
  final bool embedded;
  final VoidCallback? onOrderCreated;

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _customDescController = TextEditingController();
  final _decorationController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageFilename;
  DateTime? _pickupDateTime;
  int _quantity = 1;
  bool _submitting = false;

  bool get _isReadyStock => widget.cake != null;

  int get _maxQuantity {
    if (!_isReadyStock) return 10;
    final stock = widget.cake?['stock'];
    if (stock is num) {
      final intStock = stock.toInt();
      return intStock < 1 ? 1 : intStock;
    }
    return 20;
  }

  @override
  void dispose() {
    _customDescController.dispose();
    _decorationController.dispose();
    super.dispose();
  }

  Future<void> _pickPickupDateTime() async {
    final now = DateTime.now();
    final initialDate = _pickupDateTime ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8C4A27),
              onPrimary: Color(0xFFFFFFFF),
              onSurface: Color(0xFF2B2118),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _pickupDateTime ?? DateTime(date.year, date.month, date.day, 10, 0),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8C4A27),
              onPrimary: Color(0xFFFFFFFF),
              onSurface: Color(0xFF2B2118),
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;

    setState(() {
      _pickupDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 10,
        time?.minute ?? 0,
      );
    });
  }

  String _formatMysqlDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _formatDisplayDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y pukul $hh:$mm';
  }

  void _showImageSourcePicker() {
    showImageSourcePickerSheet(
      context,
      title: 'Pilih Foto Referensi',
      permissionTargetLabel: 'foto referensi pesanan',
      onPicked: (picked) {
        setState(() {
          _imageBytes = picked.bytes;
          _imageFilename = picked.filename;
        });
      },
      onError: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF991B1B),
          ),
        );
      },
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _customDescController.clear();
    _decorationController.clear();
    setState(() {
      _imageBytes = null;
      _imageFilename = null;
      _pickupDateTime = null;
      _quantity = 1;
    });
  }

  void _handleSubmitSuccess(Map<String, dynamic>? order, int count) {
    if (!mounted) return;
    if (widget.embedded) {
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 1
                ? '$count pesanan custom berhasil diajukan!'
                : 'Pesanan custom berhasil diajukan!',
          ),
          backgroundColor: const Color(0xFF166534),
        ),
      );
      widget.onOrderCreated?.call();
      return;
    }
    Navigator.pop(
      context,
      <String, dynamic>{
        'created': true,
        'count': count,
        'order': ?order,
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'order_type': _isReadyStock ? 'ready_stock' : 'custom',
    };

    if (_isReadyStock) {
      payload['cake_id'] = widget.cake!['id'];
    } else {
      payload['custom_description'] = _customDescController.text.trim();
    }

    final note = _decorationController.text.trim();
    if (note.isNotEmpty) {
      payload['decoration_note'] = note;
    }
    if (_pickupDateTime != null) {
      payload['pickup_date'] = _formatMysqlDateTime(_pickupDateTime!);
    }

    setState(() => _submitting = true);

    var createdCount = 0;
    Map<String, dynamic>? lastOrder;

    try {
      if (!_isReadyStock && _imageBytes != null) {
        final uploadRes = await ApiService.uploadMultipart(
          '/orders/image',
          fileBytes: _imageBytes!,
          fieldName: 'image',
          filename: _imageFilename ?? 'custom_cake.jpg',
        );
        final uploadedUrl =
            (uploadRes as Map<String, dynamic>?)?['image_url'] as String?;
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          payload['custom_image_url'] = uploadedUrl;
        }
      }

      for (var i = 0; i < _quantity; i++) {
        final res = await ApiService.post('/orders', payload);
        lastOrder =
            (res as Map<String, dynamic>?)?['order'] as Map<String, dynamic>?;
        createdCount++;
      }

      _handleSubmitSuccess(lastOrder, createdCount);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (createdCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$createdCount dari $_quantity pesanan dibuat, sisanya gagal: ${e.message}',
            ),
            backgroundColor: const Color(0xFFB45309),
          ),
        );
        if (widget.embedded) {
          _resetForm();
          widget.onOrderCreated?.call();
        } else {
          Navigator.pop(
            context,
            <String, dynamic>{'created': true, 'count': createdCount},
          );
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFF991B1B),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      if (createdCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$createdCount dari $_quantity pesanan dibuat, sisanya gagal terkirim.',
            ),
            backgroundColor: const Color(0xFFB45309),
          ),
        );
        if (widget.embedded) {
          _resetForm();
          widget.onOrderCreated?.call();
        } else {
          Navigator.pop(
            context,
            <String, dynamic>{'created': true, 'count': createdCount},
          );
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim pesanan. Periksa koneksi Anda.'),
          backgroundColor: Color(0xFF991B1B),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cake = widget.cake;

    final formContent = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        widget.embedded ? 16 : 12,
        16,
        28,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.embedded && cake == null) ...[
              Text(
                'Pre-Order Custom Cake',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2B2118),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pesan kue spesial sesuai desain dan keinginan Anda',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF736052),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (cake != null) ...[
              _CakeSummaryCard(cake: cake),
              const SizedBox(height: 18),
            ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EFE6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE6DDD0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome_outlined,
                          size: 20,
                          color: Color(0xFF8C4A27),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Jelaskan desain, ukuran, dan rasa kue yang diinginkan. Penjual akan meninjau dan menentukan harga final sebelum diproses.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              height: 19 / 12.5,
                              color: const Color(0xFF5C341E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('Upload Foto Referensi (Opsional)'),
                  const SizedBox(height: 8),
                  ImagePickerCard(
                    imageBytes: _imageBytes,
                    disabled: _submitting,
                    placeholderText: 'Ketuk untuk memilih foto referensi',
                    selectLabel: 'Pilih Foto Referensi',
                    replaceLabel: 'Ganti Foto Referensi',
                    onTapPick: _showImageSourcePicker,
                    onClear: () => setState(() {
                      _imageBytes = null;
                      _imageFilename = null;
                    }),
                  ),
                  const SizedBox(height: 14),
                  _buildLabel('Deskripsi Kue Custom *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _customDescController,
                    minLines: 3,
                    maxLines: 6,
                    inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                    decoration: _inputDecoration(
                      'Contoh: Kue ulang tahun 2 tingkat rasa cokelat hazelnut, diameter 20cm, tema pastel...',
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF2B2118),
                    ),
                    validator: (val) {
                      final trimmed = val?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Deskripsi kue custom wajib diisi';
                      }
                      if (trimmed.length < 5) {
                        return 'Deskripsi minimal 5 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                _buildLabel('Catatan Dekorasi / Ucapan (Opsional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _decorationController,
                  minLines: 2,
                  maxLines: 3,
                  inputFormatters: [LengthLimitingTextInputFormatter(500)],
                  decoration: _inputDecoration(
                    'Contoh: Tulisan "Selamat Ulang Tahun Ibu"',
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF2B2118),
                  ),
                ),

                const SizedBox(height: 16),

                _buildLabel('Jadwal Pengambilan (Opsional)'),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _submitting ? null : _pickPickupDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6DDD0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Color(0xFF8C4A27),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _pickupDateTime != null
                                ? _formatDisplayDateTime(_pickupDateTime!)
                                : 'Pilih tanggal & jam ambil',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: _pickupDateTime != null
                                  ? const Color(0xFF2B2118)
                                  : const Color(0xFFA79A8C),
                            ),
                          ),
                        ),
                        if (_pickupDateTime != null)
                          IconButton(
                            onPressed: _submitting
                                ? null
                                : () => setState(() => _pickupDateTime = null),
                            tooltip: 'Hapus jadwal',
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFF6E5D4F),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                _buildQuantitySection(cake),

                const SizedBox(height: 26),

                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFF8C4A27),
                    foregroundColor: const Color(0xFFFFFFFF),
                    disabledBackgroundColor: const Color(0xFFEFE9E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFFFFFF),
                          ),
                        )
                      : Text(_submitButtonLabel(cake)),
                ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return SafeArea(bottom: false, child: formContent);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF7),
        foregroundColor: const Color(0xFF2B2118),
        elevation: 0,
        title: Text(
          _isReadyStock ? 'Konfirmasi Pesanan' : 'Pesan Custom Cake',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(child: formContent),
    );
  }

  String _submitButtonLabel(Map<String, dynamic>? cake) {
    if (!_isReadyStock) {
      return _quantity == 1
          ? 'Ajukan Pre-Order Custom'
          : 'Ajukan $_quantity Pre-Order Custom';
    }
    final rawPrice = cake?['price'];
    final unitPrice = rawPrice is num
        ? rawPrice.toDouble()
        : (double.tryParse('${rawPrice ?? ''}') ?? 0.0);
    final total = formatRupiah(unitPrice * _quantity);
    return _quantity == 1
        ? 'Kirim Pesanan ($total)'
        : 'Kirim $_quantity Pesanan ($total)';
  }

  Widget _buildQuantitySection(Map<String, dynamic>? cake) {
    final stock = cake?['stock'];
    final maxQty = _maxQuantity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6DDD0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jumlah Pesanan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2B2118),
                  ),
                ),
                if (_isReadyStock && stock is num)
                  Text(
                    'Tersedia: ${stock.toInt()}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF6E5D4F),
                    ),
                  ),
              ],
            ),
          ),
          _QtyStepButton(
            icon: Icons.remove_rounded,
            tooltip: 'Kurangi jumlah',
            enabled: !_submitting && _quantity > 1,
            onTap: () => setState(() => _quantity--),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2B2118),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _QtyStepButton(
            icon: Icons.add_rounded,
            tooltip: 'Tambah jumlah',
            enabled: !_submitting && _quantity < maxQty,
            onTap: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF2B2118),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: const Color(0xFFA79A8C),
      ),
      filled: true,
      fillColor: const Color(0xFFFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE6DDD0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE6DDD0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8C4A27), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF991B1B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF991B1B), width: 1.5),
      ),
    );
  }
}

class _CakeSummaryCard extends StatelessWidget {
  const _CakeSummaryCard({required this.cake});

  final Map<String, dynamic> cake;

  @override
  Widget build(BuildContext context) {
    final name = cake['name'] as String? ?? 'Kue';
    final category = displayCategoryName(cake['category'] as String?);
    final imageUrl = cake['image_url'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DDD0)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6DDD0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.cake_outlined,
                      color: Color(0xFF8C4A27),
                    ),
                  )
                : const Icon(Icons.cake_outlined, color: Color(0xFF8C4A27)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.isNotEmpty)
                  Text(
                    category,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8C4A27),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2B2118),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatRupiah(cake['price'])} • ${stockLabel(cake['stock'])}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C341E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepButton extends StatelessWidget {
  const _QtyStepButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? const Color(0xFF8C4A27) : const Color(0xFFEFE9E1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFFA79A8C),
            ),
          ),
        ),
      ),
    );
  }
}
