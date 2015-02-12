class PricingCustomQuoteView extends KDView
  constructor: (options = {}, data) ->
    options.tagName  = "section"
    options.cssClass = KD.utils.curry "custom-quote", options.cssClass
    super options, data

  viewAppended: ->
    @addSubView new KDHeaderView
      title    : "Want more giant-sized Resource Pack or want to deploy a custom version to your intranet?"
      type     : "medium"
      cssClass : "general-title"

    @addSubView new CustomLinkView
      title    : "GET A CUSTOM QUOTE"
      cssClass : "border-only-green"
      href     : "mailto:sales@koding.com?subject=I need more Koding!"
      target   : "_self"
