class CommentListViewController extends KDListViewController
  constructor:->
    super
    @startListeners()

  startListeners:->
    listView = @getListView()
    
    # listView.registerListener
    #   KDEventTypes  : "CommentInputReceivedFocus"
    #   listener      : @
    #   callback      : (pubInst,{fromUnixTime,callback})=>
    #     @fetchCommentsByRange fromUnixTime, callback

    listView.registerListener
      KDEventTypes  : ["AllCommentsLinkWasClicked","CommentInputReceivedFocus"]
      listener      : @
      callback      : (pubInst, link)=>
        listView.propagateEvent KDEventType: "BackgroundActivityStarted"

        # some problems when logged out server doesnt responds
        setTimeout ->
          listView.propagateEvent KDEventType: "BackgroundActivityFinished"
        ,5000
        @fetchAllComments 0, (err, comments)=>
          listView.propagateEvent KDEventType: "BackgroundActivityFinished"
          listView.handleEvent {type: "AllCommentsWereAdded", comments}
          @removeAllItems()
          @instantiateListItems comments

    listView.registerListener
      KDEventTypes  : "NewCommentsLinkWasClicked"
      listener      : @
      callback      : (pubInst, link)=>
        # doesnt work for now
        # listView.propagateEvent KDEventType: "BackgroundActivityStarted"
        # firstCommentTimestamp = listView.items[0].getData().meta.createdAt
        # fromUnixTime = new Date(firstCommentTimestamp).getTime()
        # @fetchCommentsByRange fromUnixTime,(err, comments)=>
        #   listView.propagateEvent KDEventType: "BackgroundActivityFinished"
        #   log comments
        #   # @compareNewComments comments
    
    listView.registerListener
      KDEventTypes  : "CommentSubmitted"
      listener      : @
      callback      : (pubInst, reply)->
        model = listView.getData()
        listView.propagateEvent KDEventType: "BackgroundActivityStarted"
        model.reply reply, (err, reply)->
          listView.addItem reply
          # log listView,"OwnCommentHasArrived"
          listView.propagateEvent KDEventType: "OwnCommentHasArrived"
          listView.propagateEvent KDEventType: "BackgroundActivityFinished"
  # 
  # 
  # add: (item, index) ->
  #   @createInstance item, index
  
  # replaceAllComments:(comments)->
  #   @removeAllItems()
  #   @add comment,0 for comment in comments
  #   @handleEvent {type: 'AllCommentsWereAdded', comments}
  #   @get "BackgroundActivityFinished"
  # 
  # createInstance:(comment, index)->
  #   # console.log 'hello'
  #   itemClass = @getOptions().subItemClass
  #   commentInstance = new itemClass null, comment
  #   
  #   {originId, originType} = comment
  #   bongo.cacheable originType, originId, (err, origin)->
  #     commentInstance.updatePartial commentInstance.partial comment, origin
  #   
  #   @addItemView commentInstance, index
  #   @handleEvent type : "DecorateCommentView"

  fetchCommentsByRange:(from,to,callback)=>
    [to,callback] = [callback,to] unless callback
    query = {from,to}
    message = @getListView().getData()
    message.commentsByRange query,(err,comments)=>
      @getListView().propagateEvent KDEventType: "BackgroundActivityFinished"
      callback err,comments
  
  fetchAllComments:(skipCount=3, callback = noop)=>
    # log ":::: alll"
    message = @getListView().getData()
    message.restComments skipCount, callback
  
  replaceAllComments:(comments)->
    @removeAllItems()
    @instantiateListItems comments
  # compareNewComments:(newComments)->
  #   oldComments = (item.getData() for item in @items)
  #   listView = @getListView()
  #   # log oldComments,newComments,":::::"
  #   for newComment,index in newComments
  #     unless newComment._id is oldComments[index]?._id
  #       listView.addItem newComment,index
  #       @emit "NewCommentsLoaded"
  #   
  # refreshItems:(source,data,{listenedPath, propagatedPath})=>
  #   notChildRefresh = no
  #   listenedPath = listenedPath.replace (new RegExp propagatedPath + "\.?"), (str, offset)->
  #     notChildRefresh = yes
  #     ""
  #   return unless notChildRefresh?
  #   items = JsPath.getAt(data, listenedPath)
  #   firstItem = @items.splice 0,1
  #   for item in @items
  #     item.destroy()
  #   @items = firstItem
  #   @instantiateListItems items

class CommentView extends KDView
  constructor:(options, data)->
    super
    @setClass "comment-container"
    @createSubViews data
    @resetDecoration()
    @attachListeners()
  
  render:->
    @resetDecoration()
  
  createSubViews:(data)->
    @commentList = new CommentListView
      # lastToFirst : yes
      subItemClass: CommentListItemView
      delegate: @
    , data

    @commentController        = new CommentListViewController view: @commentList
    @addSubView showMore      = new CommentShowMoreLink delegate: @commentList, data
    @addSubView @commentList
    @addSubView @commentForm  = new NewCommentForm delegate : @commentList
    
    @commentList.registerListener
      KDEventTypes  : "OwnCommentHasArrived"
      listener      : @
      callback      : ->
        showMore.render()
      
      

    if data.replies
      for reply in data.replies when reply? and 'object' is typeof reply
        @commentList.addItem reply

    @commentList.propagateEvent KDEventType: "BackgroundActivityFinished"

    # data.watch "repliesCount", ()->
      

  attachListeners:->

    # @listenTo
    #   KDEventTypes : "DecorateCommentView"
    #   listenedToInstance : @commentList
    #   callback : @resetDecoration

    @listenTo
      KDEventTypes : "DecorateActiveCommentView"
      listenedToInstance : @commentList
      callback : @decorateActiveCommentState

    @listenTo
      KDEventTypes : "CommentLinkReceivedClick"
      listenedToInstance : @commentList
      callback : =>
        @commentForm.commentInput.setFocus()

    @listenTo
      KDEventTypes : "CommentViewShouldReset"
      listenedToInstance : @commentList
      callback : @resetDecoration

  resetDecoration:->
    post = @getData()
    if post.repliesCount is 0
      @decorateNoCommentState()
    else
      @decorateCommentedState()

  decorateNoCommentState:->
    @unsetClass "active-comment"
    @unsetClass "commented"
    @setClass "no-comment"
  
  decorateCommentedState:->
    @unsetClass "active-comment"
    @unsetClass "no-comment" 
    @setClass "commented"
  
  decorateActiveCommentState:->
    @unsetClass "commented"
    @unsetClass "no-comment" 
    @setClass "active-comment"

  decorateItemAsLiked:(likeObj)->
    if likeObj?.results?.likeCount > 0
      @setClass "liked"
    else
      @unsetClass "liked"
    @ActivityActionsView.setLikedCount likeObj

class CommentShowMoreLink extends KDView
  constructor:->
    super
    @hide()
    @setClass "show-more-comments"
    
    @listenTo
      KDEventTypes: 'AllCommentsWereAdded'
      listenedToInstance: @getDelegate()
      callback:=> @hide()
    
  click:(event)->
    list = @getDelegate()
    listLength = list.items.length

    if $(event.target).is('a')
      list.propagateEvent (KDEventType:'AllCommentsLinkWasClicked'), @
    
    # needs comment by range and comparecomments fix
    
    # if $(event.target).is('a.all-count')
    #   list.propagateEvent (KDEventType:'AllCommentsLinkWasClicked'), @
    # 
    # if $(event.target).is('a.new-count')
    #   list.propagateEvent (KDEventType: 'NewCommentsLinkWasClicked'), @
      
  viewAppended:->
    data = @getData()
    @_repliesCount = data.repliesCount or 0

    @setTemplate @pistachio()
    @template.update()

    if data.repliesCount? and data.repliesCount > 3
      @_diff = @_repliesCount - 3
      @show()
    else
      @_diff = 0
  
  getNewCount:(repliesCount)->
    listLength = @getDelegate().items.length
    newCount = repliesCount - listLength - @_diff
    if newCount > 0
      @show()
      @showNewCount()
    else
      @hide()

    return newCount
      
  hide:->
    @unsetClass "has-new-items"
    @$().slideUp 150
    super

  showNewCount:->
    @show()
    @setClass "has-new-items"
    
  show:->
    @$().slideDown 150
    super

  pistachio:->
    """
    <a href='#' class='all-count'>View all {{#(repliesCount)}} comments...</a>
    <a href='#' class='new-count'>{{@getNewCount #(repliesCount)}} new</a>
    """

class CommentListView extends KDListView
  constructor:(options,data)->
    options = options ? {} 
    options.cssClass = "kdlistview kdlistview-comments"
    super options,data
  
  # render:->
  #   log "does it work?",@getData()

class CommentListItemView extends KDListItemView
  constructor:(options,data)->
    options = $.extend
      type      : "comment"
      cssClass  : "kdlistitemview kdlistitemview-comment"
    ,options
    super options,data
    
    origin = {
      constructorName  : data.originType
      id               : data.originId
    }
    @avatar = new AvatarView {
      size    : {width: 30, height: 30}
      origin
    }
    @author = new ProfileLinkView {
      origin
    }
  
  viewAppended:->
    @setTemplate @pistachio()
    @template.update()
    # super unless @_partialUpdated

  click:(event)->
    if $(event.target).is "span.avatar a, a.user-fullname"
      {originType, originId} = @getData()
      bongo.cacheable originType, originId, (err, origin)->
        unless err
          appManager.tell "Members", "createContentDisplay", origin
  
  pistachio:->
    """
    <div class='item-content-comment clearfix'>
      <span class='avatar'>{{> @avatar}}</span>
      <div class='comment-contents clearfix'>
        <p class='comment-body'>
          {{> @author}}
          {{@utils.applyTextExpansions #(body)}}
        </p>
        <time>{{$.timeago #(meta.createdAt)}}</time>
      </div>
    </div>
    """
  
  # updatePartial:->
  #   data = @getData()
  #   # return unless 'object' is typeof data # TODO: hack
  #   super
  #   @_partialUpdated = yes
  # 
  #   title = new Date(data.meta.createdAt).format 'h:MM TT "<cite>"mmm d, yyyy"</cite>"'
  #   @$('time').twipsy title : title, placement : "right", offset : 5, delayIn : 300, html : yes, animate : yes
  # 
  # partial:(comment, account)->
  #   return unless "object" is typeof comment
  #   unless account
  #     account =
  #       profile:
  #         fullname: 'Loading...'
  #         username: 'Loading...'
  #         avatar  : ''
  #         hash    : ''
  #     fallbackUrl = ""
  #     title = "Default avatar"
  #     profile = account.profile
  #   else
  #     profile = account.profile
  #     host = "http://#{location.host}/"
  #     fallbackUrl = "url(http://www.gravatar.com/avatar/#{profile.hash}?size=30&d=#{encodeURIComponent(host + '/images/defaultavatar/default.avatar.30.png')})"
  #     title = "#{profile.firstName} #{profile.lastName}'s avatar"
  # 
  #   """
  #     <div class='item-content-comment clearfix'>
  #       <span class='avatar'>
  #         <a href='/#' title='#{title}' style='background-image:#{fallbackUrl}'></a>
  #       </span>
  #       <div class='comment-contents clearfix'>
  #         <p class='comment-body'>
  #           <a class='user-fullname' title='#{profile.firstName} #{profile.lastName}' href='/#/profile/#{profile.username}'>#{profile.firstName} #{profile.lastName}:</a>
  #           <span>#{__utils.applyTextExpansions comment.body}</span>
  #         </p>
  #         <time>#{$.timeago new Date(comment.meta.createdAt)}</time>
  #       </div>
  #     </div>
  #   """

class NewCommentForm extends KDView
  constructor:(options,data)->
    options = $.extend
      type      : "new-comment"
      cssClass  : "item-add-comment-box"
    ,options
    super options,data

  viewAppended:()->
    {profile} = @getSingleton('mainController').getVisitor().currentDelegate
    host = "http://#{location.host}/"
    fallbackUrl = "url(http://www.gravatar.com/avatar/#{profile.hash}?size=30&d=#{encodeURIComponent(host + '/images/defaultavatar/default.avatar.30.png')})"

    @addSubView commenterAvatar = new KDCustomHTMLView 
      tagName : "span"
      partial : "<a href='#' style='background-image:#{fallbackUrl};'></a>"

    @addSubView commentFormWrapper = new KDView
      cssClass    : "item-add-comment-form"

    commentFormWrapper.addSubView @commentInput   = new KDHitEnterInputView
      type        : "textarea"
      delegate    : @
      placeholder : "Type your comment and hit enter..."
      # autogrow    : yes
      validate    :
        # event       : "keyup"
        rules       : 
          required    : yes 
        messages    :
          required    : "Please type a comment..."
      callback    : @commentInputReceivedEnter

    @attachListeners()
    
  attachListeners:->
    @listenTo
      KDEventTypes:       "Focus"
      listenedToInstance: @commentInput
      callback:           @commentInputReceivedFocus
    @listenTo
      KDEventTypes:       "Blur"
      listenedToInstance: @commentInput
      callback:           @commentInputReceivedBlur

  commentPosted:()->
    @commentInput.setValue ""
    @resetCommentField()

  makeCommentFieldActive:()->
    @getDelegate().handleEvent type : "DecorateActiveCommentView"
    (@getSingleton "windowController").setKeyView @commentInput

  resetCommentField:()->
    @getDelegate().handleEvent type : "CommentViewShouldReset"
    
  otherCommentInputReceivedFocus:(instance)->
    if instance isnt @commentInput
      commentForm = @commentInput.getDelegate()
      commentForm.resetCommentField() if $.trim(@commentInput.getValue()) is ""

  commentInputReceivedFocus:()->
    # log 'focus event'
    @makeCommentFieldActive()
    list = @getDelegate()
    listLength = list.items.length
    list.propagateEvent KDEventType: "BackgroundActivityStarted"
    if list.items.length > 0
      firstCommentTimestamp = list.items[0].getData().meta.createdAt
      fromUnixTime = new Date(firstCommentTimestamp).getTime()
    else
      fromUnixTime = new Date(1e7).getTime()
    
    callback = (err,comments)=>
      # list.compareNewComments comments
      @makeCommentFieldActive()
    
    list.propagateEvent KDEventType : "CommentInputReceivedFocus",{fromUnixTime,callback}
    no

  commentInputReceivedBlur:()->
    if @commentInput.getValue() is ""
      @resetCommentField() 
    no

  commentInputReceivedEnter:(instance,event)=>
    if KD.isLoggedIn()
      reply = @commentInput.getValue()
      @commentInput.setValue ''
      @commentInput.blur()
      @commentInput.$().blur()
      @getDelegate().propagateEvent KDEventType: 'CommentSubmitted', reply
    else
      new KDNotificationView
        type      : "growl"
        title     : "please login to post a comment!"
        duration  : 1500
