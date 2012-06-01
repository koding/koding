class ContentDisplayStatusUpdate extends KDView
  constructor:(options, data)->
    options = $.extend
      tooltip     :
        title     : "Status Update"
        offset    : 3
        selector  : "span.type-icon"
    ,options
    super options,data
    @setClass 'activity-item status'

    origin =
      constructorName  : data.originType
      id               : data.originId

    @avatar = new AvatarStaticView
      tagName : "span"
      size    : {width: 50, height: 50}
      origin  : origin

    @author = new ProfileLinkView {origin}

    @commentBox = new CommentView null, data
    # temp for beta
    # take this bit to comment view
    if data.repliesCount? and data.repliesCount > 0
      @commentBox.commentController.fetchAllComments 0, (err, comments)=>
        controller = @commentBox.commentController
        listView   = controller.getListView()
        listView.propagateEvent KDEventType: "BackgroundActivityFinished"
        listView.handleEvent {type: 'AllCommentsWereAdded', comments}
        controller.removeAllItems()
        controller.instantiateListItems comments      
    @actionLinks = new ActivityActionsView delegate : @commentBox.commentList, cssClass : "comment-header", data
    
    data = @getData()

    data.on 'update', -> log 'data.onUpdate', arguments
  
  viewAppended:()->
    return if @getData().constructor is bongo.api.CStatusActivity
    super()
    @setTemplate @pistachio()
    @template.update()
  
  pistachio:->
    """
    <span>
      {{> @avatar}}
      <span class="author">AUTHOR</span>
    </span>
    <div class='activity-item-right-col'>
      <h3 class='hidden'></h3>
      <p>{{@utils.applyTextExpansions #(body)}}</p>
      <footer class='clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          <time>{{$.timeago #(meta.createdAt)}}</time>
        </div>
        {{> @actionLinks}}
      </footer>
      {{> @commentBox}}
    </div>
    """