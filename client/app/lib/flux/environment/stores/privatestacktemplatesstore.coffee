KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'


module.exports = class PrivateStackTemplatesStore extends KodingFluxStore

  @getterPath = 'PrivateStackTemplatesStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_PRIVATE_STACK_TEMPLATES_SUCCESS, @load
    @on actions.CHANGE_TEMPLATE_TITLE, @changeTitle


  load: (stackTemplates, { templates }) ->

    stackTemplates = stackTemplates.withMutations (_templates) ->
      templates.forEach (template) ->
        _templates.set template._id, toImmutable template

    return stackTemplates


  changeTitle: (stackTemplates, { id, value }) ->

    template = stackTemplates.get id

    return stackTemplates  unless template

    stackTemplates.withMutations (templates) ->
      templates
        .setIn [id, 'title'], value
        .setIn [id, 'isDirty'], yes


