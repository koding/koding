KodingFluxStore = require 'app/flux/base/store'
actions         = require '../actiontypes'

module.exports = class SelectedTemplateIdStore extends KodingFluxStore

  @getterPath = 'SelectedTemplateIdStore'

  getInitialState: -> null

  initialize: -> @on actions.SET_SELECTED_TEMPLATE_ID, @set

  set: (oldSelectedId, { id }) -> id
