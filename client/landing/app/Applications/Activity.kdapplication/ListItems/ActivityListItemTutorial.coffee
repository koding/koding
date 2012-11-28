class TutorialActivityItemView extends ActivityItemChild

  constructor:(options, data)->

    unless data.opinionCount?
      # log "This is legacy data. Updating Counts."
      data.opinionCount = data.repliesCount or 0
      data.repliesCount = 0

    options = $.extend
      cssClass    : "activity-item tutorial"
      tooltip     :
        title     : "Tutorial"
        offset    : 3
        selector  : "span.type-icon"
    ,options

    super options,data

    @embedOptions = $.extend {}, options,
      hasDropdown : no
      delegate : @

    @actionLinks = new TutorialActivityActionsView
      delegate : @commentBox.opinionList
      cssClass : "reply-header"
    , data

    @previewImage = new KDCustomHTMLView
      tagName : "img"
      cssClass : "tutorial-preview-image"
      attributes:
        src: @utils.proxifyUrl(data.link?.link_embed?.images?[0]?.url or "")
        title:"View the full Tutorial"
        alt:"View the full tutorial"
        "data-paths":"preview"

    @previewImage.hide() unless data.link?.link_embed?.images?[0]?.url

    data.on 'ReplyIsAdded', (reply)=>
      if data.bongo_.constructorName is "JTutorial"
        @opinionBox.opinionList.emit "NewOpinionHasArrived"

    @opinionBox = new TutorialActivityOpinionView
      cssClass    : "activity-opinion-list comment-container"
    , data

    # When an opinion gets deleted, then the removeReply method of JTutorial
    # will emit this event. This is a workaround for the OpinionIsDeleted
    # event not being caught for opinions that are loaded to the client data
    # structure after the snapshot is loaded

    data.on "ReplyIsRemoved",(replyId)=>

      # this will remove the item from the list if the data doesn't
      # contain it anymore, but the list does. the next snapshot refresh
      # will be okay
      # This is needed, because the "OpinionIsDeleted" event isn't available
      # for newly added JOpinions, for some reason. --arvid

      for item,i in @opinionBox.opinionList.items
        if item?.getData()._id is replyId
          item.hide()
          item.destroy()

    @scrollAreaOverlay = new KDView
      cssClass : "enable-scroll-overlay"
      partial  : ""

    # @scrollAreaList = new KDButtonGroupView
    #   buttons:
    #     "Allow Scrolling here":
    #       callback:=>
    #         @$("div.tutorial-body-container div.body").addClass "scrollable-y"
    #         @$("div.tutorial-body-container div.body").removeClass "no-scroll"

    #         @scrollAreaOverlay.hide()
    #     "View the full Tutorial":
    #       callback:=>
    #         appManager.tell "Activity", "createContentDisplay", @getData()

    # @scrollAreaOverlay.addSubView @scrollAreaList

  highlightCode:=>
    @$("div.body span.data pre").each (i,element)=>
      hljs.highlightBlock element

  prepareExternalLinks:->
    @$('div.body a[href^=http]').attr "target", "_blank"

  prepareScrollOverlay:->
    @utils.wait =>

      body = @$("div.activity-content-container.tutorial div.body")
      container = @$("div.activity-content-container.tutorial")

      if body.height() < parseInt container.css("max-height"), 10
        @scrollAreaOverlay.hide()
      else
        container.addClass "scrolling-down"
        cachedHeight = body.height()
        body.scroll =>

          percentageTop    = 100*body.scrollTop()/body[0].scrollHeight
          percentageBottom = 100*(cachedHeight+body.scrollTop())/body[0].scrollHeight

          distanceTop      = body.scrollTop()
          distanceBottom   = body[0].scrollHeight-(cachedHeight+body.scrollTop())

          triggerValues    =
            top            :
              percentage   : 0.5
              distance     : 15
            bottom         :
              percentage   : 99.5
              distance     : 15

          if percentageTop < triggerValues.top.percentage or\
             distanceTop < triggerValues.top.distance

            container.addClass "scrolling-down"
            container.removeClass "scrolling-both"
            container.removeClass "scrolling-up"

          if percentageBottom > triggerValues.bottom.percentage or\
             distanceBottom < triggerValues.bottom.distance

            container.addClass "scrolling-up"
            container.removeClass "scrolling-both"
            container.removeClass "scrolling-down"

          if percentageTop >= triggerValues.top.percentage and\
             percentageBottom <= triggerValues.bottom.percentage and\
             distanceBottom > triggerValues.bottom.distance and\
             distanceTop > triggerValues.top.distance

            container.addClass "scrolling-both"
            container.removeClass "scrolling-up"
            container.removeClass "scrolling-down"

    @$("div.activity-content-container").hover (event)=>

      @transitionStart = setTimeout =>
        @scrollAreaOverlay.$().css top:"100%"
      , 500
      unless @scrollAreaOverlay.$().hasClass "hidden"
        @checkForCompleteAnimationInterval = window.setInterval =>
          if (parseInt(@scrollAreaOverlay.$().css("top"),10)+@$("div.tutorial div.body").scrollTop()) >= @scrollAreaOverlay.$().height()
            @scrollAreaOverlay.hide()
            @$("div.tutorial div.body").addClass "scrollable-y"
            @$("div.tutorial div.body").removeClass "no-scroll"
            clearInterval @checkForCompleteAnimationInterval if @checkForCompleteAnimationInterval?
        ,50
    , (event)=>
      unless parseInt(@scrollAreaOverlay.$().css("top"),10) >= @scrollAreaOverlay.$().height()
        clearTimeout @transitionStart if @transitionStart?
        clearInterval @checkForCompleteAnimationInterval if @checkForCompleteAnimationInterval?
        @scrollAreaOverlay.$().css top:"0px"
        @$("div.tutorial div.body").removeClass "scrollable-y"
        @$("div.tutorial div.body").addClass "no-scroll"
        @scrollAreaOverlay.show()

  viewAppended:()->
    return if @getData().constructor is KD.remote.api.CTutorialActivity
    super()

    @setTemplate @pistachio()
    @template.update()

    @highlightCode()
    @prepareExternalLinks()
    @prepareScrollOverlay()


  render:->
    super()
    @highlightCode()
    @prepareExternalLinks()
    @prepareScrollOverlay()

  click:(event)->
    if $(event.target).is("[data-paths~=title]") # or\
      KD.getSingleton('router').handleRoute "/Activity/#{@getData().slug}", state:@getData()
         # appManager.tell "Activity", "createContentDisplay", @getData()
    if $(event.target).is("[data-paths~=preview]")

      @videoPopup = new VideoPopup
        delegate : @previewImage
        title : @getData().link?.link_embed?.title or "Untitled Video"
        thumb : @getData().link?.link_embed?.images?[0]?.url
      ,@getData().link?.link_embed?.object?.html

      @videoPopup.openVideoPopup()

  applyTextExpansions:(str = "")->
    str = @utils.expandUsernames str

    if str.length > 500
      visiblePart = str.substr 0, 500
      # this breaks the markdown sanitizer
      # morePart = "<span class='more'><a href='#' class='more-link'>show more...</a>#{str.substr 501}<a href='#' class='less-link'>...show less</a></span>"
      str = visiblePart  + " ..." #+ morePart

    return str

  pistachio:->
    """
    <div class="activity-tutorial-container">
      <span class="avatar">{{> @avatar}}</span>
      <div class='activity-item-right-col'>
        {{> @settingsButton}}
        <h3 class="comment-title">{{@applyTextExpansions #(title)}}</h3>
        <p class="hidden comment-title"></p>
        <div class="activity-content-container tutorial">
          {{> @previewImage}}
          <div class="body has-markdown force-small-markdown no-scroll">
            {{@utils.applyMarkdown #(body)}}
          </div>
          {{> @scrollAreaOverlay}}
        </div>
        <footer class='clearfix'>
          <div class='type-and-time'>
            <span class='type-icon'></span> by {{> @author}}
            <time>{{$.timeago #(meta.createdAt)}}</time>
            {{> @tags}}
          </div>
          {{> @actionLinks}}
        </footer>
      </div>
    </div>
    """

