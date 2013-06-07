class InvitationRequestListController extends KDListViewController

  constructor:(options = {}, data)->
    options.itemClass           ?= GroupsInvitationListItemView
    options.viewOptions         ?= {}
    options.viewOptions.cssClass =
      @utils.curryCssClass 'invitation-request-list', options.viewOptions.cssClass

    options.noItemFoundWidget   ?= new KDCustomHTMLView
      cssClass : 'lazy-loader'
      partial  : options.noItemFound

    super options, data

    @listView.setDelegate this

    @on 'noItemsFound', =>
      @showNoItemWidget()
      @noItemLeft = true
