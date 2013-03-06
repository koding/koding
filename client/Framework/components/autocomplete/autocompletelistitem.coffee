class KDAutoCompleteListItemView extends KDListItemView

  constructor:(options = {}, data)->

    options.cssClass = KD.utils.curryCssClass "kdautocompletelistitem", options.cssClass
    options.bind     = "mouseenter mouseleave"

    super options,data

    @active = no

  viewAppended:()-> @updatePartial @partial @data

  mouseEnter:()-> @makeItemActive()

  mouseLeave:()-> @makeItemInactive()

  makeItemActive:()->
    item.makeItemInactive() for item in @getDelegate().items
    @active = yes
    @setClass "active"

  makeItemInactive:()->
    @active = no
    @unsetClass "active"

  click:()->
    list = @getDelegate()
    list.emit 'KDAutoCompleteSubmit', @, @data
    no

  partial:()-> "<div class='autocomplete-item clearfix'>Default item</div>"
