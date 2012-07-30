class CommentListViewController extends KDListViewController
  constructor:->
    super
    @startListeners()

  instantiateListItems:(items, keepDeletedComments = no)->

    newItems = []

    for comment, i in items

      nextComment = items[i+1]

      skipComment = no
      if nextComment? and comment.deletedAt
        if Date.parse(nextComment.meta.createdAt) > Date.parse(comment.deletedAt)
          skipComment = yes

      if not nextComment and comment.deletedAt
        skipComment = yes

      skipComment = no if keepDeletedComments

      unless skipComment
        commentView = @getListView().addItem comment
        newItems.push commentView

    return newItems

  startListeners:->
    listView = @getListView()

    listView.on 'ItemWasAdded', (view, index)=>
      view.on 'CommentIsDeleted', ->
        listView.emit "CommentIsDeleted"

    listView.on "AllCommentsLinkWasClicked", (commentHeader)=>

      # some problems when logged out server doesnt responds
      @utils.wait 5000, -> listView.emit "BackgroundActivityFinished"

      {repliesCount} = listView.getData()

      log "Total comment: ", repliesCount
      stack = []
      removedAlready = no

      stack.push (callback) =>
        listView.emit "BackgroundActivityStarted"
        callback()

      for xto in [repliesCount..0]
        do (xto) =>
          stack.push (callback) =>
            @fetchCommentsByRange xto, xto+1, (err, comments) =>
              if not removedAlready
                @removeAllItems()
                removedAlready = yes
              @instantiateListItems comments, yes
              callback err, comments

      async.parallel stack, (error, result) =>
        listView.emit "BackgroundActivityFinished"
        if not error
          listView.emit "AllCommentsWereAdded"
        else
          log "Failed to get comments..."

    listView.registerListener
      KDEventTypes  : "CommentSubmitted"
      listener      : @
      callback      : (pubInst, reply)->
        model = listView.getData()
        listView.emit "BackgroundActivityStarted"
        model.reply reply, (err, reply)->
          # listView.emit "AllCommentsLinkWasClicked"
          listView.addItem reply
          listView.emit "OwnCommentHasArrived"
          listView.emit "BackgroundActivityFinished"

  fetchCommentsByRange:(from,to,callback)=>
    [to,callback] = [callback,to] unless callback
    query = {from,to}
    message = @getListView().getData()
    message.commentsByRange query,(err,comments)=>
      @getListView().emit "BackgroundActivityFinished"
      callback err,comments

  fetchAllComments:(skipCount=3, callback = noop)=>

    listView = @getListView()
    listView.emit "BackgroundActivityStarted"
    message = @getListView().getData()
    message.restComments skipCount, (err, comments)=>
      listView.emit "BackgroundActivityFinished"
      listView.emit "AllCommentsWereAdded"
      callback err, comments

  replaceAllComments:(comments)->
    @removeAllItems()
    @instantiateListItems comments
