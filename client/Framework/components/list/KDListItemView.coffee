class KDListItemView extends KDView

  constructor:(options = {},data)->

    options.type           = options.type ? "default"
    options.cssClass       = "kdlistitemview kdlistitemview-#{options.type} #{options.cssClass ? ''}"
    options.bind         or= "mouseenter mouseleave"
    options.childClass   or= null
    options.childOptions or= {}
    options.selectable    ?= yes

    super options,data

    @content = {}

  viewAppended:->

    {childClass, childOptions} = @getOptions()
    if childClass
      @addSubView @child = new childClass childOptions, @getData()
    else
      @setPartial @partial @data

  partial:->
    "<div class='kdlistitemview-default-content'>
      <p>This is a default partial of <b>KDListItemView</b>,
      you need to override this partial to have your custom content here.</p>
    </div>"

  dim:->

    @getDomElement().addClass "dimmed"

  undim:->

    @getDomElement().removeClass "dimmed"

  highlight:->

    @setClass "selected"
    @unsetClass "dimmed"

  removeHighlight:->

    @unsetClass "selected"
    @unsetClass "dimmed"

  getItemDataId:-> @getData().getId?()