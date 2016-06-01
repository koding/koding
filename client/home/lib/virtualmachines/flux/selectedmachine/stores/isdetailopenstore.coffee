immutable       = require 'immutable'
actions         = require '../actiontypes'
KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'

module.exports = class VirtualMachinesSelectedMachineStore extends KodingFluxStore

  @getterPath = 'VirtualMachinesSelectedMachineStore'

  getInitialState: -> null


  initialize: ->

    @on actions.UPDATE_SELECTED_MACHINE_SUCCESS, @update


  update: (state, { label }) -> label
