class ContentDisplayCodeSnippet extends KDView
  constructor:(options, data)->
    options = $.extend
      tooltip     :
        title     : "Code Snippet"
        offset    : 3
        selector  : "span.type-icon"
    ,options
    super options,data
    @setClass 'activity-item codesnip clearfix'
    
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
        listView.emit "BackgroundActivityFinished"
        listView.emit "AllCommentsWereAdded"
        controller.removeAllItems()
        controller.instantiateListItems comments      

    @actionLinks = new ActivityActionsView delegate : @commentBox.commentList, cssClass : "comment-header", data

    @codeSnippetView = new CodeSnippetView {},@getData().attachments[0]

  viewAppended: ->
    return if @getData().constructor is bongo.api.CCodeSnipActivity
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
      <h3>{{#(title)}}</h3>
      <p class='context'>{{@utils.applyTextExpansions #(body)}}</p>
      {{> @codeSnippetView}}
      <footer class='clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          <time>{{$.timeago #(meta.createdAt)}}</time>
          {{> @tags}}
        </div>
        {{> @actionLinks}}
      </footer>
      {{> @commentBox}}
    </div>
    """
