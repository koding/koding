class CodeBinActivityItemView extends ActivityItemChild

  constructor:(options, data)->
    options = $.extend
      cssClass    : "activity-item codebin"
      tooltip     :
        title     : "Code Bin"
        offset    : 3
        selector  : "span.type-icon"
    ,options
    super options,data

    @codeBinContainer = new KDTabView
      cssClass: "code-bin-container"

    @codeBinResultPane = new KDTabPaneView
      name:"Code Share"


    @codeBinHTMLPane = new KDTabPaneView
      name:"HTML"

    @codeBinCSSPane = new KDTabPaneView
      name:"CSS"

    @codeBinJSPane = new KDTabPaneView
      name:"JavaScript"

    codeBinHTMLData = @getData().attachments[0]
    codeBinCSSData = @getData().attachments[1]
    codeBinJSData = @getData().attachments[2]

    codeBinHTMLData.title = @getData().title
    codeBinCSSData.title = @getData().title
    codeBinJSData.title = @getData().title

    @codeBinHTMLView = new CodeBinSnippetView {}, codeBinHTMLData
    @codeBinCSSView = new CodeBinSnippetView {}, codeBinCSSData
    @codeBinJSView = new CodeBinSnippetView {}, codeBinJSData

    @codeBinResultView = new CodeBinResultView {}, data
    @codeBinResultView.hide()

    @codeBinResultButton = new KDButtonView
      title: "Run Code Share"
      cssClass:"clean-gray result-button"
      click:=>
        @codeBinResultButton.setTitle "Reset Code Share"
        @codeBinResultView.show()
        @resultBanner.hide()
        @codeBinCloseButton.show()
        @codeBinResultView.emit "CodeBinSourceHasChanges", @getData()
        @codeBinContainer.showPane @codeBinResultPane

    @codeBinCloseButton = new KDButtonView
      title: "Stop and Close Code Share"
      cssClass:"clean-gray hidden"
      click:=>
        @codeBinResultView.hide()
        @codeBinResultView.stopResultFrame()
        @codeBinResultView.resetResultFrame()
        @codeBinResultButton.setTitle "Run Code Share"
        @resultBanner.show()
        @codeBinCloseButton.hide()


    @codeBinForkButton = new KDButtonView
      title: "Fork this Code Share"
      cssClass:"clean-gray fork-button"
      click:=>
        @getSingleton('mainController').emit 'ContentDisplayItemForkLinkClicked', data


    @resultBanner = new KDCustomHTMLView
      tagName : "div"
      cssClass : "result-banner"
      partial : ""

    @resultBannerButton = new KDCustomHTMLView
      name : "resultBannerButton"
      tagName:"a"
      attributes:
        href:"#"
      partial : "Click here to see this Code Share!"
      cssClass : "result-banner-button"
      click:=>
        @codeBinResultButton.setTitle "Reset Code Share"
        @codeBinResultView.show()
        @resultBanner.hide()
        @codeBinCloseButton.show()
        @codeBinResultView.emit "CodeBinSourceHasChanges", @getData()


    @resultBanner.addSubView @resultBannerButton

    @codeBinResultPane.addSubView @resultBanner

    @codeBinResultPane.addSubView @codeBinResultView
    @codeBinHTMLPane.addSubView @codeBinHTMLView
    @codeBinCSSPane.addSubView @codeBinCSSView
    @codeBinJSPane.addSubView @codeBinJSView


    @codeBinContainer.addPane @codeBinResultPane
    @codeBinContainer.addPane @codeBinHTMLPane
    @codeBinContainer.addPane @codeBinCSSPane
    @codeBinContainer.addPane @codeBinJSPane

    @codeBinResultPane.hideTabCloseIcon()
    @codeBinHTMLPane.hideTabCloseIcon()
    @codeBinCSSPane.hideTabCloseIcon()
    @codeBinJSPane.hideTabCloseIcon()

    # hover switching enabled by default
    @codeBinContainer.$(".kdtabhandle").hover (event)->
      $(event.target).closest(".kdtabhandle").click()
    , noop

    @codeBinContainer.showPane @codeBinResultPane

    # setTimeout =>
    #   @codeBinResultButton.setTitle "Reset Code Share"
    #   @codeBinResultView.show()
    #   @resultBanner.hide()
    #   @codeBinCloseButton.show()
    #   @codeBinResultView.emit "CodeBinSourceHasChanges", @getData()
    #   # setTimeout =>
    #   #   @codeBinResultView.stopResultFrame()
    #   # , 10000
    # , 1000


  render:->
    super()

    codeBinHTMLData = @getData().attachments[0]
    codeBinCSSData = @getData().attachments[1]
    codeBinJSData = @getData().attachments[2]

    codeBinHTMLData.title = @getData().title
    codeBinCSSData.title = @getData().title
    codeBinJSData.title = @getData().title

    @codeBinHTMLView.setData codeBinHTMLData
    @codeBinCSSView.setData codeBinCSSData
    @codeBinJSView.setData codeBinJSData

    @codeBinHTMLView.render()
    @codeBinCSSView.render()
    @codeBinJSView.render()

  click:(event)->
    super
    if $(event.target).is(".activity-item-right-col h3")
      appManager.tell "Activity", "createContentDisplay", @getData()

  viewAppended: ->
    return if @getData().constructor is bongo.api.CCodeBinActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    maxHeight = 30
    views = [@codeBinJSView,@codeBinCSSView,@codeBinHTMLView]

    for view in views
      if view.getHeight()>maxHeight
        maxHeight = view.getHeight()

    @$("pre.subview").css height:maxHeight

    initiallyPausedObserver = setInterval =>
      codeBinOffset =@$(".code-bin-source").offset().top
      scrollViewTop = @parent.parent.parent.$().scrollTop()
      scrollviewHeight = @parent.parent.parent.$().innerHeight()+scrollViewTop

      if codeBinOffset+scrollViewTop < scrollviewHeight
        if not @initiallyPaused
          @initiallyPaused = true
          @codeBinResultButton.setTitle "Reset Code Share"
          @codeBinResultView.show()
          @resultBanner.hide()
          @codeBinCloseButton.show()
          @codeBinResultView.emit "CodeBinSourceHasChanges", @getData()
          clearInterval initiallyPausedObserver
    ,500



  pistachio:->

    """
    {{> @settingsButton}}
    <span class="avatar">{{> @avatar}}</span>
    <div class='activity-item-right-col'>
      {h3{#(title)}}
      <p class='context'>{{@utils.applyTextExpansions #(body)}}</p>
      <div class="code-bin-source">

      {{> @codeBinContainer}}

      </div>
      {{> @codeBinResultButton}}
      {{> @codeBinCloseButton}}
      {{> @codeBinForkButton}}

      <footer class='clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          {time{$.timeago #(meta.createdAt)}}
          {{> @tags}}
        </div>
        {{> @actionLinks}}
      </footer>
      {{> @commentBox}}
    </div>
    """

class CodeBinResultView extends KDCustomHTMLView
  constructor:(options,data)->
    options.cssClass = "result-container"
    super options, data
    data = @getData()

    @codeViewContainer = new KDCustomHTMLView
      cssClass : "result-frame-container"

    # @kiteController = @getSingleton('kiteController')

    @appendResultFrame "/share/iframe.html"

    @on "CodeBinSourceHasChanges",(data)=>

      codebin = data

      # these are production paths and names! beware  --arvid
      # addendum: only to be used when writing stuff to vhosts tmp

      # @iframeUsername = KD.whoami().profile.nickname
      # @iframeTimestamp = new Date().getTime()

      # @iframePath = "/Users/#{@iframeUsername}/Sites/#{@iframeUsername}.koding.com/website/codeshare_temp"
      # @iframeFileName = 'codeshare_'+@iframeTimestamp+'.html'

      resultObject =

        resetFrame    : no

        html          : Encoder.htmlDecode(codebin.attachments[0].content)
        htmlType      : "html"

        css           : Encoder.htmlDecode(codebin.attachments[1].content)
        cssType       : "css"
        cssPrefix     : yes

        js            : Encoder.htmlDecode(codebin.attachments[2].content)
        jsType        : "js"


      @$(".result-frame")[0].contentWindow.postMessage(JSON.stringify(resultObject),"*")



      ###//////////////////////////////////////////////////////////////////////
      #
      # this block is also vhost production logic. --arvid

      @kiteController.run
        withArgs  :
          command : "stat #{FSHelper.escapeFilePath(@iframePath)}"
      , (err, stderr, response)=>
        if err or stderr
          # log "temp directory not found, trying mkdir - response is",response
          @kiteController.run
            withArgs  :
              command : "mkdir #{FSHelper.escapeFilePath(@iframePath)}"
            ,(err, stderr, response)=>
              if err or stderr
                # log "Could not mkdir - response is",response
              else
                @uploadFileAndUpdateView()
        else
          @uploadFileAndUpdateView()


  uploadFileAndUpdateView:->
    @kiteController.run
       toDo           :  "uploadFile"
       withArgs       : {
         path         : FSHelper.escapeFilePath @iframePath+"/"+@iframeFileName
         contents     : @iframeContents
         username     : @iframeUsername
       }
    , (err, res)=>
      if err
        warn err
      else
        appendResultFrame "//#{@iframeUsername}.koding.com/codeshare_temp/"+@iframeFileName
      #
      #
      ///////////////////////////////////////////////////////////////////// ###


  resetResultFrame:=>
    @$(".result-frame")[0].contentWindow.postMessage(JSON.stringify({resetFrame:yes}),"*")
    # @codeView.options.attributes.src = @codeView.options.attributes.src

  stopResultFrame:=>
     @$(".result-frame")[0].contentWindow.postMessage(JSON.stringify({stopFrame:yes}),"*")

  appendResultFrame:(url)=>

    @codeView?.destroy()

    @codeView = new KDCustomHTMLView
      tagName  : "iframe"
      cssClass : "result-frame"
      name : "result-frame"
      attributes:
        src: url
        sandbox : "allow-scripts"
    @codeViewContainer.addSubView @codeView

  viewAppended: ->

    @setTemplate @pistachio()
    @template.update()


  pistachio:->
    """
      {{> @codeViewContainer}}
    """

class CodeBinSnippetView extends KDCustomHTMLView

  openFileIteration = 0

  constructor:(options, data)->
    options.tagName  = "figure"
    options.cssClass = "code-container"
    super
    @unsetClass "kdcustomhtml"

    {content, syntax, title} = data = @getData()

    hjsSyntax = __aceSettings.aceToHighlightJsSyntaxMap[syntax]

    @codeView = new KDCustomHTMLView
      tagName  : "code"
      pistachio : '{{#(content)}}'
    , data

    @codeView.setClass hjsSyntax if hjsSyntax
    @codeView.unsetClass "kdcustomhtml"

    @syntaxMode = new KDCustomHTMLView
      tagName  : "strong"
      partial  : __aceSettings.syntaxAssociations[syntax][0] or syntax

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

        # CodeBinSnippetView.emit 'CodeSnippetWantsSave', data

    @openButton = new KDButtonView
      title     : ""
      style     : "dark"
      icon      : yes
      iconOnly  : yes
      iconClass : "open"
      callback  : ->
        fileName      = "localfile:/#{title}"
        file          = FSHelper.createFileFromPath fileName
        file.contents = Encoder.htmlDecode(content)
        file.syntax   = syntax
        appManager.openFileWithApplication file, 'Ace'

    @copyButton = new KDButtonView
      title     : ""
      style     : "dark"
      icon      : yes
      iconOnly  : yes
      iconClass : "select-all"
      callback  : =>
        @utils.selectText @codeView.$()[0]

  render:->

    super()
    @codeView.setData @getData()
    @codeView.render()
    @applySyntaxColoring()

  applySyntaxColoring:( syntax = @getData().syntax)->

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
