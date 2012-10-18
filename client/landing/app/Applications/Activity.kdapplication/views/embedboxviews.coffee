class EmbedBoxLinkView extends KDView
  constructor:(options,data)->
    super options,data

    @embedImage = new EmbedBoxLinkViewImage
      cssClass : "preview_image"
      delegate : @
    ,data

    @embedText = new EmbedBoxLinkViewText
      cssClass : "preview_text"
      delegate : @
    ,data

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @embedImage}}
    {{> @embedText}}
    """

 # html = """
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
 #            """

class EmbedBoxLinkViewImage extends KDView
  constructor:(options,data)->
    super options,data

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
        href : data.link_url
        target : "_blank"
    , data
    @embedAuthor = new EmbedBoxLinkViewAuthor
      cssClass : "author_info"
    , data
    @embedProvider = new EmbedBoxLinkViewProvider
      cssClass : "provider_info"
    , data
    @embedDescription = new EmbedBoxLinkViewDescription
      tagName : "a"
      cssClass : "description"
      attributes :
        href : data.link_url
        target: "_blank"
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
  constructor:(options,data)->
    super options,data

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()
  pistachio:->
    """
      <div class="preview_title">#{@getData().link_embed?.title or @getData().link_url}</div>
    """

class EmbedBoxLinkViewDescription extends KDView
  constructor:(options,data)->
    super options,data


  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()
  pistachio:->
    """
<div class="description #{if @getData().link_embed?.description and not("description" in @getData().link_embed_hidden_items) then "" else "hidden"}">#{@getData().link_embed?.description or ""}</div>
    """

class EmbedBoxLinkViewAuthor extends KDView
  constructor:(options,data)->
    super options,data

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()
  pistachio:->
    """
    written by <a href="#{@getData().link_embed?.author_url or "#"}" target="_blank">#{@getData().link_embed?.author_name}</a>
    """

class EmbedBoxLinkViewProvider extends KDView
  constructor:(options,data)->
    super options,data

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()
  pistachio:->
    """
for <strong>#{@getData().link_embed?.provider_name or "the internet"}</strong>#{if @getData().link_embed?.provider_url then " at <a href=\"" +@getData().link_embed?.provider_url+"\" target=\"_blank\">"+@getData().link_embed?.provider_display+"</a>" else ""}
    """

