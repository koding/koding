kd                          = require 'kd'
Encoder                     = require 'htmlencode'
curryIn                     = require 'app/util/curryIn'
FSHelper                    = require 'app/util/fs/fshelper'
{ jsonToYaml, yamlToJson }  = require 'app/util/stacks/yamlutils'
IDEEditorPane               = require 'ide/workspace/panes/ideeditorpane'


module.exports = class BaseStackEditorView extends IDEEditorPane

  constructor: (options = {}, data) ->

    kd.singletons.appManager.require 'IDE'

    curryIn options, { cssClass: 'editor-view' }

    { content, contentType, targetContentType } = options

    contentType        ?= 'json'
    targetContentType  ?= 'yaml'

    content = Encoder.htmlDecode content or ''

    if content
      if targetContentType is 'json' and contentType isnt 'json'
        { content, contentType, err } = yamlToJson content
      else if targetContentType is 'yaml' and contentType isnt 'yaml'
        { content, contentType, err } = jsonToYaml content

    options.content     = content
    options.contentType = contentType
    options.file        = FSHelper.createFileInstance
      path: "localfile:/stack-#{Date.now()}.#{contentType}"

    super options, data


  createEditor: ->

    super

    { ace } = @aceView

    ace.once 'SettingsApplied', => ace.ready =>
      ace.setTheme 'github', no
      ace.setTabSize 2, no
      ace.setShowPrintMargin no, no
      ace.setUseSoftTabs yes, no
      ace.setScrollPastEnd yes, no
      ace.contentChanged = no

      { content, targetContentType } = @getOptions()

      if targetContentType is 'json'
        ace.setContent JSON.stringify(JSON.parse(content), null, '\t'), no

      ace.lastSavedContents = ace.getContents()

      kd.utils.defer =>
        @getEditorSession().setScrollTop 0

      @emit 'ready'

    ace.off 'ace.requests.save'


  resize: ->

    height = @getHeight()
    ace    = @getAce()

    ace.setHeight height
    ace.editor.resize()
