path = require 'path'

{ CLIENT_PATH, PUBNUB_PATH } = require './constants'
generateAMDLoaders = require './util/generateAMDLoaders'
ExtractTextPlugin = require 'extract-text-webpack-plugin'

thirdPartyLoaders = ->
  return [{
    test: require.resolve PUBNUB_PATH
    use: [
      'script-loader'
    ]
  }]

globalsLoader = ->
  return {
    test: require.resolve path.join CLIENT_PATH, './globals.coffee'
    loaders: [
      path.join CLIENT_PATH, "./webpack/web_loaders/globals-loader.js?clientPath=#{CLIENT_PATH}"
      'coffee-loader'
    ]
  }

babelLoader = ->
  return {
    test: /\.js$/
    exclude: [/node_modules/].concat(
      thirdPartyLoaders().map ({ test }) -> test
    )
    use: [
      'babel-loader'
    ]
  }

coffeeLoader = ->
  return {
    test: /\.coffee$/
    include: CLIENT_PATH
    exclude: [
      require.resolve path.join CLIENT_PATH, './globals.coffee'
    ]
    use: ['happypack/loader?id=coffee']
  }

stylModulesLoader = ->
  return {
    test: /\.stylus$/
    include: CLIENT_PATH
    loader: ExtractTextPlugin.extract
      fallback: 'style-loader'
      use: [
        'css-loader?modules&importLoaders=1&localIdentName=[name]__[local]___[hash:base64:5]'
        'stylus-loader'
      ]
  }

stylGlobalLoader = ->
  return {
    test: /\.styl$/
    include: CLIENT_PATH
    loader: ExtractTextPlugin.extract
      fallback: 'style-loader'
      use: [ 'css-loader', 'stylus-loader' ]
  }

cssModulesLoader = ->
  return {
    test: /\.css$/,
    include: /flexboxgrid/,
    loader: ExtractTextPlugin.extract
      fallback: 'style-loader'
      use: [ 'css-loader?modules' ]
  }

cssGlobalLoader = ->
  return {
    test: /\.css$/
    include: CLIENT_PATH
    exclude: /flexboxgrid/,
    loader: ExtractTextPlugin.extract
      fallback: 'style-loader'
      use: [ 'css-loader' ]
  }

staticAssetLoaders = ->
  return [
    test: /\.(png|jpg|gif|woff|otf)/
    use: [
      loader: 'url-loader'
      options:
        limit: 8192
        name: '[path][name].[ext]'
    ]
  ,
    test: /\.eot$/
    use: [
      loader: 'file-loader'
      options:
        mimetype: 'application/octet-stream'
    ]
  ,
    test: /\.ttf$/
    use: [
      loader: 'file-loader'
      options:
        mimetype: 'application/x-font-ttf'
    ]
  ]

svgLoader = ->
  return {
    test: /\.svg$/
    use: [
      loader: 'file-loader'
      options:
        mimetype: 'image/svg+xml'
    ]
  }

module.exports = ->

  rules = generateAMDLoaders()
    .concat thirdPartyLoaders()
    .concat staticAssetLoaders()
    .concat [
      globalsLoader()
      babelLoader()
      coffeeLoader()
      stylModulesLoader()
      stylGlobalLoader()
      cssModulesLoader()
      cssGlobalLoader()
      svgLoader()
    ]

  return { rules }
