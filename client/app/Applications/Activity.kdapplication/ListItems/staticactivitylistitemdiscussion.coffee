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

  highlightCode:=>
    @$("div.discussion-body-container span.data pre").each (i,element)=>
      hljs.highlightBlock element

  prepareExternalLinks:->
    @$('p.body a[href^=http]').attr "target", "_blank"

  render:->
    super()
    @highlightCode()

  applyTextExpansions:(str = "")->
    str = @utils.expandUsernames str

    if str.length > 500
      visiblePart = str.substr 0, 500
      # this breaks the markdown sanitizer
      # morePart = "<span class='more'><a href='#' class='more-link'>show more...</a>#{str.substr 501}<a href='#' class='less-link'>...show less</a></span>"
      str = visiblePart  + " ..." #+ morePart

    return str

  pistachio:->
    """
    <div class="activity-discussion-container">
      <span class="avatar">{{> @avatar}}</span>
      <div class='activity-item-right-col'>
        <h3 class='comment-title'>{{@applyTextExpansions #(title)}}</h3>
        <div class="activity-content-container discussion">
          <p class="body no-scroll has-markdown force-small-markdown">
            {{@utils.expandUsernames @utils.applyMarkdown #(body)}}
          </p>
        </div>
        <footer class='clearfix'>
          <div class='type-and-time'>
            <span class='type-icon'></span> by {{> @author}}
            <time>{{$.timeago #(meta.createdAt)}}</time>
            {{> @tags}}
          </div>
          {{> @actionLinks}}
        </footer>
      </div>
    </div>
    """

