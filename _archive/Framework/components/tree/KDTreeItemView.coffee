class KDTreeItemView extends KDView
  constructor:(options = {},data = {})->
    options.bind      or= ""
    options.cssClass  or= ""

    data.type         or= "default"
    
    options.bind      = "mousedown mouseup click #{options.bind}"
    options.cssClass  = "kdtreeitemview #{data.type} #{options.cssClass}"

    super options,data

  getItemDataId:()-> @getData().id
  getParentNodeId:()-> @getData().parentId
  
  dim:()->
    @getDomElement().addClass "dimmed"

  undim:()->
    @getDomElement().removeClass "dimmed"
  
  isSelected:()->
    @selected
  
  setSelected:()->
    @selected = yes
  
  setUnselected:()->
    @selected = no

  highlight:()->
    @getDomElement().addClass "selected"
    @getDomElement().removeClass "dimmed"

  removeHighlight:()->
    @getDomElement().removeClass "selected"
    @getDomElement().removeClass "dimmed"

  viewAppended:()->
    @getDomElement().append @partial @data
    super

  partial:(data)->
    $ "<div class='default clearfix'>
        <span class='arrow arrow-right'></span>
        <span class='title'>#{data.title}</span>
      </div>"