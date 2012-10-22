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

  setDomElement:(CssClass="")->
    super CssClass

    # basically, here we can add aynthing like modals, overlays and the liek

    @$().after """<div class='input_preview preview-#{@options.preview.language}'>
        <div class="preview_switch">
          <label for="previewCheckbox#{@getId()}">Preview</label>
          <input name="previewCheckbox#{@getId()}" type="checkbox" class="preview_checkbox" />
        </div>
        <div class="preview_content"></div>
      </div>"""

  viewAppended:->
    super

    @$("input.preview_checkbox").on "click",(event)=>
      checkState = @$("input.preview_checkbox").prop("checked") or no

      if checkState
        @showPreview = yes
        @generatePreview()
        @$("div.preview_content").removeClass "hidden"
        @$("div.preview_switch").removeClass "content-hidden"
        @$().removeClass "content-hidden"
      else
        @$("div.preview_content").addClass "hidden"
        @$("div.preview_switch").addClass "content-hidden"
        @$().addClass "content-hidden"

    unless @showPreview
      @$("div.preview_content").addClass "hidden"
      @$("div.preview_switch").addClass "content-hidden"
      @$().addClass "content-hidden"
      @$("input.preview_checkbox").prop("checked",no)
    else
      @generatePreview()
      @$("input.preview_checkbox").prop("checked",yes)

    @$("label").on "click",=>
      @$("input.preview_checkbox").get(0).click()

    @$("div.preview_content").addClass("has-"+@options.preview.language)


  generatePreview:=>
    if @showPreview
      if @options.preview.language is "markdown"
        @$("div.preview_content").html @utils.applyMarkdown @getValue()
        @$("div.preview_content pre").addClass("prettyprint").each (i,element)=>
          hljs.highlightBlock element