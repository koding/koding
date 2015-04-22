kd = require 'kd'
KDView = kd.View
InvitationRequestListController = require '../controllers/invitationrequestlistcontroller'


module.exports = class GroupsInvitationTabPaneView extends KDView

  requestLimit: 10

  constructor:(options={}, data)->
    options.showResolved  ?= no

    super options, data

    @controller = new InvitationRequestListController
      delegate            : this
      itemClass           : options.itemClass
      noItemFound         : options.noItemFound
      lazyLoadThreshold   : 0.90
      startWithLazyLoader : yes
      lazyLoaderOptions   :
        spinnerOptions    :
          loaderOptions   :
            shape         : 'spiral'
            color         : '#a4a4a4'
          size            :
            width         : 40
            height        : 40

    @addSubView @listView = @controller.getView()

    @listView.on   'InvitationStatusChanged', =>
      @getDelegate().tabHandle?.markDirty()

  addListeners:->
    @on 'teasersLoaded', =>
      @fetchAndPopulate()  unless @controller.scrollView.hasScrollBars()

    @controller.on 'LazyLoadThresholdReached', =>
      return @controller.hideLazyLoader()  if @controller.noItemLeft
      @fetchAndPopulate()

    @on 'SearchInputChanged', (@searchValue)=> @refresh()

    groupController = kd.getSingleton("groupsController")
    groupController.on "MemberJoinedGroup", (data) =>
      @refresh()

  viewAppended:->
    super()
    @addListeners()
    @fetchAndPopulate()

  refresh:->
    @controller.removeAllItems()
    @timestamp = null
    @fetchAndPopulate()

  setShowResolved:(showResolved)-> @options.showResolved = showResolved


  fetchAndPopulate:->
    @controller.showLazyLoader no

    options = { @timestamp, @requestLimit, search: @searchValue }
    options.showResolved = @getOptions().showResolved
    options.type = @getOptions().type

    @getData().fetchInvitationsByStatus options, (err, results)=>
      @controller.hideLazyLoader()
      results = results.filter (res)-> res isnt null
      if err or results.length is 0
        kd.warn err  if err
        return @controller.emit 'noItemsFound'

      @timestamp = results.last[@options.timestampField]
      @controller.instantiateListItems results
      @emit 'teasersLoaded'  if results.length is @requestLimit

