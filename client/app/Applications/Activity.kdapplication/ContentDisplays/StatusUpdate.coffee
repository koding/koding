class ContentDisplayStatusUpdate extends ActivityContentDisplay

  constructor:(options = {}, data={})->

    options.tooltip or=
      title     : "Status Update"
      offset    : 3
      selector  : "span.type-icon"

    super options,data

    embedOptions = $.extend {}, options,
      hasDropdown : no
      delegate    : this
      maxWidth    : 700

    if data.link?
      @embedBox = new EmbedBox @embedOptions, data.link
    else
      @embedBox = new KDView

    origin =
      constructorName  : data.originType
      id               : data.originId

    @avatar = new AvatarStaticView
      tagName : "span"
      size    : {width: 50, height: 50}
      origin  : origin

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

  viewAppended:()->
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

        firstUrl = @getData().body.match(/(([a-zA-Z]+\:)?\/\/)+(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g)
        @embedBox.embedLinks.setLinks firstUrl  if firstUrl?

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

  applyTextExpansions:(str = "")->
    # link = @getData().link?.link_url
    # if link

    #   links = str.match(/([a-zA-Z]+\:\/\/)?(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g)
    #   if links?
    #     hasManyLinks = links.length > 1
    #   else
    #     hasManyLinks = no

    #   isJustOneLink = str.trim() is link
    #   endsWithLink = str.trim().indexOf(link, str.trim().length - link.length) isnt -1
    #   startsWithLink = str.trim().indexOf(link) is 0

    #   if (not hasManyLinks) and (not isJustOneLink) and (endsWithLink or startsWithLink)
    #     str = str.replace link, ""

    str = @utils.applyTextExpansions str, yes

  render:->
    super

    {link} = @getData()
    if link?
      if @embedBox.constructor.name is "KDView"
        @embedBox = new EmbedBox @embedOptions, link

      @embedBox.embedExistingData link.link_embed, {}, =>
        @embedBox.hide()  unless @embedBox.hasValidContent

      @embedBox.setActiveLink link.link_url
    else
      @embedBox = new KDView

    @attachTooltipAndEmbedInteractivity()

  pistachio:->

    """
    {{> @header}}
    <h2 class="sub-header">{{> @back}}</h2>
    <div class='kdview content-display-main-section activity-item status'>
      <span>
        {{> @avatar}}
        <span class="author">AUTHOR</span>
      </span>
      <div class='activity-item-right-col'>
        <h3 class='hidden'></h3>
        <p class="status-body">{{@applyTextExpansions #(body)}}</p>
        {{> @embedBox}}
        <footer class='clearfix'>
          <div class='type-and-time'>
            <span class='type-icon'></span> by {{> @author}}
            {{> @timeAgoView}}
            {{> @tags}}
          </div>
          {{> @actionLinks}}
        </footer>
        {{> @commentBox}}
      </div>
    </div>
    """