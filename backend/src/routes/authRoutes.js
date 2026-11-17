const router = require('express').Router();
const { register, login, me } = require('../controllers/authController');
const { verifyToken } = require('../middlewares/authMiddleware');
const { validate } = require('../middlewares/validateMiddleware');
const { registerSchema, loginSchema } = require('../validations/authValidation');

router.post('/register', validate(registerSchema), register); // daftar akun baru (selalu role pembeli)
router.post('/login', validate(loginSchema), login);          // dapat JWT
router.get('/me', verifyToken, me);                           // profil dari token — protected

module.exports = router;
