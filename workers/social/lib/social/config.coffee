nodePath = require 'path'
{argv} = require 'optimist'

console.log argv.c

module.exports = require argv.c