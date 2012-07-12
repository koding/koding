class JTreeItemView extends KDListItemView

  constructor:(options = {}, data = {})->

    options.tagName   or= "li"
    options.type      or= "jtreeitem"
    options.bind      or= "mouseenter contextmenu dragstart dragenter dragleave dragend dragover drop"
    super options, data
    @setClass "jtreeitem"
    @expanded = no
  
  viewAppended:->

    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    
    """
    <span class='icon'></span>
    {{#(title)}}
    """

  toggle:(callback)->

    if @expanded then @collapse() else @expand()

  expand:(callback)->

    @expanded = yes
    @setClass "expanded"
      
  collapse:(callback)->
    
    @expanded = no
    @unsetClass "expanded"

  decorateSubItemsState:(state = yes)->

    if state
      @setClass "has-sub-items"
    else
      @unsetClass "has-sub-items"