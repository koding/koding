class OpinionListItemView extends KDListItemView

  constructor:(options,data)->
    options = $.extend
      type      : "opinion"
      cssClass  : "kdlistitemview kdlistitemview-comment"
    ,options

    super options,data

    data = @getData()

    # listener for when this gets deleted by the creator JAccount
    data.on "OpinionIsDeleted", (things)=>
      @hide()
      delete @

    originId    = data.getAt('originId')
    originType  = data.getAt('originType')
    deleterId   = data.getAt('deletedBy')?.getId?()

    origin =
      constructorName  : originType
      id               : originId

    @needsToResize = no

    @avatar = new AvatarView {
      size    :
        width: 40
        height: 40
      origin
    }

    @author = new ProfileLinkView {
      origin
    }

    if deleterId? and deleterId isnt originId
      @deleter = new ProfileLinkView {}, data.getAt('deletedBy')

    @deleteLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        title     : "Delete your opinion"
        href      : '#'
      cssClass    : 'delete-link hidden'

    @editLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        title     : "Edit your opinion"
        href      : '#'
      cssClass    : 'edit-link hidden'

    @commentBox = new CommentView null, data

    @commentBox.on "RefreshTeaser",=>
      @parent.emit "RefreshTeaser"

    @actionLinks = new ActivityActionsView
      delegate : @commentBox.commentList
      cssClass : "opinion-comment-header"
    , data

    @tags = new ActivityChildViewTagGroup
      itemsToShow   : 3
      itemClass  : TagLinkView
    , data.meta.tags

    @smaller = new KDCustomHTMLView
        tagName    : "a"
        cssClass   : "opinion-size-link hidden"
        attributes :
          href     : "#"
          title    : "Show less"
        partial    :  "See less…"
        click      :(event)=>
          event.preventDefault()
          @markup.css "max-height":"300px"
          @larger.show()
          @smaller.hide()

    @larger = new KDCustomHTMLView
        tagName    : "a"
        cssClass   : "opinion-size-link hidden"
        attributes :
          href     : "#"
          title    : "Show more"
        partial    :  "See more…"
        click      :=>
          @markup.css maxHeight : @textMaxHeight+20
          @smaller.show()
          @larger.hide()

    @textMaxHeight = 0

    # activity = @getDelegate().getData()

    loggedInId = KD.whoami().getId()
    if loggedInId is data.originId or       # if comment owner
       # loggedInId is activity.originId or     # activity owner can remove opinion
       KD.checkFlag "super-admin", KD.whoami()  # if super-admin

      @editLink.on "click", =>

          if @editForm?
            @editForm?.destroy()
            delete @editForm
            @$("p.opinion-body").show()
            @$(".opinion-size-links").show() if @needsToResize

          else
            @editForm = new OpinionFormView
              submitButtonTitle : "Save your changes"
              title             : "edit-opinion"
              cssClass          : "edit-opinion-form opinion-container"
              callback          : (data)=>
                @getData().modify data, (err, opinion) =>
                  @$("p.opinion-body").show()
                  callback? err, opinion
                  @editForm.reset()
                  @editForm.submitOpinionBtn.hideLoader()
                  if err
                    new KDNotificationView title : "Your changes weren't saved.", type :"mini"
                  else
                    @getDelegate().emit "RefreshTeaser", ->
                    @emit "OwnOpinionWasAdded", opinion
                    @editForm.setClass "hidden"
                    @$("p.opinion-body").show()
                    @$(".opinion-size-links").show() if @needsToResize
            , data

            @addSubView @editForm, "p.opinion-body-edit", yes
            @$("p.opinion-body").hide()
            @$(".opinion-size-links").hide() if @needsToResize

      @deleteLink.on "click", =>
        @confirmDeleteOpinion data

      @editLink.unsetClass "hidden"
      @deleteLink.unsetClass "hidden"

  render:->
    super()

    # @$("pre").addClass "prettyprint"
    @$("p.opinion-body span.data pre").each (i,element)=>
      element = hljs.highlightBlock element

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

    @markup = @$("p.opinion-body")
    maxHeight = 300

    if @markup.height()>maxHeight
      @needsToResize = yes
      @textMaxHeight = @markup.height()
      @markup.css {maxHeight}
      @larger.show()

    # @$("pre").addClass "prettyprint"
    # prettyPrint()

    @$("p.opinion-body span.data pre").each (i,element)=>
      element = hljs.highlightBlock element

  click:(event)->

    event.preventDefault() unless $(event.target).attr("target") is "_blank"

    if $(event.target).is "span.avatar a, a.user-fullname"
      {originType, originId} = @getData()
      KD.remote.cacheable originType, originId, (err, origin)->
        unless err
          log origin
          # KD.getSingleton('router').handleRoute "/Member/#{@getData().slug}", state:@getData()

          appManager.tell "Members", "createContentDisplay", origin


  confirmDeleteOpinion:(data)->
    modal = new KDModalView
      title          : "Delete opinion"
      content        : "<div class='modalformline'>Are you sure you want to delete this opinion?</div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        Delete       :
          style      : "modal-clean-red"
          loader     :
            color    : "#ffffff"
            diameter : 16
          callback   : =>
            @hide()
            data.delete (err)=>
              modal.buttons.Delete.hideLoader()
              modal.destroy()
              unless err

                # tell the JDiscussion what happened
                @getDelegate().getData().emit "OpinionWasRemoved",yes

                # this destroys the listviewitem itself
                @destroy()

              else @show()

              if err then new KDNotificationView
                type     : "mini"
                cssClass : "error editor"
                title    : "Error, please try again later!"

  pistachio:->
    """
    <div class='item-content-opinion clearfix'>
      <span class='avatar'>{{> @avatar}}</span>
      <div class='opinion-contents clearfix'>
        {{> @deleteLink}}
        {{> @editLink}}
        <p class="opinion-body-edit"></p>
        <p class='opinion-body has-markdown'>
          {{@utils.expandUsernames(@utils.applyMarkdown(#(body)),"pre")}}
        </p>
        <div class="opinion-size-links">
          {{> @larger}}
          {{> @smaller}}
        </div>
    </div>
        <footer class='opinion-footer clearfix'>
          <div class='type-and-time'>
            <span class='type-icon'></span> answer by {{> @author}} •
            <time>{{$.timeago #(meta.createdAt)}}</time>
            {{> @tags}}
            {{> @actionLinks}}
          </div>
        </footer>
    </div>
    <div class='item-content-opinion-comments clearfix'>
      <div class='opinion-comment'>
        {{> @commentBox}}
      </div>
    </div>
    """
