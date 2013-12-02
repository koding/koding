class VideoPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = "vide-pane"

    super options, data

    @container      = new KDCustomHTMLView
      tagName       : "iframe"
      attributes    :
        type        : "text/html"
        width       : options.width  or "100%"
        height      : options.height or "100%"
        frameborder : 0
        src         : "http://www.youtube.com/embed/#{options.videoId}?autoplay=0"

  pistachio: ->
    """
      {{> @header}}
      {{> @container}}
    """