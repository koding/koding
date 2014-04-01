class BusinessAppController extends AppController

  KD.registerAppClass this,
    name         : "Business"
    route        : "/Business"

  constructor:(options = {}, data)->

    options.view    = new BusinessView
      cssClass      : "content-page business"

    super options, data
