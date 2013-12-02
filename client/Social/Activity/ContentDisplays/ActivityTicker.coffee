class ActivityTicker extends ActivityRightBase
  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry "activity-ticker", options.cssClass
    super options, data

    @listController = new KDListViewController
      lazyLoadThreshold: .99
      viewOptions :
        type      : "activities"
        cssClass  : "activities"
        itemClass : ActivityTickerItem

    @listView = @listController.getView()

    @listController.on "LazyLoadThresholdReached", @bound "load"

    @load()

    group = KD.getSingleton("groupsController")
    group.on "MemberJoinedGroup", (data)=>
      {member} = data
      return console.warn "member is not defined in new member event"  unless member

      {constructorName, id} = member
      KD.remote.cacheable constructorName, id, (err, account)=>
        return console.error "account is not found", err if err or not account
        @listController.addItem {as: "member", target: account}, 0

    group.on "LikeIsAdded", (data)=>
      {liker, origin, subject} = data
      unless liker and origin and subject
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

            eventObj = {source, target, subject, as:"like"}
            @listController.addItem eventObj, 0

    group.on "FollowHappened", (data)=>
      {follower, origin} = data
      return console.warn "data is not valid"  unless follower and origin

      {constructorName, id} = follower
      KD.remote.cacheable constructorName, id, (err, source)=>
        return console.log "account is not found" if err or not source
        {_id:id, bongo_:{constructorName}} = data.origin
        KD.remote.cacheable constructorName, id, (err, target)=>
          return console.log "account is not found" if err or not target
          eventObj = {source, target, as:"follower"}

          # following tag has its relationship flipped!!!
          if constructorName is "JTag"
            eventObj =
              source : target
              target : source
              as     : "follower"

          @listController.addItem eventObj, 0

  load: ->
    lastItem = @listController.getItemsOrdered().last
    lastItemTimestamp = +(new Date())

    if lastItem and timestamp = lastItem.getData().timestamp
      lastItemTimestamp = (new Date(timestamp)).getTime()

    options = from: lastItemTimestamp

    KD.remote.api.ActivityTicker.fetch options, (err, items = []) =>
      @listController.hideLazyLoader()
      return  if err
      for item in items
        {as, source, target, subject} = item
        if source and target and as
          @listController.addItem item

  pistachio:
    """
    <div class="activity-ticker right-block-box">
      <h3>Activity Feed <i class="cog-icon"></i></h3>
      {{> @listView}}
    </div>
    """
