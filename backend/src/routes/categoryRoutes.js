const router = require('express').Router();
const { listCategories } = require('../controllers/cakeController');

router.get('/', listCategories);

module.exports = router;
