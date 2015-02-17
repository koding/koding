kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
module.exports = class PrivacyPolicyView extends KDCustomHTMLView
  constructor : (options = {}, data) ->
    options.tagName     = 'iframe'
    options.attributes  =
      src               : "/privacy.html"

    super options, data


