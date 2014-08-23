class CommentListItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type = 'comment'

    super options, data

    (KD.singleton 'mainController').on 'AccountChanged', @bound 'addMenu'

    @initDataEvents()


  initDataEvents: ->

    data = @getData()

    data.on 'update', @bound 'handleUpdate'


  handleUpdate: ->

    { updatedAt, createdAt } = @getData()

    if updatedAt > createdAt
    then @body.setClass 'edited'
    else @body.unsetClass 'edited'


  click: (event) -> KD.utils.showMoreClickHandler event


  showEditForm: ->

    @menuWrapper.hide()
    @body.hide()
    @body.unsetClass 'edited'
    @likeView.hide()
    @replyView?.hide()

    activity   = @getData()
    @editInput = new CommentInputEditWidget {}, activity

    @formWrapper.addSubView @editInput
    @formWrapper.show()

    @editInput
      .once 'SubmitStarted', @bound 'hideEditForm'
      .once 'Cancel', @bound 'hideEditForm'


  hideEditForm: ->

    { createdAt, updatedAt } = @getData()

    @menuWrapper.show()
    @likeView.show()
    @replyView?.show()
    @editInput.destroy()
    @body.show()
    @editInput.hide()


  showDeleteModal: ->

    modal = new CommentDeleteModal {}, @getData()
    modal.once "DeleteClicked"   , @bound "hide"
    modal.once "DeleteConfirmed" , @bound "destroy"
    modal.once "DeleteError"     , @bound "show"


  createReplyLink: ->

    return @replyView = new KDView tagName: 'span'  if KD.isMyPost @getData()

    @replyView   = new CustomLinkView
      cssClass   : 'action-link reply-link'
      title      : 'Mention'
      bind       : 'mouseenter mouseleave'
      click      : @bound 'reply'
      mouseenter : => @emit 'MouseEnterHappenedOnMention', this
      mouseleave : => @emit 'MouseLeaveHappenedOnMention', this


  reply: (event) ->

    KD.utils.stopDOMEvent event

    @emit "MentionStarted", this

    {account: {constructorName, _id}} = @getData()
    KD.remote.cacheable constructorName, _id, (err, account) =>

      return KD.showError err  if err

      @emit 'MentionHappened', account.profile.nickname


  addMenu: ->

    comment       = @getData()
    {activity}    = @getOptions()
    owner         = KD.isMyPost comment
    postOwner     = KD.isMyPost activity
    hasPermission = KD.utils.hasPermission.bind()
    canEdit       = hasPermission 'edit comments'
    canEditOwn    = hasPermission 'edit own comments'

    if canEdit or (owner and canEditOwn)
      @addMenuView edit: yes, delete: yes
    else if postOwner
      @addMenuView delete: yes


  addMenuView: (options) ->

    @menuWrapper.destroySubViews()

    menu = {}

    if options.edit
      menu['Edit Comment'] = callback: @bound 'showEditForm'

    if options.delete
      menu['Delete Comment'] = callback: @bound 'showDeleteModal'

    delegate = this

    @menuWrapper.addSubView new CommentSettingsButton {delegate, menu}


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
        width     : 38
        height    : 38

    @author = new ProfileLinkView {origin}

    @body       = new JCustomHTMLView
      cssClass  : 'comment-body-container'
      pistachio : '{p{KD.utils.applyTextExpansions #(body), yes}}'
    , data

    @formWrapper = new KDCustomHTMLView cssClass: 'edit-comment-wrapper hidden'

    @body.setClass 'edited'  if updatedAt > createdAt

    # if deleterId? and deleterId isnt origin.id
    #   @deleter = new ProfileLinkView {}, data.getAt 'deletedBy'

    @menuWrapper = new KDCustomHTMLView
    @addMenu()
    @createReplyLink()

    @likeView    = new CommentLikeView {}, data
    @timeAgoView = new KDTimeAgoView {}, createdAt

    JView::viewAppended.call this


  # updateTemplate: (force = no) ->

  #   { createdAt, deletedAt } = @getData()

  #   if deletedAt > createdAt
  #     {type} = @getOptions()
  #     @setClass 'deleted'
  #     if @deleter
  #       pistachio = '<div class="item-content-comment clearfix"><span>{{> @author}}\'s #{type} has been deleted by {{> @deleter}}.</span></div>'
  #     else
  #       pistachio = '<div class="item-content-comment clearfix"><span>{{> @author}}\'s #{type} has been deleted.</span></div>'
  #     @setTemplate pistachio
  #   else if force
  #     @setTemplate @pistachio()


  pistachio: ->
    '''
    {{> @avatar}}
    <div class='comment-contents clearfix'>
    {{> @author}}
    {{> @body}}
    {{> @formWrapper}}
    {{> @menuWrapper}}
    {{> @likeView}}
    {{> @replyView}}
    {{> @timeAgoView}}
    </div>
    '''
