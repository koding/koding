kd                     = require 'kd'
JView                  = require 'app/jview'
KDButtonView           = kd.ButtonView
KDListItemView         = kd.ListItemView
KDCustomHTMLView       = kd.CustomHTMLView
KDCheckBox             = kd.CheckBox
KDListViewController   = kd.ListViewController
KDHitEnterInputView    = kd.HitEnterInputView

TopicLeafItemView      = require './topicleafitemview'
SelectableItemView     = require './selectableitemview'


module.exports = class TopicItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type                or= 'topic'
    options.noItemFoundWidget   or= new KDCustomHTMLView
    options.listViewItemClass   or= TopicLeafItemView
    options.listViewItemOptions or= {}
    options.itemLimit            ?= 10
    
    @leafSkip    = 0
    @similarSkip = 0
    
    super options, data
    
    @createLabels data
    @createSettingsView data
 
 
  createLabels: (data)->
    
    @moderationLabel = new KDCustomHTMLView
      cssClass : 'moderate-role'
      partial  : "Moderate <span class='settings-icon'></span>"
      click    : =>
        @settings.toggleClass  'hidden'
        @moderationLabel.toggleClass 'active'
    
    @typeLabel = new KDCustomHTMLView
      cssClass : 'type-label hidden'


  createSettingsView : (data) ->

    @settings  = new KDCustomHTMLView
      cssClass : 'settings hidden'
    
    if data.typeConstant is "topic" then @createAllTopicView data else @createDeletedTopicView data
    
    @createLeafChannelSetting data
            
    @createSimilarChannelSetting data


  createAllTopicView : (data) ->
      @settings.addSubView deleteButton = new KDCustomHTMLView
        tagName  : 'a'
        cssClass : 'delete-topic'
        click    :=>
          @setClass 'hidden'
          options = 
            rootId  : kd.singletons.groupsController.getCurrentGroup().socialApiChannelId
            leafId  : data.id
          
          kd.singletons.socialapi.moderation.blacklist options, (err, data) =>
            return kd.warn err if err
          
          # TO-DO
          # Send removed data into DELETED Topics
          
            
              
  createDeletedTopicView: (data) ->
      options = 
        rootId  : kd.singletons.groupsController.getCurrentGroup().socialApiChannelId
        leafId  : data.id
      
      kd.singletons.socialapi.moderation.fetchRoot options, (err, rootChannel) =>
       
        return kd.warn err if err 
          
        
        if rootChannel
          text = "Blacklisted"
          if kd.singletons.groupsController.getCurrentGroup().socialApiChannelId isnt rootChannel.id 
            text = "##{rootChannel.name}"
          
        @typeLabel.setPartial "#{text}"
        @typeLabel.show()
        
        @settings.addSubView whitelistButton = new KDButtonView
          cssClass : 'solid compact outline whitelist-topic'
          title    : 'WHITELIST CHANNEL'
          callback : -> 
            options = 
              rootId  : kd.singletons.groupsController.getCurrentGroup().socialApiChannelId
              leafId  : data.id

            kd.singletons.socialapi.moderation.unlink options, (err, data) ->
              return kd.warn err if err
                
         
  createLeafChannelSetting: (data) ->
    
    @settings.addSubView @removeLabel = new KDCustomHTMLView
      cssClass: 'topics-connected'
      partial : '<span class="label">CONNECTED CHANNELS</span>'

    @createLeafChannelsListController()
    @settings.addSubView @leafChannelsListController.getView()
    @createLeafItemViews @getData()

    @settings.addSubView @removeButton = new KDButtonView
      cssClass : 'solid compact hidden remove-topic'
      title    : 'REMOVE LINK'
      callback : =>
        listItems = @leafChannelsListController.getListItems()
        listItems.forEach (item)=> 
          return  if item.switcher.getValue() is false
          options = 
            rootId  : data.id
            leafId  : item.getData().id

          kd.singletons.socialapi.moderation.unlink options, (err) =>
            return kd.warn err if err
            @leafChannelsListController.removeItem item
    
  
  createSimilarChannelSetting: (data) ->
         
    @settings.addSubView new KDCustomHTMLView
      cssClass: 'topics-similar'
      partial : '<span class="label">SIMILAR CHANNELS</span>'


    @settings.addSubView @searchContainer = new KDCustomHTMLView
      cssClass: 'search'

    @searchContainer.addSubView @searchInput = new KDHitEnterInputView
      type        : 'text'
      placeholder : 'Find similar channels'
      callback    : @bound 'searchSimilarChannels'
    
    @createSimilarChannelsListController()
    @settings.addSubView @similarChannelsListController.getView()
    @fetchSimilarChannels(@getData().name)
    
    @settings.addSubView linkButton = new KDButtonView
      cssClass : 'solid compact link-topic'
      title    : 'LINK CHANNEL'
      callback : =>
        listItems = @similarChannelsListController.getListItems()
        listItems.forEach (item) => 
          return  if item.switcher.getValue() is false
          options = 
            rootId  : data.id
            leafId  : item.getData().id
     
          kd.singletons.socialapi.moderation.link options, (err) =>
            return kd.warn err if err
            @similarChannelsListController.removeItem item
            @listLeafChannels [item.getData()]


  createLeafItemViews: (data) ->
    options = rootId  :  data.id
          
    kd.singletons.socialapi.moderation.list options, (err, channels) =>
      return kd.warn err if err
      @listLeafChannels channels
      if channels.length > 0
        @removeButton.show()
        @removeLabel.show()
      
      
  listLeafChannels: (channels) ->
    
    return  unless channels?.length
    @removeLabel.show()
    
    @leafSkip += channels.length

    for channel in channels
      @leafChannelsListController.addItem channel

    @leafChannelsListController.hideLazyLoader()
    if @leafChannelsListController.getItemCount() > 0
      @removeButton.show()

            
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
      
      return kd.warn err if err
      
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

    @leafChannelsListController = new KDListViewController
      viewOptions         :
        wrapper           : yes
        itemClass         : SelectableItemView
        cssClass          : 'leaf-channel-list'
        itemOptions       : {}
      noItemFoundWidget   : new KDCustomHTMLView  {
          cssClass        : 'topics-empty'
          partial         : "Doesn't have linked channels" 
      }
      startWithLazyLoader : no
      lazyLoadThreshold   : .99
      lazyLoaderOptions   :
        spinnerOptions    :
          size            : width: 28
    
    
  createSimilarChannelsListController: ->

    @similarChannelsListController = new KDListViewController
      viewOptions         :
        wrapper           : yes
        itemClass         : SelectableItemView
        cssClass          : 'similar-item-list'
        itemOptions       : {}
      noItemFoundWidget   : new KDCustomHTMLView { 
          cssClass        : 'topics-empty'
          partial         : "Doesn't have similar channels" 
      }
      startWithLazyLoader : yes
      lazyLoadThreshold   : .99
      lazyLoaderOptions   :
        spinnerOptions    :
          size            : width: 28


  pistachio: ->
    data = @getData()
    
    return """
      <div class="details">
        <p class="topicname">\#{{#(name)}}</p>
      </div>
      {{> @typeLabel}}
      {{> @moderationLabel}}
      <div class='clear'></div>
      {{> @settings}}
    """
