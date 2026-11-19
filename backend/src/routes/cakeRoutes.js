const router = require('express').Router();
const {
  listCakes, getCake, createCake, updateCake, deleteCake, uploadCakeImage,
} = require('../controllers/cakeController');
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');
const { validate } = require('../middlewares/validateMiddleware');
const upload = require('../middlewares/uploadMiddleware');
const { createCakeSchema, updateCakeSchema, cakeIdSchema } = require('../validations/cakeValidation');

// Katalog publik — pembeli (dan pengunjung) bisa melihat menu tanpa login
router.get('/', listCakes);
router.get('/:id', validate(cakeIdSchema), getCake);

// Pengelolaan menu — hanya penjual
router.post('/', verifyToken, requireRole('penjual'), validate(createCakeSchema), createCake);
router.post('/:id/image', verifyToken, requireRole('penjual'), validate(cakeIdSchema), upload.single('image'), uploadCakeImage);
router.put('/:id', verifyToken, requireRole('penjual'), validate(cakeIdSchema), validate(updateCakeSchema), updateCake);
router.delete('/:id', verifyToken, requireRole('penjual'), validate(cakeIdSchema), deleteCake);

module.exports = router;
