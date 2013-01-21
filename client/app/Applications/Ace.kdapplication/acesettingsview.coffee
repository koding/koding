class AceSettingsView extends KDTreeItemView

  constructor:->
    super
    @setClass "ace-settings-view"

    button = @getDelegate()

    @useSoftTabs    = new KDOnOffSwitch
      callback      : (state) => button.emit "ace.changeSetting", "useSoftTabs", state
    @showGutter     = new KDOnOffSwitch
      callback      : (state) => button.emit "ace.changeSetting", "showGutter", state
    @useWordWrap    = new KDOnOffSwitch
      callback      : (state) => button.emit "ace.changeSetting", "useWordWrap", state
    @showPrintMargin= new KDOnOffSwitch
      callback      : (state) => button.emit "ace.changeSetting", "showPrintMargin", state
    @highlightActiveLine = new KDOnOffSwitch
      callback      : (state) => button.emit "ace.changeSetting", "highlightActiveLine", state
    @highlightWord  = new KDOnOffSwitch
      callback      : (state) => button.emit "ace.changeSetting", "highlightSelectedWord", state
    @showInvisibles = new KDOnOffSwitch
      callback      : (state) => button.emit "ace.changeSetting", "showInvisibles", state

    @softWrap       = new KDSelectBox
      selectOptions : __aceSettings.softWrapOptions
      callback      : (value) => button.emit "ace.changeSetting", "softWrap", value

    @syntax         = new KDSelectBox
      selectOptions : __aceSettings.getSyntaxOptions()
      callback      : (value) => button.emit "ace.changeSetting", "syntax", value
    @fontSize       = new KDSelectBox
      selectOptions : __aceSettings.fontSizes
      callback      : (value) => button.emit "ace.changeSetting", "fontSize", value
    @theme          = new KDSelectBox
      selectOptions : __aceSettings.themes
      callback      : (value) => button.emit "ace.changeSetting", "theme", value
    @tabSize        = new KDSelectBox
      selectOptions : __aceSettings.tabSizes
      callback      : (value) => button.emit "ace.changeSetting", "tabSize", value

    @shortcuts      = new KDCustomHTMLView
      tagName       : "a"
      cssClass      : "shortcuts"
      attributes    :
        href        : "#"
      partial       : "⌘ Keyboard Shortcuts"
      click         : => log "show shortcuts"

  setDefaultValues:(settings)->

    @[key]?.setDefaultValue value for key,value of settings

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()

    aceView = @getDelegate()
    if aceView
      @setDefaultValues aceView.getSettings()


  click:(event)->

    event.preventDefault()
    event.stopPropagation()
    return no

  pistachio:->

    """
    <p>Use soft tabs            {{> @useSoftTabs}}</p>
    <p>Show gutter              {{> @showGutter}}</p>
    <p>Use word wrapping        {{> @useWordWrap}}</p>
    <p>Show print margin        {{> @showPrintMargin}}</p>
    <p>Highlight active line    {{> @highlightActiveLine}}</p>

    <p class='hidden'>Highlight selected word  {{> @highlightWord}}</p>

    <p>Show invisibles          {{> @showInvisibles}}</p>
    <hr>
    <p>Soft wrap                {{> @softWrap}}</p>
    <p>Syntax                   {{> @syntax}}</p>
    <p>Font                     {{> @fontSize}}</p>
    <p>Theme                    {{> @theme}}</p>
    <p>Tab size                 {{> @tabSize}}</p>

    <p class='hidden'>{{> @shortcuts}}</p>

    """
