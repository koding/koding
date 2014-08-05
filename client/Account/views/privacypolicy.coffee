class PrivacyPolicyView extends KDCustomHTMLView
  constructor : (options = {}, data) ->
    options.tagName     = 'iframe'
    options.attributes  =
      src               : "#{KD.config.mainUri}/privacy.html"

    super options, data
