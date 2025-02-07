const express = require('express');
const router = express.Router();
const indexController = require('../controllers/indexController.js');

router.post('/api/number', indexController.orgQuery);
router.post('/api/name', indexController.nameQuery);
router.get('/', indexController.indexPage);

exports.router = router;