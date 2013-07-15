class PreviewPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = "preview-pane"

    super options, data

    @container = new KDView

    if options.url then @setIframe()
    else
      @placeholder = new KDView
        cssClass : "placeholder"
        partial  : "Your result will be displayed here"
      @container.addSubView @placeholder

  setIframe: ->
    options = @getOptions()

    @container.addSubView new KDCustomHTMLView
      tagName       : "iframe"
      attributes    :
        type        : "text/html"
        width       : options.width  or "100%"
        height      : options.height or "100%"
        frameborder : 0
        src         : @getProperty "url"

  pistachio: ->
    """
      {{> @header}}
      {{> @container}}
    """
