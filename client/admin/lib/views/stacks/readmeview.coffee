kd                      = require 'kd'
KDCustomHTMLView        = kd.CustomHTMLView
StackBaseEditorTabView  = require './stackbaseeditortabview'
MarkdownEditorView      = require './editors/markdowneditorview'


module.exports = class ReadmeView extends StackBaseEditorTabView


  constructor: (options = {}, data) ->

    super options, data

    { stackTemplate } = @getOptions()

    @addSubView new KDCustomHTMLView
      cssClass   : 'text header'
      partial    : 'Readme text for this stack template'

    @messageView = @addSubView new KDCustomHTMLView
      cssClass   : 'message-view'
      partial    : "You can write down a readme text for new users. This text
                    will be shown when they wants to use this stack. You can
                    use markdown with the readme content."

    @editorView   = @addSubView new MarkdownEditorView
      content     : stackTemplate?.description or ''
      delegate    : this
      contentType : 'md'

