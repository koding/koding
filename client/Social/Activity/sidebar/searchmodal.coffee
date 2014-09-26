class SidebarSearchModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title       or= 'Browse'
    options.content     or= ''
    options.overlay      ?= yes
    options.width        ?= 522
    options.height      or= 'auto'
    options.placeholder or= 'Search...'
    options.noItemText  or= ''
    options.itemClass   or= SidebarTopicItem
    options.endpoints    ?=
      fetch               : dummyCallback
      search              : dummyCallback

    super options, data

    {appManager, router} = KD.singletons
    appManager.tell 'Activity', 'bindModalDestroy', this, router.visitedRoutes.last

    @beingFetched = no
    @searchActive = no


  viewAppended: ->

    {placeholder, noItemText, itemClass} = @getOptions()
    @addSubView @searchField = new KDInputView
      placeholder : placeholder
      cssClass    : 'search-input'
      keyup       : KD.utils.debounce 300, @bound 'search'


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

    @listController.on 'LazyLoadThresholdReached', @bound 'handleLazyLoad'

    @fetch {}, @bound 'populate'


  populate: (items) ->

    return unless items?.length?

    @listController.addItem itemData for itemData in items


  handleLazyLoad: ->

    return  if @beingFetched
    return @listController.hideLazyLoader()  if @reachedEndOfTheList

    options = @getLazyLoadOptions()
    @fetch options, @bound 'populate'


  getLazyLoadOptions: ->

    return skip: @listController.getItemCount()


  search: ->

    val = @searchField.getValue()
    val = val.slice(1)  if val[0] is '#'

    if val is '' and @searchActive             then return @reset()
    else if val is '' and not @searchActive    then return
    else if val is @lastTerm and @searchActive then return

    @setClass 'search-active'
    @searchActive = yes
    @searchField.setFocus()
    @listController.removeAllItems()
    @listController.showLazyLoader()

    @fetchForSearch name : val, @bound 'populate'


  reset: ->

    @searchActive = no

    @unsetClass 'search-active'
    @listController.removeAllItems()
    @listController.showLazyLoader()
    @fetch {}, @bound 'populate'


  fetchForSearch: (options = {}, callback) ->

    options.name ?= @searchField.getValue()
    @lastTerm     = options.name

    {search} = @getOptions().endpoints

    return callback() unless search

    search options, (err, items) =>

      @listController.hideLazyLoader()
      @beingFetched = no

      return  if err

      @reachedEndOfTheList = yes  unless items.length

      callback items


  fetch: (options = {}, callback) ->

    @beingFetched = yes
    options.limit ?= 25

    return @fetchForSearch options, callback  if @searchActive

    {fetch} = @getOptions().endpoints

    fetch options, (err, items = []) =>

      @listController.hideLazyLoader()
      @beingFetched = no

      return  if err

      callback items
      @reachedEndOfTheList = yes  unless items.length


  dummyCallback = (options, callback) ->

    callback()
