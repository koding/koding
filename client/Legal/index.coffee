class LegalAppController extends KDViewController

  KD.registerAppClass this,
    name  : 'Legal'
    route : '/Legal'

  constructor:(options = {}, data)->

    options.view    = new LegalAppView
      cssClass      : "content-page legal"

    super options, data
