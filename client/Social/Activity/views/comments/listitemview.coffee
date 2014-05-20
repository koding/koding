class CommentListItemView extends KDListItemView

  constructor: (options = {}, data) ->

    options.type = "comment"

    super options, data


  click: (event) ->

    KD.utils.showMoreClickHandler event


  createMenu: ->

    data         = @getData()
    {activity}   = @getOptions()
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
      menu['Edit Comment'] = callback: @bound "showEditForm"

    if options.delete
      menu['Delete Comment'] = callback: @bound "showDeleteModal"

    delegate = this

    return new CommentSettingsButton {delegate, menu}


  showEditForm: ->

    @settings.hide()
    @body.hide()
    @editInfo.hide()
    @likeView.hide()
    @replyView?.hide()

    @form = new CommentEditForm delegate: this, @getData()
    @formWrapper.addSubView @form
    @formWrapper.show()

    @form
      .once "Submit", @bound "hideEditForm"
      .once "Cancel", @bound "hideEditForm"


  hideEditForm: ->

    {meta: {createdAt, updatedAt}} = @getData()

    @settings.show()
    @likeView.show()
    @replyView?.show()
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
      click    : @bound "reply"


  reply: (event) ->

    KD.utils.stopDOMEvent event

    {account: {constructorName, _id}} = @getData()
    KD.remote.cacheable constructorName, _id, (err, account) =>

      return KD.showError err  if err

      @getDelegate().emit "Mention", account.profile.nickname


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
