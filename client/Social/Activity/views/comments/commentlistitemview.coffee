class CommentListItemView extends KDListItemView

  constructor: (options = {}, data) ->

    options.type = "comment"

    super options, data

    @on 'CommentUpdated', @bound "update"
    @on 'CommentUpdateCancelled', @bound "hideEditForm"


  click: (event) ->

    KD.utils.showMoreClickHandler event


  update: (body = "") ->

    return  unless comment.trim().length

    data = @getData()
    data.modify body, (err) =>

      if err
        @hideEditForm()
        new KDNotificationView title: err.message
        return

      data.body = body
      data.meta.updatedAt = new Date
      @hideEditForm()


  createMenu: ->

    data         = @getData()
    activity     = @getDelegate().getData()
    isOwner      = KD.isMyPost activity or KD.isMyPost data
    canEdit      = "edit comments" in KD.config.permissions
    canDeleteOwn = (KD.isMyPost(data) and "edit own comments" in KD.config.permissions)

    @settings =
      if canEdit
      then @getSettingsButton edit: yes, delete: yes
      else if isOwner or canDeleteOwn
      then @getSettingsButton delete: yes
      else KDView


  getSettingsButton: (options) ->

    menu = {}

    if options.edit
      menu['Edit'] = callback: @bound "showEditForm"

    if options.delete
      menu['Delete'] = callback: @bound "showDeleteModal"

    delegate = this

    return new CommentSettingsButton {delegate, menu}


  showEditForm: ->

    @settings.hide()
    @body.hide()
    @editInfo.hide()

    @form = new EditCommentForm delegate: this, @getData()
    @formWrapper.addSubView @form
    @formWrapper.show()


  hideEditForm: ->

    {meta: {createdAt, updatedAt}} = @getData()

    @settings.show()
    @form.destroy()
    @body.show()
    @editInfo.show()  if updatedAt > createdAt
    @form.hide()


  showDeleteModal: ->

    new CommentDeleteModal {}, @getData()


  createReplyLink: ->

    return @replyView = new KDView tagName: "span"  if KD.isMyPost @getData()

    @replyView = new CustomLinkView
      cssClass : "action-link reply-link"
      title    : "Mention"
      click    : (event) =>

        KD.utils.stopDOMEvent event

        {account: {constructorName, _id}} = @getData()

        KD.remote.cacheable constructorName, _id, (err, account) =>

          @getDelegate().emit 'ReplyLinkClicked', account.profile.nickname


  viewAppended: ->

    data = @getData()
    {account} = data
    {createdAt, deletedAt, updatedAt} = data

    origin            =
      constructorName : account.constructorName
      id              : account._id

    @avatar       = new AvatarView
      origin      : origin
      showStatus  : yes
      size        :
        width     : 40
        height    : 40

    @author = new ProfileLinkView {origin}

    @body       = new KDCustomHTMLView
      cssClass  : "comment-body-container"
      pistachio : "{p{KD.utils.applyTextExpansions #(body), yes}}"
    , data

    @formWrapper = new KDCustomHTMLView cssClass: "edit-comment-wrapper hidden"

    @editInfo   = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "hidden edited"
      pistachio : "edited"

    @editInfo.show()  if updatedAt > createdAt

    # if deleterId? and deleterId isnt origin.id
    #   @deleter = new ProfileLinkView {}, data.getAt "deletedBy"

    @createMenu()
    @createReplyLink()

    @likeView    = new CommentLikeView {}, data
    @timeAgoView = new KDTimeAgoView {}, createdAt

    JView::viewAppended.call this


  # updateTemplate: (force = no) ->

  #   {meta: {createdAt, deletedAt}} = @getData()

  #   if deletedAt > createdAt
  #     {type} = @getOptions()
  #     @setClass "deleted"
  #     if @deleter
  #       pistachio = "<div class='item-content-comment clearfix'><span>{{> @author}}'s #{type} has been deleted by {{> @deleter}}.</span></div>"
  #     else
  #       pistachio = "<div class='item-content-comment clearfix'><span>{{> @author}}'s #{type} has been deleted.</span></div>"
  #     @setTemplate pistachio
  #   else if force
  #     @setTemplate @pistachio()


  pistachio: ->
    """
      {{> @avatar}}
      <div class='comment-contents clearfix'>
      {{> @author}}
      {{> @body}}
      {{> @formWrapper}}
      {{> @editInfo}}
      {{> @settings}}
      {{> @likeView}}
      {{> @replyView}}
      {{> @timeAgoView}}
      </div>
    """
