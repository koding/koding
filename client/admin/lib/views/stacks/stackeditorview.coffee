kd             = require 'kd'
Encoder        = require 'htmlencode'
curryIn        = require 'app/util/curryIn'
FSHelper       = require 'app/util/fs/fshelper'

{jsonToYaml}   = require './yamlutils'

IDEEditorPane  = require 'ide/workspace/panes/ideeditorpane'


module.exports = class StackEditorView extends IDEEditorPane

  constructor: (options = {}, data) ->

    kd.singletons.appManager.require 'IDE'

    curryIn options, cssClass: 'editor-view'

    content = Encoder.htmlDecode options.content or require './defaulttemplate'

    { content, contentType, err } = jsonToYaml content

    new kd.NotificationView "Parse error on template"  if err

    options.content     = content
    options.contentType = contentType

    options.file        = FSHelper.createFileInstance
      path: "localfile:/stack.#{contentType}"

    super options, data

    @setCss background: 'black'
