kd = require 'kd'
KDViewController = kd.ViewController
WelcomeAppView = require './welcomeappview'


module.exports = class WelcomeAppController extends KDViewController

  @options =
    name  : 'Welcome'
    route : '/:name?/Welcome'

  constructor:(options = {}, data)->

    options.view    = new WelcomeAppView
      cssClass      : "content-page welcome"

    super options, data
