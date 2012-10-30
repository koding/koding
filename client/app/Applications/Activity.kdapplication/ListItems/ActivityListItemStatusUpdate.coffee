class StatusActivityItemView extends ActivityItemChild

  constructor:(options = {}, data={})->

    options.cssClass or= "activity-item status"
    options.tooltip  or=
      title            : "Status Update"
      selector         : "span.type-icon"
      offset           : 3

    super options,data

    @embedOptions = $.extend {}, options,
      hasDropdown : no
      delegate : @

    if data.link?
      @embedBox = new EmbedBox @embedOptions, data?.link
    else
      @embedBox = new KDView

  viewAppended:()->
    return if @getData().constructor is KD.remote.api.CStatusActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    # If there is embed data in the model, use that!
    if @getData().link?.link_url? and not (@getData().link.link_url is "")
      if not ("embed" in @getData()?.link?.link_embed_hidden_items)
        @embedBox.show()

        firstUrl = @getData().body.match(/([a-zA-Z]+\:\/\/)?(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g)
        if firstUrl?
          @embedBox.embedLinks.setLinks firstUrl

        @embedBox.embedExistingData @getData().link.link_embed, {
          maxWidth: 700
          maxHeight: 300
        }
      else
        # no need to show stuff if it should not be shown.
        @embedBox.hide()
        # # not even in the code
        # @embedBox.destroy()

    # This will involve heavy load on the embedly servers - every client
    # will need to make a request.
    else
      urls = @$("span.data > a")
      for url in urls
        if $(url).attr("href").match(/([a-zA-Z]+\:\/\/)?(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g)
          firstUrl = $(url).attr "href"

      if firstUrl then @embedBox.embedUrl firstUrl, {}
      else
        @embedBox.hide()

  render:=>
    super

    {link} = @getData()

    if link?
      if @embedBox.constructor.name is "KDView"
        @embedBox = new EmbedBox @embedOptions, link
      @embedBox.setEmbedHiddenItems link.link_embed_hidden_items
      @embedBox.setEmbedImageIndex link.link_embed_image_index
      @embedBox.embedExistingData link.link_embed, {} ,=>
        if "embed" in link.link_embed_hidden_items
          @embedBox.hide()
        else
          @embedBox.show()
    else
      @embedBox = new KDView

  click:(event)->

    super

    if $(event.target).is("[data-paths~=body]")
      appManager.tell "Activity", "createContentDisplay", @getData()

  applyTextExpansions:(str = "")->
    link = @getData().link?.link_url
    if link

      links = str.match(/([a-zA-Z]+\:\/\/)?(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g)
      if links?
        hasManyLinks = links.length > 1
      else
        hasManyLinks = no

      isJustOneLink = str.trim() is link
      endsWithLink = str.trim().indexOf(link, str.trim().length - link.length) isnt -1
      startsWithLink = str.trim().indexOf(link) is 0

      if (not hasManyLinks) and (not isJustOneLink) and (endsWithLink or startsWithLink)
        str = str.replace link, ""

    @utils.applyTextExpansions str, yes

  pistachio:->
    """
    {{> @settingsButton}}
    <span class="avatar">{{> @avatar}}</span>
    <div class='activity-item-right-col'>
      <h3 class='hidden'></h3>
      <p>{{@applyTextExpansions #(body)}}</p>
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
    """
