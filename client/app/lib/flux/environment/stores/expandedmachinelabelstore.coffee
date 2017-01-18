KodingFluxStore = require 'app/flux/base/store'
actions         = require '../actiontypes'


module.exports = class ExpandedMachineLabelStore extends KodingFluxStore

  @getterPath = 'ExpandedMachineLabelStore'


  getInitialState: -> null


  initialize: ->

    @on actions.UPDATE_SELECTED_MACHINE_SUCCESS, @load
    @on actions.LOAD_EXPANDED_MACHINE_LABEL_SUCCESS, @load


  load: (oldLabel, { label }) ->

    return label
