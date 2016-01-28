KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'


module.exports = class ActiveMachineStore extends KodingFluxStore

  @getterPath = 'ActiveMachineStore'

  getInitialState: -> null


  initialize: ->

    @on actions.MACHINE_SELECTED, @setMachineId


  setMachineId: (activeMachineId, id) -> id
