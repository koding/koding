class IDE.EditorSettingsView extends IDE.IDESettingsView

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
      'keyboardHandler', 'scrollPastEnd', 'openRecentFiles'
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
      <p class="with-select">Key binding {{> @keyboardHandler}}</p>
      <p class="with-select">Font        {{> @fontSize}}</p>
      <p class="with-select">Theme       {{> @theme}}</p>
      <p class="with-select">Tab size    {{> @tabSize}}</p>
    """
