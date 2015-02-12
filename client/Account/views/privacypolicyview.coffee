class PrivacyPolicyView extends KDCustomHTMLView
  constructor : (options = {}, data) ->
    options.tagName     = 'iframe'
    options.attributes  =
      src               : "/privacy.html"

    super options, data
