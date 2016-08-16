require('coffee-script/register')
var path = require('path')
var clientConfig = require('../webpack.config')

var CLIENT_PATH = path.resolve(__dirname, '..')

console.log('conf', clientConfig)

var isStyleLoader = function(loaderConfig) {
  if (!Array.isArray(loaderConfig.loaders)) return false

  return loaderConfig.loaders.reduce(function(res, loader) {
    console.log('loader', loader)
    return res || /css/.test(loader)
  }, false)
}

module.exports = {
  module: {
    loaders: clientConfig.module.loaders.filter(isStyleLoader)
  }
}

console.log(module.exports.module.loaders)

