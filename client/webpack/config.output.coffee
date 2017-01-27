{ BUILD_PATH, JS_BUNDLE_FILE, PUBLIC_PATH } = require './constants'

module.exports = ->

  return {
    path: BUILD_PATH
    filename: JS_BUNDLE_FILE
    publicPath: PUBLIC_PATH
  }
