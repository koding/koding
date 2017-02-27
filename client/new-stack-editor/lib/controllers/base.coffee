debug = (require 'debug') 'nse:controller:base'
kd = require 'kd'


module.exports = class BaseController extends kd.Object

  constructor: (options = {}, data) ->

    options.shared ?= {}

    super options, data

    for shared, obj of @getOption 'shared'
      @[shared] = obj


  setData: (data) ->

    debug 'setData called with', data
    super data


  save: (callback) ->

    console.log '::save not implemented yet', this.constructor.name
    callback null


  check: (callback) ->

    console.log '::check not implemented yet', this.constructor.name
    callback null
