class ContentDisplayDiscussion extends ActivityContentDisplay

  constructor:(options = {}, data)->

    unless data.opinionCount?
      # log "This is legacy data. Updating Counts."
      data.opinionCount = data.repliesCount or 0
      data.repliesCount = 0

    options.tooltip or=
      title     : "Discussion"
      offset    : 3
      selector  : "span.type-icon"

    super options, data

    origin =
      constructorName  : data.originType
      id               : data.originId

    @timeAgoView = new KDTimeAgoView {}, @getData().meta.createdAt

    @avatar = new AvatarStaticView
      tagName : "span"
      size    : {width: 50, height: 50}
      origin  : origin

    @author = new ProfileLinkView {origin:origin}

    @commentBox = new CommentView {}, data

    @opinionBox = new OpinionView {}, data

    @opinionBoxHeader = new KDCustomHTMLView
      tagName  : "div"
      cssClass : "opinion-box-header"
      partial  : @opinionHeaderCountString data.opinionCount

    @opinionBox.opinionList.on "OwnOpinionHasArrived", (data)=>
      @resetHeaderCount data
      @opinionBox.resetDecoration()

    @opinionBox.opinionList.on "OpinionIsDeleted", (data)=>
      @resetHeaderCount data

    @opinionForm = new OpinionFormView
      preview         :
        language      : "markdown"
        autoUpdate    : yes
        showInitially : no
      cssClass        : "opinion-container"
      callback        : (data)=>
        @getData().replyOpinion data, (err, opinion) =>
          callback? err, opinion
          @opinionForm.reset()
          @opinionForm.submitOpinionBtn.hideLoader()
          if err
            new KDNotificationView type : "mini", title : "There was an error, try again later!"
          else
            @opinionBox.opinionList.emit "OwnOpinionHasArrived", opinion
    , data

    @newAnswers = 0

    @actionLinks = new DiscussionActivityActionsView
      delegate : @commentBox.commentList
      cssClass : "comment-header"
    , data

    @tags = new ActivityChildViewTagGroup
      itemsToShow   : 3
      itemClass  : TagLinkView
    , data.tags

    @deleteDiscussionLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        title     : "Delete your discussion"
        href      : '#'
      cssClass    : 'delete-link hidden'

    @editDiscussionLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        title     : "Edit your discussion"
        href      : '#'
      cssClass    : 'edit-link hidden'

    activity = @getData()

    loggedInId = KD.whoami().getId()
    if loggedInId is data.originId or       # if discussion owner
       loggedInId is activity.originId or   # if activity owner
       KD.checkFlag "super-admin", KD.whoami()  # if super-admin

      @editDiscussionLink.on "click", =>

        if @editDiscussionForm?
          @editDiscussionForm?.destroy()
          delete @editDiscussionForm
          @$(".discussion-body .data").show()

        else
          @editDiscussionForm = new DiscussionFormView
            preview       :
              language      : "markdown"
              autoUpdate    : yes
              showInitially : yes
            title         : "edit-discussion"
            cssClass      : "edit-discussion-form"
            callback      : (data)=>
              @getData().modify data, (err, discussion) =>
                callback? err, opinion
                @editDiscussionForm.reset()
                if err
                  new KDNotificationView
                    title : "Your changes weren't saved."
                    type  : "mini"
                else
                  @editDiscussionForm.setClass "hidden"
                  @$(".discussion-body .data").show()
          , data

          @addSubView @editDiscussionForm, "p.discussion-body", yes
          @$(".discussion-body .data").hide()

      @deleteDiscussionLink.on "click", =>
        @confirmDeleteDiscussion data

      @editDiscussionLink.unsetClass "hidden"
      @deleteDiscussionLink.unsetClass "hidden"

    # quick fix - noli me judicare - MSA
    activity.on 'CommentIsAdded', (reply) =>
      activity.repliesCount = reply.repliesCount
      @commentBox.setData activity

    activity.on 'ReplyIsAdded',(reply)=>
      if data.bongo_.constructorName is "JDiscussion"
        unless reply.replier.id is KD.whoami().getId()
          # newAnswers populated the headerCountString if it is not OwnOpinion
          @newAnswers++

          @opinionBox.opinionList.emit "NewOpinionHasArrived"

        @opinionBoxHeader.updatePartial @opinionHeaderCountString reply.opinionCount

    # When the activity gets deleted correctly, it will emit this event,
    # which leaves only the count of the custom element to be updated

    activity.on "OpinionWasRemoved",(args)=>
      @opinionBoxHeader.updatePartial @opinionHeaderCountString @getData().opinionCount

    # in any case, the JDiscussion emits this event as a failsafe. if the deleted
    # item can still be found in the list, it needs to be removed

    activity.on "ReplyIsRemoved", (replyId)=>
      @opinionBoxHeader.updatePartial @opinionHeaderCountString @getData().opinionCount

      for item,i in @opinionBox.opinionList.items
        if item.getData()._id is replyId
          item.hide()
          item.destroy()

    if activity.repliesCount > 0 and not activity.replies?
      activity.commentsByRange                   # so we fetch them manually
        from : 0
        to : 5
      , (err, comments)=>
        if err
         log err
        else                    # set the data in the appropriate places
          comments = comments.reverse()           # take care of sorting
          activity.replies = comments
          @commentBox.setData comments
          for comment in comments       # and add them to the commentBox
            @commentBox.commentList.addItem comment


  resetHeaderCount:(data)->
    opinionCount = @opinionBox.opinionList.items and @opinionBox.opinionList.items.length or 0
    @opinionBoxHeader.updatePartial @opinionHeaderCountString opinionCount

  opinionHeaderCountString:(count)->

    countString = if count is 0 then "No Answers yet"
    else if count is 1 then          "One Answer"
    else                             "#{count} Answers"

    return '<span class="opinion-count">'+countString+'</span>'

  confirmDeleteDiscussion:(data)->

    modal = new KDModalView
      title          : "Delete discussion"
      content        : "<div class='modalformline'>Are you sure you want to delete this discussion and all it's opinions and comments?</div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        Delete       :
          style      : "modal-clean-red"
          loader     :
            color    : "#ffffff"
            diameter : 16
          callback   : =>
            data.delete (err)=>
              modal.buttons.Delete.hideLoader()
              modal.destroy()
              unless err
                KD.singleton('display').emit 'ContentDisplayWantsToBeHidden', @
                @utils.wait 2000, =>
                  @destroy()

              else new KDNotificationView
                type     : "mini"
                cssClass : "error editor"
                title    : "Error, please try again later!"

  highlightCode:->
    # @$("pre").addClass "prettyprint"
    @$("p.discussion-body span.data pre").each (i,element)=>
      hljs.highlightBlock element

  render:->
    super()
    @highlightCode()
    @prepareExternalLinks()

  viewAppended:->
    super()
    @highlightCode()
    @prepareExternalLinks()

    # @$(".discussion-body .data").addClass "has-markdown"

  prepareExternalLinks:->
    @$('p.discussion-body a[href^=http]').attr "target", "_blank"

  pistachio:->
    """
    {{> @header}}
    <h2 class="sub-header">{{> @back}}</h2>
    <div class='kdview content-display-main-section activity-item discussion'>
      <div class='discussion-contents'>
        <div class="discussion-content">
          <span>
            {{> @avatar}}
            <span class="author">AUTHOR</span>
          </span>
          <div class='discussion-main-opinion'>
            <h3>{{@utils.expandUsernames @utils.applyMarkdown #(title)}}</h3>
            <footer class='discussion-footer clearfix'>
              <div class='type-and-time'>
                <span class='type-icon'></span>{{> @contentGroupLink }} by {{> @author}} •
                {{> @timeAgoView}}
                {{> @tags}}
                {{> @actionLinks}}
              </div>
            </footer>
            {{> @editDiscussionLink}}
            {{> @deleteDiscussionLink}}
            <p class='context discussion-body has-markdown'>{{@utils.expandUsernames(@utils.applyMarkdown(#(body)),"pre")}}</p>
            {{> @commentBox}}
          </div>
        </div>
      </div>
      <div class="opinion-content">
        {{> @opinionBoxHeader}}
        {{> @opinionBox}}
        <div class="content-display-main-section opinion-form-footer">
          {{> @opinionForm}}
        </div>
      </div>
    </div>
    """
