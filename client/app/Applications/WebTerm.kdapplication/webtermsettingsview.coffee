class WebtermSettingsView extends JView

  constructor:->
    super
    @setClass "ace-settings-view"

    webtermView = @getDelegate()

    @font       = new KDSelectBox
      selectOptions : __webtermSettings.fonts
      callback      : (value,stuff) =>
        webtermView.container.unsetClass font.value for font in __webtermSettings.fonts
        webtermView.container.setClass value
        webtermView.terminal.setFont value

    @fontSize       = new KDSelectBox
      selectOptions : __webtermSettings.fontSizes
      callback      : (value,stuff) =>
        webtermView.container.$().css
          fontSize:value+"px"
        webtermView.terminal.setFontSize value
        webtermView.terminal.updateSize yes
        @utils.wait =>
          webtermView.terminal.scrollToBottom()

    @theme          = new KDSelectBox
      selectOptions : __webtermSettings.themes
      callback      : (value) =>
        webtermView.container.unsetClass theme.value for theme in __webtermSettings.themes
        webtermView.container.setClass value
        webtermView.terminal.setTheme value

  setDefaultValues:(settings)->
    @[key]?.setDefaultValue value for key,value of settings

  viewAppended:->

    super

    webtermView = @getDelegate().terminal
    if webtermView
      @setDefaultValues webtermView.getSettings()

  click:(event)->

    event.preventDefault()
    event.stopPropagation()
    return no

  pistachio:->

    """
    <p>Font                     {{> @font}}</p>
    <p>Font Size                {{> @fontSize}}</p>
    <p>Theme                    {{> @theme}}</p>

    """
