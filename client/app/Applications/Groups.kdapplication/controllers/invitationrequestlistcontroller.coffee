class InvitationRequestListController extends KDListViewController

  constructor:(options, data)->
    options.itemClass           ?= GroupsInvitationListItemView
    options.viewOptions         ?= {}
    options.viewOptions.cssClass =
      @utils.curryCssClass 'invitation-request-list', options.viewOptions.cssClass

    options.noItemFoundWidget   ?= new KDCustomHTMLView
        cssClass : 'lazy-loader'
        partial  : options.noItemFound

    if options.isModal
      options.lazyLoadThreshold     = .99
      options.noMoreItemFoundWidget = new KDCustomHTMLView
        cssClass : 'lazy-loader'
        partial  : options.noMoreItemFound

    super

    @listView.setDelegate this

    @on 'noItemsFound', =>
      @showNoItemWidget()
      @noItemLeft = true
      @moreLink?.hide()

    unless options.isModal
      @getView().once 'viewAppended', =>
        @getView().addSubView @moreLink = new CustomLinkView
          cssClass : 'hidden more-link'
          title    : 'More...'
          href     : '#'
          click    : (event)=>
            event.preventDefault()
            @emit 'ShowMoreRequested'

  getStatuses:-> @getOptions().statuses

  setLastTimestamp:(@lastTimestamp)->
  getLastTimestamp:-> @lastTimestamp