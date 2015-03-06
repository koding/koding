Shortcuts = require 'shortcuts'
kd        = require 'kd'
events    = require 'events'
globals   = require 'globals'
defaults  = require './shortcuts/defaults'

# XXX: globals.modules should not be used, and should not be exposed indeed
# lazyrouter also makes use of this -og
index = globals.modules.reduce (acc, x) ->
  acc[x.name] = x.shortcuts
  return acc
, {}

shortcuts = new Shortcuts defaults

module.exports =

class ShortcutsController extends kd.Object

  constructor: ->

    #wc = kd.singleton 'windowController'
    #am = kd.singleton 'appManager'

    #@_kv  = null

    #am.on 'AppIsBeingShown', (app) =>
      #@_reset app  unless @_app or @_app.name isnt app.name

    #wc.on 'WindowChangeKeyView', (view) =>
      #@_handleKeyViewChange view

    #super()


  #_reset: ->

    #if @_app

      #_unlistenApp


    #name = app.getOption('name').toLowerCase()
    #sets = index[name]
    #return undefined  unless Array.isArray sets

  
  #_dispatcher: (e) ->




  #_handleKeyViewChange: (view) ->

    #console.log 'keyview changed', view
    #@_kv = view

    
