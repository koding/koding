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

    if options.content?
      content = Encoder.htmlDecode options.content or ''
      { content, contentType, err } = jsonToYaml content
    else
      content = """
        # This is a YAML file which you can define
        # key-value pairs like;
        #
        #   foo: bar
        #

      """
      contentType = 'yaml'

    options.content     = content
    options.contentType = contentType

    options.file        = FSHelper.createFileInstance
      path: "localfile:/stack.#{contentType}"

    super options, data

    @setCss background: 'black'

    { ace } = @aceView

    ace.ready ->
      @emit 'ace.changeSetting', 'tabSize', 2