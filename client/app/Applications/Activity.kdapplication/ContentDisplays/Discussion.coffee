class ContentDisplayDiscussion extends KDView

  constructor:(options = {}, data)->

    options.tooltip or=
      title     : "Discussion"
      offset    : 3
      selector  : "span.type-icon"

    super options, data

    @setClass 'activity-item discussion'

    origin =
      constructorName  : data.originType
      id               : data.originId

    @avatar = new AvatarStaticView
      tagName : "span"
      size    : {width: 50, height: 50}
      origin  : origin

    @author = new ProfileLinkView {origin}

    @replyBox = new ReplyView null, data

    @opinionForm = new ReplyOpinionFormView
      cssClass : "opinion-container"
      callback  : (data)=>
        msg = new KDNotificationView
          title : "You continued a discussion."
        bongo.api.JDiscussion::reply data.body, (err, opinion) =>
          callback? err, opinion
          if err
            new KDNotificationView type : "mini", title : "There was an error, try again later!"
          else
            new KDNotificationView title : "Opinion added to database"
            @propagateEvent (KDEventType:"OwnActivityHasArrived"), opinion



    @actionLinks = new DiscussionActivityActionsView
      delegate : @replyBox.commentList
      cssClass : "comment-header"
    , data

    @heartBox = new HelpBox
      subtitle : "About Status Updates"
      tooltip  :
        title  : "This a public wall, here you can share anything with the Koding community."


    @tags = new ActivityChildViewTagGroup
      itemsToShow   : 3
      subItemClass  : TagLinkView
    , data.tags

  viewAppended:()->

    # return if @getData().constructor is bongo.api.CStatusActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    # temp for beta
    # take this bit to comment view
    if @getData().repliesCount? and @getData().repliesCount > 0
      commentController = @replyBox.commentController
      commentController.fetchAllComments 0, (err, comments)->
        commentController.removeAllItems()
        commentController.instantiateListItems comments

  pistachio:->
    """
    <span>
      {{> @avatar}}
      <span class="author">AUTHOR</span>
    </span>
    <div class='activity-item-right-col'>
      <h3>{{#(title)}}</h3>
      <p class='context'>{{@utils.applyTextExpansions #(body)}}</p>
      <footer class='clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          <time>{{$.timeago #(meta.createdAt)}}</time>
          {{> @tags}}
        </div>
        {{> @actionLinks}}
      </footer>
      {{> @replyBox}}
    </div>
    <div class="content-display-main-section opinion-form-footer">
      <div class="opinion-form-headline">
        <p>Post your reply here</p>
      </div>
    {{> @opinionForm}}
    {{> @heartBox}}
    </div>
    """
