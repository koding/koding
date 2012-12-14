class WebtermSettingsView extends KDTreeItemView

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
        # webtermView.terminal.windowDidResize()

    @theme          = new KDSelectBox
      selectOptions : __webtermSettings.themes
      callback      : (value) =>
        webtermView.container.unsetClass theme.value for theme in __webtermSettings.themes
        webtermView.container.setClass value
        webtermView.terminal.setTheme value

  setDefaultValues:(settings)->
    @[key]?.setDefaultValue value for key,value of settings

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()

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
