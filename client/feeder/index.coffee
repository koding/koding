class FeederAppController extends KDController

  KD.registerAppClass this,
    name       : "Feeder"
    background : yes

  constructor:(options={}, data)->

    options.view    = new KDView
    options.appInfo = name : 'Feeder'

    super options, data

  createContentFeedController:(options, callback, feedControllerConstructor)->

    callback? \
      if feedControllerConstructor?
        new feedControllerConstructor options
      else
        new FeedController options
