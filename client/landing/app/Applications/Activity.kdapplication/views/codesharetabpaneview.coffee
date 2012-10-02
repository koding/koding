class CodeShareTabPaneView extends KDTabPaneView
  constructor:(options,data)->
    options = $.extend
      hiddenHandle : no      # yes or no
      name         : no      # a String
    ,options
    super options,data

    @name = options.name
    @hasEditor = @hasConfig = options.allowEditing or no

    @setClass "clearfix"
    @setHeight @$().parent().height()

    @listenTo
      KDEventTypes        : [ eventType : "KDTabPaneActive" ]
      listenedToInstance  : @
      callback            : @becameActive
    @listenTo
      KDEventTypes        : [ eventType : "KDTabPaneInactive" ]
      listenedToInstance  : @
      callback            : @becameInactive
    @listenTo
      KDEventTypes        : [ eventType : "KDTabPaneDestroy" ]
      listenedToInstance  : @
      callback            : @aboutToBeDestroyed

    if @hasEditor
      @createCodeEditor data
    else
      @createCodeViewer data

  createCodeViewer:(data)=>
    @codeView = new CodeShareView {},data

  createCodeEditor:(data)=>
    @codeViewLoader = new KDLoaderView
      size          :
        width       : 30
      loaderOptions :
        color       : "#ffffff"
        shape       : "spiral"
        diameter    : 30
        density     : 30
        range       : 0.4
        speed       : 1
        FPS         : 24

    @codeView = new Ace {}, FSHelper.createFileFromPath "localfile:/codeShare.txt"

    @codeViewLoader.show()

    @codeViewConfig = new CodeShareConfigView
      cssClass : "codeshare-config"
      type : data.CodeShareItemType.syntax
    , data

    # INSTANCE LISTENERS

    @codeView.on "ace.ready", =>
      @codeViewLoader.destroy()
      @codeView.setShowGutter no
      @codeView.setContents Encoder.htmlDecode data.CodeShareItemSource or "//your code snippet goes here..."
      @codeView.setTheme()
      @codeView.setFontSize(12, no)
      @codeView.setSyntax data.CodeShareItemType.syntax or "javascript"
      @codeView.editor.getSession().on 'change', =>
        @refreshEditorView()
      @refreshEditorView()
      @emit "codeShare.aceLoaded"

    @on "codeShare.aceLoaded",=>
      @codeView.editor.resize()

  refreshEditorView:->
    lines = @codeView.editor.selection.doc.$lines
    lineAmount = if lines.length > 15 then 15 else if lines.length < 5 then 5 else lines.length
    @setAceHeightByLines lineAmount

  setAceHeightByLines: (lineAmount) ->
    lineHeight  = @codeView.editor.renderer.lineHeight
    container   = @codeView.editor.container
    height      = lineAmount * lineHeight
    @$('.codeshare-code-wrapper').height height + 20
    @codeView.editor.resize()

  becameActive: noop
  becameInactive: noop
  aboutToBeDestroyed: noop

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

    # LISTENERS for Syntax changer (needs to be here for getHandle access)

    @getHandle().on "codeShare.changeSyntax",(syntax) =>
      @codeView.setSyntax syntax

    unless @hasEditor
      @hideTabCloseIcon()

  pistachio:->
    if @hasEditor
      """
      <div class="codeshare-code-wrapper">
      {{> @codeViewLoader}}
      {{> @codeView}}
      {{> @codeViewConfig}}
      </div>
      """
    else
     """
     <div class="codeshare-code-wrapper">
      {{> @codeView}}
    </div>
     """


class CodeShareConfigView extends KDView
  constructor:(options,data)->
    super options,data

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <p>Config</p>

    """


class CodeShareView extends KDCustomHTMLView

  openFileIteration = 0

  constructor:(options, data)->
    options.tagName  = "figure"
    options.cssClass = "code-container"
    super
    @unsetClass "kdcustomhtml"

    {CodeShareItemSource,CodeShareItemType,CodeShareItemTitle} = data = @getData()

    syntax = CodeShareItemType?.syntax or "test"

    hjsSyntax = __aceSettings.aceToHighlightJsSyntaxMap[syntax]

    @codeView = new KDCustomHTMLView
      tagName  : "code"
      pistachio : '{{#(CodeShareItemSource)}}'
    , data

    @currentClass = hjsSyntax or "text"

    @codeView.setClass hjsSyntax if hjsSyntax
    @codeView.unsetClass "kdcustomhtml"

    @syntaxMode = new KDCustomHTMLView
      tagName  : "strong"
      partial  : __aceSettings.syntaxAssociations[syntax]?[0] or syntax ? "text"

    @saveButton = new KDButtonView
      title     : ""
      style     : "dark"
      icon      : yes
      iconOnly  : yes
      iconClass : "save"
      callback  : ->
        new KDNotificationView
          title     : "Currently disabled!"
          type      : "mini"
          duration  : 2500

        # CodeSnippetView.emit 'CodeSnippetWantsSave', data

    @openButton = new KDButtonView
      title     : ""
      style     : "dark"
      icon      : yes
      iconOnly  : yes
      iconClass : "open"
      callback  : ->
        fileName      = "localfile:/#{CodeShareItemTitle}"
        file          = FSHelper.createFileFromPath fileName
        file.contents = Encoder.htmlDecode(CodeShareItemSource)
        file.syntax   = CodeShareItemType.syntax
        appManager.openFileWithApplication file, 'Ace'

    @copyButton = new KDButtonView
      title     : ""
      style     : "dark"
      icon      : yes
      iconOnly  : yes
      iconClass : "select-all"
      callback  : =>
        @utils.selectText @codeView.$()[0]

  setSyntax:(syntax = "text")=>

    @syntaxMode.updatePartial __aceSettings.syntaxAssociations[syntax]?[0] or syntax ? "text"

    hjsSyntax = __aceSettings.aceToHighlightJsSyntaxMap[syntax]

    if hjsSyntax
      @codeView.unsetClass @currentClass
      @codeView.setClass hjsSyntax
      @currentClass = hjsSyntax

      # Reset DOM alterations made by previous hjs calls
      @codeView.render()
      @applySyntaxColoring syntax
    else
      log "Could not set Syntax - Missing from Syntax Map"



  render:->
    super()
    @codeView.setData @getData()
    @codeView.render()
    @applySyntaxColoring()

  applySyntaxColoring:( syntax = @getData().CodeShareItemType.syntax)=>

    snipView  = @
    hjsSyntax = __aceSettings.aceToHighlightJsSyntaxMap[syntax]

    if hjsSyntax
      requirejs (['js/highlightjs/highlight.js']), ->
        requirejs (["highlightjs/languages/#{hjsSyntax}"]), ->
          try
            hljs.compileModes()
            hljs.highlightBlock snipView.codeView.$()[0],'  '
          catch err
            console.warn "Error applying highlightjs syntax #{syntax}:", err
    else
      log "Syntax not found in Syntax Map"

  viewAppended: ->

    @setTemplate @pistachio()
    @template.update()
    @applySyntaxColoring()

    twOptions = (title) ->
      title : title, placement : "above", offset : 3, delayIn : 300, html : yes, animate : yes

    @saveButton.$().twipsy twOptions("Save")
    @copyButton.$().twipsy twOptions("Select all")
    @openButton.$().twipsy twOptions("Open")

  pistachio:->
    """
    <div class='kdview'>
      {pre{> @codeView}}
      <div class='button-bar'>{{> @saveButton}}{{> @openButton}}{{> @copyButton}}</div>
    </div>
    {{> @syntaxMode}}
    """
