require('es6-promise').polyfill()
var path = require('path')

var COMPONENT_LAB_PATH = path.join(__dirname, 'component-lab')
var SERVER_PORT = 1905

module.exports = {
  title: 'Koding Component Lab',
  components: COMPONENT_LAB_PATH + '/**/*.js',
  serverPort: SERVER_PORT,

  getComponentPathLine: function(componentPath) {
    var name = path.basename(componentPath, '.js');
    var dir = path.dirname(componentPath);
    return name + " = require '" + dir + "'"
  },

  updateWebpackConfig: function(webpackConfig, env) {

    webpackConfig.module.loaders.push(
      { test: /\.jsx?$/, include: COMPONENT_LAB_PATH, loader: 'babel' },
      { test: /\.css$/, include: COMPONENT_LAB_PATH, loader: 'style!css?modules&importLoaders=1?localIdentName=[path][name]---[local]---[hash:base64:5]!postcss' }
    )


    var originalPostcss = typeof webpackConfig.postcss === 'function' ? webpackConfig.postcss() : []

    webpackConfig.postcss = function() {
      return originalPostcss.concat([
        require('postcss-mixins'),
        require('postcss-modules-values'),
        require('postcss-modules-local-by-default'),
        require('postcss-modules-extract-imports'),
      ])
    }

    return webpackConfig
  },
}
