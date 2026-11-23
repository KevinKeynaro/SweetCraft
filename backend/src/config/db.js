const mysql = require('mysql2/promise');

// Pool koneksi MySQL — dipakai semua controller.
// mysql2/promise sudah berbasis Promise: createPool langsung bisa di-await, tanpa .promise().
const pool = mysql
  .createPool({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    // mysql2 default: DECIMAL dikembalikan sebagai STRING ("75000.00").
    // Opsi ini (diverifikasi ada di node_modules/mysql2/lib/connection_config.js)
    // membuat price sampai ke API/Flutter sebagai number.
    decimalNumbers: true,
  });

module.exports = pool;
