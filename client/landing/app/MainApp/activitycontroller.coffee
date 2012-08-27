class ActivityController extends KDObject

  constructor:->

    super

    koding.api.CActivity.on 'feed.new', (activities) =>
      @emit 'ActivitiesArrived', activities