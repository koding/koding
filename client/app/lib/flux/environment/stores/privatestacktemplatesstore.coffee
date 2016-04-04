KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'


module.exports = class PrivateStackTemplatesStore extends KodingFluxStore

  @getterPath = 'PrivateStackTemplatesStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_PRIVATE_STACK_TEMPLATES_SUCCESS, @load


  load: (stackTemplates, { templates }) ->

    stackTemplates = stackTemplates.withMutations (_templates) ->
      templates.forEach (template) ->
        _templates.set template._id, toImmutable template

    return stackTemplates



