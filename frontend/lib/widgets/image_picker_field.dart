import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

/// Data foto yang dipilih dan siap diunggah ke backend.
class PickedImageData {
  const PickedImageData({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Menampilkan pemilih sumber foto (Galeri / Kamera), memvalidasi ukuran <= 2 MB,
/// serta menangani error izin dengan dialog informatif.
void showImageSourcePickerSheet(
  BuildContext context, {
  required String title,
  required String permissionTargetLabel,
  required ValueChanged<PickedImageData> onPicked,
  required ValueChanged<String> onError,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFFFFFFFF),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2B2118),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                minVerticalPadding: 14,
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF8C4A27),
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2B2118),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromSource(
                    context,
                    ImageSource.gallery,
                    permissionTargetLabel: permissionTargetLabel,
                    onPicked: onPicked,
                    onError: onError,
                  );
                },
              ),
              ListTile(
                minVerticalPadding: 14,
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF8C4A27),
                ),
                title: Text(
                  'Ambil Foto Kamera',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2B2118),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromSource(
                    context,
                    ImageSource.camera,
                    permissionTargetLabel: permissionTargetLabel,
                    onPicked: onPicked,
                    onError: onError,
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _pickFromSource(
  BuildContext context,
  ImageSource source, {
  required String permissionTargetLabel,
  required ValueChanged<PickedImageData> onPicked,
  required ValueChanged<String> onError,
}) async {
  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (!context.mounted) return;
      if (bytes.length > 2 * 1024 * 1024) {
        onError('Ukuran gambar maksimal 2 MB.');
        return;
      }
      onPicked(PickedImageData(bytes: bytes, filename: picked.name));
    }
  } on PlatformException catch (e) {
    if (!context.mounted) return;
    final isDenied =
        e.code.contains('denied') || e.code.contains('permission');
    if (isDenied) {
      _showPermissionDeniedDialog(
        context,
        source,
        permissionTargetLabel: permissionTargetLabel,
      );
    } else {
      onError(
        'Gagal membuka ${source == ImageSource.camera ? 'kamera' : 'galeri'}: ${e.message ?? e.code}',
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    onError('Gagal memilih gambar: $e');
  }
}

void _showPermissionDeniedDialog(
  BuildContext context,
  ImageSource source, {
  required String permissionTargetLabel,
}) {
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
          color: const Color(0xFF2B2118),
        ),
      ),
      content: Text(
        'SweetCraft memerlukan izin akses $target untuk mengambil $permissionTargetLabel. '
        'Silakan aktifkan izin $target pada Pengaturan perangkat Anda.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          height: 21 / 14,
          color: const Color(0xFF6E5D4F),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          style: FilledButton.styleFrom(
            minimumSize: const Size(90, 48),
            backgroundColor: const Color(0xFF8C4A27),
            foregroundColor: const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Mengerti'),
        ),
      ],
    ),
  );
}

/// Kotak pratinjau dan tombol pemilihan foto (reusable untuk form produk & pre-order).
class ImagePickerCard extends StatelessWidget {
  const ImagePickerCard({
    super.key,
    required this.imageBytes,
    this.existingImageUrl,
    required this.disabled,
    required this.placeholderText,
    required this.selectLabel,
    required this.replaceLabel,
    required this.onTapPick,
    this.onClear,
  });

  final Uint8List? imageBytes;
  final String? existingImageUrl;
  final bool disabled;
  final String placeholderText;
  final String selectLabel;
  final String replaceLabel;
  final VoidCallback onTapPick;
  final VoidCallback? onClear;

  bool get _hasImage =>
      imageBytes != null ||
      (existingImageUrl != null && existingImageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: disabled ? null : onTapPick,
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE6DDD0),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPreview(),
                if (onClear != null && imageBytes != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: const Color(0xCC2B2118),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: disabled ? null : onClear,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton.icon(
            onPressed: disabled ? null : onTapPick,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            icon: const Icon(
              Icons.add_a_photo_outlined,
              size: 18,
              color: Color(0xFF8C4A27),
            ),
            label: Text(
              _hasImage ? replaceLabel : selectLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8C4A27),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (imageBytes != null) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _buildSelectedImageFallback(),
      );
    }

    if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      return Image.network(
        existingImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildSelectedImageFallback() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.image_outlined, size: 44, color: Color(0xFF8C4A27)),
        const SizedBox(height: 8),
        Text(
          'Foto siap diunggah',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF8C4A27),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Pratinjau tidak didukung untuk format ini',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF6E5D4F),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_photo_alternate_outlined,
          size: 44,
          color: Color(0xFF8C4A27),
        ),
        const SizedBox(height: 8),
        Text(
          placeholderText,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF8C4A27),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Maksimal 2 MB',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF6E5D4F),
          ),
        ),
      ],
    );
  }
}
