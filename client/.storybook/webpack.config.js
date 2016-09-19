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
  'stylus'
])

customConfig = _.assign({}, customConfig, {
  plugins: [
    new ProgressBarPlugin({ format: ' client: [:bar] :percent ', width: 1024 }),
    new WebpackNotifierPlugin({ title: 'Component lab' })
  ]
})

module.exports = customConfig
