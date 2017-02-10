kd = require 'kd'


module.exports = class BaseController extends kd.Object

  constructor: (options = {}, data) ->

    super options, data

    if editor = @getOption 'editor'
      @editor = editor

    if logs = @getOption 'logs'
      @logs = logs


  save: (callback) ->

    console.log '::save not implemented yet', this.constructor.name
    callback null


  check: (callback) ->

    console.log '::check not implemented yet', this.constructor.name
    callback null
