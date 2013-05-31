class NavigationSeparator extends KDCustomHTMLView

  constructor:(options = {}, data)->

    options.tagName  = "hr"

    super options, data
