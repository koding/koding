class CodeShareActivityItemView extends ActivityItemChild

  constructor:(options, data)->
    options = $.extend
      cssClass    : "activity-item codeshare"
      tooltip     :
        title     : "Code Share"
        offset    : 3
        selector  : "span.type-icon"
    ,options
    super options,data

    @codeShareBoxView = new CodeShareBox
      viewMode : "TabView"
      allowEditing:no
      allowClosing:no
    ,data



  render:->
    super()

  click:(event)->
    super
    if $(event.target).is(".activity-item-right-col h3")
      appManager.tell "Activity", "createContentDisplay", @getData()

  viewAppended: ->
    return if @getData().constructor is bongo.api.CCodeShareActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    maxHeight = 40
    views = @codeShareBoxView.codeShareView.panes

    for view in views
      thisHeight = view.$("pre.subview").height()
      if thisHeight>maxHeight
        maxHeight = thisHeight

    @$("pre.subview").css height:maxHeight


    # initiallyPausedObserver = setInterval =>
    #   codeShareOffset    = @$(".code-share-source").offset().top
    #   scrollViewTop    = @parent.parent.parent.$().scrollTop()
    #   scrollviewHeight = @parent.parent.parent.$().innerHeight()+scrollViewTop

    #   if codeShareOffset+scrollViewTop < scrollviewHeight
    #     if not @initiallyPaused
    #       @initiallyPaused = true
    #       @codeShareResultButton.setTitle "Reset Code Share"
    #       @codeShareResultView.show()
    #       @resultBanner.hide()
    #       @codeShareCloseButton.show()
    #       @codeShareResultView.emit "CodeShareSourceHasChanges", @getData()
    #       clearInterval initiallyPausedObserver
    # ,500

  pistachio:->
    """
    {{> @settingsButton}}
    <span class="avatar">{{> @avatar}}</span>
    <div class='activity-item-right-col'>
      {h3{#(title)}}
      <p class='context'>{{@utils.applyTextExpansions #(body)}}</p>
      <div class="code-share-source">

      {{> @codeShareBoxView}}

      </div>

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

    @iframeURL = "*"
    @iframeFile = "/share/iframe.html"

    @codeViewContainer = new KDCustomHTMLView
      cssClass : "result-frame-container"

    @appendResultFrame @iframeFile

    # this gets called whenever an iframe should be refreshed
    # it prepares the codeshare object, compiles content types and then
    # sends a message to the iframe.

    @on "CodeShareSourceHasChanges",(data)=>
      codeshare = data
      codeshare.html= Encoder.htmlDecode(codeshare.attachments?[0]?.content) or codeshare.codeHTML
      codeshare.css = Encoder.htmlDecode(codeshare.attachments?[1]?.content) or codeshare.codeCSS
      codeshare.js  = Encoder.htmlDecode(codeshare.attachments?[2]?.content) or codeshare.codeJS
      @handleMarkdown codeshare, (codeshare_md)=>
        @handleLESS codeshare_md, (codeshare_less)=>
          @handleStylus codeshare_less, (codeshare_stylus)=>
            @handleCoffee codeshare_stylus, (codeshare_coffee)=>
              @setResultObject codeshare_coffee

  handleMarkdown:(codeshare, callback)=>
   if codeshare.modeHTML is "markdown"
    marked.setOptions
      gfm: true
      pedantic: false
      sanitize: true
      highlight:(text)-> # highlighting handled by either ACE or g-prettify
    codeshare.html = marked codeshare.html
    callback(codeshare)
   else
    callback(codeshare)

  handleCoffee:(codeshare, callback)=>
   if codeshare.modeJS is "coffee"
    requirejs (['js/coffee-script.js']), (coffee)->
      try
        codeshare.js = coffee.compile codeshare.js
        callback(codeshare)
      catch err
        log "While compiling the coffee-script to js, this happened: ",err
        callback(codeshare)
   else
    callback(codeshare)

  handleLESS:(codeshare, callback)=>
   if codeshare.modeCSS is "less"
    try
      # requirejs (["libs/less.min.js"]), (e,r)->
      parser = new less.Parser({})
      parser.parse codeshare.css, (err,css) ->
        unless err
          codeshare.css = css.toCSS()
        else
          log "While compiling the LESS to CSS, this happened: ",err
          throw err
        callback(codeshare)
    catch err
      log "While trying to compile the LESS to CSS, this happened: ",err
      callback(codeshare)
   else
    callback(codeshare)

  handleStylus:(codeshare, callback)=>
   if codeshare.modeCSS is "stylus"
    try
      callback(codeshare)
    catch err
      log "While trying to compile the Stylus to CSS, this happened: ",err
      callback(codeshare)
   else
    callback(codeshare)



  setResultObject:(codeshare)=>

   ## checkbox debug ## log "alics::setResultObject (codeshare.prefixCSS):", codeshare.prefixCSS, "(codeshare.prefixCSSCheck):", codeshare.prefixCSSCheck
   resultObject =
    resetFrame    : no
    stopFrame     : no
    renderFrame   : yes

    html          : codeshare.html
    htmlType      : "html"
    htmlClass     : codeshare.classesHTML
    htmlExtras    : codeshare.extrasHTML

    css           : codeshare.css
    cssType       : "css"
    cssPrefix     : if codeshare.prefixCSS is "on" then yes else no
    cssResets     : codeshare.resetsCSS
    cssExternals  : codeshare.externalCSS

    js            : codeshare.js
    jsType        : "javascript"
    jsLibs        : codeshare.libsJS
    jsExternals   : codeshare.externalJS
    jsModernizr   : if codeshare.modernizeJS is "on" then yes else no

   ## checkbox debug ## log "alics::setResultObject (resultObject.cssPrefix):", resultObject.cssPrefix

   @$(".result-frame")[0].contentWindow.postMessage(JSON.stringify(resultObject),@iframeURL)

  resetResultFrame:=>
    # @$(".result-frame")[0].contentWindow.postMessage(JSON.stringify({resetFrame:yes}),@iframeURL)
    # @codeView.options.attributes.url = @iframeFile
    @$(".result-frame")[0].src = @$(".result-frame")[0].src

  stopResultFrame:=>
    @$(".result-frame")[0].contentWindow.postMessage(JSON.stringify({stopFrame:yes}),@iframeURL)

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

  constructor:(options, data, extras={})->
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

    @extrasMode = new KDCustomHTMLView
      tagName  : "strong"
      cssClass : "snippet-extras "#+("hidden" if extrasListLength is 0)
      partial  : "<div>Extras:</div><span>#{@compileExtrasList(extras)}</span>"

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

  compileExtrasList:(extras)=>
    extrasList = []

    if extras.prefixCSS? and extras.prefixCSS is "on" then extrasList.push "PrefixFree"
    if extras.modernizeJS? and extras.modernizeJS is "on" then extrasList.push "Modernizr.js"

    if extras.externalJS? and extras.externalJS is not "" then extrasList.push "external JS"
    if extras.externalCSS? and extras.externalCSS is "" then extrasList.push "external CSS"
    if extras.classesHTML? and extras.classesHTML is "" then extrasList.push "additional HTML classes"
    if extras.extrasHTML? and extras.extrasHTML is "" then extrasList.push "additional HEAD tags"

    if extras.resetsCSS? and extras.resetsCSS is "reset" then extrasList.push "Eric Meyers CSS reset"
    if extras.resetsCSS? and extras.resetsCSS is "normalize" then extrasList.push "CSS normalize"

    if extras.libsJS? and /jquery/.test(extras.libsJS) is yes then extrasList.push "JQuery/JQueryUI"
    if extras.libsJS? and /mootools/.test(extras.libsJS) is yes then extrasList.push "MooTools"
    if extras.libsJS? and /dojo/.test(extras.libsJS) is yes then extrasList.push "Dojo"
    if extras.libsJS? and /ext-core/.test(extras.libsJS) is yes then extrasList.push "Ext Core"
    if extras.libsJS? and /prototype/.test(extras.libsJS) is yes then extrasList.push "Prototype"
    if extras.libsJS? and /scriptaculous/.test(extras.libsJS) is yes then extrasList.push "script.aculo.us"

    extrasListLength = extrasList.length

    if extrasListLength is 0
      compiledList = ""
    else if extrasListLength is 1
      compiledList = extrasList[0]
    else if extrasListLength is 2
      compiledList = extrasList[0]+" and "+extrasList[1]
    else
      compiledList = extrasList[0]+", "+extrasList[1...extrasListLength-1].join(", ")+" and "+extrasList[extrasListLength-1]

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
    {{> @extrasMode}}
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