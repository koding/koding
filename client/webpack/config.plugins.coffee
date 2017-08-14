path = require 'path'
webpack = require 'webpack'
CopyWebpackPlugin = require 'copy-webpack-plugin'
ProgressBarPlugin = require 'progress-bar-webpack-plugin'
ExtractTextPlugin = require 'extract-text-webpack-plugin'

HappyPack = require './util/HappyPack'
isExternal = require './util/isExternal'

{ CLIENT_PATH, THIRD_PARTY_PATH,
  BUILD_PATH, COMMON_STYLES_PATH, CSS_BUNDLE_FILE } = require './constants'

module.exports = (options) ->

  plugins = [
    new CopyWebpackPlugin [
      from: THIRD_PARTY_PATH
      to: path.join BUILD_PATH, '..', 'thirdparty'
    ]

    new ProgressBarPlugin {
      width: 1024, format: ' client: [:bar] :percent '
    }

    new HappyPack {
      id: 'coffee'
      loaders: [ 'coffee-loader', 'cjsx-loader' ]
    }

    new webpack.LoaderOptionsPlugin {
      test: /\.(styl|stylus)$/
      stylus: {
        default: {
          use: [require('nib')()]
          import: [ '~nib/lib/nib/index.styl', COMMON_STYLES_PATH ]
          define: { assetsPath: '/assets', rootPath: CLIENT_PATH }
        }
      }
    }

    new webpack.optimize.CommonsChunkPlugin
      name: 'vendor'
      minChunks: (mod) -> isExternal mod

    new ExtractTextPlugin
      filename: CSS_BUNDLE_FILE
      allChunks: yes

  ]
