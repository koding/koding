class KDCustomHTMLView extends KDView

  constructor:(options = {}, data)->

    if typeof options is "string"

      if options is "hidden"
        tagName  = "span"
        cssClass = "hidden"
      else
        tagName  = options
        cssClass = ''

      options = {tagName, cssClass}

    if options.tagName? is "a" and not options.attributes?.href?
      options.attributes = href : "#"

    super

  setDomElement:(cssClass)->
    super cssClass, ''
