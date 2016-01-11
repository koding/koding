kd = require 'kd'
KDViewController = kd.ViewController
LegalAppView = require './legalappview'


module.exports = class LegalAppController extends KDViewController

  @options =
    name  : 'Legal'
    route : '/:name?/Legal'

  constructor:(options = {}, data)->

    options.view    = new LegalAppView
      cssClass      : "content-page legal"

    super options, data
