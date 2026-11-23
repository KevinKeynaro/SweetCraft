const { z } = require('zod');

// Sumber field: schema.sql — cakes (category_id, name, price, is_custom,
// stock, description, image_url). image_url diisi dari upload Cloudinary (tahap berikutnya).
const cakeBody = z.object({
  category_id: z.number().int().positive('Kategori tidak valid'),
  name: z.string().min(2, 'Nama minimal 2 karakter').max(150),
  price: z.number().nonnegative('Harga tidak boleh negatif'),
  is_custom: z.boolean().optional(),
  stock: z.number().int().nonnegative('Stok tidak boleh negatif').nullable().optional(),
  description: z.string().max(5000).nullable().optional(),
  image_url: z.url('URL gambar tidak valid').max(500).nullable().optional(),
});

// POST — semua field wajib dasar harus ada
const createCakeSchema = z.object({ body: cakeBody });

// PUT — boleh update sebagian (mis. hanya harga/stok), minimal satu field.
const updateCakeSchema = z.object({
  body: cakeBody
    .partial()
    .refine((o) => Object.keys(o).length > 0, 'Minimal satu field diisi'),
});

// Params :id — wajib angka positif (string dari URL dikonversi oleh zod)
const cakeIdSchema = z.object({
  params: z.object({ id: z.coerce.number().int().positive('ID tidak valid') }),
});

module.exports = { createCakeSchema, updateCakeSchema, cakeIdSchema };
