kd                         = require 'kd'
_                          = require 'lodash'
remote                     = require 'app/remote'
requirementsParser         = require 'app/util/stacks/requirementsparser'
{ yamlToJson, jsonToYaml } = require 'app/util/stacks/yamlutils'
VariablesEditorView        = require './variableseditorview'


module.exports = class VariablesView extends kd.View

  STATES    =
    INITIAL : 'You can define your custom variables,
               and use them in your stack template.'
    MISSING : "Please fill the missing variables: <pre>%VARIABLES%</pre>
               that you've used in your stack template."
    PASSED  : 'All the used variable in your stack template defined
               properly.'
    INVALID : 'Please check the syntax. It should be a valid YAML content.'


  constructor: (options = {}, data) ->

    super options, data

    { stackTemplate } = @getData()
    { @canUpdate } = @getOptions()

    @editorView = @addSubView new VariablesEditorView options

    if cred = stackTemplate?.credentials?.custom?.first
      @reviveCredential cred


  viewAppended: ->
    super

    @indicator = @parent.tabHandle.addSubView new kd.View
      cssClass : 'indicator'
      partial  : '0'

    @setState 'INITIAL'

    @editorView.ready =>
      @checkVariableChanges()
      @followVariableChanges()

      @checkStackTemplateChanges()
      @followStackTemplateChanges()
      @setReadOnly()  unless @canUpdate
      @listenEditorEvents()


  listenEditorEvents: ->

    @on 'FocusToEditor', @editorView.lazyBound 'setFocus', yes


  setReadOnly: ->

    @setClass 'readonly'
    @editorView.aceView.ace.editor.setReadOnly yes


  handleDataChange: ->

    return  if not @_requiredData? or not @_providedData?

    if @_requiredData.length > 0

      @indicator.setClass 'in'

      missings = []

      for field in @_requiredData
        if not value = @_providedData[field] or value?.trim?() is ''
          missings.push field

      if missings.length then @setState 'MISSING', missings else @setState 'PASSED'

    else
      @setState 'INITIAL'


  setState: (newState, missings) ->

    unless @parent
      return @on 'viewAppended', => @setState newState, missings

    stateMessage = STATES[newState]
    @_state      = newState

    @indicator.unsetTooltip()

    if @isPassed()
      @indicator.unsetClass 'in red'
      @parent.tabHandle.unsetClass 'notification'
    else
      @indicator.setClass 'in'
      @indicator.unsetClass 'red'
      @parent.tabHandle.setClass 'notification'

    if newState is 'MISSING'
      if missings.length
        stateMessage = STATES.MISSING.replace '%VARIABLES%', missings
        @indicator.setTooltip { title: stateMessage }
        @indicator.updatePartial missings.length
    else if newState is 'INVALID'
      @indicator.setClass 'red'
      @indicator.updatePartial '!'
      @indicator.setTooltip { title: STATES.INVALID }


  isPassed: -> @_state in ['PASSED', 'INITIAL']


  getAce: -> @editorView.aceView.ace


  followVariableChanges: ->

    @getAce().on 'FileContentChanged', \
      kd.utils.debounce 500, @bound 'checkVariableChanges'


  checkVariableChanges: ->

    return  if @_pinnedWarning

    content   = @getAce().getContents()
    converted = yamlToJson content, silent = yes

    if converted.err
      @_providedData = {}
      @setState 'INVALID'
    else
      { contentObject } = converted
      @_providedData = if Object.keys(contentObject).length
      then _.extend contentObject, { __rawContent : content }
      else {}
      @handleDataChange()


  followStackTemplateChanges: ->

    { editorView } = @getDelegate().stackTemplateView
    { ace }        = editorView.aceView

    ace.on 'FileContentChanged', \
      kd.utils.debounce 500, @bound 'checkStackTemplateChanges'


  checkStackTemplateChanges: ->

    { editorView } = @getDelegate().stackTemplateView
    { ace }        = editorView.aceView
    content        = ace.getContents()
    @_requiredData = (requirementsParser content).custom or []
    @handleDataChange()


  reviveCredential: (identifier) ->

    { JCredential } = remote.api

    JCredential.one identifier, (err, credential) =>
      return kd.warn err  if err
      return  unless credential

      credential.fetchData (err, data) =>

        if err
          @pinWarning "You don't have access to custom variables"
          return kd.warn err

        @_activeCredential = credential

        { meta } = data
        if (Object.keys meta).length > 1
          content = meta.__rawContent ? (jsonToYaml meta).content

          @getAce().setContent _.unescape content


  pinWarning: (warning) ->

    @_pinnedWarning = yes
    @indicator.setClass 'red'
    @indicator.updatePartial '!'
    @indicator.setTooltip { title: warning }
    @indicator.setClass 'in'
    @parent.tabHandle.setClass 'notification'
