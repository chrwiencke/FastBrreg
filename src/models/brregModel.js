const mongoose = require('mongoose');

const BrregSchema = new mongoose.Schema({}, { strict: false });

module.exports = mongoose.model('BrregOrganization', BrregSchema,);