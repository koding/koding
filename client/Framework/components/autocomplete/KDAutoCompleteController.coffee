class KDAutoCompleteController extends KDViewController
  constructor:(options = {},data)->
    options = $.extend
      view                  : mainView = options.view or new KDAutoComplete
        name                : options.name
        label               : options.label or new KDLabelView
          title             : options.name
      itemClass             : KDAutoCompleteListItemView
      selectedItemClass     : KDAutoCompletedItem
      nothingFoundItemClass : KDAutoCompleteNothingFoundItem
      fetchingItemClass     : KDAutoCompleteFetchingItem
      listWrapperCssClass   : ''
      minSuggestionLength   : 2
      selectedItemsLimit    : null
      itemDataPath          : ''
      separator             : ','
      wrapper               : 'parent'
      submitValuesAsText    : no
      defaultValue          : []
    ,options

    super options, data

    mainView.registerListener
      KDEventTypes: 'focus'
      listener: @
      callback:(event)=>
        @updateDropdownContents()

    @selectedItemData    = []
    @hiddenInputs        = {}
    @selectedItemCounter = 0

  reset:->
    subViews    = @itemWrapper.getSubViews().slice()
    for item in subViews
      @removeFromSubmitQueue item

  loadView:(mainView)->
    @createDropDown()
    @getAutoCompletedItemParent()
    @setDefaultValue()

    mainView.registerListener KDEventTypes : 'keyup', callback : __utils.throttle(@keyUpOnInputView,300), listener : @
    mainView.registerListener KDEventTypes : 'keydown', listener : @, callback : @keyDownOnInputView

  setDefaultValue:(defaultItems)->
    {defaultValue, itemDataPath} = @getOptions()
    defaultItems or= defaultValue
    for item in defaultItems
      @addItemToSubmitQueue @getView(), item

  keyDownOnInputView:(autoCompleteView,event)=>

    switch event.which
      when 13, 9 #enter, tab
        unless autoCompleteView.getValue() is ""
          @submitAutoComplete autoCompleteView.getValue()
        else
          return yes
      when 27 #escape
        @hideDropdown()
      when 38 #uparrow
        @dropdown.getListView().goUp()
      when 40 #downarrow
        @dropdown.getListView().goDown()
        @getView().$input().blur()
    no

  getPrefix:()->
    separator = @getOptions().separator
    items = @getView().getValue().split separator
    prefix = items[items.length-1]
    prefix

  createDropDown:(data = [])->
    # log "#{data.length} items in auto complete"
    @dropdownPrefix = ""
    @dropdownListView = dropdownListView = new KDAutoCompleteListView {
      subItemClass  : @getOptions().itemClass
    },{
      items : data
    }
    dropdownListView.registerListener
      KDEventTypes  : 'ItemsDeselected'
      listener      : @
      callback      : =>
        view = @getView()
        view.$input().trigger('focus')

    dropdownListView.on 'ItemWasAdded', (view, index)=>
      view.registerListener
        KDEventTypes  : 'KDAutoCompleteSubmit'
        listener      : @
        callback      : @submitAutoComplete

    windowController = @getSingleton('windowController')

    @dropdown = new KDListViewController
      view          : dropdownListView

    dropdownWrapper = @dropdown.getView()

    dropdownWrapper.on 'ReceivedClickElsewhere', =>
      @hideDropdown()

    dropdownWrapper.setClass "kdautocomplete hidden #{@getOptions().listWrapperCssClass}"
    KDView.appendToDOMBody dropdownWrapper

  hideDropdown:->
    dropdownWrapper = @dropdown.getView()
    dropdownWrapper.$().fadeOut 75

  showDropdown:->
    windowController = @getSingleton('windowController')
    dropdownWrapper = @dropdown.getView()
    dropdownWrapper.unsetClass "hidden"
    input  = @getView()
    offset = input.$().offset()

    offset.top += input.getHeight()
    dropdownWrapper.$().css offset

    dropdownWrapper.$().fadeIn 75
    windowController.addLayer dropdownWrapper

    # parent = @getView()
    # x = parent.getX()
    # y = parent.getY()
    # @dropdown.getView().$().css
    #   top   : y
    #   left  : x
    # log @dropdown.getListView()
    # @dropdown.getListView().$().css
    #   left  : mainView.getLeftOffset()
    #   top   : mainView.getHeight()-1


  refreshDropDown:(data = [])->
    listView = @dropdown.getListView()
    @dropdown.removeAllItems()
    listView.userInput = @dropdownPrefix

    exactPattern = RegExp('^'+@dropdownPrefix.replace(/[^\s\w]/, '')+'$', 'i')
    exactMatches = []
    inexactMatches = []

    {itemDataPath,allowNewSuggestions,minSuggestionLength} = @getOptions()

    data.forEach (datum)=>
      unless @isItemAlreadySelected datum
        match = JsPath.getAt datum, itemDataPath

        if exactPattern.test match
          exactMatches.push datum
        else
          inexactMatches.push datum

    if (@dropdownPrefix.length >= minSuggestionLength) and allowNewSuggestions and not exactMatches.length
      @dropdown.getListView().addItemView @getNoItemFoundView()

    data = exactMatches.concat inexactMatches
    @dropdown.instantiateListItems data
    @dropdown.getListView().goDown()
  #
  # instantiateDropdownListItems:(items)->
  #   itemClass = @getOptions().itemClass
  #   dropdownListView = @dropdown.getListView()
  #
  #   if not itemClass
  #     log 'there is no item class for autocomplete item, will use default one'
  #     itemClass = KDAutoCompleteListItemView
  #
  #   for listItem in items
  #     itemInstance = new itemClass {delegate : dropdownListView},listItem
  #     dropdownListView.items.push itemInstance
  #     dropdownListView.appendItem itemInstance
  #
  #     itemInstance.registerListener KDEventTypes : 'KDAutoCompleteSubmit', listener : @, callback : @submitAutoComplete
  #
  #   dropdownListView.items[0]?.makeItemActive()
  #
  submitAutoComplete:(publishingInstance, data)->
    inputView = @getView()
    # log @getOptions().selectedItemsLimit, @selectedItemCounter
    if @getOptions().selectedItemsLimit is null or @getOptions().selectedItemsLimit > @selectedItemCounter
      activeItem = @dropdown.getListView().getActiveItem()
      if activeItem.item
        @appendAutoCompletedItem()
      @addItemToSubmitQueue activeItem.item
      @rearrangeInputWidth()
      @emit 'ItemListChanged'
    else
      inputView.setValue ''
      @getSingleton("windowController").setKeyView null
      new KDNotificationView
        type      : "mini"
        title     : "You can add up to #{@getOptions().selectedItemsLimit} items!"
        duration  : 4000

    @hideDropdown()

  getAutoCompletedItemParent:->
    {outputWrapper} = @getOptions()
    if outputWrapper instanceof KDView
      @itemWrapper = outputWrapper
    else
      @itemWrapper = @getView()

  isItemAlreadySelected:(data)->
    {itemDataPath,customCompare,isCaseSensitive} = @getOptions()
    suggested = JsPath.getAt data, itemDataPath
    for selectedData in @getSelectedItemData()
      if compare?
        alreadySelected = customCompare data, selectedData
        return yes if alreadySelected
      else
        selected = JsPath.getAt selectedData, itemDataPath
        unless isCaseSensitive
          suggested = suggested.toLowerCase()
          selected = selected.toLowerCase()
        if suggested is selected
          return yes
    no

  addHiddenInputItem:(name, value)->
    @itemWrapper.addSubView @hiddenInputs[name] = new KDInputView
      type          : "hidden"
      name          : name
      defaultValue  : value

  removeHiddenInputItem:(name)->
    @hiddenInputs[name].remove()

  addSelectedItem:(name,data)->
    {selectedItemClass} = @getOptions()
    @itemWrapper.addSubView itemView = new selectedItemClass
      cssClass : "kdautocompletedlistitem"
      delegate : @
      name     : name
    ,data
    itemView.setPartial "<span class='close-icon'></span>"

  getSelectedItemData:->
    @selectedItemData

  addSelectedItemData:(data)->
    @getSelectedItemData().push data

  removeSelectedItemData:(data)->
    selectedItemData = @getSelectedItemData()
    for selectedData,i in selectedItemData
      if selectedData is data
        selectedItemData.splice i,1
        return

  getCollectionPath:->
    {name} = @getOptions()
    throw new Error 'No name!' unless name
    [path..., leaf] = name.split('.')
    collectionName = Inflector.pluralize(leaf)
    path.push collectionName
    path.join('.')

  addSuggestion:(title)->
    @emit 'AutocompleteSuggestionWasAdded', title

  addItemToSubmitQueue:(item,data)->
    data or= item.getData()

    {itemDataPath,form,submitValuesAsText} = @getOptions()

    if data
      itemValue = if submitValuesAsText then JsPath.getAt data, itemDataPath else data
    else
      itemValue = item.getOptions().userInput
      data = JsPath itemDataPath, itemValue

    return no if @isItemAlreadySelected data

    path = @getCollectionPath()

    itemName  = "#{name}-#{@selectedItemCounter++}"
    if form
      collection = form.getCustomData path
      collection = [] unless collection?
      form.addCustomData path, collection
      id = itemValue.getId?()
      collection.push(
        if submitValuesAsText
          itemValue
        else if id?
          constructorName   : itemValue.constructor.name
          id                : id
          title             : itemValue.title
        else
          $suggest          : itemValue
      )
      if item.getOptions().userInput is not ""
        @selectedItemCounter++
    else
      @addHiddenInputItem path.join('.'),itemValue

    @addSelectedItemData data
    @addSelectedItem itemName, data
    # debugger
    @getView().setValue @dropdownPrefix = ""

  removeFromSubmitQueue:(item, data)->
    {itemDataPath,form} = @getOptions()
    data      or= item.getData()
    path = @getCollectionPath()
    if form
      collection = JsPath.getAt form.getCustomData(), path
      collection = collection.filter (sibling)->
        id = data.getId?()
        unless id?
          sibling.$suggest isnt data.title
        else
          sibling.id isnt id
      JsPath.setAt form.getCustomData(), path, collection
    else
      @removeHiddenInputItem path.join('.')
    @removeSelectedItemData data
    @selectedItemCounter--
    item.destroy()
    @emit 'ItemListChanged'

  rearrangeInputWidth:()->
    # mainView = @getView()
    # mainView.$input().width mainView.$input().parent().width() - mainView.$input().prev().width()

  appendAutoCompletedItem:()->
    @getView().setValue ""
    @getView().$input().trigger "focus"

  updateDropdownContents:->
    inputView = @getView()
    if inputView.getValue() is ""
      @hideDropdown()

    if inputView.getValue() isnt "" # and @dropdownPrefix isnt inputView.getValue()
      @dropdownPrefix = inputView.getValue()
      @fetch (data)=>
        @refreshDropDown data
        @showDropdown()

  keyUpOnInputView:(inputView, event)=>
    return if event.keyCode in [9,38,40] #tab
    @updateDropdownContents()
    # else
    #   log "just wait for a selection"
    no

  #this one I guess should be overriden
  fetch:(callback)->
    args = {}
    if @getOptions().fetchInputName
      args[@getOptions().fetchInputName] = @getView().getValue()
    else
      args = inputValue : @getView().getValue()

    @dropdownPrefix = @getView().getValue()
    source = @getOptions().dataSource
    source args, callback

  showFetching: ->
    {fetchingItemClass} = @getOptions()
    if @dropdown.getListView().items?[0] not instanceof KDAutoCompleteFetchingItem
      view = new fetchingItemClass
      if @dropdown.getListView().items.length
        @dropdown.getListView().addItemView view, 0
      else
        @dropdown.getListView().addItemView view

  getNoItemFoundView:(suggestion) ->
    {nothingFoundItemClass} = @getOptions()
    view = new nothingFoundItemClass
      delegate: @dropdown.getListView()
      userInput: suggestion or @getView().getValue()

  showNoDataFound: ->
    noItemFoundView = @getNoItemFoundView()
    @dropdown.removeAllItems()
    @dropdown.getListView().addItemView noItemFoundView
    @showDropdown()

  destroy:->
    @dropdown.getView().destroy()
    super

class KDAutoComplete extends KDInputView
  mouseDown: ->
    @focus()

  setDomElement:->
    @domElement = $ "<div class='kdautocompletewrapper clearfix'><input type='text' class='kdinput text'/></div>"

  setDomId:()->
    @$input().attr "id",@getDomId()
    @$input().attr "name",@getName()
    @$input().data "data-id",@getId()

  setDefaultValue:(value) ->
    @inputDefaultValue = value
    @setValue value

  $input:()->@$().find("input").eq(0)
  getValue:()-> @$input().val()
  setValue:(value)-> @$input().val(value)

  bindEvents:()->
    super @$input()

  # FIX THIS: on blur dropdown should disappear but the
  # problem is if you the lines below, blur fires earlier than
  # KDAutoCompleteListItemViewClick and that breaks mouse selection
  # on autocomplete list
  blur:(pubInst,event)->
    @unsetClass "focus"
    # @hideDropdown()
    # log pubInst,event.target,"blur"
    # @destroyDropdown()

  focus:(pubInst,event)->
    @setClass "focus"
    (@getSingleton "windowController").setKeyView @

  keyDown:(event)->
    (@getSingleton "windowController").setKeyView @
    switch event.which
      when 13, 27, 38, 40 #enter, escape, up, down
        no
      else yes

  getLeftOffset:()->
    @$input().prev().width()

  destroyDropdown:()->
    @removeSubView @dropdown if @dropdown?
    @dropdownPrefix = ""
    @dropdown = null

class KDAutocompleteUnselecteableItem extends KDListItemView
  click: ->
    no

  keyUp: ->
    no

  keyDown: ->
    no

  makeItemActive: ->

  destroy: ->
    super no

class KDAutoCompleteFetchingItem extends KDAutocompleteUnselecteableItem
  constructor:->
    super
    @setClass "kdautocompletelistitem fetching"
  partial: (data) ->
    "Fetching in process..."

class KDAutoCompleteNothingFoundItem extends KDAutocompleteUnselecteableItem
  constructor:->
    super
    @setClass "kdautocompletelistitem no-result"
  partial: (data) ->
    "Nothing found"

class KDAutoCompletedItem extends KDView
  constructor:(options,data)->
    options = options ? {}
    cssClass = options.cssClass ? ''
    options.cssClass = "kdautocompletedlistitem #{cssClass}"
    super

  click:(event)->
    @getDelegate().removeFromSubmitQueue @ if $(event.target).is('span.close-icon')
    @getDelegate().getView().$input().trigger "focus"

  viewAppended:->
    @setPartial @partial()

  partial:(data)->
    @getDelegate().getOptions().itemClass::partial @getData()

#FIXME: Can't these methods be used in the general KDListView? -sah
class KDAutoCompleteListView extends KDListView
  constructor:(options,data)->
    super options,data
    @setClass "kdautocompletelist"

  # keyDown:(autoCompleteView,event)=>
  #   switch event.which
  #     when 13 #enter
  #       # @submitAutoComplete autoCompleteView.getValue()
  #     when 27 #escape
  #       # @hideDropdown()
  #     when 38 #uparrow
  #       @goUp()
  #       # @getView().$input().blur()
  #     when 40 #downarrow
  #       @goDown()
  #       # @getView().$input().blur()
  #   no
  goDown:()->
    activeItem = @getActiveItem()
    if activeItem.index?
      nextItem = @items[activeItem.index+1]
      if nextItem?
        nextItem.makeItemActive()
    else
      @items[0]?.makeItemActive()

  goUp:()->
    activeItem = @getActiveItem()
    if activeItem.index?
      if @items[activeItem.index-1]?
        @items[activeItem.index-1].makeItemActive()
      else
        @propagateEvent KDEventType: 'ItemsDeselected'
    else
      @items[0].makeItemActive()

  getActiveItem:()->
    active =
      index : null
      item  : null
    for item,i in @items
      if item.active
        active.item  = item
        active.index = i
        break
    active

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

# SIMPLE AUTOCOMPLETE VIEW
class KDSimpleAutocomplete extends KDAutoComplete
  addItemToSubmitQueue: (item) ->
    itemValue = JsPath.getAt item.getData(), @getOptions().itemDataPath
    @setValue itemValue

  keyUp: (event) ->
    return if event.keyCode is 13
    super

  showNoDataFound: ->
    @dropdown.removeAllItems()
    @hideDropdown()

class KDMultipleInputView extends KDSimpleAutocomplete
  constructor: (options) ->
    @_values = []
    options = $.extend {
      icon: 'noicon'
      title: ''
    }, options
    super options

  focus:(pubInst,event)->
    (@getSingleton "windowController").setKeyView @

  viewAppended: ->
    # log 'view appended'
    @list = new MultipleInputListView delegate: @
    @addSubView @list

  $input:()-> @$().find("input.main").eq(0)

  getValues: ->
    @_values

  rearrangeInputWidth: ->
    no

  addItemToSubmitQueue: ->
    super
    @inputAddCurrentValue()

  keyUp: (event) ->
    if event.keyCode is 13
      @inputAddCurrentValue()

    super

  inputRemoveValue: (value) ->
    index = @_values.indexOf value
    if index > -1
      @_values.splice index, 1

    @_inputChanged()

  clear: ->
    @_values = []
    @removeAllItems()
    @_inputChanged()

  inputAddCurrentValue: () ->
    value = @$input().val()
    value = $.trim value

    return if value in @_values or value is ''

    @_values.push value
    @$input().val ''
    @list.addItems [value]

    @_inputChanged()

  _inputChanged: ->
    if not @_hiddenInputs
      @_hiddenInputs = []

    #remove old inputs
    for input in @_hiddenInputs
      input.destroy()

    inputName = @getOptions().name
    for value, index in @_values
      newInput = new KDInputView type: 'hidden', name: inputName + "[#{index}]", defaultValue: value
      @_hiddenInputs.push newInput
      @addSubView newInput

    @handleEvent type: 'MultipleInputChanged', values: @getValue()

  click: (event) ->
    if $(event.target).hasClass 'addNewItem'
      @inputAddCurrentValue()


  setDomId:()->
    @$input().attr "id", @getDomId()
    @$input().data "data-id", @getId()
    # @$input().attr "name", @getName()

  setDomElement: ->
    # <p class='search-tags clearfix'><span>Ryan <cite>x</cite></span></p>
    @domElement = $ "<div class='filter kdview'>
      <h2>#{@getOptions().title}</h2>
      <div class='clearfix'>
        <span class='#{@getOptions().icon}'></span>
        <input type='text' class='main'>
        <a href='#' class='addNewItem'>+</a>
      </div>
    </div>"

class NoAutocompleteInputView extends KDMultipleInputView

  keyUp: (event) ->
    if event.keyCode is 13
      @inputAddCurrentValue()

  setDomElement:(cssClass)->
    {placeholder} = @getOptions()
    @domElement = $ "<div class='#{cssClass}'><input type='text' class='main' placeholder='#{placeholder or ''}' /></div>"

  addItemToSubmitQueue: (item) ->
    no

class NoAutocompleteMultipleListView extends KDView
  constructor: (options, data) ->
    options ?= {}
    defaults =
      cssClass: 'common-view input-with-extras'
    options = $.extend defaults, options
    super options, data

  viewAppended: ->
    {icon,input,button} = @options

    if icon
      @setClass "with-icon"
      options =
        tagName  : "span"
        cssClass : "icon #{icon}"
      @addSubView @icon   = new KDCustomHTMLView options

    if input
      @addSubView @input  = new NoAutocompleteInputView input

    if button
      defaults =
        callback:(event)=>
          event.preventDefault()
          event.stopPropagation()
          @input.inputAddCurrentValue()

      button = $.extend defaults, button
      @addSubView @button = new KDButtonView button

class MultipleInputListView extends KDListView
  setDomElement: ->
    # <span>Ryan <cite>x</cite></span>
    @domElement = $ "<p class='search-tags clearfix'></p>"

  addItems: (items) ->
    for item in items
      newItem = new MultipleListItemView {delegate: @}, item
      @addItemView newItem

  removeListItem: (instance) ->
    super instance
    @getDelegate().inputRemoveValue instance.getData()

class MultipleListItemView extends KDListItemView
  click: (event) ->
    if $(event.target).hasClass 'removeIcon'
      @getDelegate().removeListItem @

  setDomElement: ->
    @domElement = $ '<span />'
  partial: ->
    "#{@getData()} <cite class='removeIcon'>x</cite>"
