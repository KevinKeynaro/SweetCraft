import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api.dart';
import '../widgets/seller_dashboard_widgets.dart';

/// Halaman/Tab form untuk menambah atau mengedit produk kue/pastry oleh pemilik toko.
/// Mendukung mode `embedded: true` (sebagai Tab "Tambah") dan modal full-page untuk Edit.
class AddEditCakePage extends StatefulWidget {
  const AddEditCakePage({
    super.key,
    this.cake,
    this.embedded = false,
    this.initialCategories = const [],
    this.isMockMode = false,
    this.onSaved,
  });

  /// Data produk yang akan diubah. Null berarti mode tambah produk baru.
  final Map<String, dynamic>? cake;

  /// True jika dipasang langsung di tab BottomNavigationBar (tanpa AppBar back button).
  final bool embedded;

  /// Daftar kategori awal dari HomePage agar dropdown langsung siap tampil.
  final List<Map<String, dynamic>> initialCategories;

  /// Jika true, mutasi disimpan secara lokal ke daftar mock tanpa gagal jaringan.
  final bool isMockMode;

  /// Callback setelah berhasil menyimpan produk (mengembalikan objek produk hasil API/lokal).
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
  bool _isCustom = false;
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

  void _initData() {
    final c = widget.cake;
    if (c != null) {
      _nameController.text = c['name'] as String? ?? '';
      _priceController.text = (c['price'] ?? '').toString();
      _stockController.text = (c['stock'] ?? '').toString();
      _descriptionController.text = c['description'] as String? ?? '';
      _selectedCategoryId = c['category_id'] as int?;
      _isCustom = c['is_custom'] == true || c['is_custom'] == 1;
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
    }

    if (widget.isMockMode) {
      if (_categories.isEmpty) {
        _categories = buildMockBakeryCategories();
        _selectedCategoryId ??= _categories.first['id'] as int?;
      }
      if (mounted) setState(() => _loadingCategories = false);
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
        if (_categories.isEmpty) {
          _categories = buildMockBakeryCategories();
        }
        _selectedCategoryId ??= _categories.first['id'] as int?;
        _loadingCategories = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() {
          _imageBytes = bytes;
          _imageFilename = picked.name;
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      final isDenied =
          e.code.contains('denied') || e.code.contains('permission');
      if (isDenied) {
        _showPermissionDeniedDialog(source);
      } else {
        _showErrorSnackBar(
          'Gagal membuka ${source == ImageSource.camera ? 'kamera' : 'galeri'}: ${e.message ?? e.code}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Gagal memilih gambar: $e');
    }
  }

  void _showPermissionDeniedDialog(ImageSource source) {
    final target = source == ImageSource.camera ? 'Kamera' : 'Galeri / Foto';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Izin $target Ditolak',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3B2A1E),
          ),
        ),
        content: Text(
          'SweetCraft memerlukan izin akses $target untuk mengambil foto produk kue. '
          'Silakan aktifkan izin $target pada Pengaturan perangkat Anda.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            height: 21 / 14,
            color: const Color(0xFF736052),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              minimumSize: const Size(90, 48),
              backgroundColor: const Color(0xFF8B5A2B),
              foregroundColor: const Color(0xFFFFFFFF),
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showImageSourcePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pilih Foto Produk',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B2A1E),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  minVerticalPadding: 14,
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF8B5A2B),
                  ),
                  title: Text(
                    'Pilih dari Galeri',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3B2A1E),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  minVerticalPadding: 14,
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF8B5A2B),
                  ),
                  title: Text(
                    'Ambil Foto Kamera',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3B2A1E),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFA63232),
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
      _isCustom = false;
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
    final selectedCat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => {'id': _selectedCategoryId, 'name': 'Cake'},
    );

    setState(() => _saving = true);

    try {
      final payload = <String, dynamic>{
        'category_id': _selectedCategoryId,
        'name': _nameController.text.trim(),
        'price': price,
        'is_custom': _isCustom,
        'stock': stock,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      };

      Map<String, dynamic> savedCake;

      if (widget.isMockMode || (_isEditing && (widget.cake?['id'] as int? ?? 0) < 0)) {
        savedCake = {
          ...?widget.cake,
          ...payload,
          'id': widget.cake?['id'] ?? -DateTime.now().millisecondsSinceEpoch,
          'category': selectedCat['name'] ?? 'Cake',
          'mock_asset': widget.cake?['mock_asset'] ?? 'assets/images/Tarts.png',
        };
      } else {
        int cakeId;
        if (_isEditing) {
          cakeId = widget.cake!['id'] as int;
          final res = await ApiService.put('/cakes/$cakeId', payload);
          savedCake = ((res as Map<String, dynamic>?)?['cake']
                  as Map<String, dynamic>?) ??
              {...widget.cake!, ...payload};
        } else {
          final res = await ApiService.post('/cakes', payload);
          savedCake = ((res as Map<String, dynamic>?)?['cake']
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
            final updatedWithImage = (uploadRes as Map<String, dynamic>?)?['cake']
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
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Perubahan produk berhasil disimpan'
                : 'Produk baru berhasil ditambahkan',
          ),
          backgroundColor: const Color(0xFF1E6B3A),
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
    final formContent = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
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
                  color: const Color(0xFF3B2A1E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lengkapi detail kue atau pastry untuk etalase toko.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF736052),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 1. Pemilihan Foto Produk
            GestureDetector(
              onTap: _saving ? null : _showImageSourcePicker,
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE8DFD1),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: _saving ? null : _showImageSourcePicker,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(
                  Icons.add_a_photo_outlined,
                  size: 18,
                  color: Color(0xFF8B5A2B),
                ),
                label: Text(
                  _imageBytes != null ||
                          (_existingImageUrl != null &&
                              _existingImageUrl!.isNotEmpty)
                      ? 'Ganti Foto Produk'
                      : 'Pilih Foto Produk',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8B5A2B),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2. Nama Produk
            _buildFieldLabel('Nama Produk *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Contoh: Strawberry Fruit Tart'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF3B2A1E),
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
                        color: Color(0xFF8B5A2B),
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
                      border: Border.all(color: const Color(0xFFE8DFD1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF8B5A2B),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat['id'] as int,
                            child: Text(
                              cat['name'] as String? ?? 'Kategori',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFF3B2A1E),
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
                        decoration: _inputDecoration('45000').copyWith(
                          prefixText: 'Rp ',
                          prefixStyle: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF8B5A2B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF3B2A1E),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Harga wajib diisi';
                          }
                          final numVal = double.tryParse(val.trim());
                          if (numVal == null || numVal <= 0) {
                            return 'Masukkan harga > 0';
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
                        decoration: _inputDecoration('10'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF3B2A1E),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            if (_isCustom) return null;
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
              decoration: _inputDecoration(
                'Ceritakan bahan, rasa, atau catatan penyajian kue...',
              ),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF3B2A1E),
              ),
            ),

            const SizedBox(height: 14),

            // 6. Switch Pre-Order / Custom
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8DFD1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Produk Custom / Pre-Order',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3B2A1E),
                          ),
                        ),
                        Text(
                          'Stok opsional jika dibuat berdasarkan pesanan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF736052),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isCustom,
                    activeThumbColor: const Color(0xFF8B5A2B),
                    onChanged: _saving
                        ? null
                        : (val) => setState(() => _isCustom = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 7. Tombol Simpan (>= 52dp untuk area sentuh nyaman satu tangan)
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: const Color(0xFF8B5A2B),
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
                  : Text(
                      _isEditing ? 'Simpan Perubahan' : 'Simpan Produk',
                    ),
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return SafeArea(
        bottom: false,
        child: formContent,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6EC),
        foregroundColor: const Color(0xFF3B2A1E),
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
        color: const Color(0xFF3B2A1E),
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
        borderSide: const BorderSide(color: Color(0xFFE8DFD1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8DFD1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8B5A2B), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFA63232)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFA63232), width: 1.5),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return Image.network(
        _existingImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_photo_alternate_outlined,
          size: 44,
          color: Color(0xFF8B5A2B),
        ),
        const SizedBox(height: 8),
        Text(
          'Ketuk untuk memilih foto kue',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF8B5A2B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Format JPG, PNG, atau WEBP maks 2 MB',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF736052),
          ),
        ),
      ],
    );
  }
}
