class AboutAppController extends KDViewController

  KD.registerAppClass this,
    name  : 'About'
    route : '/About'

  constructor:(options = {}, data)->

    options.view    = new AboutAppView
      cssClass      : "content-page about"

    super options, data
