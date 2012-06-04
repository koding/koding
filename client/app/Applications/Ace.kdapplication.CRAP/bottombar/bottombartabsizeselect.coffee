class Editor_BottomBar_TabSizeSelector extends Editor_BottomBar_Section
  viewAppended: ->
    @input = select = new Editor_BottomBar_Select
      defaultValue: 2
      selectOptions: @_getSplitViewOptions()

    @listenTo
      KDEventTypes: 'EditorAsksToSetTabSize'
      listenedToInstance: @getCodeField()
      callback: (pubInst, event) =>
        select.setValue event.size

    @listenTo
      KDEventTypes: 'change'
      listenedToInstance: select
      callback: (pubInst, event) =>
        @handleEvent type: 'EditorChangeTabSize', size: select.getValue()

        @getCodeField().setTabSize select.getValue()
        @getCodeField().saveTabSizeForExtension select.getValue()

    @addSubView select

  _getSplitViewOptions: ->
    sizes = __aceData.tabSizes
    options = for size in sizes
      option =
        value: size
        title: size    
