class WebtermSettingsView extends JView

  constructor: ->
    super
    @setClass "ace-settings-view webterm-settings-view"
    webtermView = @getDelegate()

    @font       = new KDSelectBox
      selectOptions : __webtermSettings.fonts
      callback      : (value) =>
        webtermView.appStorage.setValue 'font', value
        webtermView.updateSettings()
      defaultValue  : webtermView.appStorage.getValue 'font'

    @fontSize       = new KDSelectBox
      selectOptions : __webtermSettings.fontSizes
      callback      : (value) =>
        webtermView.appStorage.setValue 'fontSize', value
        webtermView.updateSettings()
      defaultValue  : webtermView.appStorage.getValue 'fontSize'

    @theme          = new KDSelectBox
      selectOptions : __webtermSettings.themes
      callback      : (value) =>
        webtermView.appStorage.setValue 'theme', value
        webtermView.updateSettings()
      defaultValue  : webtermView.appStorage.getValue 'theme'

    @bell           = new KDOnOffSwitch
      callback      : (value) =>
        webtermView.appStorage.setValue 'visualBell', value
        webtermView.updateSettings()
      defaultValue  : webtermView.appStorage.getValue 'visualBell'

    @scrollback     = new KDSelectBox
      selectOptions : __webtermSettings.scrollback
      callback      : (value) =>
        webtermView.appStorage.setValue 'scrollback', value
        webtermView.updateSettings()
      defaultValue  : webtermView.appStorage.getValue 'scrollback'

  pistachio:->
    """
    <p>Font                     {{> @font}}</p>
    <p>Font Size                {{> @fontSize}}</p>
    <p>Theme                    {{> @theme}}</p>
    <p>Scrollback               {{> @scrollback}}</p>
    <p>Use Visual Bell          {{> @bell}}</p>
    """
