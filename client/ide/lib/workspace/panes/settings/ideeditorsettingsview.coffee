kd              = require 'kd'
KDSelectBox     = kd.SelectBox
KodingSwitch    = require 'app/commonviews/kodingswitch'
editorSettings  = require './editorsettings'
IDESettingsView = require './idesettingsview'


module.exports = class IDEEditorSettingsView extends IDESettingsView

  constructor: (options = {}, data) ->

    options.componentId = 'editor'

    super options, data


  createElements: ->

    @useAutosave         = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'useAutosave', state

    @useSoftTabs         = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'useSoftTabs', state

    @showGutter          = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'showGutter', state

    @useWordWrap         = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'useWordWrap', state

    @showPrintMargin     = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'showPrintMargin', state

    @highlightActiveLine = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'highlightActiveLine', state

    @highlightWord       = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'highlightWord', state

    @showInvisibles      = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'showInvisibles', state

    @scrollPastEnd       = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'scrollPastEnd', state

    @trimTrailingWhitespaces = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'trimTrailingWhitespaces', state

    @enableAutocomplete  = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'enableAutocomplete', state

    @openRecentFiles     = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
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

    @enableSnippets      = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'enableSnippets', state

    @enableEmmet         = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'enableEmmet', state

    @enableAutoRemovePane = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'enableAutoRemovePane', state

    @enableBraceCompletion = new KodingSwitch
      cssClass           : 'tiny settings-on-off'
      callback           : (state) => @emit 'SettingsChanged', 'enableBraceCompletion', state


  getStorageInformation: -> return { name: 'Ace', version: '1.0.1' }


  getSettingKeys: ->

    return [
      'theme', 'useSoftTabs', 'showGutter', 'useWordWrap', 'showPrintMargin'
      'highlightActiveLine', 'showInvisibles', 'fontSize', 'tabSize', 'enableBraceCompletion'
      'keyboardHandler', 'scrollPastEnd', 'trimTrailingWhitespaces', 'openRecentFiles', 'useAutosave'
      'enableAutocomplete', 'enableSnippets', 'enableEmmet', 'enableAutoRemovePane'
    ]


  defaults:
    tabSize                 : 4
    fontSize                : 12
    showGutter              : yes
    useSoftTabs             : yes
    useAutosave             : no
    enableEmmet             : no
    useWordWrap             : no
    scrollPastEnd           : yes
    enableSnippets          : yes
    showInvisibles          : no
    showPrintMargin         : no
    keyboardHandler         : 'default'
    openRecentFiles         : yes
    enableAutocomplete      : yes
    highlightActiveLine     : yes
    enableAutoRemovePane    : no
    enableBraceCompletion   : yes
    trimTrailingWhitespaces : no


  pistachio: ->

    """
      <div class="settings-header">Editor Settings</div>
      <p>Enable autosave                        {{> @useAutosave}}</p>
      <p>Use soft tabs                          {{> @useSoftTabs}}</p>
      <p>Line numbers                           {{> @showGutter}}</p>
      <p>
        <span title="Remove pane when last tab closed">
          Remove pane when last tab closed
        </span>
        {{> @enableAutoRemovePane}}
      </p>
      <p>Use word wrapping                      {{> @useWordWrap}}</p>
      <p>Show print margin                      {{> @showPrintMargin}}</p>
      <p>Highlight active line                  {{> @highlightActiveLine}}</p>
      <p>Show invisibles                        {{> @showInvisibles}}</p>
      <p>Use scroll past end                    {{> @scrollPastEnd}}</p>
      <p>
        <span title="Trim trailing whitespaces on save">
          Trim trailing whitespaces on save
        </span>
        {{> @trimTrailingWhitespaces}}
      </p>
      <p>Enable autocomplete             {{> @enableAutocomplete}}</p>
      <p>Enable emmet                    {{> @enableEmmet}}</p>
      <p>Enable snippets                 {{> @enableSnippets}}</p>
      <p>Enable brace, tag completion    {{> @enableBraceCompletion}}
      <p class="with-select">Key binding {{> @keyboardHandler}}</p>
      <p class="with-select">Font size   {{> @fontSize}}</p>
      <p class="with-select">Theme       {{> @theme}}</p>
      <p class="with-select">Tab size    {{> @tabSize}}</p>
    """
