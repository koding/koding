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
    {{> @embedImage}}
    {{> @embedText}}
    {{> @embedImageSwitch}}
    """

 #              <div class="preview_image #{if ("image" in @getEmbedHiddenItems()) or not data?.images?[@getEmbedImageIndex()]? then "hidden" else ""}">
 #                <a class="preview_link" target="_blank" href="#{data.url or url}"><img class="thumb" src="#{data?.images?[@getEmbedImageIndex()]?.url or "this needs a default url"}" title="#{(data.title + (if data.author_name then " by "+data.author_name else "")) or "untitled"}"/></a>
 #              </div>
 #              <div class="preview_text">
 #               <a class="preview_text_link" target="_blank" href="#{data.url or url}">
 #                <div class="preview_title">#{data.title or data.url}</div>
 #               </a>
 #                <div class="author_info #{if data.author_name then "" else "hidden"}">written by <a href="#{data.author_url or "#"}" target="_blank">#{data.author_name}</a></div>
 #                <div class="provider_info">for <strong>#{data.provider_name or "the internet"}</strong>#{if data.provider_url then " at <a href=\"" +data.provider_url+"\" target=\"_blank\">"+data.provider_display+"</a>" else ""}</div>
 #               <a class="preview_text_link" target="_blank" href="#{data.url or url}">
 #                <div class="description #{if data.description and not("description" in @getEmbedHiddenItems()) then "" else "hidden"}">#{data.description or ""}</div>
 #               </a>
 #              </div>
 #              <div class="preview_link_pager #{unless (@options.hasDropdown) and not("image" in @getEmbedHiddenItems()) and data?.images? and (data?.images?.length > 1) then "hidden" else ""}">
 #                <a class="preview_link_switch previous #{if @getEmbedImageIndex() is 0 then "disabled" else ""}">&lt;</a><a class="preview_link_switch next #{if @getEmbedImageIndex() is @getEmbedData()?.images?.length then "disabled" else ""}">&gt;</a>
 #                <div class="thumb_count"><span class="thumb_nr">#{@getEmbedImageIndex()+1 or "1"}</span>/<span class="thumb_all">#{data?.images?.length}</span> <span class="thumb_text">Thumbs</span></div>
 #              </div>


class EmbedBoxLinkViewImageSwitch extends KDView
  constructor:(options,data)->
    super options,data

    @hide() if (data?.link_embed_hidden_items?["image"]?) or not data.link_options?.hasConfig or not data.link_embed?.images? or data.link_embed?.images?.length < 2
    @embedImageIndex = data.link_embed_image_index or 0

  getEmbedImageIndex:->
    @embedImageIndex

  setEmbedImageIndex:(i=0)->
    @embedImageIndex = i

  click:(event)=>
    if  $(event.target).hasClass "preview_link_switch"

      if ($(event.target).hasClass "next") and (@getData().link_embed?.images?.length-1 > @getEmbedImageIndex() )
        @setEmbedImageIndex @getEmbedImageIndex() + 1
        @$("a.preview_link_switch.previous").removeClass "disabled"

      if ($(event.target).hasClass "previous") and (@getEmbedImageIndex() > 0)
        @setEmbedImageIndex @getEmbedImageIndex() - 1
        @$("a.preview_link_switch.next").removeClass "disabled"

      @getDelegate().embedImage.setSrc @getData().link_embed?.images?[@getEmbedImageIndex()]?.url
      @getDelegate().getDelegate().setEmbedImageIndex @getEmbedImageIndex()
      # @$("div.preview_image img.thumb").attr src : @getData().link_embed?.images?[@getEmbedImageIndex()]?.url
      @$("span.thumb_nr").html @getEmbedImageIndex()+1


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
    <img src="#{@getData().link_embed?.images?[0]?.url}" style="max-width:#{if @options.maxWidth? then @options.maxWidth+"px" else "560px"};max-height:#{if @options.maxHeight? then @options.maxHeight+"px" else "300px"}" title="#{@getData().link_embed?.title or ""}" />
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
    @hide() if (data?.link_embed_hidden_items?["image"]?) or  (data.link_embed?.images?.length is 0)

  setSrc:(url)->
    @$("img.thumb").attr src : url

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <a class="preview_link" target="_blank" href="#{@getData().link_url or @getData().link_embed?.url}">
      <img class="thumb" src="#{@getData().link_embed?.images?[@getData().link_embed_image_index]?.url or "this needs a default url"}" title="#{(@getData().link_embed?.title + (if @getData().link_embed?.author_name then " by "+@getData().link_embed?.author_name else "")) or "untitled"}"/>
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
    @hide() if (data?.link_embed_hidden_items?["title"]?) or not data.link_embed?.title? or data.link_embed?.title.trim() is ""

    if options.hasConfig is yes
      @setClass "has-config"
      @titleInput = new KDInputView
        cssClass     : "preview_title_input hidden"
        name         : "preview_title_input"
        defaultValue : data.link_embed?.title or ""

    else
      @titleInput = new KDCustomHTMLView
        cssClass : "hidden"
        partial : data.link_embed?.title or ""

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  getValue:->
    if @options.hasConfig
      @titleInput.getValue()
    else
      @titleInput.getPartial()

  click:(event)->
    if @options.hasConfig is yes
      event.preventDefault()
      event.stopPropagation()
      @titleInput.show()
      @$("div.preview_title").hide()
      no
    else
      super

  pistachio:->
    """
      {{> @titleInput}}
      <div class="preview_title">#{@getData().link_embed?.title or @getData().title or @getData().link_url or @getData().url}</div>
    """

class EmbedBoxLinkViewDescription extends KDView
  constructor:(options={},data)->
    super options,data
    @options = options
    @hide() if (data?.link_embed_hidden_items?["description"]?) or not data.link_embed?.description? or data.link_embed?.description.trim() is ""

    if options.hasConfig is yes
      @setClass "has-config"
      @descriptionInput = new KDInputView
        type         : "textarea"
        cssClass     : "description_input hidden"
        name         : "description_input"
        defaultValue : data.link_embed?.description or ""

    else
      @descriptionInput = new KDCustomHTMLView
        cssClass : "hidden"
        partial : data.link_embed?.description or ""

  getValue:->
    if @options.hasConfig
      @descriptionInput.getValue()
    else
      @descriptionInput.getPartial()

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  click:(event)->
    if @options.hasConfig is yes
      event.preventDefault()
      event.stopPropagation()
      @descriptionInput.show()
      @descriptionInput.focus()

      @$("div.description").hide()
      no
    else
      super
  pistachio:->
    """
    {{> @descriptionInput}}
    <div class="description #{if (@getData().link_embed?.description or @getData().description) and not("description" in @getData().link_embed_hidden_items) then "" else "hidden"}">#{@getData().link_embed?.description or @getData().description or ""}</div>
    """

class EmbedBoxLinkViewAuthor extends KDView
  constructor:(options,data)->
    super options,data
    @hide() if (data?.link_embed_hidden_items?["author"]?) or not data.link_embed?.author_name?

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
    @hide() if (data?.link_embed_hidden_items?["provider"]?) or not data.link_embed?.provider_name?

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()
  pistachio:->
    """
for <strong>#{@getData().link_embed?.provider_name or @getData().provider_name or "the internet"}</strong>#{if (@getData().link_embed?.provider_url or @getData().provider_url) then " at <a href=\"" +(@getData().link_embed?.provider_url or @getData().provider_url)+"\" target=\"_blank\">"+(@getData().link_embed?.provider_display or @getData().provider_display)+"</a>" else ""}
    """

