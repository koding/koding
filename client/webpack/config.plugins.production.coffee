webpack = require 'webpack'


module.exports = ->

  return [
    new webpack.DefinePlugin
      'process.env':
        'NODE_ENV': JSON.stringify('production')

    new webpack.optimize.UglifyJsPlugin
      sourceMap: no
      mangle:
        keep_fnames: yes
      compress:
        unused: yes
        dead_code: yes
        warnings: no

  ]
