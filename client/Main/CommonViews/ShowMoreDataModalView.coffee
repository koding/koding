class ShowMoreDataModalView extends KDModalView

  titleMap = ->
    account : "Members"
    tag     : "Topics"
    app     : "Applications"

  listControllerMap = ->
    account : KDListViewController
    tag     : KDListViewController
    app     : KDListViewController

  listItemMap = ->
    account : MembersListItemView
    app     : ModalAppsListItemView

  constructor:(options = {}, data)->

    participants = data

    if participants[0] instanceof KD.remote.api.JAccount
      @type = "account"
      css   = "modal-topic-wrapper"
    else if participants[0] instanceof KD.remote.api.JTag
      @type = "tag"
      css   = "modal-topic-wrapper"
    else
      @type = "app"
      css   = "modal-applications-wrapper"

    options.title    or= titleMap()[@type]
    options.height   = "auto"
    options.overlay  = yes
    options.width  or= 540
    options.cssClass = css
    options.buttons  =
      Close :
        style : "modal-clean-gray"
        callback : =>
          @destroy()

    super

  viewAppended:->
    @addSubView @loader = new KDLoaderView
      size          :
        width       : 30
      loaderOptions :
        color       : "#cccccc"
        shape       : "spiral"
        diameter    : 30
        density     : 30
        range       : 0.4
        speed       : 1
        FPS         : 24

    @loader.show()

    @prepareList()
    @setPositions()

  putList: (participants) ->
    @controller = new KDListViewController
      view              : new KDListView
        itemClass       : listItemMap()[@type]
        cssClass        : "modal-topic-list"
    , items             : participants

    @controller.getListView().on "CloseTopicsModal", =>
      @destroy()

    @controller.on "AllItemsAddedToList", =>
      if @type is "tag"
        @reviveFollowButtons (item.getId() for item in participants)

      @loader.destroy()

    @addSubView @controller.getView()

  reviveFollowButtons: (ids) ->
    KD.remote.api.JTag.fetchMyFollowees ids, (err, followees) =>
      for modal in @controller.getItemsOrdered()
        button = modal.followButton
        id = button?.getData()?.getId()
        button.setState 'Following' if id and id in followees

  prepareList:->

    {group} = @getOptions()

    if group
      KD.remote.cacheable group, (err, participants)=>
        if err then warn err
        else
          @putList participants
    else
      @putList @getData()
