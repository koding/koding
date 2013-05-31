class StaticTutorialActivityItemView extends StaticActivityItemChild

  constructor:(options, data)->

    unless data.opinionCount?
      # log "This is legacy data. Updating Counts."
      data.opinionCount = data.repliesCount or 0
      data.repliesCount = 0

    options = $.extend
      cssClass    : "activity-item tutorial"
      tooltip     :
        title     : "Tutorial"
        offset    :
          top     : 3
          left    : -5
        selector  : "span.type-icon"
    ,options

    super options,data

    @embedOptions = $.extend {}, options,
      hasDropdown : no
      delegate : @

    @previewImage = new KDCustomHTMLView
      tagName : "img"
      cssClass : "tutorial-preview-image"
      attributes:
        src: @utils.proxifyUrl(data.link?.link_embed?.images?[0]?.url or "")
        title:"View the full Tutorial"
        alt:"View the full tutorial"
        "data-paths":"preview"

    @previewImage.hide() unless data.link?.link_embed?.images?[0]?.url

  highlightCode:->
    @$("div.body span.data pre").each (i,element)=>
      hljs.highlightBlock element

  prepareExternalLinks:->
    @$('div.body a[href^=http]').attr "target", "_blank"

  viewAppended:()->
    super()

    @setTemplate @pistachio()
    @template.update()

    @highlightCode()

  render:->
    super()
    @highlightCode()

  click:(event)->
    if $(event.target).is("[data-paths~=preview]")

      @videoPopup = new VideoPopup
        delegate : @previewImage
        title : @getData().link?.link_embed?.title or "Untitled Video"
        thumb : @getData().link?.link_embed?.images?[0]?.url
      ,@getData().link?.link_embed?.object?.html

      @videoPopup.openVideoPopup()

  applyTextExpansions:(str = "")->
    str = @utils.expandUsernames str

    if str?.length > 500
      visiblePart = str.substr 0, 500
      # this breaks the markdown sanitizer
      # morePart = "<span class='more'><a href='#' class='more-link'>show more...</a>#{str.substr 501}<a href='#' class='less-link'>...show less</a></span>"
      str = visiblePart  + " ..." #+ morePart

    return str

  pistachio:->
    """
    <div class="content-item">
      <div class='title'>
        <span class="text">
          {{@applyTextExpansions #(title)}}
        </span>
        <div class='create-date'>
          <span class='type-icon'></span>
          {time{@formatCreateDate #(meta.createdAt)}}
          {{> @tags}}
          {{> @actionLinks}}
        </div>
      </div>
      <div class="tutorial">
        {{> @previewImage}}
        <div class="body has-markdown">
          {{@utils.applyMarkdown #(body)}}
        </div>
      </div>
    </div>
    """

