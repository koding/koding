class AceSettingsView extends KDTreeItemView
  
  constructor:->
    super
    @setClass "ace-settings-view"

    button = @getDelegate().getDelegate()

    @useSoftTabs    = new KDRySwitch
      callback      : (state) => button.emit "ace.changeSetting", "useSoftTabs", state
    @showGutter     = new KDRySwitch
      callback      : (state) => button.emit "ace.changeSetting", "showGutter", state
    @useWordWrap    = new KDRySwitch
      callback      : (state) => button.emit "ace.changeSetting", "useWordWrap", state
    @showPrintMargin= new KDRySwitch
      callback      : (state) => button.emit "ace.changeSetting", "showPrintMargin", state
    @highlightActiveLine = new KDRySwitch
      callback      : (state) => button.emit "ace.changeSetting", "highlightActiveLine", state
    @highlightWord  = new KDRySwitch
      callback      : (state) => button.emit "ace.changeSetting", "highlightSelectedWord", state
    @showInvisibles = new KDRySwitch
      callback      : (state) => button.emit "ace.changeSetting", "showInvisibles", state
    
    @softWrap       = new KDSelectBox 
      selectOptions : __aceSettings.softWrapOptions
      callback      : (value) => button.emit "ace.changeSetting", "softWrap", value
    @syntax         = new KDSelectBox
      selectOptions : __aceSettings.syntaxes
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

    @[key]?.inputSetDefaultValue value for key,value of settings

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()

    button  = @getDelegate().getDelegate()
    aceView = button.getDelegate()
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
