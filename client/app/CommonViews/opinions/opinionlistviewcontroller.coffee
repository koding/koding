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

    listView.on 'ItemWasAdded', (view, index)=>
      view.on "OpinionIsDeleted", (data)->
        listView.emit "OpinionIsDeleted", data

    listView.on "OwnOpinionHasArrived",(data)->
      listView.addItem data, null, {type : "slideDown", duration : 100}
      @getDelegate().resetDecoration()

    listView.on "AllOpinionsLinkWasClicked", (opinionHeader)=>

      return if @_hasBackgrounActivity

      # some problems when logged out server doesnt responds
      @utils.wait 5000, -> listView.emit "BackgroundActivityFinished"

      {meta} = listView.getData()

      listView.emit "BackgroundActivityStarted"
      @_hasBackgrounActivity = yes
      @_removedBefore = no

      @fetchRelativeOpinions 5, listView.items.length,(err, opinions)->
        for opinion in opinions
          listView.addItem opinion, null, {type : "slideDown", duration : 100}
        listView.emit "RelativeOpinionsWereAdded"

  # this updates the JDiscussion teaser, because posting a comment will only
  # update the JOpinion teaser, not the JDiscussion --arvid
  fetchTeaser:->
    listView = @getListView()
    message = @getListView().getData()
    message.updateTeaser (err, teaser)=>
      log err if err

  # will be used for pagination (soon) --arvid
  fetchOpinionsByRange:(from,to,callback)->
    [to,callback] = [callback,to] unless callback
    query = {from,to}
    message = @getListView().getData()

    message.opinionsByRange query,(err,opinions)=>
      @getListView().emit "BackgroundActivityFinished"
      callback err, opinions

  fetchAllOpinions:(skipCount=3, callback = noop)->
    listView = @getListView()
    listView.emit "BackgroundActivityStarted"
    message = @getListView().getData()

    message.restOpinions skipCount, (err, opinions)=>
      listView.emit "BackgroundActivityFinished"
      listView.emit "AllOpinionsWereAdded"
      callback err, opinions

  fetchRelativeOpinions:(_limit = 10, _from, callback = noop)->
    listView = @getListView()
    message = @getListView().getData()

    message.opinionsByRange to:_limit+_from, from:_from, (err, opinions)=>
      listView = @getListView()
      listView.emit "BackgroundActivityFinished"
      @_hasBackgrounActivity = no
      callback err, opinions if callback?

  replaceAllOpinions:(opinions)->
    @removeAllItems()
    @instantiateListItems opinions
