class KDProgressBarView extends KDCustomHTMLView
  constructor:(options = {})->
    options.cssClass = KD.utils.curry "progressbar-container", options.cssClass

    super options

  viewAppended:->
    @createBar()

  createBar:(value, label)->
    @addSubView @bar = new KDCustomHTMLView
      cssClass    : "bar"
    @addSubView @darkLabel = new KDCustomHTMLView
      tagName     : "span"
    @bar.addSubView @lightLabel = new KDCustomHTMLView
      tagName     : "span"

  updateBar:(value, unit, label)->
    @bar.setWidth value, unit
    @darkLabel.updatePartial "#{label}&nbsp;"
    @lightLabel.updatePartial "#{label}&nbsp;"