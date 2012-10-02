class CodeShareTabPaneView extends KDTabPaneView
  constructor:(options,data)->
    options = $.extend
      hiddenHandle : no      # yes or no
      name         : no      # a String
    ,options
    super options,data

    @name = options.name
    @hasConfig = options.allowEdit or no

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




    @codeView.on "ace.ready", =>
      @codeViewLoader.destroy()
      @codeView.setShowGutter no
      @codeView.setContents Encoder.htmlDecode data.CodeShareItemSource or "//your code snippet goes here..."
      @codeView.setTheme()
      @codeView.setFontSize(12, no)
      @codeView.setSyntax data.CodeShareItemType.syntax or "javascript"
      @codeView.editor.getSession().on 'change', =>
        # @refreshEditorView()
      @emit "codeSnip.aceLoaded"



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

  pistachio:->
    """
    <div class="codeshare-code-wrapper">
    {{> @codeViewLoader}}
    {{> @codeView}}
    {{> @codeViewConfig}}
    </div>
    """


class CodeShareConfigView extends KDView
  constructor:(options,data)->
    super options,data
    log "config for",data


  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <p>Config</p>

    """