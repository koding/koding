class WebtermSettingsView extends JView

  constructor: (options={}, data)->
    super options, data
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

    @bell           = new KodingSwitch
      size          : "tiny"
      callback      : (value) =>
        webtermView.appStorage.setValue 'visualBell', value
        webtermView.updateSettings()
      defaultValue  : webtermView.appStorage.getValue 'visualBell'

    mainView        = KD.getSingleton "mainView"
    @fullscreen     = new KodingSwitch
      size          : "tiny"
      callback      : (state) =>
        if state
          mainView.enableFullscreen()
        else
          mainView.disableFullscreen()
        {menu} = @getOptions()
        menu.contextMenu.destroy()
        menu.click()
      defaultValue  : mainView.isFullscreen()

    @scrollback     = new KDSelectBox
      selectOptions : __webtermSettings.scrollback
      callback      : (value) =>
        webtermView.appStorage.setValue 'scrollback', value
        webtermView.updateSettings()
      defaultValue  : webtermView.appStorage.getValue 'scrollback'

  pistachio:->
    """
    <p class="with-select">Font               {{> @font}}</p>
    <p class="with-select">Font size          {{> @fontSize}}</p>
    <p class="with-select">Theme              {{> @theme}}</p>
    <p class="with-select">Scrollback         {{> @scrollback}}</p>
    <hr>
    <p>Use visual bell                  {{> @bell}}</p>
    <p>Fullscreen                       {{> @fullscreen}}</p>
    """
