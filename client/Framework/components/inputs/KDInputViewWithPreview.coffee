class KDInputViewWithPreview extends KDInputView

  constructor:(options = {}, data)->
    options.preview               or= {}
    options.preview.autoUpdate    ?= yes
    options.preview.language      or= "markdown"
    options.preview.showInitially ?= yes
    options.preview.mirrorScroll  ?= yes
    options.allowMaximized        ?= yes
    options.openMaximized         ?= no
    options.showHelperModal       ?= yes

    options.keyup ?= (event)=>
      if @options.preview.autoUpdate
        @generatePreview()
      yes

    options.focus ?= (event)=>
      if @options.preview.autoUpdate
        @generatePreview()
      yes

    super options, data

    @setClass "kdinputwithpreview"

    @showPreview = options.preview.showInitially or no

    @previewOnOffLabel = new KDLabelView
      cssClass      : "preview_switch_label unselectable"
      title         : "Preview"
      tooltip       :
        title       : "Show/hide the Text Preview Box"
      click         :=>
        @previewOnOffSwitch.setValue not @previewOnOffSwitch.getValue()
        no

    @previewOnOffSwitch = new KDOnOffSwitch
      label         : @previewOnOffLabel
      size          : "tiny"
      defaultValue  : if @showPreview then on else off
      callback      : (state)=>
        if state
          @showPreview = yes
          @generatePreview()
          @$("div.preview_content").removeClass "hidden"
          @$("div.preview_switch").removeClass "content-hidden"
          @$().removeClass "content-hidden"
          @emit "PreviewShown"
        else
          @$("div.preview_content").addClass "hidden"
          @$("div.preview_switch").addClass "content-hidden"
          @$().addClass "content-hidden"
          @emit "PreviewHidden"

    @previewOnOffContainer = new KDView
      cssClass : "preview_switch"

    if @options.showHelperModal
      @markdownLink = @getMarkdownLink()
      @previewOnOffContainer.addSubView @markdownLink

    if @options.allowMaximized
      @fullscreenEditButton = @getFullscreenEditButton()
      @previewOnOffContainer.addSubView @fullscreenEditButton

    @previewOnOffContainer.addSubView @previewOnOffLabel
    @previewOnOffContainer.addSubView @previewOnOffSwitch

    @addSubView @previewOnOffContainer

    @listenWindowResize()

  setPaneSizes:(opt_setWidths = yes)->
    # For: "Uncaught TypeError: Cannot call method '$' of undefined"
    return  unless @modal

    # selector performance?
    kdmodalContent = @modal.$(".kdmodal-content")
    fullscreenData = @modal.$(".fullscreen-data")
    inputPreview   = @modal.$(".input_preview")

    # minus the margin, border pixels too..
    kdmodalContent.height @modal.$(".kdmodal-inner").height() - @modal.$(".kdmodal-buttons").height() - @modal.$(".kdmodal-title").height()
    
    kdmodalContentHeight = kdmodalContent.height()

    fullscreenData.height kdmodalContentHeight - 30 - 23 + 10
    inputPreview.height kdmodalContentHeight - 0 - 21 + 10
    @modal.$(".input_preview div.preview_content").css "maxHeight",  kdmodalContentHeight - 0 - 21

    contentWidth = kdmodalContent.width() - 40
    halfWidth    = contentWidth / 2

    @text.on "PreviewHidden", =>
      fullscreenData.width contentWidth

    @text.on "PreviewShown", =>
      fullscreenData.width contentWidth - halfWidth - 5

    if opt_setWidths
      fullscreenData.width contentWidth - halfWidth - 5
      inputPreview.width halfWidth - 5

    # quick fix for "window.on resize"
    @modal.$().height window.innerHeight - 55

  getMarkdownLink:->
    new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "markdown-link unselectable"
      partial     : "What is Markdown?"
      tooltip     :
        title     : "Show available Markdown formatting syntax"
      click       : -> new MarkdownModal

  getFullscreenEditButton:->
    new KDButtonView
      style           : "clean-gray small"
      cssClass        : "fullscreen-button"
      title           : "Fullscreen Edit"
      icon            : no
      tooltip         :
        title         : "Open a Fullscreen Editor"
      callback        : =>
        @textContainer = new KDView
          cssClass:"modal-fullscreen-text"

        @text = new KDInputViewWithPreview
          type           : "textarea"
          cssClass       : "fullscreen-data kdinput text"
          allowMaximized : no
          defaultValue   : @getValue()

        @textContainer.addSubView @text

        @modal = new KDModalView
          title        : "Please enter your content here."
          cssClass     : "modal-fullscreen"
          width        : window.innerWidth - 100
          height       : window.innerHeight - 55
          overlay      : yes
          view         : @textContainer
          buttons      :
            Apply      :
              title    : "Apply changes"
              style    : "modal-clean-gray"
              callback :=>
                @setValue @text.getValue()
                @generatePreview()
                @modal.destroy()
            Cancel     :
              title    : "cancel"
              style    : "modal-cancel"
              callback :=> @modal.destroy()

        @utils.defer =>
          @setPaneSizes()

  getEditScrollPercentage:->
      scrollPosition  = @$().scrollTop()
      scrollHeight    = @$().height()
      scrollMaxheight = @getDomElement()[0].scrollHeight

      scrollPosition / (scrollMaxheight - scrollHeight) * 100

  setPreviewScrollPercentage:(percentage)->
    s = @$("div.preview_content")
    s.animate
     scrollTop : ((s[0].scrollHeight - s.height()) * percentage / 100)
    , 50, "linear"

  setDomElement:(cssClass="")->
    @inputName = @getOptions().name
    name = "name='#{@inputName}'"
    @domElement = $ """<textarea #{name} class='kdinput text #{cssClass}'></textarea>
      <div class='input_preview kdinputwithpreview preview-#{@options.preview.language}'>
        <div class="preview_content"><span class="data"></span></div>
      </div>"""

  viewAppended:->
    super

    @$("div.preview_content").addClass("has-"+@options.preview.language)

    unless @showPreview
      @$("div.preview_content").addClass "hidden"
      @$("div.preview_switch").addClass "content-hidden"
      @$().addClass "content-hidden"
      @previewOnOffSwitch.setValue off
    else
      @generatePreview()
      @previewOnOffSwitch.setValue on

    @$("label").on "click",=>
      @$("input.checkbox").get(0).click()


    # hotfix for random display:none that can sometimes come up
    @utils.defer =>
      @$("span.data").css display:"block"

    if @options.preview.mirrorScroll then @$().scroll (event)=>
      @setPreviewScrollPercentage @getEditScrollPercentage()

  setValue:(value)->
    super value
    @text?.setValue value
    @generatePreview()

  generatePreview:->
    if @showPreview
      if @options.preview.language is "markdown"
        @$("div.preview_content span.data").html @utils.applyMarkdown @getValue()
        @$("div.preview_content span.data pre").each (i,element)=>
          hljs.highlightBlock element
  
  _windowDidResize:->
    @utils.defer =>
      opt_setWidths = @previewOnOffSwitch.defaultValue is on
      @setPaneSizes(opt_setWidths)
