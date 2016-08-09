// polyfill Promise to make it work with node v0.10
global.Promise = global.Promise || require('bluebird')

var path = require('path')
var webpack = require('webpack')
var glob = require('glob')
var _ = require('lodash')
var CopyWebpackPlugin = require('copy-webpack-plugin')
var ProgressBarPlugin = require('progress-bar-webpack-plugin')
var WebpackNotifierPlugin = require('webpack-notifier')

// this config is being generated `./configure` in koding root.
var configData = require('./.config.json')

var CLIENT_PATH        = __dirname
var BUILD_PATH         = path.join(__dirname, '../website/a/p/p', configData.rev)
var WEBSITE_PATH       = path.join(__dirname, '..', 'website')
var THIRD_PARTY_PATH   = path.join(CLIENT_PATH, './thirdparty')
var ASSETS_PATH        = path.join(CLIENT_PATH, './assets')
var COMMON_STYLES_PATH = path.join(CLIENT_PATH, 'app/styl/**/*.styl')
var PUBNUB_PATH        = path.join(THIRD_PARTY_PATH, 'pubnub.min.js')

// we are gonna set NODE_ENV to either `production` or `development` to figure
// out the compile target.
var __DEV__ = process.env.NODE_ENV === 'development'
var __PROD__ = process.env.NODE_ENV === 'production'
var __TEST__ = process.env.NODE_ENV === 'test'


// let's use current manifest files to identify app folders eventually we want
// to get rid of `bant.json` files, and figure out another way to identify what
// apps we are serving.
var manifests = glob.sync('*/bant.json', {
  cwd: CLIENT_PATH,
  realpath: true
}).map(require)

var webpackConfig = {
  context: __dirname,
  entry: [
    './app/lib/index.coffee'
  ],
  output: {
    path: BUILD_PATH,
    filename: 'bundle.js',
    publicPath: '/a/p/p/' + configData.rev + '/'
  },
  module: {}
}


// We are aliasing all apps to be backwards compatible. What this does
// basically, it allows folders with `bant.json` inside to be requirable on top
// level.
//
// This lets us omit the `lib` folders from require paths as well.
//
// No need to write
//    require '../../../home/lib/routehandler'
// We can just write
//    require 'home/routehandler'
var appAliases = manifests.reduce(function(res, manifest) {
  res[manifest.name] = path.join(CLIENT_PATH, manifest.name, 'lib')
  return res
}, {})

// module resolvers
webpackConfig.resolve = {
    root: __dirname,
    extensions: [ '', '.coffee', '.js', '.json', '.styl' ],
    alias: _.assign({}, appAliases, {
      kd: 'kd.js',
      pubnub: PUBNUB_PATH,
      assets: ASSETS_PATH
    })
}

// Loader config

// These are the dependencies that are using some magic to identify module
// system (e.g AMD, CommonJS, window global, etc.). Since webpack supports both
// `RequireJS` and `CommonJS` at the same time, we are enforcing `CommonJS`
// with `imports` loader by importing `define` as false in those scripts.
var AMD_MODULES = [
  /[\/\\]node_modules[\/\\]jquery-mousewheel[\/\\]jquery\.mousewheel\.js$/,
  require.resolve('dateformat')
]
function generateAMDModuleLoaders() {
  return AMD_MODULES.map(function(testPath) {
    return {test: testPath, loader: 'imports?define=>false'}
  })
}

// simple helper to push loaders easier.
var pushLoader = function(loaders) {
  webpackConfig.module.loaders || (webpackConfig.module.loaders = [])
  webpackConfig.module.loaders = webpackConfig.module.loaders.concat(loaders)

  return loaders
}

// imports loader items
pushLoader(
  generateAMDModuleLoaders()
)

// third party libraries which uses script-loader
var thirdPartyLoaders = pushLoader([
  {
    test: require.resolve(PUBNUB_PATH),
    loader: 'script'
  }
])

// special loader for globals
pushLoader([
  {
    test: require.resolve('./globals.coffee'),
    loaders: [
      path.join(CLIENT_PATH, './webpack/web_loaders/globals-loader.js?clientPath=' + CLIENT_PATH),
      'coffee'
    ]
  }
])

// JS, JSON, coffee
pushLoader([
  {
    test: /\.js$/,
    loaders: ['babel'],
    // this might cause some problems.
    exclude: [
      /node_modules/,
    ].concat(
      // we are also excluding the test paths from third party libraries.
      thirdPartyLoaders.map(function (loader) {
        return loader.test
      })
    )
  },
  {
    test: /\.coffee$/,
    include: __dirname,
    exclude: [
      path.join(__dirname, 'src'),
      // globals has its own loader
      require.resolve('./globals.coffee'),
    ],
    loaders: [
      'pistachio', 'coffee', 'cjsx'
    ],
  },
  {
    test: /\.json$/,
    loaders: ['json'],
    include: __dirname,
  },
])

// Style loaders configuration
pushLoader([
  {
    test: /\.styl$/,
    include: CLIENT_PATH,
    loaders: [
      'style', 'css', 'stylus'
    ]
  },
  {
    test: /\.css$/,
    include: CLIENT_PATH,
    loaders: [
      'style', 'css'
    ],
  },
])

// File & Url loaders
pushLoader([
  {
    test: /\.(png|jpg|gif|woff|otf)/,
    loader: 'url',
    query: {
      limit: 8192,
      // this name will be appended to webpackConfig.output.publicPath
      // if file size is greater than 8kb.
      name: '[path][name].[ext]'
    }
  },
  {
    test: /\.ttf$/,
    loader: 'file',
    query: {
      mimetype: 'application/x-font-ttf'
    }
  },
  {
    test: /\.eot$/,
    loader: 'file',
    query: {
      mimetype: 'application/octet-stream'
    }
  },
  {
    test: /\.svg$/,
    loader: 'file',
    query: {
      mimetype: 'image/svg+xml'
    }
  },
])

// plugins

webpackConfig.plugins = [
  // move thirdparty folder
  new CopyWebpackPlugin([
    { from: THIRD_PARTY_PATH, to: path.join(BUILD_PATH, '..', 'thirdparty') }
  ]),
  new ProgressBarPlugin({
    format: ' client: [:bar] :percent ',
    // to trigger 100% terminal width.
    width: 1024
  })
]

// development environment specific plugins.
if (__DEV__) {
  webpackConfig.plugins.push(
    new WebpackNotifierPlugin({ title: 'Koding Frontend' })
  )
}
// prod environment specific plugins.
else if (__PROD__) {
  webpackConfig.plugins.push(
    new webpack.optimize.OccurrenceOrderPlugin(),
    new webpack.optimize.DedupePlugin(),
    new webpack.optimize.UglifyJsPlugin({
      compress: {
        unused: true,
        dead_code: true,
        warnings: false,
      }
    })
  )
}

// Configure stylus that way we can require styl files and the final bundle
// will include a css bundle as well.
webpackConfig.stylus = {
  use: [require('nib')()],
  import: [
    '~nib/lib/nib/index.styl',
    COMMON_STYLES_PATH
  ],
  define: {
    assetsPath: '/assets',
    rootPath: CLIENT_PATH,
  }
}

module.exports = webpackConfig

