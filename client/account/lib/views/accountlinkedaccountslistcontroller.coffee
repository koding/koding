kd = require 'kd'
KDListViewController = kd.ListViewController
globals = require 'globals'


module.exports = class AccountLinkedAccountsListController extends KDListViewController

  constructor:(options = {}, data)->

    super options, data

    @instantiateListItems ({title : nicename, provider} for own provider, {nicename} of globals.config.externalProfiles)
