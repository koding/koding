IDESettingsView  = require './idesettingsview'
terminalSettings = require './terminalSettings'


class TerminalSettingsView extends IDESettingsView

  createElements: ->
    @font           = new KDSelectBox
      cssClass      : 'dark'
      selectOptions : terminalSettings.fonts
      callback      : (state) => @emit 'SettingsChanged', 'font', state

    @fontSize       = new KDSelectBox
      cssClass      : 'dark'
      selectOptions : terminalSettings.fontSizes
      callback      : (state) => @emit 'SettingsChanged', 'fontSize', state

    @theme          = new KDSelectBox
      cssClass      : 'dark'
      selectOptions : terminalSettings.themes
      callback      : (state) => @emit 'SettingsChanged', 'theme', state

    @scrollback     = new KDSelectBox
      cssClass      : 'dark'
      selectOptions : terminalSettings.scrollback
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


module.exports = TerminalSettingsView
