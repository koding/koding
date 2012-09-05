class DiscussionActivityItemView extends ActivityItemChild

  constructor:(options, data)->

    # in case of Discussions, the comments can go beyond one level. we need another view for that
    options = $.extend
      cssClass    : "activity-item discussion"
      tooltip     :
        title     : "Discussion"
        offset    : 3
        selector  : "span.type-icon"
    ,options

    super options,data

    @actionLinks = new DiscussionActivityActionsView
      delegate : @commentBox.opinionList
      cssClass : "reply-header"
    , data

    @commentBox.destroy()

    if data.repliesCount > 0
      @opinionBox = new DiscussionActivityOpinionView
        cssClass : "activity-opinion-list comment-container"
      , data
    else
      @opinionBox = new KDCustomHTMLView
        tagName:"a"
        cssClass:"first-reply-link"
        attributes:
          title:"Be the first to reply"
          href:"#"
        partial:"Be the first to reply!"
        click:->
          appManager.tell "Activity", "createContentDisplay", data


  viewAppended:()->
    return if @getData().constructor is bongo.api.CDiscussion
    super()
    @setTemplate @pistachio()
    @template.update()

    # if @getData().repliesCount? and @getData().repliesCount > 0
    #   opinionController = @opinionBox.opinionController
    #   opinionController.fetchRelativeOpinions 3, 0, (err, opinions)=>
    #     for opinion in opinions
    #       @opinionBox.opinionList.addItem opinion, null
    #     @opinionBox.opinionList.emit "RelativeOpinionsWereAdded"

    # if @getData().repliesCount > 3
    #   @opinionBox.addSubView test = new KDCustomHTMLView
    #     title : "show more"
    #     tagName : "a"
    #     cssClass : "activity-opinion-more"
    #     attributes :
    #       href: "#"
    #     partial : "View all the opinions ("+(@getData().repliesCount-3)+" more)"
    #     click:->
    #       log "pew"

  click:(event)->
    if $(event.target).is("[data-paths~=title]")
      appManager.tell "Activity", "createContentDisplay", @getData()

  applyTextExpansions:(str = "")->

    str = @utils.applyTextExpansions str

    # FIXME: 500 chars is a naive separation, check if it is in a tag (<a> etc) and
    # make the separation after or before the tag in plain text.

    if str.length > 500
      visiblePart = str.substr 0, 500
      morePart = "<span class='more'><a href='#' class='more-link'>show more...</a>#{str.substr 501}<a href='#' class='less-link'>...show less</a></span>"
      str = visiblePart + morePart

    return str
  pistachio:->
    """
    {{> @settingsButton}}
    <span class="avatar">{{> @avatar}}</span>
    <div class='activity-item-right-col'>
      <h3 class='hidden'></h3>
      <p>{{@applyTextExpansions #(title)}}</p>
      {{> @opinionBox}}
      <footer class='clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          <time>{{$.timeago #(meta.createdAt)}}</time>
          {{> @tags}}
        </div>
        {{> @actionLinks}}
      </footer>
    </div>
    """

