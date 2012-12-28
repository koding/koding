class ActivityController extends KDObject

  constructor:->

    super

    KD.remote.api.CActivity.on 'feed-new', (activities) =>
      @emit 'ActivitiesArrived', activities