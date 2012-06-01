class Editor_BottomBar_SyntaxSelector extends Editor_BottomBar_Section
  constructor: (options, data) ->
    super options, data

  viewAppended: ->
    @input = select = new Editor_BottomBar_Select
      selectOptions: @_getSyntaxOptions()

    @listenTo
      KDEventTypes: 'EditorAsksToSetSyntax'
      listenedToInstance: @getDelegate().getDelegate()
      callback: (pubInst, event) =>
        select.inputSetValue event.syntax

    @listenTo
      KDEventTypes:'change'
      listenedToInstance: select
      callback: (pubInst, event) =>
        @handleEvent type: 'EditorChangeSyntax', selectsyntax: select.inputGetValue()

        @getCodeField().setSyntax select.inputGetValue()
        @getCodeField().saveSyntaxForExtension select.inputGetValue()

    @addSubView select

  _getSyntaxOptions: ->
    __aceData.syntaxes
