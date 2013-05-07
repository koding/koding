class InvitationRequestListController extends KDListViewController

  constructor:(options, data)->
    options.itemClass           ?= GroupsInvitationListItemView
    options.viewOptions         ?= {}
    options.viewOptions.cssClass =
      @utils.curryCssClass 'request-list', options.viewOptions.cssClass
    options.noItemFoundWidget   ?= new KDCustomHTMLView
        cssClass : 'lazy-loader'
        partial  : options.noItemFound

    if options.isModal
      options.lazyLoadThreshold     = .99
      options.noMoreItemFoundWidget = new KDCustomHTMLView
        cssClass : 'lazy-loader'
        partial  : options.noMoreItemFound

    super

    @on 'noItemsFound', =>
      @showNoItemWidget()
      @moreLink?.hide()

    unless options.isModal
      @getView().once 'viewAppended', =>
        @getView().addSubView @moreLink = new CustomLinkView
          cssClass : 'hidden'
          title    : 'More...'
          href     : '#'
          click    : (event)=>
            event.preventDefault()
            @emit 'ShowMoreRequested'

  getStatuses:-> @getOptions().statuses

  setLastTimestamp:(@lastTimestamp)->
  getLastTimestamp:-> @lastTimestamp