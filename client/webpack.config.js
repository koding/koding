global.Promise = global.Promise || require('bluebird')

var path = require('path');
var webpack = require('webpack');
var configData = require('./.config.json')
var glob = require('glob')
var _ = require('lodash')
var CopyWebpackPlugin = require('copy-webpack-plugin')

var STYLES_COMMONS_GLOB = 'app/styl/**/*.styl'

var BUILD_PATH         = path.join(__dirname, '../website/a/p/p', configData.rev)
var CLIENT_PATH        = path.join(__dirname, '..', 'client')
var WEBSITE_PATH       = path.join(__dirname, '..', 'website')
var OLD_BUILDER_PATH   = path.join(CLIENT_PATH, './builder')
var THIRD_PARTY_PATH   = path.join(CLIENT_PATH, './thirdparty')
var ASSETS_PATH        = path.join(CLIENT_PATH, './assets')
var COMMON_STYLES_PATH = path.join(CLIENT_PATH, STYLES_COMMONS_GLOB)

var PUBNUB_PATH = path.join(THIRD_PARTY_PATH, 'pubnub.min.js')

var manifests = glob.sync('*/bant.json', {
  cwd: CLIENT_PATH,
  realpath: true
}).map(require)

var AMD_MODULES = [
  /[\/\\]node_modules[\/\\]jquery-mousewheel[\/\\]jquery\.mousewheel\.js$/,
  require.resolve('dateformat')
]

var appAliases = manifests.reduce(function(res, manifest) {
  res[manifest.name] = path.join(
    CLIENT_PATH,
    manifest.name,
    'lib'
  )
  return res
}, {})

module.exports = {
  context: __dirname,
  debug: true,
  entry: [
    // './app/lib/styl/require-styles.coffee',
    './app/lib/index.coffee'
  ],
  resolve: {
    root: __dirname,
    extensions: [ '', '.coffee', '.js', '.json', '.styl' ],
    alias: _.assign({}, appAliases, {
      kd: 'kd.js',
      pubnub: PUBNUB_PATH,
      assets: ASSETS_PATH
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
    // move thirdparty folder
    new CopyWebpackPlugin([
      { from: THIRD_PARTY_PATH, to: path.join(BUILD_PATH, '..', 'thirdparty') }
    ]),
  ],
  module: {
    loaders: generateAMDModuleLoaders().concat([
      { test: require.resolve(PUBNUB_PATH), loader: 'script' },
      { test: require.resolve('./globals.coffee'), loaders: ['globals-loader', 'coffee'] },
      { test: /\.js$/, loaders: ['babel'], include: path.join(__dirname, 'src') },
      { test: /\.json$/, loaders: ['json'], include: __dirname, exclude: [ path.join(__dirname, 'builder'), ] },
      { test: /\.coffee$/, loaders: ['pistachio', 'coffee', 'cjsx'], include: __dirname, exclude: [ path.join(__dirname, 'src'), path.join(__dirname, 'builder'), require.resolve('./globals.coffee') ] },
      { test: /\.styl$/, loaders: ['style', 'css', 'stylus'], include: CLIENT_PATH },
      { test: /\.css$/, loaders: ['style', 'css'], include: CLIENT_PATH },
      { test: /\.(png|jpg|gif|woff|otf)/, loader: 'url', query: { limit: 8192, name: '[path][name].[ext]' } },
      { test: /\.ttf$/    , loader: 'file'  , query: { prefix: 'application/x-font-ttf'   } },
      { test: /\.eot$/    , loader: 'file'  , query: { prefix: 'application/octet-stream' } },
      { test: /\.svg$/    , loader: 'file'  , query: { prefix: 'image/svg+xml'            } },
    ])
  },
  stylus: {
    use: [require('nib')()],
    import: [
      '~nib/lib/nib/index.styl',
      COMMON_STYLES_PATH
    ],
    define: {
      assetsPath: '/assets',
      rootPath: CLIENT_PATH,
    }
  },
}


function generateAMDModuleLoaders() {
  return AMD_MODULES.map(function(testPath) {
    return {test: testPath, loader: 'imports?define=>false'}
  })
}
