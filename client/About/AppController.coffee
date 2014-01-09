class AboutAppController extends AppController

  KD.registerAppClass this,
    name         : "About"
    route        : "/About"
    # navItem      :
    #   title      : "About"
    #   path       : "/About"
    #   order      : 90

  constructor:(options = {}, data)->

    options.view    = new AboutView
      cssClass      : "content-page about"

    super options, data
