kd = require 'kd'


module.exports = class BaseController extends kd.Object

  constructor: (options = {}, data) ->

    super options, data

    @editor = @getOption 'editor'
