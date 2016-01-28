kd               = require 'kd'
KodingFluxStore  = require 'app/flux/base/store'
toImmutable      = require 'app/util/toImmutable'
immutable        = require 'immutable'
actions          = require '../actiontypes'


module.exports = class ActiveStackStore extends KodingFluxStore

  @getterPath = 'ActiveStackStore'

  getInitialState: -> null


  initialize: ->

    @on actions.STACK_IS_ACTIVE, @setStackId


  setStackId: (activeStackId, id) -> id
