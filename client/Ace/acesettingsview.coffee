class AceSettingsView extends JView

  constructor:->
    super
    @setClass "ace-settings-view"

    button = @getDelegate()

    @useSoftTabs    = new KodingSwitch
      cssClass      : "tiny"
      callback      : (state) -> button.emit "ace.changeSetting", "useSoftTabs", state
    @showGutter     = new KodingSwitch
      cssClass      : "tiny"
      callback      : (state) -> button.emit "ace.changeSetting", "showGutter", state
    @useWordWrap    = new KodingSwitch
      cssClass      : "tiny"
      callback      : (state) -> button.emit "ace.changeSetting", "useWordWrap", state
    @showPrintMargin= new KodingSwitch
      cssClass      : "tiny"
      callback      : (state) -> button.emit "ace.changeSetting", "showPrintMargin", state
    @highlightActiveLine = new KodingSwitch
      cssClass      : "tiny"
      callback      : (state) -> button.emit "ace.changeSetting", "highlightActiveLine", state
    @highlightWord  = new KodingSwitch
      cssClass      : "tiny"
      callback      : (state) -> button.emit "ace.changeSetting", "highlightSelectedWord", state
    @showInvisibles = new KodingSwitch
      cssClass      : "tiny"
      callback      : (state) -> button.emit "ace.changeSetting", "showInvisibles", state
    @scrollPastEnd  = new KodingSwitch
      cssClass      : "tiny"
      callback      : (state) -> button.emit "ace.changeSetting", "scrollPastEnd", state
    @openRecentFiles = new KodingSwitch
      cssClass      : "tiny"
      callback      : (state) -> button.emit "ace.changeSetting", "openRecentFiles", state

    @keyboardHandler= new KDSelectBox
      selectOptions : __aceSettings.keyboardHandlers
      callback      : (value) -> button.emit "ace.changeSetting", "keyboardHandler", value
    @softWrap       = new KDSelectBox
      selectOptions : __aceSettings.softWrapOptions
      callback      : (value) -> button.emit "ace.changeSetting", "softWrap", value
    @syntax         = new KDSelectBox
      selectOptions : __aceSettings.getSyntaxOptions()
      callback      : (value) -> button.emit "ace.changeSetting", "syntax", value
    @fontSize       = new KDSelectBox
      selectOptions : __aceSettings.fontSizes
      callback      : (value) -> button.emit "ace.changeSetting", "fontSize", value
    @theme          = new KDSelectBox
      selectOptions : __aceSettings.themes
      callback      : (value) -> button.emit "ace.changeSetting", "theme", value
    @tabSize        = new KDSelectBox
      selectOptions : __aceSettings.tabSizes
      callback      : (value) -> button.emit "ace.changeSetting", "tabSize", value

    @shortcuts      = new KDCustomHTMLView
      tagName       : "a"
      cssClass      : "shortcuts"
      attributes    :
        href        : "#"
      partial       : "⌘ Keyboard Shortcuts"
      click         : => log "show shortcuts"

  setDefaultValues:(settings)->

    @[key]?.setDefaultValue value for own key, value of settings

  viewAppended:->

    super

    aceView = @getDelegate()
    if aceView
      @setDefaultValues aceView.getSettings()

  click:(event)->

    event.preventDefault()
    event.stopPropagation()
    return no

  pistachio:->

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
    <p class="with-select">Font                {{> @fontSize}}</p>
    <p class="with-select">Theme               {{> @theme}}</p>
    <p class="with-select">Tab size            {{> @tabSize}}</p>
    <p class='hidden'>{{> @shortcuts}}</p>
    <hr>
    <p>Open Recent Files                       {{> @openRecentFiles}}</p>
    """
