class YourTopicsModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title    or= 'Browse Your Topics'
    options.cssClass or= 'topics your activity-modal'
    options.content  or= ''
    options.overlay   ?= yes
    options.width     ?= 330
    options.height   or= 'auto'

    super options, data

    {appManager, router} = KD.singletons
    appManager.tell 'Activity', 'bindModalDestroy', this, router.visitedRoutes.last

    @beingFetched = no
    @searchActive = no


  viewAppended: ->

    @addSubView @searchField = new KDInputView
      placeholder : 'Search all topics...'
      keyup       : KD.utils.debounce 300, @bound 'search'

    @listController = new KDListViewController
      startWithLazyLoader : yes
      noItemFoundWidget   : new KDCustomHTMLView
        cssClass          : 'nothing hidden'
        partial           : 'You don\'t follow any topics yet. You can search for some topics above e.g HTML, CSS, golang.'
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
        itemClass         : SidebarTopicItem
        cssClass          : 'activities'

    @addSubView @listController.getView()

    @listController.customScrollView.wrapper.on 'LazyLoadThresholdReached', @bound 'handleLazyLoad'

    @fetch {}, @bound 'populate'


  fetch: (options = {}, callback) ->

    @beingFetched = yes
    options.limit ?= 25

    return @fetchForSearch options, callback  if @searchActive

    {channel} = KD.singletons.socialapi

    channel.fetchFollowedChannels options, (err, items = []) =>

      @listController.hideLazyLoader()
      @beingFetched = no

      return  if err

      callback items


  fetchForSearch: (options = {}, callback) ->

    {channel} = KD.singletons.socialapi

    options.name ?= @searchField.getValue()
    @lastTerm     = options.name

    channel.searchTopics options, (err, items) =>

      @listController.hideLazyLoader()
      @beingFetched = no

      return  if err

      callback items


  populate: (items) ->

    @listController.addItem itemData for itemData in items


  handleLazyLoad: ->

    return  if @beingFetched

    @fetch skip : @listController.getItemCount(), @bound 'populate'


  cancelsearch: ->

    @searchActive = no

    @unsetClass 'search-active'
    @listController.removeAllItems()
    @listController.showLazyLoader()
    @fetch {}, @bound 'populate'


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


