class SettingsPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'settings-pane', options.cssClass

    super options, data

    @createSettings()

  createSettings: ->
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
    @softWrap            = new KDSelectBox
    @syntax              = new KDSelectBox
    @fontSize            = new KDSelectBox
    @theme               = new KDSelectBox
    @tabSize             = new KDSelectBox

    @shortcuts           = new KDCustomHTMLView
      tagName            : "a"
      cssClass           : "shortcuts"
      attributes         :
        href             : "#"
      partial            : "⌘ Keyboard Shortcuts"
      click              : => log "show shortcuts"

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
    <p class="with-select">Font                {{> @fontSize}}</p>
    <p class="with-select">Theme               {{> @theme}}</p>
    <p class="with-select">Tab size            {{> @tabSize}}</p>
    <p class='hidden'>{{> @shortcuts}}</p>
    <hr>
    <p>Open Recent Files                       {{> @openRecentFiles}}</p>
    """
