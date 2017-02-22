kd = require 'kd'


module.exports = class BaseController extends kd.Object

  constructor: (options = {}, data) ->

    options.shared ?= {}

    super options, data

    for shared, obj of @getOption 'shared'
      @[shared] = obj


  save: (callback) ->

    console.log '::save not implemented yet', this.constructor.name
    callback null


  check: (callback) ->

    console.log '::check not implemented yet', this.constructor.name
    callback null
