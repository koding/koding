class IDESettingsView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @unsetClass 'kdview'

    @createElements()
    @getSettings()

    @on 'SettingsFetched', @bound 'setSettings'

  getSettings: ->
    {name, version}  = @getStorageInformation()
    settingKeys      = @getSettingKeys()
    appStorage       = KD.getSingleton('appStorageController').storage name, version

    appStorage.fetchStorage =>
      @settings      = {}
      @settings[key] = appStorage.getValue key  for key in settingKeys

      @emit 'SettingsFetched'

  setSettings: ->
    @[key].setDefaultValue value  for own key, value of @settings


class EditorSettingsView extends IDESettingsView

  createElements: ->
    @useSoftTabs         = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) -> console.log state

    @showGutter          = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) -> console.log state

    @useWordWrap         = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) -> console.log state

    @showPrintMargin     = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) -> console.log state

    @highlightActiveLine = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) -> console.log state

    @highlightWord       = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) -> console.log state

    @showInvisibles      = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) -> console.log state

    @scrollPastEnd       = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) -> console.log state

    @openRecentFiles     = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) -> console.log state

    @keyboardHandler     = new KDSelectBox
      selectOptions      : IDE.settings.editor.keyboardHandlers

    @softWrap            = new KDSelectBox
      selectOptions      : IDE.settings.editor.softWrapOptions

    @syntax              = new KDSelectBox
      selectOptions      : IDE.settings.editor.getSyntaxOptions()

    @fontSize            = new KDSelectBox
      selectOptions      : IDE.settings.editor.fontSizes

    @theme               = new KDSelectBox
      selectOptions      : IDE.settings.editor.themes

    @tabSize             = new KDSelectBox
      selectOptions      : IDE.settings.editor.tabSizes

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
    @font       = new KDSelectBox  selectOptions : IDE.settings.terminal.fonts
    @fontSize   = new KDSelectBox  selectOptions : IDE.settings.terminal.fontSizes
    @theme      = new KDSelectBox  selectOptions : IDE.settings.terminal.themes
    @scrollback = new KDSelectBox  selectOptions : IDE.settings.terminal.scrollback
    @visualBell = new KodingSwitch size: "tiny settings-on-off"

  getStorageInformation: -> { name: 'Terminal', version: '1.0.1' }

  getSettingKeys: ->
    return [ 'visualBell', 'font', 'theme', 'fontSize', 'scrollback' ]

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
