{ CLIENT_PATH } = require './webpack/constants'

module.exports =
  context: CLIENT_PATH
  entry:
    main: './app/lib/index.coffee'
  output: require('./webpack/config.output')()
  resolve: require('./webpack/config.resolve')()
  module: require('./webpack/config.module')()
  plugins: require('./webpack/config.plugins')().concat(
    require("./webpack/config.plugins.#{process.env.NODE_ENV}")()
  )
