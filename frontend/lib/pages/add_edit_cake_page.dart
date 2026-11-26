import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api.dart';
import '../widgets/image_picker_field.dart';
import '../widgets/product_card.dart';

/// Halaman/Tab form untuk menambah atau mengedit produk kue/pastry oleh pemilik toko.
/// Mendukung mode `embedded: true` (sebagai Tab "Tambah") dan modal full-page untuk Edit.
class AddEditCakePage extends StatefulWidget {
  const AddEditCakePage({
    super.key,
    this.cake,
    this.embedded = false,
    this.initialCategories = const [],
    this.onSaved,
  });

  /// Data produk yang akan diubah. Null berarti mode tambah produk baru.
  final Map<String, dynamic>? cake;

  /// True jika dipasang langsung di tab BottomNavigationBar (tanpa AppBar back button).
  final bool embedded;

  /// Daftar kategori awal dari HomePage agar dropdown langsung siap tampil.
  final List<Map<String, dynamic>> initialCategories;

  /// Callback setelah berhasil menyimpan produk (mengembalikan objek produk hasil API).
  final ValueChanged<Map<String, dynamic>>? onSaved;

  @override
  State<AddEditCakePage> createState() => _AddEditCakePageState();
}

class _AddEditCakePageState extends State<AddEditCakePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  bool _loadingCategories = true;
  bool _saving = false;

  Uint8List? _imageBytes;
  String? _imageFilename;
  String? _existingImageUrl;

  bool get _isEditing => widget.cake != null;

  @override
  void initState() {
    super.initState();
    _initData();
    _loadCategories();
  }

  @override
  void didUpdateWidget(covariant AddEditCakePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategories != oldWidget.initialCategories &&
        widget.initialCategories.isNotEmpty) {
      setState(() {
        _categories = List<Map<String, dynamic>>.from(widget.initialCategories);
        _loadingCategories = false;
        final exists = _categories.any((c) => c['id'] == _selectedCategoryId);
        if (!exists) {
          _selectedCategoryId = _categories.first['id'] as int?;
        }
      });
    }
  }

  void _initData() {
    final c = widget.cake;
    if (c != null) {
      _nameController.text = c['name'] as String? ?? '';
      _priceController.text = (c['price'] ?? '').toString();
      _stockController.text = (c['stock'] ?? '').toString();
      _descriptionController.text = c['description'] as String? ?? '';
      _selectedCategoryId = c['category_id'] as int?;
      _existingImageUrl = c['image_url'] as String?;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (widget.initialCategories.isNotEmpty) {
      _categories = List<Map<String, dynamic>>.from(widget.initialCategories);
      _selectedCategoryId ??= _categories.first['id'] as int?;
      _loadingCategories = false;
      return;
    }

    try {
      final res = await ApiService.get('/categories');
      final data = res as Map<String, dynamic>?;
      final cats =
          (data?['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (!mounted) return;
      if (cats.isNotEmpty) {
        setState(() {
          _categories = cats;
          _loadingCategories = false;
          final exists = cats.any((c) => c['id'] == _selectedCategoryId);
          if (!exists) {
            _selectedCategoryId = cats.first['id'] as int?;
          }
        });
      } else {
        setState(() => _loadingCategories = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_categories.isNotEmpty) {
          _selectedCategoryId ??= _categories.first['id'] as int?;
        }
        _loadingCategories = false;
      });
    }
  }

  void _showImageSourcePicker() {
    showImageSourcePickerSheet(
      context,
      title: 'Pilih Foto Produk',
      permissionTargetLabel: 'foto produk kue',
      onPicked: (picked) {
        setState(() {
          _imageBytes = picked.bytes;
          _imageFilename = picked.filename;
        });
      },
      onError: _showErrorSnackBar,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF991B1B),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    _descriptionController.clear();
    setState(() {
      _imageBytes = null;
      _imageFilename = null;
      _existingImageUrl = null;
      if (_categories.isNotEmpty) {
        _selectedCategoryId = _categories.first['id'] as int?;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showErrorSnackBar('Pilih kategori produk terlebih dahulu.');
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final stockText = _stockController.text.trim();
    final stock = stockText.isEmpty ? null : int.tryParse(stockText);

    setState(() => _saving = true);

    try {
      final payload = <String, dynamic>{
        'category_id': _selectedCategoryId,
        'name': _nameController.text.trim(),
        'price': price,
        'is_custom': false,
        'stock': stock,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      };

      Map<String, dynamic> savedCake;
      int cakeId;

      if (_isEditing) {
        cakeId = widget.cake!['id'] as int;
        final res = await ApiService.put('/cakes/$cakeId', payload);
        savedCake =
            ((res as Map<String, dynamic>?)?['cake']
                as Map<String, dynamic>?) ??
            {...widget.cake!, ...payload};
      } else {
        final res = await ApiService.post('/cakes', payload);
        savedCake =
            ((res as Map<String, dynamic>?)?['cake']
                as Map<String, dynamic>?) ??
            payload;
        cakeId = savedCake['id'] as int? ?? 0;
      }

      // Upload foto via multipart jika penjual memilih foto baru
      if (_imageBytes != null && cakeId > 0) {
        try {
          final uploadRes = await ApiService.uploadMultipart(
            '/cakes/$cakeId/image',
            fileBytes: _imageBytes!,
            fieldName: 'image',
            filename: _imageFilename ?? 'cake_$cakeId.jpg',
          );
          final updatedWithImage =
              (uploadRes as Map<String, dynamic>?)?['cake']
                  as Map<String, dynamic>?;
          if (updatedWithImage != null) {
            savedCake = updatedWithImage;
          }
        } catch (uploadError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Produk tersimpan, namun foto gagal diunggah: $uploadError',
                ),
                backgroundColor: const Color(0xFFB45309),
              ),
            );
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Perubahan produk berhasil disimpan'
                : 'Produk baru berhasil ditambahkan',
          ),
          backgroundColor: const Color(0xFF166534),
        ),
      );

      widget.onSaved?.call(savedCake);

      if (widget.embedded) {
        _resetForm();
      } else {
        Navigator.pop(context, savedCake);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Batasi input mengikuti schema backend: nama <= 150 karakter,
    // deskripsi <= 5000 karakter, serta harga/stok hanya digit.
    // Sumber: https://api.flutter.dev/flutter/services/FilteringTextInputFormatter-class.html
    // Sumber: https://api.flutter.dev/flutter/services/LengthLimitingTextInputFormatter-class.html
    final formContent = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, widget.embedded ? 16 : 12, 16, 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.embedded) ...[
              Text(
                'Tambah Produk',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2B2118),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lengkapi detail kue atau pastry untuk etalase toko.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF6E5D4F),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 1. Pemilihan Foto Produk
            ImagePickerCard(
              imageBytes: _imageBytes,
              existingImageUrl: _existingImageUrl,
              disabled: _saving,
              placeholderText: 'Ketuk untuk memilih foto kue',
              selectLabel: 'Pilih Foto Produk',
              replaceLabel: 'Ganti Foto Produk',
              onTapPick: _showImageSourcePicker,
            ),

            const SizedBox(height: 14),

            // 2. Nama Produk
            _buildFieldLabel('Nama Produk *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              inputFormatters: [LengthLimitingTextInputFormatter(150)],
              decoration: _inputDecoration('Contoh: Strawberry Fruit Tart'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF2B2118),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama produk wajib diisi';
                }
                if (val.trim().length < 2) {
                  return 'Nama produk minimal 2 karakter';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 3. Kategori
            _buildFieldLabel('Kategori *'),
            const SizedBox(height: 6),
            _loadingCategories
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        color: Color(0xFF8C4A27),
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6DDD0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF8C4A27),
                        ),
                        items: _categories.map((cat) {
                          final catLabel = displayCategoryName(
                            cat['name'] as String?,
                          );
                          return DropdownMenuItem<int>(
                            value: cat['id'] as int,
                            child: Text(
                              catLabel.isEmpty ? 'Kategori' : catLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFF2B2118),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: _saving
                            ? null
                            : (newVal) =>
                                  setState(() => _selectedCategoryId = newVal),
                      ),
                    ),
                  ),

            const SizedBox(height: 16),

            // 4. Harga & Stok (aman untuk lebar 360dp)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Harga (Rp) *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        decoration: _inputDecoration('45000').copyWith(
                          prefixText: 'Rp ',
                          prefixStyle: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF8C4A27),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF2B2118),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Harga wajib diisi';
                          }
                          final numVal = double.tryParse(val.trim());
                          if (numVal == null || numVal <= 0) {
                            return 'Minimal lebih dari 0';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Stok Ready *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        decoration: _inputDecoration('10'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF2B2118),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Stok wajib diisi';
                          }
                          final intVal = int.tryParse(val.trim());
                          if (intVal == null || intVal < 0) {
                            return 'Stok minimal 0';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 5. Deskripsi
            _buildFieldLabel('Deskripsi Produk'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              inputFormatters: [LengthLimitingTextInputFormatter(5000)],
              decoration: _inputDecoration(
                'Ceritakan bahan, rasa, atau catatan penyajian kue...',
              ),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF2B2118),
              ),
            ),

            const SizedBox(height: 26),

            // 7. Tombol Simpan (>= 52dp untuk area sentuh nyaman satu tangan)
            FilledButton(
              onPressed: _saving ? null : _submit,
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
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFFFFFF),
                      ),
                    )
                  : Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Produk'),
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
          _isEditing ? 'Edit Produk' : 'Tambah Produk',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(child: formContent),
    );
  }

  Widget _buildFieldLabel(String text) {
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
