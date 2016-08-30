require('coffee-script/register')
config = require('./webpack.config.coffee')

config.target = 'node'

module.exports = config
