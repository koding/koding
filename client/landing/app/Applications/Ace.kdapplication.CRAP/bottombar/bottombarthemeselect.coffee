class Editor_BottomBar_ThemeSelector extends Editor_BottomBar_Section
  constructor: (options, data) ->
    super options, data

  viewAppended: ->
    @input = select = new Editor_BottomBar_Select
      defaultValue: 'idle_fingers'
      selectOptions: @_getThemesOptions()

    @listenTo
      KDEventTypes: 'EditorAsksToSetTheme'
      listenedToInstance: @getCodeField()
      callback: (pubInst, event) =>
        select.inputSetValue event.theme

    @listenTo
      KDEventTypes:'change'
      listenedToInstance: select
      callback: (pubInst, event) =>
        @handleEvent type: 'EditorChangeTheme', theme: select.inputGetValue()

        @getCodeField().setTheme select.inputGetValue()
        @getCodeField().saveThemeForExtension select.inputGetValue()

    @addSubView select

  _getThemesOptions: ->
    __aceData.themes
