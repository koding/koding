kd                     = require 'kd'
JView                  = require 'app/jview'
KDButtonView           = kd.ButtonView
KDListItemView         = kd.ListItemView
KDCustomHTMLView       = kd.CustomHTMLView
KDCheckBox             = kd.CheckBox
KDListViewController = kd.ListViewController
KDHitEnterInputView  = kd.HitEnterInputView

TopicLeafItemView    = require './topicleafitemview'
SimilarItemView      = require './similaritemview'

module.exports = class TopicItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type or= 'member'
    options.noItemFoundWidget   or= new KDCustomHTMLView
    options.listViewItemClass   or= TopicLeafItemView
    options.listViewItemOptions or= {}
    options.itemLimit            ?= 10
    
    super options, data
    
    @typeLabel = new KDCustomHTMLView
      cssClass : 'role'
      partial  : "Type <span class='settings-icon'></span>"
      click    : =>
        @settings.toggleClass  'hidden'
        @typeLabel.toggleClass 'active'
    
    @createSettingsView()
    @createLeafChannelsListController()
    @createLeafItemViews (data)

  createLeafItemViews: (data) ->
    options = rootId  :  data.id
          
    kd.singletons.socialapi.moderation.list options, (err, channels) =>
      console.log arguments
      if err
        console.log "no leaf channel found for #{data.id}, #{data.name}"
        return
      @listLeafChannels channels
      
  listLeafChannels: (channels) ->

    unless channels.length
      return @leafChannelsListController.lazyLoader?.hide()

    @skip += channels.length

    for channel in channels
      @leafChannelsListController.addItem channel

    @leafChannelsListController.lazyLoader?.hide()

  createSettingsView: ->

    @settings  = new KDCustomHTMLView
      cssClass : 'settings hidden'

    @settings.addSubView linkButton = new KDButtonView
      cssClass : 'solid compact outline'
      title    : 'LINK CHANNEL'

    @settings.addSubView removeButton = new KDButtonView
      cssClass : 'solid compact outline'
      title    : 'REMOVE LINK'

    @settings.addSubView deleteButton = new KDButtonView
      cssClass : 'solid compact outline'
      title    : 'DELETE CHANNEL'
      
    @settings.addSubView @searchContainer = new KDCustomHTMLView
      cssClass: 'search'
      partial : '<span class="label">Find similar channels</span>'

    @searchContainer.addSubView @searchInput = new KDHitEnterInputView
      type        : 'text'
      placeholder : @getData().name
      callback    : @bound 'searchSimilarChannels'

    @createSimilarChannelsListController()
    @settings.addSubView @similarChannelsListController.getView()

  searchSimilarChannels: ->

    @skip  = 0
    query = @searchInput.getValue()

    @similarChannelsListController.removeAllItems()
    @similarChannelsListController.lazyLoader.show()
    @fetchSimilarChannels query


  fetchSimilarChannels:(query = "") ->

    options  =
      name   : query
      limit  : @getOptions().itemLimit
      sort   : { timestamp: -1 }
      skip   : @skip
      
    kd.singletons.socialapi.channel.searchTopics options , (err, channels) =>
      if err
        @similarChannelsListController.lazyLoader?.hide()
        return kd.warn err
      
      @listSimilarChannels channels
      


  listSimilarChannels: (channels) ->

    unless channels.length
      return @similarChannelsListController.lazyLoader?.hide()

    @skip += channels.length

    for channel in channels
      @similarChannelsListController.addItem channel

    @similarChannelsListController.lazyLoader?.hide()
    @searchContainer.show()



  createLeafChannelsListController: ->

    @leafChannelsListController       = new KDListViewController
      viewOptions         :
        wrapper           : yes
        itemClass         : TopicLeafItemView
        itemOptions       : {}
      noItemFoundWidget   : new KDCustomHTMLView
      startWithLazyLoader : yes
      lazyLoadThreshold   : .99
      lazyLoaderOptions   :
        spinnerOptions    :
          size            : width: 28

    #@listController.on 'LazyLoadThresholdReached', @bound 'fetchChannels'
    
    
  createSimilarChannelsListController: ->

    @similarChannelsListController       = new KDListViewController
      viewOptions         :
        wrapper           : yes
        itemClass         : SimilarItemView
        itemOptions       : {}
      noItemFoundWidget   : new KDCustomHTMLView
      startWithLazyLoader : yes
      lazyLoadThreshold   : .99
      lazyLoaderOptions   :
        spinnerOptions    :
          size            : width: 28

    #@listController.on 'LazyLoadThresholdReached', @bound 'fetchChannels'

  pistachio: ->
    data     = @getData()
    type     = 'Type'
    
    return """
      <div class="details">
        <p class="nickname">#{data.name}</p>
      </div>
      {{> @typeLabel}}
      <div class='clear'></div>
      {{> @settings}}
      {{> @leafChannelsListController.getView()}}
    """