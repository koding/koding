var countlyConfig = require('./config.sample.js');
module.exports = require(process.env.KONFIG_COUNTLYPATH + '/configextender')(countlyConfig);
