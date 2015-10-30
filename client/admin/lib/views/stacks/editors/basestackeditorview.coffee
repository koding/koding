kd                  = require 'kd'
Encoder             = require 'htmlencode'
curryIn             = require 'app/util/curryIn'
FSHelper            = require 'app/util/fs/fshelper'
{ jsonToYaml }      = require '../yamlutils'
IDEEditorPane       = require 'ide/workspace/panes/ideeditorpane'
KDNotificationView  = kd.NotificationView


module.exports = class BaseStackEditorView extends IDEEditorPane

  constructor: (options = {}, data) ->

    kd.singletons.appManager.require 'IDE'

    curryIn options, cssClass: 'editor-view'

    { content, contentType } = options
    contentType             ?= 'json'

    if content and contentType is 'json'
      content = Encoder.htmlDecode content or ''
      { content, contentType, err } = jsonToYaml content

    options.content     = content
    options.contentType = contentType
    options.file        = FSHelper.createFileInstance
      path: "localfile:/stack.#{contentType}"

    super options, data


  createEditor: ->

    super

    { ace } = @aceView

    ace.once 'SettingsApplied', => ace.ready =>
      ace.setTheme 'github', no
      ace.setTabSize 2, no
      ace.setShowPrintMargin no, no
      ace.setEnableAutocomplete no, no
      ace.setUseSoftTabs yes, no
      ace.setScrollPastEnd yes, no

      kd.utils.defer =>
        @getEditorSession().setScrollTop 0

      @emit 'EditorReady'
