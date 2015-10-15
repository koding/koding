webpack           = require 'webpack'
ExtractTextPlugin = require 'extract-text-webpack-plugin'

module.exports =

  entry:
    app: "./app/lib/index.coffee"
    admin: "./admin/lib/index.coffee"
    about: "./about/lib/index.coffee"
    account: "./account/lib/index.coffee"
    account: "./account/lib/index.coffee"
    activity: "./activity/lib/index.coffee"
    ide: "./ide/lib/index.coffee"
    finder: "./finder/lib/index.coffee"

  resolve:
    alias:
      app: "#{__dirname}/app/lib/"
      admin: "#{__dirname}/admin/lib"
      about: "#{__dirname}/about/lib"
      account: "#{__dirname}/account/lib"
      account: "#{__dirname}/account/lib"
      activity: "#{__dirname}/activity/lib"
      ide: "#{__dirname}/ide/lib"
      finder: "#{__dirname}/finder/lib"
    extensions: [ "", ".coffee", ".js", ".json" ]


  output:
    path: 'static'
    filename: '[name].js'

  plugins: [
    # ./robot is automatically detected as common module and extracted
    new ExtractTextPlugin '[name].css'
    new webpack.optimize.CommonsChunkPlugin 'common.js'
  ]

  module:
    loaders: [
      { test: /\.coffee$/ , loader: 'coffee-jsx-loader' }
      { test: /\.styl$/   , loader: ExtractTextPlugin.extract 'style-loader', '!css-loader!stylus-loader' }
    ]
