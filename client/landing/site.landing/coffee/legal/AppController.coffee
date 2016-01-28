LegalView      = require './AppView'

module.exports = class LegalAppController extends KDViewController

  KD.registerAppClass this,
    name  : 'Legal'
    route : '/Legal'

  constructor:(options = {}, data)->

    options.view    = new LegalView
      cssClass      : "content-page legal"

    super options, data
