kd             = require 'kd'
Encoder        = require 'htmlencode'
curryIn        = require 'app/util/curryIn'
FSHelper       = require 'app/util/fs/fshelper'

{jsonToYaml}   = require '../helpers/yamlutils'

IDEEditorPane  = require 'ide/workspace/panes/ideeditorpane'


module.exports = class BaseDefineStackEditorView extends IDEEditorPane


  constructor: (options = {}, data) ->

    kd.singletons.appManager.require 'IDE'

    curryIn options, cssClass: 'editor-view'

    content = Encoder.htmlDecode(options.content) or options.defaultTemplate

    { content, contentType, err } = jsonToYaml content

    new kd.NotificationView 'Parse error on template'  if err

    options.content     = content
    options.contentType = contentType

    options.file        = FSHelper.createFileInstance
      path: "localfile:/#{options.fileName}.#{contentType}"

    super options, data

    @setCss background: 'black'

    {ace} = @aceView

    ace.ready ->
      @emit 'ace.changeSetting', 'tabSize', 2
