class ActivityController extends KDObject

  constructor:->

    super

    KD.remote.api.CActivity.addGlobalListener 'feed.new', (activities) =>
      @emit 'ActivitiesArrived', activities