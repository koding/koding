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

    options.type or= 'topic'
    options.noItemFoundWidget   or= new KDCustomHTMLView
    options.listViewItemClass   or= TopicLeafItemView
    options.listViewItemOptions or= {}
    options.itemLimit            ?= 10
    
    super options, data
    
    @typeLabel = new KDCustomHTMLView
      cssClass : 'role'
      partial  : "Moderate <span class='settings-icon'></span>"
      click    : =>
        @settings.toggleClass  'hidden'
        @typeLabel.toggleClass 'active'
    
    @createSettingsView(data)
  
  createLeafItemViews: (data) ->
    options = rootId  :  data.id
          
    kd.singletons.socialapi.moderation.list options, (err, channels) =>
      console.log arguments
      if err
        console.log "no leaf channel found for #{data.id}, #{data.name}"
      @listLeafChannels channels
      if channels.length > 0
        @removeButton.show()
        @removeLabel.show()
      
      
  listLeafChannels: (channels) ->
    
    @leafChannelsListController.hideLazyLoader()
    return  unless channels?.length

    
    @skip += channels.length

    for channel in channels
      @leafChannelsListController.addItem channel

    @leafChannelsListController.hideLazyLoader()

  createSettingsView:(data) ->

    @settings  = new KDCustomHTMLView
      cssClass : 'settings hidden'

    @settings.addSubView deleteButton = new KDButtonView
      cssClass : 'solid compact outline'
      title    : 'DELETE CHANNEL'

    @settings.addSubView @removeLabel = new KDCustomHTMLView
      cssClass: 'solid compact hidden'
      partial : '<span class="label">Leaf Channels</span>'

    @createLeafChannelsListController()
    @settings.addSubView @leafChannelsListController.getView()
    @createLeafItemViews @getData()
    
    @settings.addSubView @removeButton = new KDButtonView
      cssClass : 'solid compact outline hidden'
      title    : 'REMOVE LINK'
      callback : =>
        listItems = @leafChannelsListController.getListItems()
        console.log item for item in listItems
        #listItems?.forEach (item)->
          #console.log item
        #console.log listItems
      
     
    @settings.addSubView new KDCustomHTMLView
      cssClass: 'solid compact'
      partial : '<span class="label">Similar Channels</span>'


    @settings.addSubView @searchContainer = new KDCustomHTMLView
      cssClass: 'search'
      partial : '<span class="label">Find similar channels</span>'

    @searchContainer.addSubView @searchInput = new KDHitEnterInputView
      type        : 'text'
      placeholder : @getData().name
      callback    : @bound 'searchSimilarChannels'
    
    @createSimilarChannelsListController()
    @settings.addSubView @similarChannelsListController.getView()
    @fetchSimilarChannels(@getData().name)

    @settings.addSubView linkButton = new KDButtonView
      cssClass : 'solid compact outline'
      title    : 'LINK CHANNEL'
      callback : =>
        listItems = @similarChannelsListController.getListItems()
        console.log item.switcher.getValue() for item in listItems
        
  
  searchSimilarChannels: ->

    @skip  = 0
    query = @searchInput.getValue()

    @similarChannelsListController.removeAllItems()
    @similarChannelsListController.showLazyLoader()
    @fetchSimilarChannels query


  fetchSimilarChannels:(query = "") ->

    options  =
      name   : query
      limit  : @getOptions().itemLimit
      sort   : { timestamp: -1 }
      skip   : @skip
      
    kd.singletons.socialapi.channel.searchTopics options , (err, channels) =>
      @similarChannelsListController.hideLazyLoader()
        
      if err
        return kd.warn err
      
      @listSimilarChannels channels
      


  listSimilarChannels: (channels) ->

    unless channels.length
      return @similarChannelsListController.hideLazyLoader()

    @skip += channels.length

    for channel in channels
      @similarChannelsListController.addItem channel

    @similarChannelsListController.hideLazyLoader()
    @searchContainer.show()



  createLeafChannelsListController: ->

    @leafChannelsListController       = new KDListViewController
      viewOptions         :
        wrapper           : yes
        itemClass         : TopicLeafItemView
        cssClass          : 'leaf-channel-list'
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
        cssClass          : 'similar-item-list'
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
        <p class="topicname">#{data.name}</p>
      </div>
      {{> @typeLabel}}
      <div class='clear'></div>
      {{> @settings}}
    """