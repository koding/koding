IDESettingsView = require './idesettingsview'
editorSettings  = require './editorSettings'


class EditorSettingsView extends IDESettingsView

  createElements: ->

    @useAutosave         = new KodingSwitch
      cssClass           : "tiny settings-on-off"
      callback           : (state) => @emit 'SettingsChanged', 'useAutosave', state

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
      cssClass           : 'dark'
      selectOptions      : editorSettings.keyboardHandlers
      callback           : (state) => @emit 'SettingsChanged', 'keyboardHandler', state

    @syntax              = new KDSelectBox
      cssClass           : 'dark'
      selectOptions      : editorSettings.getSyntaxOptions()
      callback           : (state) => @emit 'SettingsChanged', 'syntax', state

    @fontSize            = new KDSelectBox
      cssClass           : 'dark'
      selectOptions      : editorSettings.fontSizes
      callback           : (state) => @emit 'SettingsChanged', 'fontSize', state

    @theme               = new KDSelectBox
      cssClass           : 'dark'
      selectOptions      : editorSettings.themes
      callback           : (state) => @emit 'SettingsChanged', 'theme', state

    @tabSize             = new KDSelectBox
      cssClass           : 'dark'
      selectOptions      : editorSettings.tabSizes
      callback           : (state) => @emit 'SettingsChanged', 'tabSize', state


  getStorageInformation: -> return { name: 'Ace', version: '1.0.1' }


  getSettingKeys: ->

    return [
      'theme', 'useSoftTabs', 'showGutter', 'useWordWrap', 'showPrintMargin'
      'highlightActiveLine', 'showInvisibles', 'fontSize', 'tabSize'
      'keyboardHandler', 'scrollPastEnd', 'openRecentFiles', 'useAutosave'
    ]


  defaults:
    useSoftTabs          : yes
    useAutosave          : no
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
      <p>Enable autosave                 {{> @useAutosave}}</p>
      <p>Use soft tabs                   {{> @useSoftTabs}}</p>
      <p>Line numbers                    {{> @showGutter}}</p>
      <p>Use word wrapping               {{> @useWordWrap}}</p>
      <p>Show print margin               {{> @showPrintMargin}}</p>
      <p>Highlight active line           {{> @highlightActiveLine}}</p>
      <p>Show invisibles                 {{> @showInvisibles}}</p>
      <p>Use scroll past end             {{> @scrollPastEnd}}</p>
      <p class="with-select">Key binding {{> @keyboardHandler}}</p>
      <p class="with-select">Font size   {{> @fontSize}}</p>
      <p class="with-select">Theme       {{> @theme}}</p>
      <p class="with-select">Tab size    {{> @tabSize}}</p>
    """


module.exports = EditorSettingsView
