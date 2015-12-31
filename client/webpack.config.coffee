webpack           = require 'webpack'
ExtractTextPlugin = require 'extract-text-webpack-plugin'

module.exports =

  entry:
    app: './app/lib/index.coffee'

  resolve:
    root: __dirname
    extensions: [ '', '.coffee', '.js', '.json', '.styl' ]
    alias:
      globals: 'globals.coffee'
      about: 'about/lib'
      account: 'account/lib'
      ace: 'ace/lib'
      activity: 'activity/lib'
      admin: 'admin/lib'
      app: 'app/lib'
      dashboard: 'dashboard/lib'
      finder: 'finder/lib'
      feeder: 'feeder/lib'
      ide: 'ide/lib'
      members: 'members/lib'
      pricing: 'pricing/lib'
      teams: 'teams/lib'
      viewer: 'viewer/lib'
      welcome: 'welcome/lib'
      sinon: 'sinon/pkg/sinon.js'

  output:
    path: 'static'
    filename: 'bundle.js'
    sourceMapFilename: '[file].map'

  plugins: [
    new ExtractTextPlugin '[name].css'
    # new webpack.optimize.DedupePlugin()
    # new webpack.optimize.UglifyJsPlugin { compress: { warnings: no } }
    # new webpack.optimize.CommonsChunkPlugin 'common.js'
  ]

  module:
    noParse: [ /\.md$/, /autoit\.js/ ]
    loaders: [
      { test: /\.coffee$/ , loader: 'coffee-jsx-loader' }
      # { test: /\.styl$/   , loader: ExtractTextPlugin.extract 'style-loader', "!css-loader?minimize!stylus-loader?import=#{__dirname}/app/styl/index.styl" }
      { test: /\.styl$/   , loader: ExtractTextPlugin.extract 'style-loader', "!css-loader!stylus-loader?import=#{__dirname}/app/styl/index.styl" }
      { test: /\.json$/   , loader: 'json' }
      { test: /\.png$/    , loader: 'url'   , query: { limit: 8192, mimetype: 'image/png' } }
      { test: /\.jpg$/    , loader: 'url'   , query: { limit: 8192, mimetype: 'image/jpg' } }
      { test: /\.gif$/    , loader: 'url'   , query: { limit: 8192, mimetype: 'image/gif' } }
      { test: /\.woff$/   , loader: 'url'   , query: { prefix: 'application/font-woff'       , mimetype: 'application/font-woff', limit: 5000 } }
      { test: /\.otf$/    , loader: 'url'   , query: { prefix: 'application/x-font-opentype' , mimetype: 'application/x-font-opentype' } }
      { test: /\.ttf$/    , loader: 'file'  , query: { prefix: 'application/x-font-ttf'   } }
      { test: /\.eot$/    , loader: 'file'  , query: { prefix: 'application/octet-stream' } }
      { test: /\.svg$/    , loader: 'file'  , query: { prefix: 'image/svg+xml'            } }
    ]