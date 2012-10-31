class EmbedBoxLinksViewItem extends KDListItemView

  constructor:(options,data)->
    super options,data
    @linkUrl = data.url

    @setClass "embed-link-item"

    # visible link shortening here
    @linkUrlShort = @linkUrl.replace(/(ht|f)tp(s)?\:\/\//,"")
                    .replace(/\/.*/,"")

    @linkButton = new KDButtonView
      title: @linkUrlShort
      style: "transparent"

      callback :=>
        @changeEmbed()

    @favicon = ""

    @faviconImage = new KDCustomHTMLView
      tagName     : "img"
      cssClass    : "embed-favicon hidden"
      attributes  :
        src       : @favicon
        alt       : data.title

  changeEmbed:=>
    @makeActive()

    # KDListView -> EmbedBoxLinksView -> EmbedBox .embedUrl
    @getDelegate().getDelegate().getDelegate().embedLoader.hide()
    @getDelegate().getDelegate().getDelegate().embedUrl @linkUrl, {}, (embedData)=>
      if embedData.favicon_url? then @setFavicon embedData.favicon_url

  makeActive:->
    for item in @getDelegate().items
      item.unsetClass "active"

    @setClass "active"

  setFavicon:(fav="")->
    @favicon = fav

    @faviconImage.setDomAttributes src:@favicon
    @faviconImage.show()

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

    twOptions = (title) ->
      title : title, placement : "above", offset : 3, delayIn : 300, html : yes, animate : yes

    @$("div.embed-link-wrapper").twipsy   twOptions(@getData().link_url or @getData().url)

  pistachio:->
    """
    <div class="embed-link-wrapper">
      {{> @faviconImage}}
      {{> @linkButton}}
    </div>
    """


class EmbedBoxLinksView extends KDView
  constructor:(options,data)->
    super options,data

    @linkList = new KDListView
      cssClass : "embed-link-list layout-wrapper"
      delegate :@
      itemClass : EmbedBoxLinksViewItem
    ,{}

    @hide()

  clearLinks:->
    @linkList.empty()

  setLinks:(links=[])->
    # smarter link adding (keep links already in there intact)

    newList = yes
    for link in links
      for item in @linkList.items
        if link is item.data.url
          newList = no

    # only show the link list if there is a need to actually select sth
    if links.length > 1 then @show() else @hide()

    if newList
      @linkList.empty()

      for link in links
        if links instanceof Array
          @linkList.addItem {
            url : link
          }
      @linkList.items[0].makeActive()

    else
      for link in links
        linkFound = no
        for item in @linkList.items
          if link is item.data.url
            linkFound = yes
        unless linkFound
          if links instanceof Array
            @linkList.addItem {
              url : link
            }

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @linkList}}
    """


class EmbedBoxLinkView extends KDView
  constructor:(options={},data)->
    super options,data

    @embedImage = new EmbedBoxLinkViewImage
      cssClass : "preview_image"
      delegate : @
    ,data

    @embedText = new EmbedBoxLinkViewText
      cssClass : "preview_text"
      hasConfig : data.link_options?.hasConfig or options.hasConfig or no
      delegate : @
    ,data

    @embedImageSwitch = new EmbedBoxLinkViewImageSwitch
      cssClass : "preview_link_pager"
      delegate : @
    ,data

  populate:(data,options={})->
    @setData data

    @embedImage.destroy()
    @embedImage = new EmbedBoxLinkViewImage
      cssClass : "preview_image"
      delegate : @
    ,data

    @embedText.destroy()
    @embedText = new EmbedBoxLinkViewText
      cssClass : "preview_text"
      hasConfig : data.link_options?.hasConfig or options.hasConfig or no
      delegate : @
    ,data

    @embedImageSwitch.destroy()
    @embedImageSwitch = new EmbedBoxLinkViewImageSwitch
      cssClass : "preview_link_pager"
      delegate : @
    ,data

    @viewAppended()

  render:->
    @template.update()
    super()

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @embedImageSwitch}}
    {{> @embedImage}}
    {{> @embedText}}
    """


class EmbedBoxLinkViewImageSwitch extends KDView
  constructor:(options,data)->
    super options,data

    @hide() if (data?.link_embed_hidden_items?["image"]?) or\
               not data.link_options?.hasConfig or\
               not data.link_embed?.images? or\
               data.link_embed?.images?.length < 2

    @embedImageIndex = data.link_embed_image_index or 0

  getEmbedImageIndex:->
    @embedImageIndex

  setEmbedImageIndex:(i=0)->
    @embedImageIndex = i

  click:(event)=>
    if  $(event.target).hasClass "preview_link_switch"

      event.preventDefault()
      event.stopPropagation()

      # There are 1+ more images beyond the current one
      if ($(event.target).hasClass "next") and\
         (@getData().link_embed?.images?.length-1 > @getEmbedImageIndex())

        @setEmbedImageIndex @getEmbedImageIndex() + 1
        @$("a.preview_link_switch.previous").removeClass "disabled"

      # There are 1+ more images before the current one
      if ($(event.target).hasClass "previous") and\
         (@getEmbedImageIndex() > 0)

        @setEmbedImageIndex @getEmbedImageIndex() - 1
        @$("a.preview_link_switch.next").removeClass "disabled"

      # Refresh the image with the new src data
      if @getEmbedImageIndex() < @getData().link_embed?.images.length-1
        imgSrc = @getData().link_embed?.images?[@getEmbedImageIndex()]?.url
        if imgSrc
          @getDelegate().embedImage.setSrc imgSrc
        else
          # imgSrc is undefined - this would be the place for a default
          fallBackImgSrc="http://koding.com/images/service_icons/Koding.png"
          @getDelegate().embedImage.setSrc fallBackImgSrc

        # Either way, set the embedImageIndex to the appropriate nr
        @getDelegate().getDelegate().setEmbedImageIndex @getEmbedImageIndex()

      else
        # imageindex out of bounds - displaying default image
        # (first in the images array) the pistachio will also take care
        # of this

        defaultImgSrc = @getData().link_embed?.images?[0]?.url
        @getDelegate().embedImage.setSrc defaultImgSrc

      @$("span.thumb_nr").html @getEmbedImageIndex()+1

      # When we're at 0/x or x/x, disable the next/prev buttons
      if @getEmbedImageIndex() is 0
        @$("a.preview_link_switch.previous").addClass "disabled"

      else if @getEmbedImageIndex() is (@getData().link_embed?.images?.length-1)
        @$("a.preview_link_switch.next").addClass "disabled"

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <a class="preview_link_switch previous #{if @getEmbedImageIndex() is 0 then "disabled" else ""}">&lt;</a><a class="preview_link_switch next #{if @getEmbedImageIndex() is data?.link_embed?.images?.length then "disabled" else ""}">&gt;</a>
    <div class="thumb_count"><span class="thumb_nr">#{@getEmbedImageIndex()+1 or "1"}</span>/<span class="thumb_all">#{@getData()?.link_embed?.images?.length}</span> <span class="thumb_text">Thumbs</span></div>
    """


class EmbedBoxImageView extends KDView
  constructor:(options,data)->
    super options,data
    @options = options

  populate:(data)->
    @setData data
    @options = data.link_options
    @viewAppended()

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <a href="#{@getData().link_url or "#"}" target="_blank">
    <img src="#{@getData().link_embed?.images?[0]?.url or "http://koding.com/images/service_icons/Koding.png"}" style="max-width:#{if @options.maxWidth? then @options.maxWidth+"px" else "560px"};max-height:#{if @options.maxHeight? then @options.maxHeight+"px" else "300px"}" title="#{@getData().link_embed?.title or ""}" />
    </a>
    """


class EmbedBoxObjectView extends KDView
  constructor:(options,data)->
    super options,data

  populate:(data)->
    @setData data
    @viewAppended()

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    #{Encoder.htmlDecode @getData().link_embed?.object?.html}
    """


class EmbedBoxLinkViewImage extends KDView
  constructor:(options,data)->
    super options,data
    @hide() if (data?.link_embed_hidden_items?["image"]?) or\
               (data.link_embed?.images?.length is 0)

  # this will get called from the image-switch click events to update the preview
  # images when browsing the available embed links
  setSrc:(url="http://koding.com/images/service_icons/Koding.png")->
    @$("img.thumb").attr src : url

  viewAppended:->
    super()

    @imageLink  = @getData().link_embed?.images?[@getData().link_embed_image_index]?.url or\
                  @getData().link_embed?.images?[0]?.url or\
                  "http://koding.com/images/service_icons/Koding.png" # hardcode a default

    @setTemplate @pistachio()
    @template.update()



  # this includes a fallback for when the embedimageindex is out of bounds
  # it will however still request a nonsensical image src
  pistachio:->
    """
    <a class="preview_link" target="_blank" href="#{@getData().link_url or @getData().link_embed?.url}">
      <img class="thumb" src="#{@imageLink}" title="#{(@getData().link_embed?.title + (if @getData().link_embed?.author_name then " by "+@getData().link_embed?.author_name else "")) or "untitled"}"/>
    </a>
    """

class EmbedBoxLinkViewText extends KDView
  constructor:(options,data)->
    super options,data

    @embedTitle = new EmbedBoxLinkViewTitle
      tagName : "a"
      cssClass : "preview_text_link"
      attributes:
        href : data.link_url or data.url
        target : "_blank"
      hasConfig : options.hasConfig or no
    , data
    @embedAuthor = new EmbedBoxLinkViewAuthor
      cssClass : "author_info"
    , data
    @embedProvider = new EmbedBoxLinkViewProvider
      cssClass : "provider_info"
    , data
    @embedDescription = new EmbedBoxLinkViewDescription
      tagName : "a"
      cssClass : "preview_text_link"
      attributes :
        href : data.link_url or data.url
        target: "_blank"
      hasConfig : options.hasConfig or no
    , data

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @embedTitle}}
    {{> @embedAuthor}}
    {{> @embedProvider}}
    {{> @embedDescription}}
    """

class EmbedBoxLinkViewTitle extends KDView
  constructor:(options={},data)->
    super options,data
    @options = options

    @originalTitle = data.link_embed?.title

    @hide() if (data?.link_embed_hidden_items?["title"]?) or\
               not data.link_embed?.title? or\
               data.link_embed?.title.trim() is ""

    if options.hasConfig is yes
      @setClass "has-config"
      @titleInput = new KDInputView
        cssClass     : "preview_title_input hidden"
        name         : "preview_title_input"
        defaultValue : data.link_embed?.title or ""
        blur         : =>
          @titleInput.hide()
          @$("div.preview_title").html(@getValue()).show()

    else
      @titleInput = new KDCustomHTMLView
        cssClass : "hidden"
        partial : data.link_embed?.title or ""

    @author = new KDCustomHTMLView
      tagName : "div"
      cssClass : "edit-indicator title-edit-indicator"
      pistachio : """edited"""
      tooltip :
        title: "Original Content was: "+data.link_embed?.original_title or data.link_embed?.title or ""
    @author.hide()

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()
    if @getData().link_embed?.titleEdited
      @author.show()

  getValue:->
    if @options.hasConfig
      @titleInput.getValue()
    else
      @titleInput.getPartial()

  getOriginalValue:->
    @originalTitle

  click:(event)->
    if @options.hasConfig is yes
      event.preventDefault()
      event.stopPropagation()
      @titleInput.show()
      @titleInput.setFocus()
      @$("div.preview_title").hide()
      no
    else
      super

  pistachio:->
    """
      {{> @titleInput}}
      <div class="preview_title">#{@getData().link_embed?.title or @getData().title or @getData().link_url or @getData().url}
      {{> @author}}
      </div>
    """

class EmbedBoxLinkViewDescription extends KDView
  constructor:(options={},data={})->
    super options,data
    @options = options
    @hide() if (data?.link_embed_hidden_items?["description"]?) or\
               not data.link_embed?.description? or\
               data.link_embed?.description.trim() is ""

    @originalDescription = data.link_embed?.description

    if options.hasConfig is yes
      @setClass "has-config"
      @descriptionInput = new KDInputView
        type         : "textarea"
        cssClass     : "description_input hidden"
        name         : "description_input"
        defaultValue : data.link_embed?.description or ""
        autogrow     : yes
        blur         : =>
          @descriptionInput.hide()
          @$("div.description").html(@getValue()).show()

    else
      @descriptionInput = new KDCustomHTMLView
        cssClass : "hidden"
        partial : data.link_embed?.description or ""

    @author = new KDCustomHTMLView
      tagName : "div"
      cssClass : "edit-indicator discussion-edit-indicator"
      pistachio : "edited"
      tooltip :
        title: "Original Content was: <p>"+(data.link_embed?.original_description or data.link_embed?.description or "")+"</p>"
    @author.hide()

  getValue:->
    if @options.hasConfig
      @descriptionInput.getValue()
    else
      @descriptionInput.getPartial()

  getOriginalValue:->
    @originalDescription

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()
    if @getData().link_embed?.descriptionEdited
      @author.show()

  click:(event)->
    if @options.hasConfig is yes
      event.preventDefault()
      event.stopPropagation()
      @descriptionInput.show()
      @descriptionInput.setFocus()
      @$("div.description").hide()
      no
    else
      super
  pistachio:->
    """
    {{> @descriptionInput}}
    <div class="description #{if (@getData().link_embed?.description or @getData().description) and not("description" in @getData().link_embed_hidden_items) then "" else "hidden"}">#{@getData().link_embed?.description or @getData().description or ""}
    {{> @author}}</div>
    """

class EmbedBoxLinkViewAuthor extends KDView
  constructor:(options,data)->
    super options,data
    @hide() if (data?.link_embed_hidden_items?["author"]?) or\
               not data.link_embed?.author_name?

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()
  pistachio:->
    """
    written by <a href="#{@getData().link_embed?.author_url or @getData().author_url or "#"}" target="_blank">#{@getData().link_embed?.author_name or @getData().author_name}</a>
    """

class EmbedBoxLinkViewProvider extends KDView
  constructor:(options,data)->
    super options,data
    @hide() if (data?.link_embed_hidden_items?["provider"]?) or\
               not data.link_embed?.provider_name?

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()
  pistachio:->
    """
for <strong>#{@getData().link_embed?.provider_name or @getData().provider_name or "the internet"}</strong>#{if (@getData().link_embed?.provider_url or @getData().provider_url) then " at <a href=\"" +(@getData().link_embed?.provider_url or @getData().provider_url)+"\" target=\"_blank\">"+(@getData().link_embed?.provider_display or @getData().provider_display)+"</a>" else ""}
    """

