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

    @author = new ProfileLinkView {origin:origin}

    @opinionBox = new OpinionView null, data

    @opinionBoxHeader = new KDCustomHTMLView
      tagName  : "div"
      cssClass : "opinion-box-header"
      partial  : @opinionHeaderCountString data.repliesCount

    @opinionBox.opinionList.on "OwnOpinionHasArrived", (data)=>
      @opinionBoxHeader.updatePartial @opinionHeaderCountString @getData().repliesCount

    @opinionBox.opinionList.on "OpinionIsDeleted", (data)=>
      @opinionBoxHeader.updatePartial @opinionHeaderCountString @getData().repliesCount

    @opinionForm = new OpinionFormView
      cssClass  : "opinion-container"
      callback  : (data)=>
        @getData().reply data, (err, opinion) =>
          callback? err, opinion
          if err
            new KDNotificationView type : "mini", title : "There was an error, try again later!"
            @opinionForm.submitOpinionBtn.hideLoader()
          else
            @opinionBox.opinionList.emit "OwnOpinionHasArrived", opinion
            @opinionForm.submitOpinionBtn.hideLoader()
    , data

    @newAnswers = 0

    # @jumpToReplyLink = new KDCustomHTMLView
    #   tagName     : "a"
    #   partial     : "Scroll to Reply Box"
    #   attributes  :
    #     href      : "#"
    #   click:->
    #     $('div.kdscrollview.discussion').animate({scrollTop: $("#opinion-form-box").position().top}, "slow")

    # @jumpToTopLink = new KDCustomHTMLView
    #   tagName     : "a"
    #   partial     : "Scroll to Top"
    #   attributes  :
    #     href      : "#"
    #   click:->
    #     $('div.kdscrollview.discussion').animate({scrollTop: $(".section-title").position().top}, "slow")

    ###
    <div class="discussion-nav">
      {{> @jumpToTopLink}}
      {{> @jumpToReplyLink}}
    </div>
    ###

    @staticLinkBox = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Static Link"
      attributes  :
        href      : "/discussion/"+@utils.slugify data.title

    @actionLinks = new DiscussionActivityActionsView
      delegate    : @opinionBox.opinionList
      cssClass    : "comment-header"
    , data

    @tags = new ActivityChildViewTagGroup
      itemsToShow   : 3
      subItemClass  : TagLinkView
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
    bongo.cacheable data.originId, "JAccount", (err, account)=>
      loggedInId = KD.whoami().getId()
      if loggedInId is data.originId or       # if comment owner
         loggedInId is activity.originId or   # if activity owner
         KD.checkFlag "super-admin", account  # if super-admin

        @listenTo
          KDEventTypes        : "click"
          listenedToInstance  : @editDiscussionLink
          callback            : =>
            if @editDiscussionForm?
              @editDiscussionForm?.destroy()
              delete @editDiscussionForm
              @$(".discussion-body .data").show()
            else
              @editDiscussionForm = new DiscussionFormView
                title         : "edit-discussion"
                cssClass      : "edit-discussion-form"
                callback      : (data)=>
                  @getData().modify data, (err, discussion) =>
                    callback? err, opinion
                    if err
                      new KDNotificationView
                        title : "Your changes weren't saved."
                        type  : "mini"
                    else
                      @emit "DiscussionWasEdited", discussion
                      @editDiscussionForm.setClass "hidden"
                      @$(".discussion-body .data").show()
              , data

              @addSubView @editDiscussionForm, "p.discussion-body", yes
              @$(".discussion-body .data").hide()

        @listenTo
          KDEventTypes       : "click"
          listenedToInstance : @deleteDiscussionLink
          callback           : => @confirmDeleteDiscussion data

        @editDiscussionLink.unsetClass "hidden"
        @deleteDiscussionLink.unsetClass "hidden"

    activity.on 'ReplyIsAdded',(reply)=>

      # JDiscussion needs the new Opinion
      if data.bongo_.constructorName is "JDiscussion"

        # Why this workaround, you ask?
        #
        #  Getting the data from the JDiscussion.reply event "ReplyIsAdded"
        #  without JSONifying it locks up the UI for up to 10 seconds.

        # Create new JOpinion and convert JSON into Object

        # newOpinion = new bongo.api.JOpinion
        # opinionData = JSON.parse(reply.opinionData)

        # Copy JSON data to the newly created JOpinion

        # for variable of opinionData
        #   newOpinion[variable] = opinionData[variable]

        # Updating the local data object, then adding the item to the box
        # and increasing the count box


        # unless newOpinion.originId is KD.whoami().getId()
        unless reply.replier.id is KD.whoami().getId()

          # Manually add the opinion to the data...

          # if data.opinions?
          #   unless data.opinions.indexOf newOpinion is -1
          #     data.opinions.push newOpinion
          # else
          #   data.opinions = [newOpinion]

          # The following line would add the new Opinion to the View
          # @opinionBox.opinionList.addItem newOpinion, null, {type : "slideDown", duration : 100}

          # newAnswers populated the headerCountString if it is not OwnOpinion
          @newAnswers++

          @opinionBox.opinionList.emit "NewOpinionHasArrived"

        @opinionBoxHeader.updatePartial @opinionHeaderCountString data.repliesCount

    activity.on "OpinionWasRemoved",(args)=>
      @opinionBoxHeader.updatePartial @opinionHeaderCountString @getData().repliesCount

    activity.on "ReplyIsRemoved", (replyId)=>
      @opinionBoxHeader.updatePartial @opinionHeaderCountString @getData().repliesCount

      for item,i in @opinionBox.opinionList.items
        if item.getData()._id is replyId
          item.hide()
          item.destroy()

  opinionHeaderCountString:(count)=>
    if count is 0
      countString = "No Answers yet"
    else if count is 1
      countString = "One Answer"
    else
      countString = count+ " Answers"

    '<span class="opinion-count">'+countString+'</span>'

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
                @emit 'DiscussionIsDeleted'
                @destroy()
              else new KDNotificationView
                type     : "mini"
                cssClass : "error editor"
                title    : "Error, please try again later!"

  render:->
    super()

    @$("pre").addClass "prettyprint"
    prettyPrint()

  viewAppended:()->
    super()
    @setTemplate @pistachio()
    @template.update()

    @$("pre").addClass "prettyprint"
    prettyPrint()

  pistachio:->
    """
    <div class='discussion-contents'>
    <div class="discussion-content">
      <span>
        {{> @avatar}}
        <span class="author">AUTHOR</span>
      </span>
      <div class='discussion-main-opinion'>
        <h3>{{@utils.expandUsernames @utils.applyMarkdown #(title)}}</h3>
        {{> @editDiscussionLink}}
        {{> @deleteDiscussionLink}}
        <p class='has-markdown context discussion-body'>{{@utils.expandUsernames @utils.applyMarkdown #(body)}}</p>
        <footer class='discussion-footer clearfix'>
          <div class='type-and-time'>
            <span class='type-icon'></span> by {{> @author}} •
            <time>{{$.timeago #(meta.createdAt)}}</time>
            {{> @tags}}
            {{> @actionLinks}}
          </div>
        </footer>
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
    """