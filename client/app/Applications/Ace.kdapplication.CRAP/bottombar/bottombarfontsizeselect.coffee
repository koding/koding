class Editor_BottomBar_FontSizeSelector extends Editor_BottomBar_Section
  viewAppended: ->
    codeField = @getCodeField()
    @input = select = new Editor_BottomBar_Select
      defaultValue: codeField._fontSize
      selectOptions: @_getFontOptions()

    # log 'delegate', @getDelegate().getDelegate(), @getDelegate()
    @listenTo
      KDEventTypes: 'EditorAsksToSetFontSize'
      listenedToInstance: codeField
      callback: (pubInst, event) =>
        select.setValue event.size

    @listenTo
      KDEventTypes: 'change'
      listenedToInstance: select
      callback: (pubInst, event) =>
        @handleEvent type: 'EditorChangeFontSize', size: select.getValue()

        @getCodeField().setFontSize select.getValue()
        @getCodeField().saveFontSizeForExtension select.getValue()

    @addSubView select

  _getFontOptions: ->
    sizes = __aceData.fontSizes
    options = for size in sizes
      option =
        value: size
        title: size + 'px'