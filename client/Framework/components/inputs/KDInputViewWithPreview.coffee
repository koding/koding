class KDInputViewWithPreview extends KDInputView

  constructor:(options,data)->

    options.preview               or= {}
    options.preview.autoUpdate    ?= yes
    options.preview.language      or= "markdown"
    options.preview.showInitially ?= yes

    options.keyup ?= (event)=>
      if @options.preview.autoUpdate
        @generatePreview()
      yes

    options.focus ?= (event)=>
      if @options.preview.autoUpdate
        @generatePreview()
      yes

    super options,data

    @setClass "kdinputwithpreview"

    @showPreview = options.preview.showInitially or no

    @previewOnOffLabel = new KDLabelView
      cssClass : "preview_switch_label"
      title: "Preview"
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

    @previewOnOffContainer.addSubView @previewOnOffLabel
    @previewOnOffContainer.addSubView @previewOnOffSwitch

    @addSubView @previewOnOffContainer

  setDomElement:(CssClass="")->
    super CssClass

    # basically, here we can add aynthing like modals, overlays and the liek

    @$().after """
      <div class='input_preview preview-#{@options.preview.language}'>
        <div class="preview_content"></div>
      </div>"""

  viewAppended:->
    super

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

    @$("div.preview_content").addClass("has-"+@options.preview.language)


  generatePreview:=>
    if @showPreview
      if @options.preview.language is "markdown"
        @$("div.preview_content").html @utils.applyMarkdown @getValue()
        @$("div.preview_content pre").addClass("prettyprint").each (i,element)=>
          hljs.highlightBlock element