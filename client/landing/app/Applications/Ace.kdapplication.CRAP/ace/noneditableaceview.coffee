class NonEditableAceField extends MiniAceEditor
  setExtensionBasedPreferences: ->

  setDomElement: ->
    super 'not-editable'

  addSyntaxSelector: -> no

  contentOpened: ->
    super
    @editor.setReadOnly yes
    @editor.renderer.hideCursor()
    @setShowInvisibles no
    @setShowPrintMargin no
    @setShowGutter no
    @setHighlightActiveLine no
    @setFontSize 12
