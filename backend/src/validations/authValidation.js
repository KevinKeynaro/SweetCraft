const { z } = require('zod');

// Schema dibungkus key 'body' — sesuai pola validate() yang mem-parse {body, query, params}.
// Key query/params di luar schema otomatis di-strip oleh zod (bukan error).
// Zod 4: format string jadi fungsi top-level (z.email), bukan z.string().email()
// Source: https://zod.dev/v4/changelog — "Top-level string formats"
const registerSchema = z.object({
  body: z.object({
    name: z.string().min(2, 'Nama minimal 2 karakter').max(100),
    email: z.email('Email tidak valid').max(150),
    password: z.string().min(6, 'Password minimal 6 karakter').max(255),
    phone: z.string().min(8, 'Nomor HP minimal 8 digit').max(20).optional(),
  }),
});

const loginSchema = z.object({
  body: z.object({
    email: z.email('Email tidak valid').max(150),
    password: z.string().min(1, 'Password wajib diisi'),
  }),
});

module.exports = { registerSchema, loginSchema };
