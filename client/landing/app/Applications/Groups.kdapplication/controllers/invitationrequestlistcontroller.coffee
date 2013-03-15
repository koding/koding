class InvitationRequestListController extends KDListViewController

  constructor:(options, data)->
    options.itemClass ?= GroupsInvitationRequestListItemView
    options.viewOptions ?= {}
    options.viewOptions.cssClass =
      @utils.curryCssClass 'request-list', options.viewOptions.cssClass
    
    super

    mainView = @getView()

    mainView.once 'viewAppended', =>
      mainView.addSubView @moreLink = new CustomLinkView
        title : 'More...'
        href  : '#'
        click : (event)=>
          event.preventDefault()
          @emit 'ShowMoreRequested'