BasePack = require 'happypack'

module.exports = class HappyPack extends BasePack

  constructor: (options) ->

    defaultOptions = { threads: 4 }

    super(Object.assign defaultOptions, options)
