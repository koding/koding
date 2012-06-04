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
        select.setValue event.theme

    @listenTo
      KDEventTypes:'change'
      listenedToInstance: select
      callback: (pubInst, event) =>
        @handleEvent type: 'EditorChangeTheme', theme: select.getValue()

        @getCodeField().setTheme select.getValue()
        @getCodeField().saveThemeForExtension select.getValue()

    @addSubView select

  _getThemesOptions: ->
    __aceData.themes
