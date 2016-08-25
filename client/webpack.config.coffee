# polyfill Promise to make it work with node v0.10
global.Promise ?= require 'bluebird'

_ = require 'lodash'
path = require 'path'
webpack = require 'webpack'
glob = require 'glob'
CopyWebpackPlugin = require 'copy-webpack-plugin'
ProgressBarPlugin = require 'progress-bar-webpack-plugin'
WebpackNotifierPlugin = require 'webpack-notifier'

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
  root: CLIENT_PATH,
  extensions: ['', '.coffee', '.js', '.json', '.styl']
  alias: _.assign {}, appAliases,
    kd: 'kd.js'
    pubnub: PUBNUB_PATH
    assets: ASSETS_PATH
    images: IMAGES_PATH
    lab: COMPONENT_LAB_PATH

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
  AMD_MODULES.map (testPath) -> { test: testPath, loader: 'imports?define=>false' }

# simple helper to push loaders easier.
pushLoader = (loaders) ->
  webpackConfig.module.loaders ?= []
  loaders = [loaders]  unless Array.isArray loaders
  webpackConfig.module.loaders = webpackConfig.module.loaders.concat loaders
  return loaders

# imports loader items
pushLoader generateAMDModuleLoaders()

# third party libraries which uses script-loader
thirdPartyLoaders = pushLoader [
  test: require.resolve PUBNUB_PATH
  loader: 'script'
]

# special loader for globals
pushLoader [
  test: require.resolve './globals.coffee'
  loaders: [
    path.join CLIENT_PATH, "./webpack/web_loaders/globals-loader.js?clientPath=#{CLIENT_PATH}"
    'coffee'
  ]
]

# JS, JSON, coffee
pushLoader [
  test: /\.js$/
  loader: 'babel'
  # this might cause some problems.
  exclude: [/node_modules/].concat thirdPartyLoaders.map (loader) -> loader.test
,
  test: /\.coffee$/
  include: CLIENT_PATH
  exclude: [
    path.join CLIENT_PATH, 'src'
    # globals has its own loader
    require.resolve './globals.coffee'
  ]
  loaders: ['pistachio', 'coffee', 'cjsx']
,
  test: /\.json$/
  loader: 'json'
  include: CLIENT_PATH
]


# Style loaders configuration
pushLoader [
  test: /\.stylus$/
  include: CLIENT_PATH
  loaders: [
    'style'
    'css?modules&importLoaders=1&localIdentName=[name]__[local]___[hash:base64:5]'
    'stylus'
  ]
,
  test: /\.styl$/
  include: CLIENT_PATH
  loaders: [
    'style'
    'css'
    'stylus'
  ]
,
  test: /\.css$/
  include: CLIENT_PATH
  exclude: /flexboxgrid/,
  loaders: [
    'style'
    'css'
  ]
,
  test: /\.css$/,
  loader: 'style!css?modules',
  include: /flexboxgrid/,
]

# File & Url loaders
pushLoader [
  test: /\.(png|jpg|gif|woff|otf)/
  loader: 'url'
  query:
    limit: 8192
    # this name will be appended to webpackConfig.output.publicPath
    # if file size is greater than 8kb.
    name: '[path][name].[ext]'
,
  test: /\.ttf$/
  loader: 'file'
  query: { mimetype: 'application/x-font-ttf' }
,
  test: /\.eot$/
  loader: 'file'
  query: { mimetype: 'application/octet-stream' }
,
  test: /\.svg$/
  loader: 'file'
  query: { mimetype: 'image/svg+xml' }
]

# plugins

webpackConfig.plugins = [
  # move thirdparty folder
  new CopyWebpackPlugin [
    from: THIRD_PARTY_PATH
    to: path.join BUILD_PATH, '..', 'thirdparty'
  ]
  new ProgressBarPlugin { format: ' client: [:bar] :percent ', width: 1024 }
]

# development environment specific plugins.
if __DEV__
  webpackConfig.plugins.push(
    new WebpackNotifierPlugin { title: 'Koding Frontend' }
  )
# prod environment specific plugins.
else if __PROD__
  webpackConfig.plugins.push(
    new webpack.optimize.OccurrenceOrderPlugin()
    new webpack.optimize.DedupePlugin()
    new webpack.optimize.UglifyJsPlugin
      compress:
        unused: yes
        dead_code: yes
        warnings: no
  )

# Configure stylus that way we can require styl files and the final bundle
# will include a css bundle as well.
webpackConfig.stylus =
  use: [require('nib')()]
  import: [ '~nib/lib/nib/index.styl', COMMON_STYLES_PATH ]
  define: { assetsPath: '/assets', rootPath: CLIENT_PATH }


module.exports = webpackConfig

