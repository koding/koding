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
      partial  : '<span class="label">Search</span>'

    @searchContainer.addSubView @searchInput = new KDHitEnterInputView
      type        : 'text'
      placeholder : 'Find by channel name'
      callback    : @bound 'search'


  createListController: ->

    { listViewItemClass, noItemFoundWidget, listViewItemOptions } = @getOptions()

    @listController       = new KDListViewController
      viewOptions         :
        wrapper           : yes
        itemClass         : listViewItemClass
        itemOptions       : listViewItemOptions
      noItemFoundWidget   : noItemFoundWidget
      startWithLazyLoader : yes
      lazyLoadThreshold   : .99
      lazyLoaderOptions   :
        spinnerOptions    :
          size            : width: 28

    @addSubView @listController.getView()

    @listController.on 'LazyLoadThresholdReached', @bound 'searchChannels'


  fetchChannels: ->
    
    return if @isFetching
    @isFetching = yes

    options  =
      limit                 : @getOptions().itemLimit
      skip                  : @skip
      showModerationNeeded  : true
      type                  : @getOptions().typeConstant or= "topic"
      
    kd.singletons.socialapi.channel.list options , (err, channels) =>
      @isFetching = no
      if err
        @listController.lazyLoader?.hide()
        return kd.warn err
    
      @listChannels channels
      

  searchChannels:(query = "") ->
    
    return if @isFetching
    @isFetching = yes

    options  =
      name                  : query
      limit                 : @getOptions().itemLimit
      skip                  : @searchSkip
      showModerationNeeded  : true
      type                  : @getOptions().typeConstant or= "topic"

    kd.singletons.socialapi.channel.searchTopics options , (err, channels) =>
      @isFetching = no
      
      if err
        @listController.lazyLoader?.hide()
        return kd.warn err
      
      @listChannels channels
      

  listChannels: (channels) ->

    unless channels.length
      return @listController.lazyLoader?.hide()

    @skip += channels.length

    for channel in channels
      @listController.addItem channel

    @listController.lazyLoader?.hide()
    @searchContainer.show()


  search: ->

    @skip  = 0
    @query = @searchInput.getValue()

    @listController.removeAllItems()
    @listController.lazyLoader.show()
    @searchChannels @query
