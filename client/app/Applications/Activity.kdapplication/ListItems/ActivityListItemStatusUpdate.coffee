class StatusActivityItemView extends ActivityItemChild

  constructor:(options = {}, data={})->

    options.cssClass or= "activity-item status"
    options.tooltip  or=
      title            : "Status Update"
      selector         : "span.type-icon"
      offset           :
        top            : 3
        left           : -5

    super options,data

    @embedOptions = $.extend {}, options,
      hasDropdown : no
      delegate : @

    if data.link?
      @embedBox = new EmbedBox @embedOptions, data?.link
    else
      @embedBox = new KDView

    @timeAgoView = new KDTimeAgoView {}, @getData().meta.createdAt

  attachTooltipAndEmbedInteractivity:->
    @$("p.status-body > span.data > a").each (i,element)->
      href = $(element).attr("data-original-url") or $(element).attr("href") or ""

      twOptions = (title) ->
         title : title, placement : "above", offset : 3, delayIn : 300, html : yes, animate : yes, className : "link-expander"

      if $(element).attr("target") is "_blank"
        $(element).twipsy twOptions("External Link : <span>"+href+"</span>")
      element


  viewAppended:()->
    return if @getData().constructor is KD.remote.api.CStatusActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    # load embed on next callstack

    @utils.wait =>

      # If there is embed data in the model, use that!
      if @getData().link?.link_url? and not (@getData().link.link_url is "")

        if not ("embed" in @getData()?.link?.link_embed_hidden_items)
          @embedBox.show()
          @embedBox.$().fadeIn 200
          firstUrl = @getData().body.match(/(([a-zA-Z]+\:)?\/\/)+(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g)

          if firstUrl?
            @embedBox.embedLinks.setLinks firstUrl

          @embedBox.embedExistingData @getData().link.link_embed, {
            maxWidth: 700
            maxHeight: 300
          }, =>
            @embedBox.setActiveLink @getData().link.link_url
            unless @embedBox.hasValidContent
              @embedBox.hide()
          , @getData().link.link_cache

          @embedBox.embedLinks.hide()
        else
          @embedBox.hide()
      else
        @embedBox.hide()

      @attachTooltipAndEmbedInteractivity()

  render:=>
    super

    {link} = @getData()

    if link?
      if @embedBox.constructor.name is "KDView"
        @embedBox = new EmbedBox @embedOptions, link
      @embedBox.setEmbedHiddenItems link.link_embed_hidden_items
      @embedBox.setEmbedImageIndex link.link_embed_image_index

      # render embedBox only when the embed changed, else there will be ugly
      # re-rendering (particularly of the image)
      unless @embedBox.getEmbedData() is link.link_embed
        @embedBox.embedExistingData link.link_embed, {} ,=>
          if "embed" in link.link_embed_hidden_items or not @embedBox.hasValidContent
            @embedBox.hide()
        , link.link_cache

      @embedBox.setActiveLink link.link_url

    else
      @embedBox = new KDView
    @attachTooltipAndEmbedInteractivity()

  click:(event)->

    super

    # if $(event.target).is("span.type-icon")
    #   KD.getSingleton('router').handleRoute "/Activity/#{@getData().slug}", state:@getData()

  applyTextExpansions:(str = "")->

    # This code will remove single links from the text if they are located
    # at the start or end of the line. However, since we defer the embed
    # load, there is no way to be sure if the embed is there or not when
    # shortening the link -> so i disabled it --arvid

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

    #   if @embedBox.hasValidContent and not hasManyLinks and not isJustOneLink and (endsWithLink or startsWithLink)
    #     str = str.replace link, ""

    str = @utils.applyTextExpansions str, yes

  pistachio:->
    """
    {{> @settingsButton}}
    <span class="avatar">{{> @avatar}}</span>
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
    """
