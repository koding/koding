kd = require 'kd'
KDViewController = kd.ViewController
FeaturesView = require './featuresview'


module.exports = class FeaturesAppController extends KDViewController

  @options =
    name  : 'Features'
    route : '/:name?/Features'

  constructor: (options = {}, data) ->

    options.view = new FeaturesView
      cssClass : 'content-page features'

    super options, data
