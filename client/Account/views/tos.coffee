class TermsOfServiceView extends KDCustomHTMLView
  constructor : (options = {}, data) ->
    options.tagName     = 'iframe'
    options.attributes  =
      src               : "#{KD.config.mainUri}/tos.html"

    super options, data
