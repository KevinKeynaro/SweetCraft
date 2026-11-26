const cloudinary = require('../config/cloudinary');

/**
 * Mengunggah buffer gambar ke folder Cloudinary yang ditentukan.
 * Membungkus cloudinary.uploader.upload_stream ke dalam Promise agar bisa di-await.
 */
function uploadImageBuffer(buffer, folder) {
  return new Promise((resolve, reject) => {
    cloudinary.uploader
      .upload_stream(
        { folder, resource_type: 'image' },
        (error, result) => (error ? reject(error) : resolve(result))
      )
      .end(buffer);
  });
}

module.exports = { uploadImageBuffer };
