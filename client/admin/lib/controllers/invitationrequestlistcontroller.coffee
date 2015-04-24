kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDListViewController = kd.ListViewController
GroupsInvitationListItemView = require '../views/groupsinvitationlistitemview'


module.exports = class InvitationRequestListController extends KDListViewController

  constructor:(options = {}, data)->
    options.itemClass           ?= GroupsInvitationListItemView
    options.viewOptions         ?= {}
    options.viewOptions.cssClass =
      kd.utils.curry 'invitation-request-list', options.viewOptions.cssClass

    options.noItemFoundWidget   ?= new KDCustomHTMLView
      cssClass : 'lazy-loader'
      partial  : options.noItemFound

    @noItemView                  = options.noItemFoundWidget

    super options, data

    @listView.setDelegate this

    @on 'noItemsFound', => @noItemLeft = true
