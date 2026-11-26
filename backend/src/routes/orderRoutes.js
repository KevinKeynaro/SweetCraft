const router = require('express').Router();
const {
  createOrder, listOrders, getOrder, updateStatus, updatePrice, uploadCustomOrderImage,
} = require('../controllers/orderController');
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');
const { validate } = require('../middlewares/validateMiddleware');
const upload = require('../middlewares/uploadMiddleware');
const {
  createOrderSchema, listOrdersQuerySchema, updateStatusSchema, updatePriceSchema, orderIdSchema,
} = require('../validations/orderValidation');

// Semua endpoint pesanan wajib login
router.use(verifyToken);

router.post('/', requireRole('pembeli'), validate(createOrderSchema), createOrder);
router.post('/image', requireRole('pembeli'), upload.single('image'), uploadCustomOrderImage);
router.get('/', validate(listOrdersQuerySchema), listOrders);
router.get('/:id', validate(orderIdSchema), getOrder);
router.put('/:id/status', requireRole('penjual'), validate(orderIdSchema), validate(updateStatusSchema), updateStatus);
router.put('/:id/price', requireRole('penjual'), validate(orderIdSchema), validate(updatePriceSchema), updatePrice);

module.exports = router;
