class KDInputViewWithPreview extends KDInputView

  constructor:(options,data)->

    options.preview               or= {}
    options.preview.autoUpdate    ?= yes
    options.preview.language      or= "markdown"
    options.preview.showInitially ?= yes

    options.keyup ?= (event)=>
      if @options.preview.autoUpdate and @showPreview then @generatePreview()
      yes

    options.focus ?= (event)=>
      if @options.preview.autoUpdate and @showPreview then @generatePreview()
      yes

    super options,data

    @setClass "kdinputwithpreview"

    @showPreview = options.preview.showInitially or no

    log @getId()

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
        @generatePreview()
        @$("div.preview_content").removeClass "hidden"
      else
        @$("div.preview_content").addClass "hidden"

    unless @showPreview
      @$("div.preview_content").addClass "hidden"
      @$("input.preview_checkbox").prop("checked",no)
    else
      @generatePreview()
      @$("input.preview_checkbox").prop("checked",yes)

    @$("label").on "click",=>
      @$("input.preview_checkbox").get(0).click()

  generatePreview:=>
    if @showPreview
      if @options.preview.language is "markdown"
        @$("div.preview_content").html @utils.applyMarkdown @getValue()
        @$("div.preview_content pre").addClass("prettyprint").each (i,element)=>
          hljs.highlightBlock element