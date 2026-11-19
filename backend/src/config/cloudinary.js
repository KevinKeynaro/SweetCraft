const cloudinary = require('cloudinary').v2;

// Kredensial hanya hidup di server (dari .env) — tidak pernah dikirim ke Flutter.
// Source: https://cloudinary.com/documentation/node_integration#configuration
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

module.exports = cloudinary;
