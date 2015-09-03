kd                         = require 'kd'
remote                     = require('app/remote').getInstance()

KDView                     = kd.View
KDCustomHTMLView           = kd.CustomHTMLView

requirementsParser         = require './requirementsparser'
VariablesEditorView        = require './editors/variableseditorview'
{ yamlToJson, jsonToYaml } = require './yamlutils'


module.exports = class VariablesView extends KDView

  STATES    =
    INITIAL : "You can define your custom variables,
               and use them in your stack template."
    MISSING : "Please fill the missing variables: <pre>%VARIABLES%</pre>
               that you've used in your stack template."
    PASSED  : "All the used variable in your stack template defined
               properly."
    INVALID : "Please check the syntax. It should be a valid YAML content."


  constructor: (options = {}, data) ->

    super options, data

    { stackTemplate } = @getOptions()

    @addSubView new KDCustomHTMLView
      cssClass  : 'text header'
      partial   : 'Define custom variables here'

    @messageView = @addSubView new KDCustomHTMLView
      cssClass   : 'message-view'

    @editorView  = @addSubView new VariablesEditorView options

    if cred = stackTemplate?.credentials?.custom?.first
      @reviveCredential cred


  viewAppended: ->
    super

    @indicator = @parent.tabHandle.addSubView new KDView
      cssClass : 'indicator'
      partial  : '0'

    @setState 'INITIAL'

    kd.utils.defer =>
      @checkVariableChanges()
      @followVariableChanges()

      @checkStackTemplateChanges()
      @followStackTemplateChanges()


  handleDataChange: ->

    return  if not @_requiredData? or not @_providedData?

    if @_requiredData.length > 0

      @indicator.setClass 'in'

      missings = []

      for field in @_requiredData
        if not value = @_providedData[field] or value?.trim?() is ''
          missings.push field

      if (count = missings.length) > 0
        @setState 'MISSING', missings
        @indicator.updatePartial count
        return

      @setState 'PASSED'
      @indicator.unsetClass 'in'

    else
      @indicator.unsetClass 'in'
      @setState 'INITIAL'


  setState: (newState, missings) ->

    stateMessage = STATES[newState]

    if missings?
      stateMessage = STATES.MISSING.replace '%VARIABLES%', missings

    if newState is 'INVALID'
      @indicator.setClass 'in red'
      @indicator.updatePartial 's'
    else
      @indicator.unsetClass 'red'


    @messageView.updatePartial stateMessage
    @_state = newState


  isPassed: -> @_state in ['PASSED', 'INITIAL']


  getAce: -> @editorView.aceView.ace


  followVariableChanges: ->

    @getAce().on 'FileContentChanged', \
      kd.utils.debounce 500, @bound 'checkVariableChanges'


  checkVariableChanges: ->

    content   = @getAce().getContents()
    converted = yamlToJson content, silent = yes

    if converted.err
      @_providedData = {}
      @setState 'INVALID'
    else
      @_providedData = converted.contentObject
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
        return kd.warn err  if err

        @_activeCredential = credential
        content = (jsonToYaml data.meta).content
        @getAce().setContent content
