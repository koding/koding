class TermsOfServiceView extends KDCustomHTMLView
  constructor : (options = {}, data) ->
    options.tagName     = 'iframe'
    options.attributes  =
      src               : "/tos.html"

    super options, data
