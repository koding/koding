class CommentListItemView extends KDListItemView
  constructor:(options,data)->

    options.type     or= "comment"
    options.cssClass or= "kdlistitemview kdlistitemview-comment"

    super options,data

    data = @getData()

    originId    = data.getAt('originId')
    originType  = data.getAt('originType')
    deleterId   = data.getAt('deletedBy')?.getId?()

    origin =
      constructorName  : originType
      id               : originId

    @avatar = new AvatarView {
      size     :
        width  : options.avatarWidth or 30
        height : options.avatarHeight or 30
      origin
    }

    @author = new ProfileLinkView { origin }

    if deleterId? and deleterId isnt originId
      @deleter = new ProfileLinkView {}, data.getAt('deletedBy')

    @deleteLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        href      : '#'
      cssClass    : 'delete-link hidden'

    activity = @getDelegate().getData()

    loggedInId = KD.whoami().getId()
    if loggedInId is data.originId or       # if comment/review owner
       loggedInId is activity.originId or   # if activity/app owner
       KD.checkFlag "super-admin", KD.whoami()  # if super-admin
      @deleteLink.unsetClass "hidden"
      @listenTo
        KDEventTypes       : "click"
        listenedToInstance : @deleteLink
        callback           : => @confirmDeleteComment data

    @likeView = new LikeViewClean { tooltipPosition : 'sw' }, data

  applyTooltips:->
    @$("p.comment-body > span.data > a").each (i,element)=>
      href = $(element).attr("data-original-url") or $(element).attr("href") or ""

      twOptions = (title) ->
         title : title, placement : "above", offset : 3, delayIn : 300, html : yes, animate : yes, className : "link-expander"
      unless /^(#!)/.test href
        $(element).twipsy twOptions("External Link : <span>"+href+"</span>")

      element

  render:->
    if @getData().getAt 'deletedAt'
      @emit 'CommentIsDeleted'
    @updateTemplate()
    @applyTooltips()
    super

  viewAppended:->
    @updateTemplate yes
    @template.update()
    @applyTooltips()

  click:(event)->

    if $(event.target).is("span.collapsedtext a.more-link")
      @$("span.collapsedtext").addClass "show"
      @$("span.collapsedtext").removeClass "hide"

    if $(event.target).is("span.collapsedtext a.less-link")
      @$("span.collapsedtext").removeClass "show"
      @$("span.collapsedtext").addClass "hide"

    if $(event.target).is "span.avatar a, a.user-fullname"
      {originType, originId} = @getData()
      KD.remote.cacheable originType, originId, (err, origin)->
        unless err
          appManager.tell "Members", "createContentDisplay", origin

  confirmDeleteComment:(data)->
    {type} = @getOptions()
    modal = new KDModalView
      title          : "Delete #{type}"
      content        : "<div class='modalformline'>Are you sure you want to delete this #{type}?</div>"
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
              # unless err then @emit 'CommentIsDeleted'
              # else
              if err then new KDNotificationView
                type     : "mini"
                cssClass : "error editor"
                title    : "Error, please try again later!"

  updateTemplate:(force = no)->
    # TODO: these pistachios are written in JS, pending a solution
    #  to the problem of statically not being able to find pistachios unless
    #  they are contained inside a property called "pistachio".
    if @getData().getAt 'deletedAt'
      {type} = @getOptions()
      @setClass "deleted"
      if @deleter
        pistachio = "<div class='item-content-comment clearfix'><span>{{> @author}}'s #{type} has been deleted by {{> @deleter}}.</span></div>"
      else
        pistachio = "<div class='item-content-comment clearfix'><span>{{> @author}}'s #{type} has been deleted.</span></div>"
      @setTemplate pistachio
    else if force
      @setTemplate @pistachio()

  pistachio:->
    """
    <div class='item-content-comment clearfix'>
      <span class='avatar'>{{> @avatar}}</span>
      <div class='comment-contents clearfix'>
        <p class='comment-body'>
          {{> @author}}
          {{@utils.applyTextExpansions #(body), yes}}
        </p>
        {{> @deleteLink}}
        <time>{{$.timeago #(meta.createdAt)}}</time>
        {{> @likeView}}
      </div>
    </div>
    """
