kd = require 'kd'
KDViewController = kd.ViewController
AboutAppView = require './aboutappview'


module.exports = class AboutAppController extends KDViewController

  @options =
    name  : 'About'
    route : '/:name?/About'

  constructor: (options = {}, data) ->

    options.view    = new AboutAppView
      cssClass      : 'content-page about'

    super options, data
