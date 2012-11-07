class ContentDisplayTutorial extends ActivityContentDisplay

  constructor:(options = {}, data)->

    options.tooltip or=
      title     : "Tutorial"
      offset    : 3
      selector  : "span.type-icon"

    super options, data

    @setClass "tutorial"

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

    @embedOptions = $.extend {}, options,
      delegate  : @
      hasConfig : no
      forceType : "object"

    @embedBox = new EmbedBox @embedOptions, data

    @opinionBox.opinionList.on "OwnOpinionHasArrived", (data)=>
      @opinionBoxHeader.updatePartial @opinionHeaderCountString @getData().repliesCount

    @opinionBox.opinionList.on "OpinionIsDeleted", (data)=>
      @opinionBoxHeader.updatePartial @opinionHeaderCountString @getData().repliesCount

    @opinionForm = new OpinionFormView
      preview         :
        language      : "markdown"
        autoUpdate    : yes
        showInitially : no
      cssClass        : "opinion-container"
      callback        : (data)=>
        @getData().reply data, (err, opinion) =>
          callback? err, opinion
          @opinionForm.submitOpinionBtn.hideLoader()
          if err
            new KDNotificationView type : "mini", title : "There was an error, try again later!"
          else
            @opinionBox.opinionList.emit "OwnOpinionHasArrived", opinion
    , data

    @newAnswers = 0

    # Links to easily navigate to the bottom/top of the page
    # These are useful since the opinions can be quite long, even when shortened
    # visually, and the ease of access to the form at the bottom is
    # paramount

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

    # The static link box will be useful when we have implemented actual
    # routing to the single ContentTypes

    # @staticLinkBox = new KDCustomHTMLView
    #   tagName     : "a"
    #   partial     : "Static Link"
    #   attributes  :
    #     href      : "/discussion/"+@utils.slugify data.title

    @actionLinks = new TutorialActivityActionsView
      delegate    : @opinionBox.opinionList
      cssClass    : "comment-header"
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
    KD.remote.cacheable data.originId, "JAccount", (err, account)=>
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
              @utils.wait =>
                @embedBox.show()
            else
              @editDiscussionForm = new TutorialFormView
                title         : "edit-discussion"
                cssClass      : "edit-discussion-form"
                delegate      : @
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
                      @utils.wait =>
                        @embedBox.show()
              , data

              @addSubView @editDiscussionForm, "p.discussion-body", yes
              @$(".discussion-body .data").hide()
              @embedBox.hide()

        @listenTo
          KDEventTypes       : "click"
          listenedToInstance : @deleteDiscussionLink
          callback           : => @confirmDeleteDiscussion data

        @editDiscussionLink.unsetClass "hidden"
        @deleteDiscussionLink.unsetClass "hidden"

    activity.on 'ReplyIsAdded',(reply)=>

      if data.bongo_.constructorName is "JTutorial"
        unless reply.replier.id is KD.whoami().getId()
          # newAnswers populated the headerCountString if it is not OwnOpinion
          @newAnswers++

          @opinionBox.opinionList.emit "NewOpinionHasArrived"
        @opinionBoxHeader.updatePartial @opinionHeaderCountString data.repliesCount


    # When the activity gets deleted correctly, it will emit this event,
    # which leaves only the count of the custom element to be updated

    activity.on "OpinionWasRemoved",(args)=>
      @opinionBoxHeader.updatePartial @opinionHeaderCountString @getData().repliesCount

    # in any case, the JDiscussion emits this event as a failsafe. if the deleted
    # item can still be found in the list, it needs to be removed

    activity.on "ReplyIsRemoved", (replyId)=>
      @opinionBoxHeader.updatePartial @opinionHeaderCountString @getData().repliesCount

      for item,i in @opinionBox.opinionList.items
        if item.getData()._id is replyId
          item.hide()
          item.destroy()

    # @listInfo = new KDView

    @listAnchor = new KDView

    KD.remote.api.JTutorialList.fetchForTutorialId @getData().getId(), (listData)=>
      log "list",listData
      if listData
        # @listInfo.updatePartial "In list '#{listData.title}'"
        for tutorial,i in listData.tutorials
          if tutorial._id is @getData()._id
            @position = i
            @before = listData.tutorials[0...i]
            @after = listData.tutorials[i+1..]
        log "at",@position,"before",@before,"after",@after
        if @after.length >0
          @listAnchor.addSubView new TutorialListSwitchBox
            direction:"next"
          , @after[0]
        if @before.length >0
          @listAnchor.addSubView new TutorialListSwitchBox
            direction:"previous"
          , @before[0]


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
      title          : "Delete Tutorial"
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

  hightlightCode:=>
    @$("pre").addClass "prettyprint"
    @$("p.discussion-body span.data pre").each (i,element)=>
      hljs.highlightBlock element

  render:->
    super()
    @hightlightCode()

  viewAppended:()->
    super()

    @setTemplate @pistachio()
    @template.update()

    @hightlightCode()

    @$(".discussion-body .data").addClass "has-markdown"

    if @getData().link?
      @embedBox.embedExistingData @getData().link.link_embed, @embedOptions, =>
        @embedBox.show()
      ,@getData().link.link_cache


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
            {{> @listAnchor}}
            <h3>{{@utils.expandUsernames @utils.applyMarkdown #(title)}}</h3>
            <footer class='discussion-footer clearfix'>
              <div class='type-and-time'>
                <span class='type-icon'></span> by {{> @author}} •
                <time>{{$.timeago #(meta.createdAt)}}</time>
                {{> @tags}}
                {{> @actionLinks}}
              </div>
            </footer>
            {{> @editDiscussionLink}}
            {{> @deleteDiscussionLink}}
            {{> @embedBox}}
            <p class='context discussion-body'>{{@utils.expandUsernames(@utils.applyMarkdown(#(body)),"pre")}}</p>
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

class TutorialListSwitchBox extends KDView
  constructor:(options, data)->

    @options = options
    @options.direction or= "next"

    super options, data

    @setClass "tutorial-navigation-box"

    @outgoingContainer = new KDView
    if data.link?
      log data.link
      image = new KDCustomHTMLView
        cssClass : "image-preview"
        tagName : "img"
        attributes :
          src : @utils.proxifyUrl data.link.link_embed.images[0].url
      log image
      @outgoingContainer.addSubView image

    @outgoingLink = new KDButtonView
      cssClass :"modal-clean-red"
      pistachio: @options.direction
      callback:=>
        appManager.tell "Activity", "createContentDisplay", @getData()

  viewAppended:->
    super()

    @setTemplate @pistachio()
    @template.update()
  pistachio:->
    """
    {{> @outgoingContainer}}
      {{> @outgoingLink}}
    """
