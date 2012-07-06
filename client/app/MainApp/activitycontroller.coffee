class ActivityController extends KDObject
  constructor:->
    super
    bongo.api.CActivity.on 'feed.new', (activities) =>
      @emit 'ActivitiesArrived', activities