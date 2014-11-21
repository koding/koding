class IDE.TerminalSettingsView extends IDE.IDESettingsView

  createElements: ->
    @font           = new KDSelectBox
      cssClass      : 'dark'
      selectOptions : IDE.settings.terminal.fonts
      callback      : (state) => @emit 'SettingsChanged', 'font', state

    @fontSize       = new KDSelectBox
      cssClass      : 'dark'
      selectOptions : IDE.settings.terminal.fontSizes
      callback      : (state) => @emit 'SettingsChanged', 'fontSize', state

    @theme          = new KDSelectBox
      cssClass      : 'dark'
      selectOptions : IDE.settings.terminal.themes
      callback      : (state) => @emit 'SettingsChanged', 'theme', state

    @scrollback     = new KDSelectBox
      cssClass      : 'dark'
      selectOptions : IDE.settings.terminal.scrollback
      callback      : (state) => @emit 'SettingsChanged', 'scrollback', state

    @visualBell     = new KodingSwitch
      size          : "tiny settings-on-off"
      callback      : (state) => @emit 'SettingsChanged', 'visualBell', state

    @blinkingCursor = new KodingSwitch
      size          : 'tiny settings-on-off'
      callback      : (state) => @emit 'SettingsChanged', 'blinkingCursor', state

  getStorageInformation: -> { name: 'Terminal', version: '1.0.1' }

  getSettingKeys: ->
    return [ 'visualBell', 'font', 'theme', 'fontSize', 'scrollback', 'blinkingCursor' ]

  defaults:
    font           : 'ubuntu-mono'
    theme          : 'green-on-black'
    fontSize       : 14
    visualBell     : no
    scrollback     : 1000
    blinkingCursor : yes

  pistachio: ->
    """
      <div class="settings-header">Terminal Settings</div>
      <p class="with-select">Font        {{> @font}}</p>
      <p class="with-select">Font size   {{> @fontSize}}</p>
      <p class="with-select">Theme       {{> @theme}}</p>
      <p class="with-select">Scrollback  {{> @scrollback}}</p>
      <p>Use visual bell                 {{> @visualBell}}</p>
      <p>Blinking cursor                 {{> @blinkingCursor}}</p>
    """
