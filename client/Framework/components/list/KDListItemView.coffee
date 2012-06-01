class KDListItemView extends KDView
  constructor:(options,data)->
    options = options ? {}
    options.type      = options.type ? "default"
    options.cssClass  = "kdlistitemview kdlistitemview-#{options.type} #{options.cssClass ? ''}"
    options.bind    or= "mouseenter mouseleave"
    super options,data
    @content = {}

  viewAppended:()->
    @setPartial @partial @data
  
  partial:()->
    $ "<div class='kdlistitemview-default-content'>
        <p>This is a default partial of <b>KDListItemView</b>, 
        you need to override this partial to have your custom content here.</p>
      </div>"
      
  dim:()->
    @getDomElement().addClass "dimmed"

  undim:()->
    @getDomElement().removeClass "dimmed"
  
  highlight:()->
    @setClass "selected"
    @unsetClass "dimmed"

  removeHighlight:()->
    @unsetClass "selected"
    @unsetClass "dimmed"

  getItemDataId:()-> @getData().getId?()