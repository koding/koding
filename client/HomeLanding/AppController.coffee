class HomeLandingAppController extends AppController

  KD.registerAppClass this,
    name         : "HomeLanding"
    route        : "/HomeLanding"

  constructor:(options = {}, data)->

    options.view    = new HomeLandingView
      cssClass      : "content-page homelanding"

    super options, data
