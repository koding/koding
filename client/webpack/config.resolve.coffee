{ CLIENT_PATH, PUBNUB_PATH, ASSETS_PATH
  IMAGES_PATH, COMPONENT_LAB_PATH, MOCKS_PATH } = require './constants'

makeAppAliases = require './util/makeAppAliases'

module.exports = ->

  modules = [
    CLIENT_PATH
    'node_modules'
  ]

  extensions = [
    '*', '.coffee', '.js', '.json', '.styl'
  ]

  alias = Object.assign({}, makeAppAliases(), {
    kd: 'kd.js'
    pubnub: PUBNUB_PATH
    assets: ASSETS_PATH
    images: IMAGES_PATH
    lab: COMPONENT_LAB_PATH
    mocks: MOCKS_PATH
  })

  return { modules, extensions, alias }
