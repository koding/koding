class ContentDisplayDiscussion extends KDView

  constructor:(options = {}, data)->

    options.tooltip or=
      title     : "Discussion"
      offset    : 3
      selector  : "span.type-icon"

    super options, data

    @setClass 'activity-item discussion'

    origin =
      constructorName  : data.originType
      id               : data.originId

    @avatar = new AvatarStaticView
      tagName : "span"
      size    : {width: 50, height: 50}
      origin  : origin

    @author = new ProfileLinkView {origin:origin}

    @opinionBox = new OpinionView null, data

    @opinionForm = new OpinionFormView
      cssClass : "opinion-container"
      callback  : (data)=>
        # do not use JDiscussion::reply here
        @getData().reply data, (err, opinion) =>
          callback? err, opinion
          if err
            new KDNotificationView type : "mini", title : "There was an error, try again later!"
          else
            @emit "OwnOpinionHasArrived", opinion
            log "here it was submitted", @, @getData()
            @opinionBox.opinionList.emit "AllOpinionsLinkWasClicked"
    , data

    @actionLinks = new DiscussionActivityActionsView
      delegate : @opinionBox.opinionList
      cssClass : "comment-header"
    , data

    @heartBox = new HelpBox
      subtitle : "About Status Updates"
      tooltip  :
        title  : "This a public wall, here you can share anything with the Koding community."

    @tags = new ActivityChildViewTagGroup
      itemsToShow   : 3
      subItemClass  : TagLinkView
    , data.tags

  viewAppended:()->
    # return if @getData().constructor is bongo.api.CStatusActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    # temp for beta
    # take this bit to comment view
    if @getData().repliesCount? and @getData().repliesCount > 0
      opinionController = @opinionBox.opinionController
      opinionController.fetchAllOpinions 0, (err, opinions)->
        opinionController.removeAllItems()
        opinionController.instantiateListItems opinions

  pistachio:->
    """
    <span>
      {{> @avatar}}
      <span class="author">AUTHOR</span>
    </span>
    <div class='activity-item-right-col'>
      <h3>{{#(title)}}</h3>
      <p class='context'>{{@utils.applyLineBreaks @utils.applyMarkdown @utils.applyTextExpansions #(body)}}</p>
      <footer class='discussion-footer clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          <time>{{$.timeago #(meta.createdAt)}}</time>
          {{> @tags}}
        </div>
        {{> @actionLinks}}
      </footer>
      {{> @opinionBox}}
    <div class="content-display-main-section opinion-form-footer">
    {{> @opinionForm}}
    {{> @heartBox}}
    </div>
    </div>
    """
