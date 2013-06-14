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

    mainView.on 'focus', @bound "updateDropdownContents"

    @lastPrefix          = null
    @selectedItemData    = []
    @hiddenInputs        = {}
    @selectedItemCounter = 0
    @readyToShowDropDown = yes

  reset:->
    subViews    = @itemWrapper.getSubViews().slice()
    for item in subViews
      @removeFromSubmitQueue item

  loadView:(mainView)->
    @createDropDown()
    @getAutoCompletedItemParent()
    @setDefaultValue()

    mainView.on 'keyup', @utils.throttle(@bound "keyUpOnInputView"), 300
    mainView.on 'keydown', (event)=> @keyDownOnInputView event

  setDefaultValue:(defaultItems)->
    {defaultValue, itemDataPath} = @getOptions()
    defaultItems or= defaultValue
    for item in defaultItems
      @addItemToSubmitQueue @getView(), item

  keyDownOnInputView:(event)->

    autoCompleteView = @getView()
    switch event.which
      when 13, 9 #enter, tab
        if autoCompleteView.getValue() isnt "" and event.shiftKey isnt yes
          @submitAutoComplete autoCompleteView.getValue()
          event.stopPropagation()
          event.preventDefault()
          @readyToShowDropDown = no
          return no
        else
          return yes
      when 27 #escape
        @hideDropdown()
      # when 38, 40 #up, down
      #   @dropdown.keyDownPerformed @dropdown.getListView(), event
      when 38 #uparrow
        if @dropdown.getView().$().is(":visible")
          @dropdown.getListView().goUp()
          event.stopPropagation()
          event.preventDefault()
          return no
        else
      when 40 #downarrow
        if @dropdown.getView().$().is(":visible")
          @dropdown.getListView().goDown()
          event.stopPropagation()
          event.preventDefault()
          return no
        # @getView().$input().blur()
      else
        @readyToShowDropDown = yes
    no

  getPrefix:->
    separator = @getOptions().separator
    items = @getView().getValue().split separator
    prefix = items[items.length-1]
    prefix

  createDropDown:(data = [])->
    # log "#{data.length} items in auto complete"
    @dropdownPrefix = ""
    @dropdownListView = dropdownListView = new KDAutoCompleteListView {
      itemClass  : @getOptions().itemClass
    },{
      items : data
    }
    dropdownListView.on 'ItemsDeselected', =>
      view = @getView()
      view.$input().trigger('focus')

    dropdownListView.on 'KDAutoCompleteSubmit', @bound "submitAutoComplete"

    windowController = KD.getSingleton('windowController')

    @dropdown = new KDListViewController
      view : dropdownListView

    dropdownWrapper = @dropdown.getView()

    dropdownWrapper.on 'ReceivedClickElsewhere', =>
      @hideDropdown()

    dropdownWrapper.setClass "kdautocomplete hidden #{@getOptions().listWrapperCssClass}"
    KDView.appendToDOMBody dropdownWrapper

  hideDropdown:->
    dropdownWrapper = @dropdown.getView()
    dropdownWrapper.$().fadeOut 75

  showDropdown:->

    return unless @readyToShowDropDown

    windowController = KD.getSingleton('windowController')
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

  submitAutoComplete:(item, data)->
    inputView = @getView()
    # log @getOptions().selectedItemsLimit, @selectedItemCounter
    if @getOptions().selectedItemsLimit is null or @getOptions().selectedItemsLimit > @selectedItemCounter
      activeItem = @dropdown.getListView().getActiveItem()
      if activeItem.item
        @appendAutoCompletedItem()
      @addItemToSubmitQueue activeItem.item
      @rearrangeInputWidth()
      @emit 'ItemListChanged', @selectedItemCounter
    else
      inputView.setValue ''
      KD.getSingleton("windowController").setKeyView null
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
    delete @hiddenInputs[name]

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

    data or= item?.getData()
    return unless data or item?.getOptions().userInput

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
      @addHiddenInputItem path, itemValue

    @addSelectedItemData data
    @addSelectedItem itemName, data
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
      @removeHiddenInputItem path
    @removeSelectedItemData data
    @selectedItemCounter--
    item.destroy()
    @emit 'ItemListChanged', @selectedItemCounter

  rearrangeInputWidth:->
    # mainView = @getView()
    # mainView.$input().width mainView.$input().parent().width() - mainView.$input().prev().width()

  appendAutoCompletedItem:->
    @getView().setValue ""
    @getView().$input().trigger "focus"

  updateDropdownContents:->
    inputView = @getView()
    if inputView.getValue() is ""
      @hideDropdown()

    if inputView.getValue() isnt "" and
       @dropdownPrefix isnt inputView.getValue() and
       @dropdown.getView().$().not(":visible")

      @dropdownPrefix = inputView.getValue()
      @fetch (data)=>
        @refreshDropDown data
        @showDropdown()

  keyUpOnInputView:(event)->
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
