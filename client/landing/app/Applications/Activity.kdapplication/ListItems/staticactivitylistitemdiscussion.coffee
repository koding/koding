class StaticDiscussionActivityItemView extends StaticActivityItemChild

  constructor:(options, data)->

    unless data.opinionCount?
      # log "This is legacy data. Updating Counts."
      data.opinionCount = data.repliesCount or 0
      data.repliesCount = 0

    options = $.extend
      cssClass    : "activity-item discussion"
      tooltip     :
        title     : "Discussion"
        offset    :
          top     : 3
          left    : -5
        selector  : "span.type-icon"
    ,options

    super options,data

  viewAppended:()->
    super
    @setTemplate @pistachio()
    @template.update()

    @highlightCode()

  highlightCode:->
    @$("div.discussion-body-container span.data pre").each (i,element)=>
      hljs.highlightBlock element

  prepareExternalLinks:->
    @$('p.body a[href^=http]').attr "target", "_blank"

  render:->
    super()
    @highlightCode()

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
          {{ @applyTextExpansions #(title)}}
        </span>
        <div class='create-date'>
          <span class='type-icon'></span>
          {time{@formatCreateDate #(meta.createdAt)}}
          {{> @tags}}
          {{> @actionLinks}}
        </div>
      </div>
      <div class="body has-markdown">
        {{@utils.expandUsernames @utils.applyMarkdown #(body)}}
      </div>
    </div>
    """

