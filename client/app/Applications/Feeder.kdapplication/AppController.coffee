class Feeder12345 extends KDController

  constructor:(options={}, data)->
    options.view = new KDView
    super options, data

  createContentFeedController:(options, callback, feedController)->
    controller = if feedController then new feedController options else new FeedController options
    callback? controller
  
  bringToFront:()->
    super name : 'Topics'
