class ActivityTicker extends ActivitySideView

  constructor:(options={}, data)->

    options.cssClass = KD.utils.curry "activity-ticker", options.cssClass

    super options, data

    @filters = null

    @listController = new KDListViewController
      lazyLoadThreshold : .99
      lazyLoaderOptions : partial : ''
      viewOptions       :
        type            : "activities"
        cssClass        : "activities"
        itemClass       : ActivityTickerItem

    @showAllLink = new KDCustomHTMLView

    @listView = @listController.getView()

    @listController.on "LazyLoadThresholdReached", @bound "continueLoading"

    # @settingsButton = new KDButtonViewWithMenu
    #   cssClass    : 'ticker-settings-menu'
    #   title       : ''
    #   icon        : yes
    #   iconClass   : "arrow"
    #   delegate    : @
    #   menu        : @settingsMenu data
    #   callback    : (event)=> @settingsButton.contextMenu event

    @indexedItems = {}

    group = KD.getSingleton("groupsController")
    group.on "MemberJoinedGroup"    , @bound "addJoin"
    group.on "LikeIsAdded"          , @bound "addLike"
    group.on "FollowHappened"       , @bound "addFollow"
    group.on "PostIsCreated"        , @bound "addActivity"
    # disable for now               , since we dont have comment view
    # and comments doesnt have slug
    # group.on "ReplyIsAdded"       , @bound "addComment"
    group.on "PostIsDeleted"        , @bound "deleteActivity"
    group.on "LikeIsRemoved"        , @bound "removeLike"

    @listController.listView.on 'ItemWasAdded', (view, index) =>
      if viewData = view.getData()
        itemId = @getItemId viewData
        @indexedItems[itemId] = view

    @load {}

    @once 'viewAppended', =>
      @$('.kdscrollview').height window.innerHeight - 120

  settingsMenu:(data)->
    filterSelected = (filters=[]) =>
      @listController.removeAllItems()
      @indexedItems = {}
      tryCount = 0
      @load {filters, tryCount}

    menu =
      'All'      :
        callback :->
          do filterSelected
      'Follower' :
        callback : ->
          filterSelected ["follower"]
      'Like'     :
        callback : ->
          filterSelected ["like"]
      # Example menu item for multiple filters.
      # 'Follower+Like'   :
      #   callback : =>
      #     @load filters : ["follower", "like"]
      'Member'   :
        callback : ->
          filterSelected ["member"]
    return menu

  getConstructorName :(obj)->
    if obj and obj.bongo_ and obj.bongo_.constructorName
      return obj.bongo_.constructorName
    return null

  fetchTags:(data, callback)->
    return callback null, null unless data

    if data.tags
      return callback null, data.tags
    else
      data.fetchTags callback

  addActivity: (data)->
    {origin, subject} = data

    return if @isFiltered "activity"

    unless @getConstructorName(origin) and @getConstructorName(subject)
      return console.warn "data is not valid"

    source = KD.remote.revive subject
    target = KD.remote.revive origin
    as     = "author"

    return if target.isExempt or @checkGuestUser origin

    @fetchTags source, (err, tags)=>
      return log "discarding event, invalid data"  if err
      @bindItemEvents source
      source.tags = tags
      @addNewItem {source, target, as}

  deleteActivity: (data) ->
    {origin, subject} = data

    return if @isFiltered "activity"

    unless @getConstructorName(origin) and @getConstructorName(subject)
      return console.warn "data is not valid"

    source = KD.remote.revive subject
    target = KD.remote.revive origin
    as     = "author"

    @removeItem {source, target, as}

  addJoin: (data)->
    {member} = data

    return if @isFiltered "member"

    return console.warn "member is not defined in new member event"  unless member

    {constructorName, id} = member
    KD.remote.cacheable constructorName, id, (err, account)=>
      return console.error "account is not found", err if err or not account
      KD.getSingleton("groupsController").ready =>
        source = KD.getSingleton("groupsController").getCurrentGroup()
        @addNewItem {as: "member", target: account, source  }

  checkGuestUser: (account) ->
    if account.profile and accountNickname = account.profile.nickname
      if /^guest-/.test accountNickname
        return yes
    return no

  checkForValidAccount: (account) ->
    # if account is not set
    return no  unless account

    isNotMe = account.getId() isnt KD.whoami().getId()
    # if user is exempt
    return no  if account.isExempt and isNotMe

    # if user is guest
    return no  if @checkGuestUser(account) and isNotMe

    return yes

  addFollow: (data)->
    {follower, origin} = data

    return if @isFiltered "follower"

    return console.warn "data is not valid"  unless follower and origin


    {constructorName, id} = follower
    KD.remote.cacheable constructorName, id, (err, source)=>
      return console.log "account is not found" if err or not source
      {_id:id, bongo_:{constructorName}} = data.origin
      KD.remote.cacheable constructorName, id, (err, target)=>
        return console.log "account is not found" if err or not target
        eventObj = {source:target, target:source, as:"follower"}

        return if not @checkForValidAccount(source) or not @checkForValidAccount(target)

        # following tag has its relationship flipped!!!
        if constructorName is "JTag"
          eventObj =
            source : target
            target : source
            as     : "follower"

        @addNewItem eventObj

  addLike: (data)->
    {liker, origin, subject} = data

    return if @isFiltered "like"

    unless subject and liker and origin
      return console.warn "data is not valid"

    {constructorName, id} = liker
    KD.remote.cacheable constructorName, id, (err, source)=>
      return console.log "account is not found", err, liker if err or not source

      {_id:id} = origin
      KD.remote.cacheable "JAccount", id, (err, target)=>
        return console.log "account is not found", err, origin if err or not target

        {constructorName, id} = subject
        KD.remote.cacheable constructorName, id, (err, subject)=>
          return console.log "subject is not found", err, data.subject if err or not subject

          return if not @checkForValidAccount(source) or not @checkForValidAccount(target)
          eventObj = {source, target, subject, as:"like"}
          if subject.bongo_.constructorName is "JNewStatusUpdate"
            @fetchTags subject, (err, tags)=>
              return log "discarding event, invalid data"  if err
              subject.tags = tags
              @addNewItem eventObj
          else
            @addNewItem eventObj

  removeLike : (data)->
    {origin, subject, liker} = data
    unless @getConstructorName(origin) and @getConstructorName(subject)
      return console.warn "data is not valid"
    source  = KD.remote.revive liker
    target  = KD.remote.revive origin
    subject = KD.remote.revive subject
    as      = "like"

    @removeItem {source, target, as, subject}

  addComment: (data) ->
    {origin, reply, subject, replier} = data

    return if @isFiltered "comment"

    unless subject and reply and replier and origin
      return console.warn "data is not valid"

    #CtF: such a copy paste it is. could be handled better
    {constructorName, id} = replier
    KD.remote.cacheable constructorName, id, (err, source)=>
      return console.log "account is not found", err, liker if err or not source

      {_id:id} = origin
      KD.remote.cacheable "JAccount", id, (err, target)=>
        return console.log "account is not found", err, origin if err or not target

        {constructorName, id} = subject
        KD.remote.cacheable constructorName, id, (err, subject)=>
          return console.log "subject is not found", err, data.subject if err or not subject

          {constructorName, id} = reply
          KD.remote.cacheable constructorName, id, (err, object)=>
            return console.log "reply is not found", err, data.reply if err or not object

            return if not @checkForValidAccount(source) or not @checkForValidAccount(target)
            eventObj = {source, target, subject, object, as:"reply"}
            @addNewItem eventObj

  continueLoading: (loadOptions = {})->
    loadOptions.continue = @filters
    @load loadOptions

  filterItem:(item)->
    {as, source, target} = item
    # objects should be there
    return null  unless source and target and as

    # relationships from guests should not be there
    return null if @checkGuestUser(source) or @checkGuestUser(target)

    #CtF instead of filtering later on we should implement its view
    return null  if as is "commenter"

    # filter user followed status activity
    if @getConstructorName(source) is "JNewStatusUpdate" and \
        @getConstructorName(target) is "JAccount" and \
        as is "follower"
      return null

    actor = if @getConstructorName(target) is "JAccount" then target else source
    return null if actor.isExempt

    return item

  tryLoadingAgain:(loadOptions={})->
    unless loadOptions.tryCount?
      return warn "Current try count is not defined, discarding request"

    if loadOptions.tryCount >= 10
      return warn "Reached max re-tries for What is Happening widget"

    loadOptions.tryCount++
    return @load loadOptions

  load: (loadOptions = {})->
    loadOptions.tryCount = loadOptions.tryCount or 0
    if loadOptions.filters
      @filters = loadOptions.filters

    if loadOptions.continue
      @filters = loadOptions.filters = loadOptions.continue

    lastItem = @listController.getItemsOrdered().last
    if lastItem and timestamp = lastItem.getData().timestamp
      lastItemTimestamp = (new Date(timestamp)).getTime()
      loadOptions.from = lastItemTimestamp

    KD.remote.api.ActivityTicker.fetch loadOptions, (err, items = []) =>
      @listController.hideLazyLoader()
      # if we had any error, try loading again
      if err
        warn err
        return @tryLoadingAgain loadOptions

      for item in items when @filterItem item
        @bindItemEvents item.source
        @addNewItem item, @listController.getItemCount()

      if @listController.getItemCount() < 15
        @tryLoadingAgain loadOptions

  pistachio:->
    """
    <div class="activity-ticker right-block-box">
      <h3>What's happening </h3>
      {{> @listView}}
    </div>
    """

  addNewItem: (newItem, index=0) ->
    itemId = @getItemId newItem

    if not @indexedItems[itemId]
      if index? then @listController.addItem newItem, index
      else @listController.addItem newItem
    else
      viewItem = @indexedItems[itemId]
      @listController.moveItemToIndex viewItem, 0

  removeItem: (item) ->
    itemId = @getItemId item

    if @indexedItems[itemId]
      viewItem = @indexedItems[itemId]
      @listController.removeItem viewItem


  getItemId: (item) ->
    {source, target, subject, as, timestamp} = item
    if as is "like"
      "#{source.getId()}_#{target.getId()}_#{as}_#{subject?.getId()}"
    else
      "#{source.getId()}_#{target.getId()}_#{as}_#{timestamp}"

  isFiltered: (filter) ->
    if @filters and @filters.length
      return unless filter in @filters then yes else no
    else
      return no

  bindItemEvents: (item) ->
    return unless @getConstructorName(item) is "JNewStatusUpdate"
    item.on "TagsUpdated", (tags) ->
      item.tags = KD.remote.revive tags
