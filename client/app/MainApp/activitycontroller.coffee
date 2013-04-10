class ActivityController extends KDObject

  constructor:->

    super

    groupsController = @getSingleton 'groupsController'

    groupChannel = null

    groupsController.on 'GroupChanged', =>
      oldChannel.close().off()  if groupChannel?
      groupChannel = groupsController.groupChannel
      groupChannel.on 'feed-new', => @emit 'ActivitiesArrived', activities
