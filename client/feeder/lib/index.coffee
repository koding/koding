kd = require 'kd'
KDController = kd.Controller
KDView = kd.View
FeedController = require './feedcontroller'


module.exports = class FeederAppController extends KDController

  @options =
    name       : 'Feeder'
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
