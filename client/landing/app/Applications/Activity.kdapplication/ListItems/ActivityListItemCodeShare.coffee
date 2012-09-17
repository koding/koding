class CodeShareActivityItemView extends ActivityItemChild

  constructor:(options, data)->
    options = $.extend
      cssClass    : "activity-item codeshare"
      tooltip     :
        title     : "Code Bin"
        offset    : 3
        selector  : "span.type-icon"
    ,options
    super options,data

    @codeShareContainer = new KDTabView
      cssClass: "code-share-container"

    @codeShareResultPane = new KDTabPaneView
      name:"Code Share"

    @codeShareHTMLPane = new KDTabPaneView
      name:"HTML"

    @codeShareCSSPane = new KDTabPaneView
      name:"CSS"

    @codeShareJSPane = new KDTabPaneView
      name:"JavaScript"

    codeShareHTMLData = @getData().attachments[0]
    codeShareCSSData = @getData().attachments[1]
    codeShareJSData = @getData().attachments[2]

    codeShareHTMLData.title = @getData().title
    codeShareCSSData.title = @getData().title
    codeShareJSData.title = @getData().title

    @codeShareHTMLView = new CodeShareSnippetView {}, codeShareHTMLData
    @codeShareCSSView = new CodeShareSnippetView {}, codeShareCSSData
    @codeShareJSView = new CodeShareSnippetView {}, codeShareJSData

    @codeShareResultView = new CodeShareResultView {}, data
    @codeShareResultView.hide()

    @codeShareResultButton = new KDButtonView
      title              : "Run Code Share"
      cssClass           : "clean-gray result-button"
      click              : =>
        @codeShareResultButton.setTitle "Reset Code Share"
        @codeShareResultView.show()
        @resultBanner.hide()
        @codeShareCloseButton.show()
        @codeShareResultView.stopResultFrame()
        @codeShareResultView.emit "CodeShareSourceHasChanges", @getData()
        @codeShareContainer.showPane @codeShareResultPane

    @codeShareCloseButton = new KDButtonView
      title             : "Stop and Close Code Share"
      cssClass          : "clean-gray hidden"
      click             : =>
        @codeShareResultView.hide()
        @codeShareResultView.stopResultFrame()
        @codeShareResultView.resetResultFrame()
        @codeShareResultButton.setTitle "Run Code Share"
        @resultBanner.show()
        @codeShareCloseButton.hide()

    @codeShareForkButton = new KDButtonView
      title            : "Fork this Code Share"
      cssClass         : "clean-gray fork-button"
      click            : =>
        @getSingleton('mainController').emit 'ContentDisplayItemForkLinkClicked', data

    @resultBanner = new KDCustomHTMLView
      tagName     : "div"
      cssClass    : "result-banner"
      partial     : ""

    @resultBannerButton = new KDCustomHTMLView
      name              : "resultBannerButton"
      tagName           : "a"
      attributes        :
        href            : "#"
      partial           : "Click here to see this Code Share!"
      cssClass          : "result-banner-button"
      click             : =>
        @codeShareResultButton.setTitle "Reset Code Share"
        @codeShareResultView.show()
        @resultBanner.hide()
        @codeShareCloseButton.show()
        @codeShareResultView.emit "CodeShareSourceHasChanges", @getData()

    @resultBanner.addSubView @resultBannerButton

    @codeShareResultPane.addSubView @resultBanner

    @codeShareResultPane.addSubView @codeShareResultView
    @codeShareHTMLPane.addSubView @codeShareHTMLView
    @codeShareCSSPane.addSubView @codeShareCSSView
    @codeShareJSPane.addSubView @codeShareJSView


    @codeShareContainer.addPane @codeShareResultPane
    @codeShareContainer.addPane @codeShareHTMLPane
    @codeShareContainer.addPane @codeShareCSSPane
    @codeShareContainer.addPane @codeShareJSPane

    @codeShareResultPane.hideTabCloseIcon()
    @codeShareHTMLPane.hideTabCloseIcon()
    @codeShareCSSPane.hideTabCloseIcon()
    @codeShareJSPane.hideTabCloseIcon()

    # hover switching enabled by default
    @codeShareContainer.$(".kdtabhandle").hover (event)->
      $(event.target).closest(".kdtabhandle").click()
    , noop

    @codeShareContainer.showPane @codeShareResultPane

  render:->
    super()

    codeShareHTMLData = @getData().attachments[0]
    codeShareCSSData = @getData().attachments[1]
    codeShareJSData = @getData().attachments[2]

    codeShareHTMLData.title = @getData().title
    codeShareCSSData.title = @getData().title
    codeShareJSData.title = @getData().title

    @codeShareHTMLView.setData codeShareHTMLData
    @codeShareCSSView.setData codeShareCSSData
    @codeShareJSView.setData codeShareJSData

    @codeShareHTMLView.render()
    @codeShareCSSView.render()
    @codeShareJSView.render()

  click:(event)->
    super
    if $(event.target).is(".activity-item-right-col h3")
      appManager.tell "Activity", "createContentDisplay", @getData()

  viewAppended: ->
    return if @getData().constructor is bongo.api.CCodeShareActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    maxHeight = 30
    views = [@codeShareJSView,@codeShareCSSView,@codeShareHTMLView]

    for view in views
      if view.getHeight()>maxHeight
        maxHeight = view.getHeight()

    @$("pre.subview").css height:maxHeight

    initiallyPausedObserver = setInterval =>
      codeShareOffset    = @$(".code-share-source").offset().top
      scrollViewTop    = @parent.parent.parent.$().scrollTop()
      scrollviewHeight = @parent.parent.parent.$().innerHeight()+scrollViewTop

      if codeShareOffset+scrollViewTop < scrollviewHeight
        if not @initiallyPaused
          @initiallyPaused = true
          @codeShareResultButton.setTitle "Reset Code Share"
          @codeShareResultView.show()
          @resultBanner.hide()
          @codeShareCloseButton.show()
          @codeShareResultView.emit "CodeShareSourceHasChanges", @getData()
          clearInterval initiallyPausedObserver
    ,500

  pistachio:->
    """
    {{> @settingsButton}}
    <span class="avatar">{{> @avatar}}</span>
    <div class='activity-item-right-col'>
      {h3{#(title)}}
      <p class='context'>{{@utils.applyTextExpansions #(body)}}</p>
      <div class="code-share-source">

      {{> @codeShareContainer}}

      </div>
      {{> @codeShareResultButton}}
      {{> @codeShareCloseButton}}
      {{> @codeShareForkButton}}

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

class CodeShareResultView extends KDCustomHTMLView
  constructor:(options,data)->
    options.cssClass = "result-container"
    super options, data
    data = @getData()

    @codeViewContainer = new KDCustomHTMLView
      cssClass : "result-frame-container"

    # @kiteController = @getSingleton('kiteController')

    @appendResultFrame "/share/iframe.html"

    @on "CodeShareSourceHasChanges",(data)=>

      codeshare = data

      resultObject =
        resetFrame    : no
        html          : Encoder.htmlDecode(codeshare.attachments[0].content)
        htmlType      : "html"
        css           : Encoder.htmlDecode(codeshare.attachments[1].content)
        cssType       : "css"
        cssPrefix     : yes
        js            : Encoder.htmlDecode(codeshare.attachments[2].content)
        jsType        : "js"

      @$(".result-frame")[0].contentWindow.postMessage(JSON.stringify(resultObject),"*")

  resetResultFrame:=>
    @$(".result-frame")[0].contentWindow.postMessage(JSON.stringify({resetFrame:yes}),"*")

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

class CodeShareSnippetView extends KDCustomHTMLView

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

        # CodeShareSnippetView.emit 'CodeSnippetWantsSave', data

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
  legacyCode:->

      ###//////////////////////////////////////////////////////////////////////
      #
      # this part is the pseudo-implementation of codeshares hosted on the
        users personal webspace on koding. whenever a user clicked "run" on
        a codeshare, the resulting code was supposed to be fed into a html
        file, uploaded to the vhost and then ran in an iframe. the following is
        not plug&play material, it's just a collection of snippets that are
        needed for this functionality.
        -- arvid


      # these are production paths and names! beware  --arvid
      # addendum: only to be used when writing stuff to vhosts tmp

      @iframeUsername = KD.whoami().profile.nickname
      @iframeTimestamp = new Date().getTime()

      @iframePath = "/Users/#{@iframeUsername}/Sites/#{@iframeUsername}.koding.com/website/codeshare_temp"
      @iframeFileName = 'codeshare_'+@iframeTimestamp+'.html'

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