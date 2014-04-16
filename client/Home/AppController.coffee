class HomeAppController extends AppController

  KD.registerAppClass this,
    name         : "Home"
    route        : "/Home"

  constructor:(options = {}, data)->

    options.view    = new HomeView
      cssClass      : "content-page home"

    super options, data
