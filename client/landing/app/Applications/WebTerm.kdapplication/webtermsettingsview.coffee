class WebtermSettingsView extends JView

  constructor: ->
    super
    @setClass "ace-settings-view webterm-settings-view"
    webtermView = @getDelegate()

    @font       = new KDSelectBox
      selectOptions : __webtermSettings.fonts
      callback      : (value) =>
        webtermView.appStorage.setValue 'font', value
        webtermView.updateStyle()
      defaultValue  : webtermView.appStorage.getValue 'font'

    @fontSize       = new KDSelectBox
      selectOptions : __webtermSettings.fontSizes
      callback      : (value) =>
        webtermView.appStorage.setValue 'fontSize', value
        webtermView.updateStyle()
      defaultValue  : webtermView.appStorage.getValue 'fontSize'

    @theme          = new KDSelectBox
      selectOptions : __webtermSettings.themes
      callback      : (value) =>
        webtermView.appStorage.setValue 'theme', value
        webtermView.updateStyle()
      defaultValue  : webtermView.appStorage.getValue 'theme'

  pistachio:->
    """
    <p>Font                     {{> @font}}</p>
    <p>Font Size                {{> @fontSize}}</p>
    <p>Theme                    {{> @theme}}</p>

    """
