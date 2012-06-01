class Editor_BottomBar_TabSizeSelector extends Editor_BottomBar_Section
  viewAppended: ->
    @input = select = new Editor_BottomBar_Select
      defaultValue: 2
      selectOptions: @_getSplitViewOptions()

    @listenTo
      KDEventTypes: 'EditorAsksToSetTabSize'
      listenedToInstance: @getCodeField()
      callback: (pubInst, event) =>
        select.inputSetValue event.size

    @listenTo
      KDEventTypes: 'change'
      listenedToInstance: select
      callback: (pubInst, event) =>
        @handleEvent type: 'EditorChangeTabSize', size: select.inputGetValue()

        @getCodeField().setTabSize select.inputGetValue()
        @getCodeField().saveTabSizeForExtension select.inputGetValue()

    @addSubView select

  _getSplitViewOptions: ->
    sizes = __aceData.tabSizes
    options = for size in sizes
      option =
        value: size
        title: size    
