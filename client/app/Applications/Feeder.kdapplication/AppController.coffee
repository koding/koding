class Feeder12345 extends KDController

  constructor:(options={}, data)->
    options.view = new KDView
    super options, data

  createContentFeedController:(options, callback, feedControllerConstructor)->
    callback? \
      if feedControllerConstructor?
        new feedControllerConstructor options
      else
        new FeedController options

  bringToFront:()->
    super name : 'Feeder'
