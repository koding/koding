class ContentDisplayTutorial extends ActivityContentDisplay

  constructor:(options = {}, data)->

    unless data.opinionCount?
      # log "This is legacy data. Updating Counts."
      data.opinionCount = data.repliesCount or 0
      data.repliesCount = 0

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

    @author = new ProfileLinkView {origin}

    @opinionBox = new OpinionView null, data

    @opinionBoxHeader = new KDCustomHTMLView
      tagName  : "div"
      cssClass : "opinion-box-header"
      partial  : @opinionHeaderCountString data.opinionCount

    @embedOptions = $.extend {}, options,
      delegate  : @
      hasConfig : no
      forceType : "object"

    @embedBox = new EmbedBox @embedOptions, data

    @previewImage = new KDCustomHTMLView
      tagName : "img"
      cssClass : "tutorial-preview-image"
      attributes:
        src: @utils.proxifyUrl(data.link?.link_embed?.images?[0]?.url or "")
        title:"View the full Tutorial"
        alt:"View the full tutorial"
        "data-paths":"preview"

    @previewImage.hide() unless data.link?.link_embed?.images?[0]?.url

    @timeAgoView = new KDTimeAgoView {}, @getData().meta.createdAt

    @opinionBox.opinionList.on "OwnOpinionHasArrived", (data)=>
      @opinionBoxHeader.updatePartial @opinionHeaderCountString @getData().opinionCount

    @opinionBox.opinionList.on "OpinionIsDeleted", (data)=>
      @opinionBoxHeader.updatePartial @opinionHeaderCountString @getData().opinionCount

    @opinionForm = new OpinionFormView
      preview         :
        language      : "markdown"
        autoUpdate    : yes
        showInitially : no
      cssClass        : "opinion-container"
      callback        : (data)=>
        @getData().reply data, (err, opinion) =>
          callback? err, opinion
          @opinionForm.reset()
          @opinionForm.submitOpinionBtn.hideLoader()
          if err
            new KDNotificationView type : "mini", title : "There was an error, try again later!"
          else
            @opinionBox.opinionList.emit "OwnOpinionHasArrived", opinion
    , data

    @newAnswers = 0

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
        title     : "Delete your tutorial"
        href      : '#'
      cssClass    : 'delete-link hidden'

    @editDiscussionLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        title     : "Edit your tutorial"
        href      : '#'
      cssClass    : 'edit-link hidden'

    activity = @getData()

    loggedInId = KD.whoami().getId()
    if loggedInId is data.originId or       # if comment owner
       loggedInId is activity.originId or   # if activity owner
       KD.checkFlag "super-admin", KD.whoami()  # if super-admin

      @editDiscussionLink.on "click", =>
          if @editDiscussionForm?
            @editDiscussionForm?.destroy()
            delete @editDiscussionForm
            @$(".tutorial-body .data").show()
            @utils.defer =>
              @embedBox.show()
          else
            @editDiscussionForm = new TutorialFormView
              title         : "edit-tutorial"
              cssClass      : "edit-tutorial-form"
              delegate      : @
              callback      : (data)=>
                @getData().modify data, (err, tutorial) =>
                  callback? err, opinion
                  @editDiscussionForm.reset()
                  if err
                    new KDNotificationView
                      title : "Your changes weren't saved."
                      type  : "mini"
                  else
                    @editDiscussionForm.setClass "hidden"
                    @$(".tutorial-body .data").show()
                    @utils.defer =>
                      @embedBox.show() if @embedBox.hasValidContent
            , data

            @addSubView @editDiscussionForm, "p.tutorial-body", yes
            @$(".tutorial-body .data").hide()
            @embedBox.hide()

      @deleteDiscussionLink.on "click", =>
        @confirmDeleteTutorial data

      @editDiscussionLink.unsetClass "hidden"
      @deleteDiscussionLink.unsetClass "hidden"

    activity.on 'ReplyIsAdded',(reply)=>

      if data.bongo_.constructorName is "JTutorial"
        unless reply.replier.id is KD.whoami().getId()
          # newAnswers populated the headerCountString if it is not OwnOpinion
          @newAnswers++

          @opinionBox.opinionList.emit "NewOpinionHasArrived"
        @opinionBoxHeader.updatePartial @opinionHeaderCountString data.opinionCount


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

  opinionHeaderCountString:(count)->

    countString = if count is 0 then "No Answers yet"
    else if count is 1 then          "One Answer"
    else                             "#{count} Answers"

    return '<span class="opinion-count">'+countString+'</span>'

  confirmDeleteTutorial:(data)->

    modal = new KDModalView
      title          : "Delete Tutorial"
      content        : "<div class='modalformline'>Are you sure you want to delete this tutorial and all it's opinions and comments?</div>"
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
                KD.getSingleton("contentDisplayController").emit 'ContentDisplayWantsToBeHidden', @
                @utils.wait 2000, =>
                  @destroy()

              else new KDNotificationView
                type     : "mini"
                cssClass : "error editor"
                title    : "Error, please try again later!"

  highlightCode:->
    # @$("pre").addClass "prettyprint"
    @$("p.tutorial-body span.data pre").each (i,element)=>
      hljs.highlightBlock element

  prepareExternalLinks:->
    @$('p.tutorial-body a[href^=http]').attr "target", "_blank"

  render:->
    super()
    @highlightCode()
    @prepareExternalLinks()

  viewAppended:->
    super()

    @setTemplate @pistachio()
    @template.update()

    @highlightCode()
    @prepareExternalLinks()

    if @getData().link?
      @embedBox.embedExistingData @getData().link.link_embed, @embedOptions, =>
        @embedBox.show() unless (("embed" in @embedBox.getEmbedHiddenItems()) or\
                                 (@embedBox.hasValidContent is no))
      ,@getData().link.link_cache

            # <div class="tutorial-navigation-container clear clearfix">
            #   {{> @listAnchorPrevious}}
            #   {{> @comingUpNextAnchor}}
            #   {{> @listAnchorNext}}
            # </div>

  click:(event)->
    if $(event.target).is("[data-paths~=preview]")

      @videoPopup = new VideoPopup
        delegate : @previewImage
        title : @getData().link?.link_embed?.title or "Untitled Video"
        thumb : @getData().link?.link_embed?.images?[0]?.url
      ,@getData().link?.link_embed?.object?.html

      @videoPopup.openVideoPopup()

  pistachio:->
    """
    {{> @header}}
    <h2 class="sub-header">{{> @back}}</h2>
    <div class='kdview content-display-main-section activity-item tutorial'>
      <div class='tutorial-contents'>
        <div class="tutorial-content">
          <span>
            {{> @avatar}}
            <span class="author">AUTHOR</span>
          </span>
          <div class='tutorial-main-opinion'>
            <h3>{{@utils.expandUsernames @utils.applyMarkdown #(title)}}</h3>
            <footer class='tutorial-footer clearfix'>
              <div class='type-and-time'>
                <span class='type-icon'></span> by {{> @author}} •
                {{> @timeAgoView}}
                {{> @tags}}
                {{> @actionLinks}}
              </div>
            </footer>
            {{> @editDiscussionLink}}
            {{> @deleteDiscussionLink}}
            {{> @previewImage}}
            <p class='context tutorial-body has-markdown'>{{@utils.expandUsernames(@utils.applyMarkdown(#(body)),"pre")}}</p>
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

# class TutorialListSwitchBox extends KDView
#   constructor:(options, data)->

#     @options = options
#     @options.direction or= "next"

#     super options, data

#     @setClass "tutorial-navigation-box"
#     @setClass @options.direction

#     if data.link?

#       @tooltipSource = """
#       <div class="container-preview">
#         <p class="title-preview">#{data.title}</p>
#         <img class="image-preview" src="#{@utils.proxifyUrl data.link.link_embed.images[0].url}" alt="#{@options.direction}"/>
#       </div>
#       """
#     else
#       @tooltipSource = data.title or ""

#     @outgoingButton = new KDButtonView
#       cssClass : "clean-gray tutorial-video-button"
#       title:"#{if @options.direction is "next" then "Next " else "Previous "}Tutorial"
#       tooltip:
#         title: if data.title then data.title else ""
#         placement : "above"
#         # offset : 3
#         delayIn : 300
#         html : no
#         animate : no
#         className : "tutorial-video"
#       callback:=>
#         unless @getData().lazyNode is true then KD.getSingleton("appManager").tell "Activity", "createContentDisplay", @getData()

#   click:->
#     KD.getSingleton("contentDisplayController").emit "ContentDisplayWantsToBeHidden", @getDelegate()
#     unless @getData().lazyNode is true then KD.getSingleton("appManager").tell "Activity", "createContentDisplay", @getData()

#   viewAppended:->
#     super()

#     @setTemplate @pistachio()
#     @template.update()

#     # @outgoingContainer.$().hover noop, =>
#     #   @outgoingContainer.hide()

#     # @outgoingButton.$().hover =>
#     #   @outgoingContainer.show()
#     # , noop

#   pistachio:->
#     """
#     {{> @outgoingButton}}
#     """
