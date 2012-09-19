nodePath = require 'path'
{argv} = require 'optimist'

module.exports = require nodePath.join __dirname, '../..', argv.c

console.log module.exports