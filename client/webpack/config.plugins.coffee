path = require 'path'
webpack = require 'webpack'
HappyPack = require './util/HappyPack'
CopyWebpackPlugin = require 'copy-webpack-plugin'
ProgressBarPlugin = require 'progress-bar-webpack-plugin'

{ CLIENT_PATH, THIRD_PARTY_PATH,
  BUILD_PATH, COMMON_STYLES_PATH } = require './constants'

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
      loaders: [
        'pistachio-loader'
        'coffee-loader'
        'cjsx-loader'
      ]
    }

    new HappyPack {
      id: 'styl-modules',
      loaders: [
        'style-loader'
        'css-loader?modules&importLoaders=1&localIdentName=[name]__[local]___[hash:base64:5]'
        'stylus-loader'
      ]
    }
    new HappyPack {
      id: 'styl-global',
      loaders: [
        'style-loader'
        'css-loader'
        'stylus-loader'
      ]
    }
    new HappyPack {
      id: 'css-global',
      loaders: [
        'style-loader'
        'css-loader'
      ]
    }
    new HappyPack {
      id: 'css-modules',
      loaders: [
        'style-loader'
        'css-loader?modules'
      ]
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

  ]
