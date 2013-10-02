class KDProgressBarView extends KDCustomHTMLView
  constructor:(options = {})->

    options.cssClass = KD.utils.curry "progressbar-container", options.cssClass

    options.determinate  ?= yes
    options.initial      ?= no
    options.title        ?= ""

    super options

  viewAppended:->
    {initial, title} = @getOptions()
    @createBar()
    @updateBar initial or 1, "%", title

  createBar:(value, label)->
    @addSubView @bar = new KDCustomHTMLView
      cssClass    : "bar"
    @addSubView @spinner = new KDCustomHTMLView
      cssClass    : "bar spinner hidden"
    @addSubView @darkLabel = new KDCustomHTMLView
      tagName     : "span"
      cssClass    : 'dark-label'
    @bar.addSubView @lightLabel = new KDCustomHTMLView
      tagName     : "span"
      cssClass    : 'light-label'

  updateBar:(value, unit, label)->
    {determinate} = @getOptions()
    if determinate
      @bar.show()
      @spinner.hide()
      @bar.setWidth value, unit
      @darkLabel.updatePartial "#{label}&nbsp;"
      @lightLabel.updatePartial "#{label}&nbsp;"
    else
      @bar.hide()
      @spinner.show()
