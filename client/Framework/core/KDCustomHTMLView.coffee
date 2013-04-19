class KDCustomHTMLView extends KDView

  constructor:(options = {}, data)->

    @tagName = options if typeof options is "string"
    @tagName ?= options.tagName ? "div"

    if @tagName is "a" and not options.attributes?.href?
      options.attributes = href : "#"

    super

  setDomElement:(cssClass)->

    super

    @unsetClass "kdview"