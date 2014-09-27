class FeaturesAppController extends KDViewController

  KD.registerAppClass this,
    name  : 'Features'
    route : '/Features'


  constructor: (options = {}, data) ->

    options.view = new FeaturesView
      cssClass : 'content-page features'

    super options, data
