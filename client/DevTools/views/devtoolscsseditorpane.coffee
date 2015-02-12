class DevToolsCssEditorPane extends DevToolsEditorPane

  constructor: (options = {}, data)->

    options.editorMode   = 'css'
    options.defaultTitle = 'Style'

    super options, data
