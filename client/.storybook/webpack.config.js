require('coffee-script/register')
var path = require('path')
// polyfill path.parse for node v0.10
path.parse = require('path-parse')

var clientConfig = require('../webpack.config')
var CLIENT_PATH = path.resolve(__dirname, '..')

var isStyleLoader = function(loaderConfig) {
  if (!Array.isArray(loaderConfig.loaders)) return false

  return loaderConfig.loaders.reduce(function(res, loader) {
    return res || /css/.test(loader)
  }, false)
}

module.exports = {
  module: {
    loaders: clientConfig.module.loaders.filter(isStyleLoader)
  }
}

