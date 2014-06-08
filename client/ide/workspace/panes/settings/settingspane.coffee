class IDESettingsView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @unsetClass 'kdview'

    {name, version} = @getStorageInformation()
    controller      = KD.getSingleton 'appStorageController'
    @appStorage     = controller.storage name, version

    @createElements()
    @getSettings()

    @on 'SettingsFetched', @bound 'setSettings'
    @on 'SettingsChanged', @bound 'handleSettingsChanged'

  getSettings: ->
    settingKeys = @getSettingKeys()

    @appStorage.fetchStorage =>
      @settings = {}

      for key in settingKeys
        value = @appStorage.getValue key
        @settings[key] = value ? @defaults[key]

      @emit 'SettingsFetched'

  setSettings: ->
    @[key].setDefaultValue value  for own key, value of @settings

  handleSettingsChanged: (key, state) ->
    @appStorage.setValue key, state


class EditorSettingsView extends IDESettingsView

  createElements: ->
    @useSoftTabs         = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) => @emit 'SettingsChanged', 'useSoftTabs', state

    @showGutter          = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) => @emit 'SettingsChanged', 'showGutter', state

    @useWordWrap         = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) => @emit 'SettingsChanged', 'useWordWrap', state

    @showPrintMargin     = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) => @emit 'SettingsChanged', 'showPrintMargin', state

    @highlightActiveLine = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) => @emit 'SettingsChanged', 'highlightActiveLine', state

    @highlightWord       = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) => @emit 'SettingsChanged', 'highlightWord', state

    @showInvisibles      = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) => @emit 'SettingsChanged', 'showInvisibles', state

    @scrollPastEnd       = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) => @emit 'SettingsChanged', 'scrollPastEnd', state

    @openRecentFiles     = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) => @emit 'SettingsChanged', 'openRecentFiles', state

    @keyboardHandler     = new KDSelectBox
      selectOptions      : IDE.settings.editor.keyboardHandlers
      callback           : (state) => @emit 'SettingsChanged', 'keyboardHandler', state

    @softWrap            = new KDSelectBox
      selectOptions      : IDE.settings.editor.softWrapOptions
      callback           : (state) => @emit 'SettingsChanged', 'softWrap', state

    @syntax              = new KDSelectBox
      selectOptions      : IDE.settings.editor.getSyntaxOptions()
      callback           : (state) => @emit 'SettingsChanged', 'syntax', state

    @fontSize            = new KDSelectBox
      selectOptions      : IDE.settings.editor.fontSizes
      callback           : (state) => @emit 'SettingsChanged', 'fontSize', state

    @theme               = new KDSelectBox
      selectOptions      : IDE.settings.editor.themes
      callback           : (state) => @emit 'SettingsChanged', 'theme', state

    @tabSize             = new KDSelectBox
      selectOptions      : IDE.settings.editor.tabSizes
      callback           : (state) => @emit 'SettingsChanged', 'tabSize', state

  getStorageInformation: ->
    return { name: 'Ace', version: '1.0.1' }

  getSettingKeys: ->
    return [
      'theme', 'useSoftTabs', 'showGutter', 'useWordWrap', 'showPrintMargin'
      'highlightActiveLine', 'showInvisibles', 'fontSize', 'tabSize'
      'softWrap', 'keyboardHandler', 'scrollPastEnd', 'openRecentFiles'
    ]

  defaults:
    useSoftTabs          : yes
    showGutter           : yes
    highlightActiveLine  : yes
    scrollPastEnd        : yes
    openRecentFiles      : yes
    showInvisibles       : no
    useWordWrap          : no
    showPrintMargin      : no
    fontSize             : 12
    tabSize              : 4
    softWrap             : 'off'
    keyboardHandler      : 'default'

  pistachio: ->
    """
      <div class="settings-header">Editor Settings</div>
      <p>Use soft tabs                   {{> @useSoftTabs}}</p>
      <p>Line numbers                    {{> @showGutter}}</p>
      <p>Use word wrapping               {{> @useWordWrap}}</p>
      <p>Show print margin               {{> @showPrintMargin}}</p>
      <p>Highlight active line           {{> @highlightActiveLine}}</p>
      <p>Show invisibles                 {{> @showInvisibles}}</p>
      <p>Use scroll past end             {{> @scrollPastEnd}}</p>
      <p class="with-select">Soft wrap   {{> @softWrap}}</p>
      <p class="with-select">Key binding {{> @keyboardHandler}}</p>
      <p class="with-select">Font        {{> @fontSize}}</p>
      <p class="with-select">Theme       {{> @theme}}</p>
      <p class="with-select">Tab size    {{> @tabSize}}</p>
    """


class TerminalSettingsView extends IDESettingsView

  createElements: ->
    @font           = new KDSelectBox
      selectOptions : IDE.settings.terminal.fonts
      callback      : (state) => @emit 'SettingsChanged', 'font', state

    @fontSize       = new KDSelectBox
      selectOptions : IDE.settings.terminal.fontSizes
      callback      : (state) => @emit 'SettingsChanged', 'fontSize', state

    @theme          = new KDSelectBox
      selectOptions : IDE.settings.terminal.themes
      callback      : (state) => @emit 'SettingsChanged', 'theme', state

    @scrollback     = new KDSelectBox
      selectOptions : IDE.settings.terminal.scrollback
      callback      : (state) => @emit 'SettingsChanged', 'scrollback', state

    @visualBell     = new KodingSwitch
      size          : "tiny settings-on-off"
      callback      : (state) => @emit 'SettingsChanged', 'visualBell', state

  getStorageInformation: -> { name: 'Terminal', version: '1.0.1' }

  getSettingKeys: ->
    return [ 'visualBell', 'font', 'theme', 'fontSize', 'scrollback' ]

  defaults:
    font       : 'ubuntu-mono'
    theme      : 'green-on-black'
    fontSize   : 14
    visualBell : no
    scrollback : 1000

  pistachio: ->
    """
      <div class="settings-header">Terminal Settings</div>
      <p class="with-select">Font        {{> @font}}</p>
      <p class="with-select">Font size   {{> @fontSize}}</p>
      <p class="with-select">Theme       {{> @theme}}</p>
      <p class="with-select">Scrollback  {{> @scrollback}}</p>
      <p>Use visual bell                 {{> @visualBell}}</p>
    """


class SettingsPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'settings-pane', options.cssClass

    super options, data

    @addSubView new EditorSettingsView
    @addSubView new TerminalSettingsView

    # TODO: reimplement these settings
    # <p class='hidden'>Highlight selected word {{> @highlightWord}}</p>
    # <p class='hidden'>             {{> @shortcuts}}</p>
    # <p class="with-select">Syntax  {{> @syntax}}</p>
    # <p>Open Recent Files           {{> @openRecentFiles}}</p>
