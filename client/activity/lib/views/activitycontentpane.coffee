kd = require 'kd'
KDTabPaneView = kd.TabPaneView
ActivityListController = require '../activitylistcontroller'
MessagePane = require './messagepane'


module.exports = class ActivityContentPane extends KDTabPaneView

  constructor: (options, data) ->
    super options, data

    { lastToFirst, channelId, wrapper, itemClass, typeConstant } = @getOptions()

    @listController = new ActivityListController {
      type          : typeConstant
      viewOptions   :
        itemOptions : { channelId }
      scrollView    : no
      wrapper       : no
      itemClass
      lastToFirst
    }

    @isLoaded = no

  viewAppended: ->
    @addSubView @listController.getListView()

  removeItem: (item) ->
    index = @listController.getListView().getItemIndex item
    @listController.removeItem item
    return index

  setContent: (items) ->
    @listController.removeAllItems()
    items.forEach (item) => kd.utils.defer => @listController.addItem item
    @listController.hideLazyLoader()
    @isLoaded = yes
    @emit 'ContentIsShown'

  appendContent: (items) ->

    return  unless items?.length

    items.forEach (item) => kd.utils.defer => @listController.addItem item

    @listController.hideLazyLoader()

  getLoadedCount: -> @listController.getItemCount()

  removeMessage: MessagePane::removeMessage

  addItem: (item, index) -> @listController.addItem item, index




