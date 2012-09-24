class DiscussionActivityItemView extends ActivityItemChild

  constructor:(options, data)->

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

    data.on 'ReplyIsAdded', (reply)=>

      # JDiscussion needs the new Opinion
      if data.bongo_.constructorName is "JDiscussion"

        # Why this workaround, you ask?
        #
        #  Getting the data from the JDiscussion.reply event "ReplyIsAdded"
        #  without JSONifying it locks up the UI for up to 10 seconds.

        # Create new JOpinion and convert JSON into Object
        newOpinion = new bongo.api.JOpinion
        opinionData = JSON.parse(reply.opinionData)

        # Copy JSON data to the newly created JOpinion
        for variable of opinionData
          newOpinion[variable] = opinionData[variable]

        # Updating the local data object, then adding the item to the box
        # and increasing the count box

        if data.opinions?
          data.opinions.push newOpinion
        else
          data.opinions = [newOpinion]

        # The following line would add the new Opinion to the View
        # @opinionBox.opinionList.addItem newOpinion, null, {type : "slideDown", duration : 100}

        @opinionBox.opinionList.emit "NewOpinionHasArrived"

    @opinionBox = new DiscussionActivityOpinionView
      cssClass    : "activity-opinion-list comment-container"
    , data


  viewAppended:()->
    return if @getData().constructor is bongo.api.CDiscussionActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    @$("pre").addClass "prettyprint"
    prettyPrint()

    if @$("p.comment-body").height() >= 250
      @$("div.view-full-discussion").show()
    else
      @$("div.view-full-discussion").hide()


  render:->
    super()

    @$("pre").addClass "prettyprint"
    prettyPrint()

  click:(event)->
    if $(event.target).closest("[data-paths~=title],[data-paths~=body]")
      if not $(event.target).is("a.action-link, a.count, .like-view")
        appManager.tell "Activity", "createContentDisplay", @getData()

  applyTextExpansions:(str = "")->
    str = @utils.expandUsernames @utils.applyMarkdown str

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
      {{> @settingsButton}}
      <h3 class='hidden'></h3>
      <p class="comment-title">{{@applyTextExpansions #(title)}}</p>
      <p class="comment-body has-markdown">{{@applyTextExpansions #(body)}}</p>
      <div class="view-full-discussion">
        <a href="#">View the full Discussion</a>
      </div>
      <footer class='clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          <time>{{$.timeago #(meta.createdAt)}}</time>
          {{> @tags}}
        </div>
        {{> @actionLinks}}
      </footer>
      {{> @opinionBox}}
    </div>
  </div>
    """

