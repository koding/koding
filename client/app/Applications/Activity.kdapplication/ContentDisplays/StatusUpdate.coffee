class ContentDisplayStatusUpdate extends ActivityContentDisplay

  constructor:(options = {}, data={})->

    options.tooltip or=
      title     : "Status Update"
      offset    : 3
      selector  : "span.type-icon"

    super options,data

    embedOptions = $.extend {}, options, {
      hasDropdown : no
      delegate : @
      maxWidth : 700
    }

    @embedBox = new EmbedBox embedOptions, data?.link

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

  viewAppended:()->

    # return if @getData().constructor is KD.remote.api.CStatusActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    # If there is embed data in the model, use that!
    if @getData()?.link
      if not ("embed" in @getData().link.link_embed_hidden_items)
        @embedBox.show()
        @embedBox.embedExistingData @getData()?.link?.link_embed, {}
      else
        # no need to show stuff if it should not be shown. not even in the code
        @embedBox.hide()
        @embedBox.destroy()

    # This will involve heavy load on the embedly servers - every client
    # will need to make a request.
    else
      urls = @$("span.data > a")
      for url in urls
        if $(url).attr("href").match(/([a-zA-Z]+\:\/\/)?(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/.*\S)?/g)
          firstUrl = $(url).attr "href"

      if firstUrl then @embedBox.embedUrl firstUrl, {}
      else @embed

    # temp for beta
    # take this bit to comment view
    if @getData().repliesCount? and @getData().repliesCount > 0
      commentController = @commentBox.commentController
      commentController.fetchAllComments 0, (err, comments)->
        commentController.removeAllItems()
        commentController.instantiateListItems comments

  render:=>
    super
    data = @getData().link or {}
    @embedBox.setEmbedHiddenItems data.link_embed_hidden_items
    @embedBox.setEmbedImageIndex data.link_embed_image_index
    @embedBox?.embedExistingData data.link_embed, {}

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
        <p>{{@utils.applyTextExpansions #(body)}}</p>
        {{> @embedBox}}
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
    </div>
    """