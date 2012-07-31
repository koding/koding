class CommentListViewController extends KDListViewController
  constructor:->
    super
    @_hasBackgrounActivity = no
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

      return if @_hasBackgrounActivity

      # some problems when logged out server doesnt responds
      @utils.wait 5000, -> listView.emit "BackgroundActivityFinished"

      {meta} = listView.getData()
      @commentStack = []

      listView.emit "BackgroundActivityStarted"
      @_hasBackgrounActivity = yes
      @fetchRelativeComments 10, meta.createdAt

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

  fetchRelativeComments:(_limit = 10, _after)=>
    listView = @getListView()
    message = @getListView().getData()
    message.fetchRelativeComments limit:_limit, after:_after, (err, comments)=>

      Array::push.apply @commentStack, comments[_limit-10...]

      if comments.length is _limit
        startTime = @commentStack[@commentStack.length-1].meta.createdAt
        @fetchRelativeComments 11, startTime
      else
        listView = @getListView()
        @removeAllItems()
        @instantiateListItems @commentStack, yes
        listView.emit "BackgroundActivityFinished"
        listView.emit "AllCommentsWereAdded"
        @_hasBackgrounActivity = no

  replaceAllComments:(comments)->
    @removeAllItems()
    @instantiateListItems comments
