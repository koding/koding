kd                   = require 'kd'
KDView               = kd.View
KDSelectBox          = kd.SelectBox
KDListItemView       = kd.ListItemView
KDCustomHTMLView     = kd.CustomHTMLView
KDListViewController = kd.ListViewController
KDHitEnterInputView  = kd.HitEnterInputView

TopicItemView = require './topicitemview'


module.exports = class TopicCommonView extends KDView

  constructor: (options = {}, data) ->

    options.noItemFoundWidget   or= new KDCustomHTMLView
    options.listViewItemClass   or= TopicItemView
    options.listViewItemOptions or= {}
    options.itemLimit            ?= 10

    super options, data

    @skip = 0

    @createSearchView()
    @createListController()
    @fetchChannels()


  createSearchView: ->
    @addSubView @searchContainer = new KDCustomHTMLView
      cssClass: 'search hidden'
      partial : '<span class="label">Sort by</span>'

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

    @listController.on 'LazyLoadThresholdReached', @bound 'fetchChannels'


  fetchChannels: ->

    return if @isFetching

    @isFetching = yes

    selector = @query or ''
    options  =
      limit  : @getOptions().itemLimit
      sort   : { timestamp: -1 }

      skip   : @skip

    @listChannels ["hebe", "hube"]
    @isFetching = no
    
    return
    
    @getData().searchChannels selector, options, (err, channels) =>
      if err
        @listController.lazyLoader.hide()
        return kd.warn err

      @listChannels channels
      @isFetching = no


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
    @fetchChannels()
