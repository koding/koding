class SidebarSearchModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title       or= 'Browse'
    options.cssClass    or= 'your activity-modal'
    options.content     or= ''
    options.overlay      ?= yes
    options.width        ?= 522
    options.height      or= 'auto'
    options.placeholder or= 'Search...'
    options.noItemText  or= ''
    options.itemClass   or= SidebarTopicItem


    options.endpoints ?=
      fetch            : (options, callback) -> callback()
      search           : (options, callback) -> callback()

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
          size            :
            width         : 16
            height        : 16
        partial           : ''
      useCustomScrollView : yes
      viewOptions         :
        type              : 'activities'
        itemClass         : itemClass
        cssClass          : 'activities topics-list'

    @addSubView @listController.getView()

    @listController.customScrollView.wrapper.on 'LazyLoadThresholdReached', @bound 'handleLazyLoad'

    @fetch {}, @bound 'populate'

    @addSubView new KDCustomHTMLView
      cssClass   : 'tag-description'
      partial    : "
        You can also create a new topic by making it a part of <br>
        a new post. <em>eg: I love #koding</em>
      "


  populate: (items) ->

    return unless items?.length?

    @listController.addItem itemData for itemData in items


  handleLazyLoad: ->

    return  if @beingFetched

    @fetch skip : @listController.getItemCount(), @bound 'populate'


  search: ->

    val = @searchField.getValue()
    val = val.slice(1)  if val[0] is '#'

    if val is '' and @searchActive             then return @cancelsearch()
    else if val is '' and not @searchActive    then return
    else if val is @lastTerm and @searchActive then return

    @setClass 'search-active'
    @searchActive = yes
    @searchField.setFocus()
    @listController.removeAllItems()
    @listController.showLazyLoader()

    @fetchForSearch name : val, @bound 'populate'


  cancelsearch: ->

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

