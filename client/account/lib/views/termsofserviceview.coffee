kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
module.exports = class TermsOfServiceView extends KDCustomHTMLView
  constructor : (options = {}, data) ->
    options.tagName     = 'iframe'
    options.attributes  =
      src               : "/Legal/Terms"

    super options, data


