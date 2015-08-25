kd                  = require 'kd'
Encoder             = require 'htmlencode'
curryIn             = require 'app/util/curryIn'
FSHelper            = require 'app/util/fs/fshelper'
{jsonToYaml}        = require '../yamlutils'
IDEEditorPane       = require 'ide/workspace/panes/ideeditorpane'
KDNotificationView  = kd.NotificationView


module.exports = class BaseStackEditorView extends IDEEditorPane

  constructor: (options = {}, data) ->

    kd.singletons.appManager.require 'IDE'

    curryIn options, cssClass: 'editor-view'

    content = Encoder.htmlDecode options.content or ''

    { content, contentType, err } = jsonToYaml content

    new KDNotificationView 'Parse error on template'  if err

    options.content     = content
    options.contentType = contentType

    options.file        = FSHelper.createFileInstance
      path: "localfile:/stack.#{contentType}"

    super options, data

    @setCss background: 'black'

    { ace } = @aceView

    ace.ready ->
      @emit 'ace.changeSetting', 'tabSize', 2