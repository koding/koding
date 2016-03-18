kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDInputView = kd.InputView
KDListViewController = kd.ListViewController
KDModalView = kd.ModalView
SidebarTopicItem = require './sidebartopicitem'


module.exports = class SidebarSearchModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title           or= 'Browse'
    options.content         or= ''
    options.overlay          ?= yes
    options.width            ?= 522
    options.height          or= 'auto'
    options.placeholder     or= 'Search...'
    options.noItemText      or= ''
    options.emptySearchText or= options.noItemText
    options.itemClass       or= SidebarTopicItem
    options.endpoints        ?=
      fetch                   : dummyCallback
      search                  : dummyCallback

    options.bindModalDestroy ?= yes

    super options, data

    { appManager, router } = kd.singletons

    { bindModalDestroy } = @getOptions()

    if bindModalDestroy
      appManager.tell 'Activity', 'bindModalDestroy', this, router.visitedRoutes.last

    @beingFetched = no
    @searchActive = no


  viewAppended: ->

    { placeholder, noItemText, itemClass, disableSearch } = @getOptions()

    unless disableSearch
      @addSubView @searchField = new KDInputView
        placeholder : placeholder
        cssClass    : 'search-input'
        keyup       : kd.utils.debounce 300, @bound 'search'

      @addSubView new KDCustomHTMLView
        tagName  : 'cite'
        cssClass : 'search-icon'

    @listController = new KDListViewController
      startWithLazyLoader : yes
      noItemFoundWidget   : new KDCustomHTMLView
        cssClass          : 'nothing hidden'
        partial           : noItemText
      lazyLoadThreshold   : 100
      lazyLoaderOptions   :
        spinnerOptions    :
          loaderOptions   :
            shape         : 'spiral'
            color         : '#a4a4a4'
          size            :
            width         : 40
            height        : 40
        partial           : ''
      useCustomScrollView : yes
      viewOptions         :
        type              : 'activities'
        itemClass         : itemClass
        cssClass          : 'activities topics-list'

    @addSubView @listController.getView()

    debouncedLazyLoad = kd.utils.debounce 300, @bound 'handleLazyLoad'

    @listController.on 'LazyLoadThresholdReached', debouncedLazyLoad
    @listController.on 'ListIsEmptied', @bound 'handleEmpyList'

    @fetch {}, @bound 'populate'


  populate: (items, options = {}) ->

    return  unless items?.length?

    @listController.removeAllItems()  unless options.skip
    @listController.addItem itemData for itemData in items


  handleLazyLoad: ->

    return  if @beingFetched
    return @listController.hideLazyLoader()  if @reachedEndOfTheList

    options = @getLazyLoadOptions()

    if @searchActive
    then fn = @bound 'fetchForSearch'
    else fn = @bound 'fetch'

    fn options, @bound 'populate'


  getLazyLoadOptions: ->

    skip  = @listController.getItemCount()

    return { skip }


  search: ->

    val = @searchField.getValue()
    val = val.slice(1)  if val[0] is '#'

    if val is '' and @searchActive             then return @reset()
    else if val is '' and not @searchActive    then return
    else if val is @lastTerm and @searchActive then return

    options      = @getSearchOptions val
    options.name = val
    @reachedEndOfTheList = no  unless options.limit

    @setClass 'search-active'
    @searchActive = yes
    @searchField.setFocus()
    @listController.removeAllItems()
    @listController.showLazyLoader no

    @fetchForSearch options, @bound 'populate'


  getSearchOptions: (val) ->

    limit = if @searchActive and (val.indexOf @lastTerm) > -1
    then @listController.getItemCount()
    else 0

    return {  limit  }


  reset: ->

    @reachedEndOfTheList = no
    @searchActive = no
    @lastTerm = ''

    @unsetClass 'search-active'
    @listController.removeAllItems()
    @listController.showLazyLoader()
    @fetch {}, @bound 'populate'


  fetchForSearch: (options = {}, callback) ->

    options.name ?= @searchField.getValue()
    @lastTerm     = options.name

    { search } = @getOptions().endpoints

    return callback() unless search

    search options, (err, items) =>

      @listController.hideLazyLoader()
      @beingFetched = no

      return  if err

      @reachedEndOfTheList = yes  unless items.length

      callback items, options


  fetch: (options = {}, callback) ->

    @beingFetched = yes
    options.limit ?= 25

    return @fetchForSearch options, callback  if @searchActive

    { fetch } = @getOptions().endpoints

    fetch options, (err, items = []) =>

      @listController.hideLazyLoader()
      @beingFetched = no

      return  if err

      callback items, options
      @reachedEndOfTheList = yes  unless items.length


  dummyCallback = (options, callback) ->

    callback()


  handleEmpyList: ->

    { noItemText, emptySearchText } = @getOptions()
    resultText = if @searchActive then emptySearchText else noItemText
    @listController.noItemView.updatePartial resultText
