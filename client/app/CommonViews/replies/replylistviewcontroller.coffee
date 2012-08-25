class OpinionListViewController extends KDListViewController
  constructor:->
    super
    @_hasBackgrounActivity = no
    @startListeners()

  instantiateListItems:(items, keepDeletedOpinions = no)->

    newItems = []

    items.sort (a,b) =>
      a = a.meta.createdAt
      b = b.meta.createdAt
      if a<b then -1 else if a>b then 1 else 0

    for opinion, i in items
      nextOpinion = items[i+1]

      skipOpinion = no
      if nextOpinion? and opinion.deletedAt
        if Date.parse(nextOpinion.meta.createdAt) > Date.parse(opinion.deletedAt)
          skipOpinion = yes

      if not nextOpinion and opinion.deletedAt
        skipOpinion = yes

      skipOpinion = no if keepDeletedOpinions

      unless skipOpinion
        opinionView = @getListView().addItem opinion
        newItems.push opinionView

    return newItems

  startListeners:->
    listView = @getListView()

    log "this is me", @

    listView.on 'ItemWasAdded', (view, index)=>
      view.on 'OpinionIsDeleted', ->
        listView.emit "OpinionIsDeleted"

    listView.on "AllOpinionsLinkWasClicked", (opinionHeader)=>

      return if @_hasBackgrounActivity

      # some problems when logged out server doesnt responds
      @utils.wait 5000, -> listView.emit "BackgroundActivityFinished"

      {meta} = listView.getData()

      listView.emit "BackgroundActivityStarted"
      @_hasBackgrounActivity = yes
      @_removedBefore = no
      @fetchRelativeOpinions 10, meta.createdAt

    # listView.registerListener
    #   KDEventTypes  : "OpinionSubmitted"
    #   listener      : @
    #   callback      : (pubInst, reply)->
    #     log "Opinion Submitted!"
    #     model = listView.getData()
    #     listView.emit "BackgroundActivityStarted"
    #     model.reply reply, (err, reply)->
    #       listView.addItem reply
    #       listView.emit "OwnOpinionHasArrived"
    #       log "in callback now"
    #       listView.emit "BackgroundActivityFinished"


  fetchOpinionsByRange:(from,to,callback)=>
    [to,callback] = [callback,to] unless callback
    query = {from,to}
    message = @getListView().getData()

    message.commentsByRange query,(err,opinions)=>
      @getListView().emit "BackgroundActivityFinished"
      callback err,opinions

  fetchAllOpinions:(skipCount=3, callback = noop)=>

    listView = @getListView()
    listView.emit "BackgroundActivityStarted"
    message = @getListView().getData()
    message.restComments skipCount, (err, opinions)=>

      listView.emit "BackgroundActivityFinished"
      listView.emit "AllOpinionsWereAdded"
      callback err, opinions

  fetchRelativeOpinions:(_limit = 10, _after)=>
    listView = @getListView()
    message = @getListView().getData()

    message.fetchRelativeComments limit:_limit, after:_after, (err, opinions)=>

      if not @_removedBefore
        @removeAllItems()
        @_removedBefore = yes
      @instantiateListItems opinions[_limit-10...], yes

      if opinions.length is _limit
        startTime = opinions[opinions.length-1].meta.createdAt
        @fetchRelativeOpinions 11, startTime
      else
        listView = @getListView()
        listView.emit "BackgroundActivityFinished"
        listView.emit "AllOpinionsWereAdded"
        @_hasBackgrounActivity = no

  replaceAllOpinions:(opinions)->
    @removeAllItems()
    @instantiateListItems opinions
