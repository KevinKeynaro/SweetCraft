const { z } = require('zod');

// Sumber: schema.sql (orders) + laporan §5 — status pending/approved/processing/
// ready/completed/cancelled/rejected.
const STATUSES = ['pending', 'approved', 'processing', 'ready', 'completed', 'cancelled', 'rejected'];

// Tanggal dari Flutter bisa "YYYY-MM-DD" atau "YYYY-MM-DDTHH:mm(:ss)";
// diseragamkan ke format yang diterima MySQL DATETIME.
const mysqlDateTime = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}([ T]\d{2}:\d{2}(:\d{2})?)?$/, 'Format tanggal tidak valid')
  .transform((s) => s.replace('T', ' '));

const createOrderSchema = z.object({
  body: z
    .object({
      order_type: z.enum(['ready_stock', 'custom']),
      cake_id: z.number().int().positive().optional(),
      custom_image_url: z.url('URL gambar tidak valid').max(500).optional(),
      custom_description: z.string().min(5, 'Deskripsi minimal 5 karakter').max(2000).optional(),
      decoration_note: z.string().max(500).optional(),
      pickup_date: mysqlDateTime.optional(),
    })
    // Aturan data schema.sql: ready_stock wajib cake_id, custom wajib deskripsi.
    .refine((o) => o.order_type !== 'ready_stock' || o.cake_id !== undefined, {
      message: 'cake_id wajib untuk pesanan ready-stock',
      path: ['cake_id'],
    })
    .refine((o) => o.order_type !== 'custom' || o.custom_description !== undefined, {
      message: 'custom_description wajib untuk pesanan custom',
      path: ['custom_description'],
    }),
});

const listOrdersQuerySchema = z.object({
  query: z.object({ status: z.enum(STATUSES, 'Status tidak valid').optional() }),
});

const updateStatusSchema = z.object({
  body: z.object({ status: z.enum(STATUSES, 'Status tidak valid') }),
});

const updatePriceSchema = z.object({
  body: z.object({ agreed_price: z.number().positive('Harga harus lebih dari 0') }),
});

const orderIdSchema = z.object({
  params: z.object({ id: z.coerce.number().int().positive('ID tidak valid') }),
});

module.exports = {
  createOrderSchema,
  listOrdersQuerySchema,
  updateStatusSchema,
  updatePriceSchema,
  orderIdSchema,
};
