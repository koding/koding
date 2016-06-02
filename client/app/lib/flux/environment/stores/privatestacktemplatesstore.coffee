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
    @on actions.CREATE_STACK_TEMPLATE_SUCCESS, @loadSingle
    @on actions.REMOVE_STACK_TEMPLATE_SUCCESS, @remove
    @on actions.REMOVE_PRIVATE_STACK_TEMPLATE_SUCCESS, @remove
    @on actions.UPDATE_STACK_TEMPLATE_SUCCESS, @updateSingle


  load: (stackTemplates, { templates }) ->

    stackTemplates = stackTemplates.withMutations (_templates) ->
      templates.forEach (template) ->
        _templates.set template._id, toImmutable template

    return stackTemplates


  loadSingle: (templates, { stackTemplate }) ->

    templates.set stackTemplate._id, toImmutable stackTemplate


  changeTitle: (stackTemplates, { id, value }) ->

    template = stackTemplates.get id

    return stackTemplates  unless template

    stackTemplates.withMutations (templates) ->
      templates
        .setIn [id, 'title'], value
        .setIn [id, 'isDirty'], yes


  remove: (stackTemplates, { template }) -> stackTemplates.remove template._id


  updateSingle: (stackTemplates, { stackTemplate }) ->

    return stackTemplates  unless stackTemplates.has stackTemplate._id

    return stackTemplates.set stackTemplate._id, toImmutable stackTemplate
