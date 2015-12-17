KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'


module.exports = class ConnectedManagedMachineStore extends KodingFluxStore

  @getterPath = 'ConnectedManagedMachineStore'

  getInitialState: -> null


  initialize: ->

    @on actions.SHOW_MANAGED_MACHINE_ADDED_MODAL, @show
    @on actions.HIDE_MANAGED_MACHINE_ADDED_MODAL, @hide


  show: (machines, id) -> id


  hide: (machines, id) -> null
