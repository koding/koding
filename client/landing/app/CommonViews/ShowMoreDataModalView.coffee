class ShowMoreDataModalView extends KDModalView

  titleMap = ->
    account : "members"
    tag     : "topics"

  listControllerMap = ->
    account : MembersListViewController
    tag     : KDListViewController

  listItemMap = ->
    account : MembersListItemView
    tag     : ModalTopicsListItem

  constructor:(options = {}, data)->

    participants = data

    if participants[0] instanceof KD.remote.api.JAccount
      @type = "account"
    else if participants[0] instanceof KD.remote.api.JTag
      @type = "tag"

    options.title    or= titleMap()[@type]
    options.height   = "auto"
    options.overlay  = yes
    options.cssClass = "modal-topic-wrapper"
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
    controller = new KDListViewController
      view              : new KDListView
        itemClass    : listItemMap()[@type]
        cssClass        : "modal-topic-list"
    , items             : participants

    controller.getListView().on "CloseTopicsModal", =>
      @destroy()

    controller.on "AllItemsAddedToList", =>
      @loader.destroy()

    @addSubView controller.getView()

  prepareList:->

    {group} = @getOptions()

    if group
      KD.remote.cacheable group, (err, participants)=>
        if err then warn err
        else @putList participants
        ###
          KD.remote.api.JTag.markFollowing participants, (err, result)=>
            if err then warn err
            else @putList result
        ###
    else
      @putList @getData()
