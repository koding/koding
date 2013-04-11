class KDHiddenView extends KDCustomHTMLView

  constructor:(options = {},data)->

    @tagName = options if typeof options is 'string'
    @tagName ?= options.tagName ? 'span'

    super
    
    @setClass 'hidden'
