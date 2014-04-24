class MarkdownWidget extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "md-widget", options.widgetClass

    super options, data

    @input         = new KDInputView
      type         : "textarea"
      autogrow     : yes
      cssClass     : KD.utils.curry "md-input", options.inputCssClass
      bind         : "keyup"
      keyup        : => @preview()  if @previewToggle.getValue()

    @previewToggle = new KodingSwitch
      size         : "tiny"
      cssClass     : "preview-toggle"
      defaultValue : options.preview ? no
      callback     : => @preview()

    @toggleLabel   = new KDCustomHTMLView
      tagName      : "span"
      cssClass     : "toggle-label"
      partial      : "Live Preview"

    @helpLink      = new KDCustomHTMLView
      tagName      : "a"
      attributes   :
        href       : "http://daringfireball.net/projects/markdown/syntax"
        target     : "_blank"
      partial      : "Need help?"
      cssClass     : "help-link"

    @previewArea   = new KDCustomHTMLView
      cssClass     : "preview-area"

    @previewLabel  = new KDCustomHTMLView
      tagName      : "p"
      cssClass     : "preview-label"
      partial      : "Preview will be available here"

    @previewArea.addSubView @previewLabel

  createMarkdownPreview: ->
    @markdownPreview?.destroy()
    @markdownPreview = new KDCustomHTMLView
      cssClass     : "md-preview"
      partial      : KD.utils.applyMarkdown @input.getValue()

    @previewArea.addSubView @markdownPreview

  preview: ->
    @previewLabel.hide()
    @createMarkdownPreview()

  setValue: (value) ->
    @input.setValue value

  getMarkdown: ->
    return KD.utils.applyMarkdown @input.getValue()

  getRawValue: ->
    return @input.getValue()

  viewAppended: ->
    super
    {defaultValue} = @getOptions()
    @setValue defaultValue  if defaultValue

  pistachio: ->
    """
      {{> @input}}
      <div class="tools">
        {{> @helpLink}}
        {{> @toggleLabel}}
        {{> @previewToggle}}
      </div>
      {{> @previewArea}}
    """
