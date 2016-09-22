require('coffee-script/register')
config = require('./webpack.config.coffee')

config.target = 'node'
config.resolve.alias['canvas-loader'] = 'kd-shim-canvas-loader'

module.exports = config
