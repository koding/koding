class ContentDisplayStatusUpdate extends ActivityContentDisplay

  constructor:(options = {}, data={})->

    options.tooltip or=
      title     : "Status Update"
      offset    : 3
      selector  : "span.type-icon"

    super options,data

    account = KD.whoami()
    if (data.originId is KD.whoami().getId()) or KD.checkFlag 'super-admin'
      @settingsButton = new KDButtonViewWithMenu
        cssClass       : 'activity-settings-menu'
        itemChildClass : ActivityItemMenuItem
        title          : ''
        icon           : yes
        delegate       : @
        iconClass      : "arrow"
        menu           : @settingsMenu data
        callback       : (event)=> @settingsButton.contextMenu event
    else
      @settingsButton = new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'

    embedOptions = $.extend {}, options,
      hasDropdown : no
      delegate    : this
      maxWidth    : 700

    if data.link?
      @embedBox = new EmbedBoxWidget @embedOptions, data.link
    else
      @embedBox = new KDView

    origin =
      constructorName  : data.originType
      id               : data.originId

    @avatar = new AvatarView {
      size        : {width: 70, height: 70}
      cssClass    : "author-avatar"
      origin
      showStatus  : yes
    }

    @author = new ProfileLinkView {origin}

    @commentBox = new CommentView null, data

    @actionLinks = new ActivityActionsView
      delegate : @commentBox.commentList
      cssClass : "comment-header"
    , data

    @tags = new ActivityChildViewTagGroup
      itemsToShow   : 3
      itemClass  : TagLinkView
    , data.tags

    @timeAgoView = new KDTimeAgoView {}, @getData().meta.createdAt

  attachTooltipAndEmbedInteractivity: CommentListItemView::applyTooltips

  settingsMenu:(data)->

    account        = KD.whoami()

    if data.originId is KD.whoami().getId()
      menu =
        'Edit'     :
          callback : ->
            KD.getSingleton("appManager").tell "Activity", "editActivity", data
        'Delete'   :
          callback : =>
            @confirmDeletePost data

      return menu

    if KD.checkFlag 'super-admin'
      if KD.checkFlag 'exempt', account
        menu =
          'Unmark User as Troll' :
            callback             : ->
              activityController.emit "ActivityItemUnMarkUserAsTrollClicked", data
      else
        menu =
          'Mark User as Troll' :
            callback           : ->
              activityController.emit "ActivityItemMarkUserAsTrollClicked", data

      menu['Delete Post'] =
        callback : =>
          @confirmDeletePost data

      menu['Block User'] =
        callback : ->
          activityController.emit "ActivityItemBlockUserClicked", data.originId

      return menu

  viewAppended:->
    return if @getData().constructor is KD.remote.api.CStatusActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    # load embed on next callstack
    @utils.defer =>

      # If there is embed data in the model, use that!
      if @getData().link?.link_url? and @getData().link.link_url isnt ''
        @embedBox.show()
        @embedBox.$().fadeIn 200

        firstUrl = @getData().body.match @utils.botchedUrlRegExp
        @embedBox.embedLinks.setLinks [firstUrl]  if firstUrl?

        embedOptions = maxWidth: 700, maxHeight: 300
        @embedBox.embedExistingData @getData().link.link_embed, embedOptions, =>
          @embedBox.setActiveLink @getData().link.link_url
        @embedBox.embedLinks.hide()
      else
        @embedBox.hide()

      @attachTooltipAndEmbedInteractivity()

    # temp for beta
    # take this bit to comment view
    if @getData().repliesCount? and @getData().repliesCount > 0
      commentController = @commentBox.commentController
      commentController.fetchAllComments 0, (err, comments)->
        commentController.removeAllItems()
        commentController.instantiateListItems comments

  render:->
    super

    {link} = @getData()
    if link?
      if @embedBox.constructor.name is "KDView"
        @embedBox = new EmbedBoxWidget @embedOptions, link

      @embedBox.embedExistingData link.link_embed, {}, =>
        @embedBox.hide()  unless @embedBox.hasValidContent

      @embedBox.setActiveLink link.link_url
    else
      @embedBox = new KDView

    @attachTooltipAndEmbedInteractivity()

  formatContent: (str = "")->
    str = @utils.applyMarkdown str
    str = @utils.expandTokens str, @getData()
    return  str

  pistachio:->
    """
    {{> @header}}
    <h2 class="sub-header">{{> @back}}</h2>
    <div class='kdview content-display-main-section activity-item status'>
      {{> @avatar}}
      {{> @settingsButton}}
      {{> @author}}
      <p class="status-body">{{@formatContent #(body)}}</p>
      {{> @embedBox}}
      <footer>
        {{> @actionLinks}}
        {{> @timeAgoView}}
      </footer>
      {{> @commentBox}}
    </div>
    """


    # """
    # {{> @header}}
    # <h2 class="sub-header">{{> @back}}</h2>
    # <div class='kdview content-display-main-section activity-item status'>
    #   <span>
    #     {{> @avatar}}
    #     <span class="author">AUTHOR</span>
    #   </span>
    #   <div class='activity-item-right-col'>
    #     <h3 class='hidden'></h3>
    #     <p class="status-body">{{@applyTextExpansions #(body)}}</p>
    #     {{> @embedBox}}
    #     <footer class='clearfix'>
    #       <div class='type-and-time'>
    #         <span class='type-icon'></span>{{> @contentGroupLink }} by {{> @author}}
    #         {{> @timeAgoView}}
    #         {{> @tags}}
    #       </div>
    #       {{> @actionLinks}}
    #     </footer>
    #     {{> @commentBox}}
    #   </div>
    # </div>
    # """
