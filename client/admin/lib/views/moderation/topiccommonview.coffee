kd                   = require 'kd'
KDView               = kd.View
KDSelectBox          = kd.SelectBox
KDListItemView       = kd.ListItemView
KDCustomHTMLView     = kd.CustomHTMLView
KDListViewController = kd.ListViewController
KDHitEnterInputView  = kd.HitEnterInputView

TopicItemView        = require './topicitemview'
TopicLeafItemView    = require './topicleafitemview'


module.exports = class TopicCommonView extends KDView

  constructor: (options = {}, data) ->

    options.noItemFoundWidget   or= new KDCustomHTMLView
    options.listViewItemClass   or= TopicItemView
    options.listViewItemOptions or= {}
    options.itemLimit            ?= 10

    super options, data

    @skip        = 0
    @searchSkip  = 0

    @createSearchView()
    @createListController()
    @fetchChannels()


  createSearchView: ->
    @addSubView @searchContainer = new KDCustomHTMLView
      cssClass : 'search'

    @searchContainer.addSubView @searchInput = new KDHitEnterInputView
      type        : 'text'
      placeholder : 'Search Channels'
      callback    : @bound 'search'


  createListController: ->

    { listViewItemClass, noItemFoundWidget, listViewItemOptions } = @getOptions()

    @listController       = new KDListViewController
      viewOptions         :
        wrapper           : yes
        itemClass         : listViewItemClass
        itemOptions       : listViewItemOptions
      noItemFoundWidget   : noItemFoundWidget
      useCustomScrollView : yes
      startWithLazyLoader : yes
      lazyLoadThreshold   : .99
      lazyLoaderOptions   :
        spinnerOptions    :
          size            : width: 28

    @addSubView @listController.getView()


    @listController.on 'LazyLoadThresholdReached', =>
      
      if @skip is 0 and @searchSkip is 0
        @fetchChannels()
      else if @skip is 0 
        @search()
      else 
        @fetchChannels()
  

  fetchChannels: ->
    
    return if @isFetching
    @isFetching = yes
    
    options  =
      limit                 : @getOptions().itemLimit
      skip                  : @skip
      showModerationNeeded  : true
      type                  : @getOptions().typeConstant or= "topic"
    
    kd.singletons.socialapi.channel.list options, @bound 'listFetchResults'
    

  searchChannels: (query = "") ->
    
    return if @isFetching
    @isFetching = yes

    options  =
      name                  : query
      limit                 : @getOptions().itemLimit
      skip                  : @searchSkip
      showModerationNeeded  : true
      type                  : @getOptions().typeConstant or= "topic"

    kd.singletons.socialapi.channel.searchTopics options, @bound 'listSearchResults'
      

  listSearchResults:  (err, channels) ->
    # if we have items from listing. remove them all
    if @searchSkip is 0
      @listController.removeAllItems()
    
    @skip = 0  # revert skip of normal listing
    
    @searchSkip += channels.length
    @listChannels err, channels


  listFetchResults :  (err, channels) ->
    
    # if we have items from searching remove them all
    if @skip is 0
      @listController.removeAllItems()
    
    @searchSkip = 0
    
    @skip += channels.length
    
    @listChannels err, channels


  listChannels:  (err, channels) ->
    @isFetching = no
    
    if err
      @listController.lazyLoader?.hide()
      return kd.warn err
    
    unless channels.length
      return @listController.lazyLoader?.hide()

    for channel in channels
      @listController.addItem channel

    @listController.lazyLoader?.hide()
    @searchContainer.show()


  search: ->
  
    query = @searchInput.getValue()
    
    unless @isSameSearch(query)
      @resetListItems()
      @searchSkip = 0
    
    @lastQuery = query

    if query is ''
      return @fetchChannels()

    @searchChannels query


  resetListItems: (showLoader = yes) ->

    @listController.removeAllItems()
    @listController.lazyLoader.show()
    
    
  isSameSearch : (query = "") ->
    @lastQuery or= ''
    
    return query is @lastQuery
