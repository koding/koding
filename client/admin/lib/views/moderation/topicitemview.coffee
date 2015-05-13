kd                     = require 'kd'
JView                  = require 'app/jview'
KDButtonView           = kd.ButtonView
KDListItemView         = kd.ListItemView
KDCustomHTMLView       = kd.CustomHTMLView
KDCheckBox             = kd.CheckBox
KDListViewController = kd.ListViewController
KDHitEnterInputView  = kd.HitEnterInputView

TopicLeafItemView    = require './topicleafitemview'
SelectableItemView      = require './selectableitemview'

module.exports = class TopicItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type or= 'topic'
    options.noItemFoundWidget   or= new KDCustomHTMLView
    options.listViewItemClass   or= TopicLeafItemView
    options.listViewItemOptions or= {}
    options.itemLimit            ?= 10
    
    @leafSkip = 0
    @similarSkip = 0
    
    super options, data
    
    @moderationLabel = new KDCustomHTMLView
      cssClass : 'moderateRole'
      partial  : "Moderate <span class='settings-icon'></span>"
      click    : =>
        @settings.toggleClass  'hidden'
        @moderationLabel.toggleClass 'active'
    
    @typeLabel = new KDCustomHTMLView
      cssClass : 'type-label'
      
    @createSettingsView(data)
  
  createLeafItemViews: (data) ->
    options = rootId  :  data.id
          
    kd.singletons.socialapi.moderation.list options, (err, channels) =>
      if err
        console.log "no leaf channel found for #{data.id}, #{data.name}"
      @listLeafChannels channels
      if channels.length > 0
        @removeButton.show()
        @removeLabel.show()
      
      
  listLeafChannels: (channels) ->
    
    @leafChannelsListController.hideLazyLoader()
    return  unless channels?.length

    
    @leafSkip += channels.length

    for channel in channels
      @leafChannelsListController.addItem channel

    @leafChannelsListController.hideLazyLoader()

  createSettingsView:(data) ->

    @settings  = new KDCustomHTMLView
      cssClass : 'settings hidden'
    
    if data.typeConstant is "topic"
      @settings.addSubView deleteButton = new KDButtonView
        cssClass : 'solid compact outline'
        title    : 'DELETE CHANNEL'
        callback :=>
          options = 
            rootId  : kd.singletons.groupsController.getCurrentGroup().socialApiChannelId
            leafId  : data.id
          
          kd.singletons.socialapi.moderation.blacklist options, (err, data) =>
            if err
              console.log "no leaf channel found for #{data.id}, #{data.name}"
    else
      options = 
        rootId  : kd.singletons.groupsController.getCurrentGroup().socialApiChannelId
        leafId  : data.id
      
      kd.singletons.socialapi.moderation.fetchRoot options, (err, rootChannel) =>
        if err 
          return console.log "err while fething root", err
        
        if rootChannel
          text = "Blacklisted"
          if kd.singletons.groupsController.getCurrentGroup().socialApiChannelId isnt rootChannel.id 
            text = "linked to #{rootChannel.name}"
          
        @typeLabel.setPartial "#{text}"
        
        @settings.addSubView whitelistButton = new KDButtonView
          cssClass : 'solid compact outline'
          title    : 'WHITELIST CHANNEL'
          callback : => 
            options = 
              rootId  : kd.singletons.groupsController.getCurrentGroup().socialApiChannelId
              leafId  : data.id

            kd.singletons.socialapi.moderation.unlink options, (err, data) =>
            
              if err
                console.log "no leaf channel found for #{options.rootId}, #{data}"
            
        
          

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
        listItems.forEach (item)=> 
          return  if item.switcher.getValue() is false
          options = 
            rootId  :  data.id
            leafId  : item.getData().id

          kd.singletons.socialapi.moderation.unlink options, (err, @item) =>
          
            if err
              return console.log "no leaf channel found for #{data.id}, #{data.name}"
            item.hide()
     
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
        listItems.forEach (item)=> 
          return  if item.switcher.getValue() is false
          options = 
            rootId  : data.id
            leafId  : item.getData().id
     
          kd.singletons.socialapi.moderation.link options, (err, @item) =>
          
            if err
              console.log "no leaf channel found for #{data.id}, #{data.name}"
            item.hide()
        
  
  searchSimilarChannels: ->

    @similarSkip  = 0
    query = @searchInput.getValue()

    @similarChannelsListController.removeAllItems()
    @similarChannelsListController.showLazyLoader()
    @fetchSimilarChannels query


  fetchSimilarChannels:(query = "") ->

    options  =
      name   : query
      limit  : @getOptions().itemLimit
      sort   : { timestamp: -1 }
      skip   : @similarSkip
      
    kd.singletons.socialapi.channel.searchTopics options , (err, channels) =>
      @similarChannelsListController.hideLazyLoader()
        
      if err
        return kd.warn err
      
      @listSimilarChannels channels
      


  listSimilarChannels: (channels) ->

    unless channels.length
      return @similarChannelsListController.hideLazyLoader()

    @similarSkip += channels.length
    

    for channel in channels
      if @getData().getId() is channel.getId()
        @similarSkip--
        continue
      @similarChannelsListController.addItem channel

    @similarChannelsListController.hideLazyLoader()
    @searchContainer.show()



  createLeafChannelsListController: ->

    @leafChannelsListController       = new KDListViewController
      viewOptions         :
        wrapper           : yes
        itemClass         : SelectableItemView
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
        itemClass         : SelectableItemView
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
    data          = @getData()
    moderateRole  = 'Topic'
    
    return """
      <div class="details">
        <p class="topicname">#{data.name}</p>
      </div>
      {{> @typeLabel}}
      {{> @moderationLabel}}
      <div class='clear'></div>
      {{> @settings}}
    """