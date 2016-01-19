kd                = require 'kd'
JView             = require 'app/jview'
generatePassword  = require 'app/util/generatePassword'


module.exports = class IDEPane extends JView


  constructor: (options = {}, data) ->

    options.cssClass  = kd.utils.curry 'pane', options.cssClass

    super options, data

    @hash = options.hash or generatePassword 64, no


  setFocus: (state) ->
