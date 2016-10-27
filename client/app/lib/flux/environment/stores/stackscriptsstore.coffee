KodingFluxStore      = require 'app/flux/base/store'
actions              = require '../actiontypes'
getTokenFromMarkdown = require 'app/util/getTokenFromMarkdown'

module.exports = class StackScriptsStore extends KodingFluxStore

  @getterPath = 'StackScriptsStore'

  getInitialState: -> []


  initialize: ->

    @on actions.LOAD_STACK_SCRIPTS_SUCCESS, @success
    @on actions.LOAD_STACK_SCRIPTS_FAIL, @fail


  success: (scripts, { data }) ->
    menuItems = []
    data = JSON.parse data
    data.forEach (d) ->
      tokenTypes = ['heading', 'code']
      description = getTokenFromMarkdown d.content_markdown, tokenTypes
      menuItems.push
        title: d.title
        description: description
        markdown: d.content_markdown

    return menuItems


  fail: (prevState, newState) -> prevState
