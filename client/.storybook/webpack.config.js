require('coffee-script/register')
var path = require('path')
// polyfill path.parse for node v0.10
path.parse = require('path-parse')

var _ = require('lodash')
var ProgressBarPlugin = require('progress-bar-webpack-plugin')
var WebpackNotifierPlugin = require('webpack-notifier')

var clientConfig = require('../webpack.config')
var customConfig = _.pick(clientConfig, [
  'module',
  'resolve',
  'stylus',
  'plugins'
])

module.exports = customConfig
