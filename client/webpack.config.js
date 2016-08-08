global.Promise = global.Promise || require('bluebird')

var path = require('path');
var webpack = require('webpack');
var configData = require('./.config.json')
var glob = require('glob')
var _ = require('lodash')
var CopyWebpackPlugin = require('copy-webpack-plugin')

var BUILD_PATH = path.join(__dirname, '../website/a/p/p', configData.rev)
var THIRD_PARTY_PATH = path.join(__dirname, './thirdparty')
var OLD_CLIENT_PATH = path.join(__dirname, '..', 'client')
var WEBSITE_PATH = path.join(__dirname, '..', 'website')

var OLD_BUILDER_PATH = path.join(OLD_CLIENT_PATH, './builder')

var PUBNUB_PATH = path.join(THIRD_PARTY_PATH, 'pubnub.min.js')

var manifests = glob.sync('*/bant.json', {
  cwd: OLD_CLIENT_PATH,
  realpath: true
}).map(require)

var AMD_MODULES = [
  /[\/\\]node_modules[\/\\]jquery-mousewheel[\/\\]jquery\.mousewheel\.js$/,
  require.resolve('dateformat')
]

var oldAppAliases = manifests.reduce(function(res, manifest) {
  res[manifest.name] = path.join(
    OLD_CLIENT_PATH,
    manifest.name,
    'lib'
  )
  return res
}, {})

module.exports = {
  context: __dirname,
  debug: true,
  entry: [
    './app/lib/index'
  ],
  resolve: {
    root: __dirname,
    extensions: [ '', '.coffee', '.js', '.json' ],
    alias: _.assign({}, oldAppAliases, {
      kd: 'kd.js',
      pubnub: PUBNUB_PATH
    })
  },
  resolveLoader: {
    root: __dirname,
    modulesDirectories: ["node_modules", "web_loaders"],
    alias: {
      'globals-loader': path.join(
        __dirname,
        './webpack/web_loaders/globals-loader'
      )
    }
  },
  output: {
    path: BUILD_PATH,
    filename: 'bundle.js',
    publicPath: '/a/p/p/' + configData.rev + '/'
  },
  plugins: [
    new webpack.optimize.OccurenceOrderPlugin(),
    new webpack.HotModuleReplacementPlugin(),
    new webpack.NoErrorsPlugin(),
    // move thirdparty folder
    new CopyWebpackPlugin([
      { from: THIRD_PARTY_PATH, to: path.join(BUILD_PATH, '..', 'thirdparty') }
    ])
  ],
  module: {
    loaders: generateAMDModuleLoaders().concat([
      { test: require.resolve(PUBNUB_PATH), loader: 'script' },
      { test: require.resolve('./globals.coffee'), loaders: ['globals-loader', 'coffee'] },
      // { test: /jquery-mousewheel$/, loaders: ['imports?define=>false'], include: path.join(__dirname, 'node_modules', 'kd.js') },
      { test: /\.js$/, loaders: ['babel'], include: path.join(__dirname, 'src') },
      { test: /\.json$/, loaders: ['json'], include: __dirname, exclude: [ path.join(__dirname, 'builder'), ] },
      { test: /\.coffee$/, loaders: ['pistachio', 'coffee', 'cjsx'], include: __dirname, exclude: [ path.join(__dirname, 'src'), path.join(__dirname, 'builder'), require.resolve('./globals.coffee') ] },
      { test: /\.(png|jpg)$/, loader: 'url?limit=8192' },
    ])
  },
}


function generateAMDModuleLoaders() {
  return AMD_MODULES.map(function(testPath) {
    return {test: testPath, loader: 'imports?define=>false'}
  })
}
