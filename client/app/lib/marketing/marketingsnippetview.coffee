kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
MarketingSnippetType = require './marketingsnippettype'
applyMarkdown = require 'app/util/applyMarkdown'

###*
 * A view for rendering marketing snippets.
 * Rendering result depends on snippet type
 *
 * @class
###
module.exports = class MarketingSnippetView extends KDCustomHTMLView

  constructor: (options = {}) ->

    options.cssClass = kd.utils.curry 'marketing-snippet', options.cssClass

    super options

    { type, url, content } = options

    cssClass = "marketing-snippet-content marketing-snippet-#{type}"
    switch type
      when MarketingSnippetType.html
        @addSubView new KDCustomHTMLView {
          tagName    : 'iframe'
          cssClass
          attributes :
            src      : url
        }
      when MarketingSnippetType.markdown
        html = applyMarkdown content
        @addSubView new KDCustomHTMLView {
          cssClass   : kd.utils.curry 'has-markdown', cssClass
          partial    : html
        }