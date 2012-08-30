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

    @opinionBoxHeader = new KDCustomHTMLView
      tagName : "div"
      cssClass : "opinion-box-header"
      partial : '<span class="opinion-count">'+data.repliesCount+' Answers</span><span class="opinion-sort">sorted by date</span>'

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
      subtitle : "About Discussions"
      tooltip  :
        title  : "Click me for additional information"
      click :->
        modal = new KDModalView
          title          : "Additional information on Discussions"
          content        : "<div class='modalformline signature'><h3>Hi!</h3><p>My name is Arvid, i just recently started to work for Koding and I am responsible for the implementation of Discussions.</p><p>Should you run into bugs, experience strange and/or unexpected behavior or have questions on how to use this feature, please don't hesitate to drop me a mail here: "+@utils.applyTextExpansions("@arvidkahl")+"</p><p>--arvid</p></div>"
          height         : "auto"
          overlay        : yes
          buttons        :
            Okay       :
              style      : "modal-clean-gray"
              loader     :
                color    : "#ffffff"
                diameter : 16
              callback   : =>
                modal.buttons.Okay.hideLoader()
                modal.destroy()

    @tags = new ActivityChildViewTagGroup
      itemsToShow   : 3
      subItemClass  : TagLinkView
    , data.tags

    @deleteDiscussionLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        title     : "Delete your discussion"
        href      : '#'
      cssClass    : 'delete-link hidden'

    @editDiscussionLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        title     : "Edit your discussion"
        href      : '#'
      cssClass    : 'edit-link hidden'

    # activity = @getDelegate().getData()
    bongo.cacheable data.originId, "JAccount", (err, account)=>
      loggedInId = KD.whoami().getId()
      if loggedInId is data.originId or       # if comment owner
         # loggedInId is activity.originId or   # if activity owner
         KD.checkFlag "super-admin", account  # if super-admin

        @listenTo
          KDEventTypes       : "click"
          listenedToInstance : @editDiscussionLink
          callback           : =>
            if @editDiscussionForm?
              @editDiscussionForm?.destroy()
              delete @editDiscussionForm
            else
              @editDiscussionForm = new DiscussionFormView
                title : "edit-discussion"
                cssClass : "edit-discussion-form"
                callback : (data)=>
                  @getData().modify data, (err, discussion) =>
                    callback? err, opinion
                    if err
                      new KDNotificationView title : "Your changes weren't saved.", type :"mini"
                    else
                      @emit "DiscussionWasEdited", discussion
                      @editDiscussionForm.setClass "hidden"
              , data

              @addSubView @editDiscussionForm, "p.discussion-body", yes

        @listenTo
          KDEventTypes       : "click"
          listenedToInstance : @deleteDiscussionLink
          callback           : => @confirmDeleteDiscussion data

        @editDiscussionLink.unsetClass "hidden"
        @deleteDiscussionLink.unsetClass "hidden"



  confirmDeleteDiscussion:(data)->

    modal = new KDModalView
      title          : "Delete discussion"
      content        : "<div class='modalformline'>Are you sure you want to delete this discussion and all it's opinions and comments?</div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        Delete       :
          style      : "modal-clean-red"
          loader     :
            color    : "#ffffff"
            diameter : 16
          callback   : =>
            data.delete (err)=>
              modal.buttons.Delete.hideLoader()
              modal.destroy()
              unless err then @emit 'DiscussionIsDeleted'
              else new KDNotificationView
                type     : "mini"
                cssClass : "error editor"
                title     : "Error, please try again later!"

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
    <div class='discussion-contents'>
      <div class='discussion-main-opinion'>
        {{> @actionLinks}}
        <h3>{{#(title)}}</h3>

        <footer class='discussion-footer clearfix'>
          <div class='type-and-time'>
            <span class='type-icon'></span> posted by {{> @author}}
            <time>{{$.timeago #(meta.createdAt)}}</time>
            {{> @tags}}
          </div>
        </footer>
        {{> @editDiscussionLink}}
        {{> @deleteDiscussionLink}}
        <p class='context discussion-body'>{{@utils.expandUsernames @utils.applyMarkdown #(body)}}</p>
      </div>
    </div>
    {{> @opinionBoxHeader}}
    {{> @opinionBox}}
    <div class="content-display-main-section opinion-form-footer">
        {{> @opinionForm}}
        {{> @heartBox}}
    </div>

    """
