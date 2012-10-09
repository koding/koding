class KDAutoCompleteListItemView extends KDListItemView
  constructor:(options,data)->
    super options,data
    @setClass "kdautocompletelistitem"
    @active = no

  viewAppended:()->
    @$().append @partial @data

  bindEvents:()->
    @getDomElement().bind "mouseenter mouseleave",(event)=>
      @handleEvent event
    super

  mouseEnter:()->
    @makeItemActive()

  destroy: ->
    super no

  mouseLeave:()->
    @makeItemInactive()

  makeItemActive:()->
    item.makeItemInactive() for item in @getDelegate().items
    @active = yes
    @setClass "active"

  makeItemInactive:()->
    @active = no
    @unsetClass "active"

  click:()->
    @propagateEvent KDEventType: 'KDAutoCompleteSubmit', globalEvent : yes, @data
    no

  partial:()->
    "<div class='autocomplete-item clearfix'>Default item</div>"
