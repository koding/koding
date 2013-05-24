class ActivityController extends KDObject

  constructor: ->

    super

    groupsController = @getSingleton 'groupsController'

    groupChannel = null

    groupsController.on 'GroupChannelReady', =>
      groupChannel.close().off()  if groupChannel?
      groupChannel = groupsController.groupChannel
      groupChannel.on 'feed-new', (activities) =>
        @emit 'ActivitiesArrived',
          (KD.remote.revive activity for activity in activities)
