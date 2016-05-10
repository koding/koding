kd = require 'kd'
KDSelectBox = kd.SelectBox
KodingSwitch = require 'app/commonviews/kodingswitch'
IDESettingsView = require './idesettingsview'
terminalSettings = require 'app/terminal/settings'


module.exports = class IDETerminalSettingsView extends IDESettingsView

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
      size          : 'tiny settings-on-off'
      callback      : (state) => @emit 'SettingsChanged', 'visualBell', state

    @blinkingCursor = new KodingSwitch
      size          : 'tiny settings-on-off'
      callback      : (state) => @emit 'SettingsChanged', 'blinkingCursor', state

    @dimIfInactive  = new KodingSwitch
      size          : 'tiny settings-on-off'
      callback      : (state) => @emit 'SettingsChanged', 'dimIfInactive', state

  getStorageInformation: -> { name: 'Terminal', version: '1.0.1' }

  getSettingKeys: ->
    return [ 'visualBell', 'font', 'theme', 'fontSize', 'scrollback', 'blinkingCursor', 'dimIfInactive' ]

  defaults:
    font           : 'ubuntu-mono'
    theme          : 'green-on-black'
    fontSize       : 14
    visualBell     : no
    scrollback     : 1000
    blinkingCursor : yes
    dimIfInactive  : no

  pistachio: ->
    '''
      <div class="settings-header">Terminal Settings</div>
      <ul>
        <li class="with-select">Font        {{> @font}}</li>
        <li class="with-select">Font size   {{> @fontSize}}</li>
        <li class="with-select">Theme       {{> @theme}}</li>
        <li class="with-select">Scrollback  {{> @scrollback}}</li>
        <li>Use visual bell                 {{> @visualBell}}</li>
        <li>Blinking cursor                 {{> @blinkingCursor}}</li>
        <li>Dim if inactive                 {{> @dimIfInactive}}</li>
      </ul>
    '''
