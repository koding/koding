class KDCustomHTMLView extends KDView
  constructor:(options = {},data)->
    @tagName = options if typeof options is "string"
    @tagName ?= options.tagName ? "div"
    super

  setDomElement:(cssClass)->
    @domElement = $ "<#{@tagName}/>",
      class : cssClass