class KDAutoCompletedItem extends KDView

  constructor:(options = {}, data)->
    options.cssClass = @utils.curry "kdautocompletedlistitem", options.cssClass
    super

  click:(event)->
    @getDelegate().removeFromSubmitQueue @ if $(event.target).is('span.close-icon')
    @getDelegate().getView().$input().trigger "focus"

  viewAppended:->
    @setPartial @partial()

  partial:(data)->
    @getDelegate().getOptions().itemClass::partial @getData()

class KDAutocompleteUnselecteableItem extends KDListItemView
  click:->no
  keyUp:->no
  keyDown:-> no
  makeItemActive:->
  destroy:-> super no

class KDAutoCompleteNothingFoundItem extends KDAutocompleteUnselecteableItem
  constructor:(options = {}, data)->
    options.cssClass = @utils.curry "kdautocompletelistitem no-result", options.cssClass
    super

  partial: (data) ->
    "Nothing found"

class KDAutoCompleteFetchingItem extends KDAutocompleteUnselecteableItem

  constructor:(options = {}, data)->
    options.cssClass = @utils.curry "kdautocompletelistitem fetching", options.cssClass
    super

  partial:-> "Fetching in process..."

class NoAutocompleteInputView extends KDMultipleInputView

  keyUp: (event) ->
    if event.keyCode is 13
      @inputAddCurrentValue()

  setDomElement:(cssClass)->
    {placeholder} = @getOptions()
    @domElement = $ "<div class='#{cssClass}'><input type='text' class='main' placeholder='#{placeholder or ''}' /></div>"

  addItemToSubmitQueue: (item) ->
    no
