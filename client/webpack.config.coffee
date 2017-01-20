# polyfill Promise to make it work with node v0.10
global.Promise ?= require 'bluebird'

_ = require 'lodash'
path = require 'path'
webpack = require 'webpack'
glob = require 'glob'
CopyWebpackPlugin = require 'copy-webpack-plugin'
ProgressBarPlugin = require 'progress-bar-webpack-plugin'
WebpackNotifierPlugin = require 'webpack-notifier'
HappyPack = require 'happypack'

# this config is being generated `./configure` in koding root.
{ rev: version } = require './.config.json'

CLIENT_PATH        = __dirname
BUILD_PATH         = path.join CLIENT_PATH, '../website/a/p/p', version
WEBSITE_PATH       = path.join CLIENT_PATH, '..', 'website'
THIRD_PARTY_PATH   = path.join CLIENT_PATH, './thirdparty'
ASSETS_PATH        = path.join CLIENT_PATH, './assets'
COMMON_STYLES_PATH = path.join CLIENT_PATH, 'app/styl/**/*.styl'
PUBNUB_PATH        = path.join THIRD_PARTY_PATH, 'pubnub.min.js'
IMAGES_PATH        = path.join WEBSITE_PATH, 'a', 'images'
COMPONENT_LAB_PATH = path.join CLIENT_PATH, 'component-lab'
MOCKS_PATH         = path.join CLIENT_PATH, 'mocks'

# we are gonna set NODE_ENV to either `production` or `development` to figure
# out the compile target.
__DEV__  = process.env.NODE_ENV is 'development'
__PROD__ = process.env.NODE_ENV is 'production'
__TEST__ = process.env.NODE_ENV is 'test'

# let's use current manifest files to identify app folders eventually we want
# to get rid of `bant.json` files, and figure out another way to identify what
# apps we are serving.
manifests = glob.sync('*/bant.json',
  cwd: CLIENT_PATH
  realpath: yes
).map(require)

webpackConfig =
  context: CLIENT_PATH
  entry: [
    './app/lib/index.coffee'
  ]
  output:
    path: BUILD_PATH
    filename: 'bundle.js'
    publicPath: "/a/p/p/#{version}/"
  module: {}


# We are aliasing all apps to be backwards compatible. What this does
# basically, it allows folders with `bant.json` inside to be requirable on top
# level.
#
# This lets us omit the `lib` folders from require paths as well.
#
# No need to write
#    require '../../../home/lib/routehandler'
# We can just write
#    require 'home/routehandler'
appAliases = manifests.reduce (res, manifest) ->
  res[manifest.name] = path.join CLIENT_PATH, manifest.name, 'lib'
  return res
, {}

# module resolvers
webpackConfig.resolve =
  modules: [
    CLIENT_PATH
    'node_modules'
  ]
  extensions: ['*', '.coffee', '.js', '.json', '.styl']
  alias: _.assign {}, appAliases,
    kd: 'kd.js'
    pubnub: PUBNUB_PATH
    assets: ASSETS_PATH
    images: IMAGES_PATH
    lab: COMPONENT_LAB_PATH
    mocks: MOCKS_PATH

# Loader config

# These are the dependencies that are using some magic to identify module
# system (e.g AMD, CommonJS, window global, etc.). Since webpack supports both
# `RequireJS` and `CommonJS` at the same time, we are enforcing `CommonJS`
# with `imports` loader by importing `define` as false in those scripts.
AMD_MODULES = [
  /[\/\\]node_modules[\/\\]jquery-mousewheel[\/\\]jquery\.mousewheel\.js$/,
  require.resolve('dateformat')
]
generateAMDModuleLoaders = ->
  AMD_MODULES.map (testPath) -> { test: testPath, loader: 'imports-loader?define=>false' }

# simple helper to add loader rules easier.
addLoaderRule = (rules) ->
  webpackConfig.module.rules ?= []
  rules = [rules]  unless Array.isArray rules
  webpackConfig.module.rules = webpackConfig.module.rules.concat rules
  return rules

# imports loader items
addLoaderRule generateAMDModuleLoaders()

# third party libraries which uses script-loader
thirdPartyLoaders = addLoaderRule [
  test: require.resolve PUBNUB_PATH
  use: [
    'script-loader'
  ]
]

# special loader for globals
addLoaderRule [
  test: require.resolve './globals.coffee'
  loaders: [
    path.join CLIENT_PATH, "./webpack/web_loaders/globals-loader.js?clientPath=#{CLIENT_PATH}"
    'coffee-loader'
  ]
]

# JS, JSON, coffee
addLoaderRule [
  test: /\.js$/
  use: [
    'babel-loader'
  ]
  exclude: [/node_modules/].concat thirdPartyLoaders.map (loader) -> loader.test
,
  test: /\.coffee$/
  include: CLIENT_PATH
  exclude: [
    require.resolve './globals.coffee'
  ]
  use: ['happypack/loader?id=coffee']
]
# Style loaders configuration
addLoaderRule [
  test: /\.stylus$/
  include: CLIENT_PATH
  use: ['happypack/loader?id=styl-modules']
,
  test: /\.styl$/
  include: CLIENT_PATH
  use: ['happypack/loader?id=styl-global']
,
  test: /\.css$/
  include: CLIENT_PATH
  exclude: /flexboxgrid/,
  use: ['happypack/loader?id=css-global']
,
  test: /\.css$/,
  include: /flexboxgrid/,
  use: ['happypack/loader?id=css-modules']
]

# File & Url loaders
addLoaderRule [
  test: /\.(png|jpg|gif|woff|otf)/
  use: [
    loader: 'url-loader'
    options:
      limit: 8192
      name: '[path][name].[ext]'
  ]
,
  test: /\.ttf$/
  use: [
    loader: 'file-loader'
    options:
      mimetype: 'application/x-font-ttf'
  ]
,
  test: /\.eot$/
  use: [
    loader: 'file-loader'
    options:
      mimetype: 'application/octet-stream'
  ]
,
  test: /\.svg$/
  use: [
    loader: 'file-loader'
    options:
      mimetype: 'image/svg+xml'
  ]
]

# plugins

webpackConfig.plugins = [
  # move thirdparty folder
  new CopyWebpackPlugin [
    from: THIRD_PARTY_PATH
    to: path.join BUILD_PATH, '..', 'thirdparty'
  ]
  new ProgressBarPlugin {
    width: 1024, format: ' client: [:bar] :percent '
  }

  new HappyPack {
    id: 'coffee', threads: 4, loaders: [
      'pistachio-loader'
      'coffee-loader'
      'cjsx-loader'
    ]
  }
  new HappyPack {
    id: 'styl-modules', threads: 4,
    loaders: [
      'style-loader'
      'css-loader?modules&importLoaders=1&localIdentName=[name]__[local]___[hash:base64:5]'
      'stylus-loader'
    ]
  }
  new HappyPack {
    id: 'styl-global', threads: 4,
    loaders: [
      'style-loader'
      'css-loader'
      'stylus-loader'
    ]
  }
  new HappyPack {
    id: 'css-global', threads: 4,
    loaders: [
      'style-loader'
      'css-loader'
    ]
  }
  new HappyPack {
    id: 'css-modules', threads: 4,
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

# development environment specific plugins.
if __DEV__
  webpackConfig.plugins.push(
    new WebpackNotifierPlugin { title: 'Koding Frontend', alwaysNotify: yes }
  )
# prod environment specific plugins.
else if __PROD__
  webpackConfig.plugins.push(
    new webpack.DefinePlugin
      'process.env':
        'NODE_ENV': JSON.stringify('production')

    new webpack.optimize.DedupePlugin()
    new webpack.optimize.UglifyJsPlugin
      sourceMap: no
      mangle:
        keep_fnames: yes
      compress:
        unused: yes
        dead_code: yes
        warnings: no
  )

module.exports = webpackConfig
