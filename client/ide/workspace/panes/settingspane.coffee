class SettingsPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'settings-pane', options.cssClass

    super options, data

    @createEditorSettings()
    @createTerminalSettings()

  createEditorSettings: ->
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
      selectOptions      : __editorSettings.keyboardHandlers
    @softWrap            = new KDSelectBox
      selectOptions      : __editorSettings.softWrapOptions
    @syntax              = new KDSelectBox
      selectOptions      : __editorSettings.getSyntaxOptions()
    @editorFontSize      = new KDSelectBox
      selectOptions      : __editorSettings.fontSizes
    @editorTheme         = new KDSelectBox
      selectOptions      : __editorSettings.themes
    @editorTabSize       = new KDSelectBox
      selectOptions      : __editorSettings.tabSizes

    @shortcuts           = new KDCustomHTMLView
      tagName            : "a"
      cssClass           : "shortcuts"
      attributes         :
        href             : "#"
      partial            : "⌘ Keyboard Shortcuts"
      click              : => log "show shortcuts"

  createTerminalSettings: ->

    @terminalFont     = new KDSelectBox
      selectOptions   : __terminalSettings.fonts

    @terminalFontSize = new KDSelectBox
      selectOptions   : __terminalSettings.fontSizes

    @terminalTheme    = new KDSelectBox
      selectOptions   : __terminalSettings.themes

    @bell             = new KodingSwitch
      size            : "tiny settings-on-off"

    mainView          = KD.getSingleton "mainView"
    @fullscreen       = new KodingSwitch
      size            : "tiny settings-on-off"
      callback        : (state) =>
        if state
          mainView.enableFullscreen()
        else
          mainView.disableFullscreen()
        {menu} = @getOptions()
        menu.contextMenu.destroy()
        menu.click()
      defaultValue  : mainView.isFullscreen()

    @scrollback     = new KDSelectBox
      selectOptions : __terminalSettings.scrollback


  pistachio: ->
    """
    <p>Use soft tabs                           {{> @useSoftTabs}}</p>
    <p>Line numbers                            {{> @showGutter}}</p>
    <p>Use word wrapping                       {{> @useWordWrap}}</p>
    <p>Show print margin                       {{> @showPrintMargin}}</p>
    <p>Highlight active line                   {{> @highlightActiveLine}}</p>
    <p class='hidden'>Highlight selected word  {{> @highlightWord}}</p>
    <p>Show invisibles                         {{> @showInvisibles}}</p>
    <p>Use scroll past end                     {{> @scrollPastEnd}}</p>
    <hr>
    <p class="with-select">Soft wrap           {{> @softWrap}}</p>
    <p class="with-select">Syntax              {{> @syntax}}</p>
    <p class="with-select">Key binding         {{> @keyboardHandler}}</p>
    <p class="with-select">Font                {{> @editorFontSize}}</p>
    <p class="with-select">Theme               {{> @editorTheme}}</p>
    <p class="with-select">Tab size            {{> @editorTabSize}}</p>
    <p class='hidden'>{{> @shortcuts}}</p>
    <hr>
    <p>Open Recent Files                       {{> @openRecentFiles}}</p>
    <hr>
    <p class="with-select">Font               {{> @terminalFont}}</p>
    <p class="with-select">Font size          {{> @terminalFontSize}}</p>
    <p class="with-select">Theme              {{> @terminalTheme}}</p>
    <p class="with-select">Scrollback         {{> @scrollback}}</p>
    <hr>
    <p>Use visual bell                        {{> @bell}}</p>
    <p>Fullscreen                             {{> @fullscreen}}</p>
    """
