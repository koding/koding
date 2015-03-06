Shortcuts = require 'shortcuts'
defaults  = require './shortcuts/defaults'
kd        = require 'kd'
events    = require 'events'

wc = kd.singleton 'windowController'

module.exports =

class ShortcutsController extends kd.Object

  constructor: ->

    super
    
    @_kv = null
    @_s = new Shortcuts defaults

    wc.on 'WindowChangeKeyView', (view) =>
      
      @_handleKeyViewChange view


  _handleKeyViewChange: (view) ->

    @_kv = view

    
