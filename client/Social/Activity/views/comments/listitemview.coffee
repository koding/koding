class CommentListItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type = 'comment'

    super options, data

    (KD.singleton 'mainController').on 'AccountChanged', @bound 'addMenu'


  click: (event) -> KD.utils.showMoreClickHandler event


  showEditForm: ->

    @menuWrapper.hide()
    @body.hide()
    @editInfo.hide()
    @likeView.hide()
    @replyView?.hide()

    @form = new CommentEditForm delegate: this, @getData()
    @formWrapper.addSubView @form
    @formWrapper.show()

    @form
      .once 'Submit', @bound 'hideEditForm'
      .once 'Cancel', @bound 'hideEditForm'


  hideEditForm: ->

    {meta: {createdAt, updatedAt}} = @getData()

    @menuWrapper.show()
    @likeView.show()
    @replyView?.show()
    @form.destroy()
    @body.show()
    @editInfo.show()  if updatedAt > createdAt
    @form.hide()


  showDeleteModal: ->

    modal = new CommentDeleteModal {}, @getData()
    modal.once "Deleted", @bound "destroy"


  createReplyLink: ->

    return @replyView = new KDView tagName: 'span'  if KD.isMyPost @getData()

    @replyView = new CustomLinkView
      cssClass : 'action-link reply-link'
      title    : 'Mention'
      click    : @bound 'reply'


  reply: (event) ->

    KD.utils.stopDOMEvent event

    {account: {constructorName, _id}} = @getData()
    KD.remote.cacheable constructorName, _id, (err, account) =>

      return KD.showError err  if err

      @getDelegate().emit 'Mention', account.profile.nickname


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
        width     : 42
        height    : 42

    @author = new ProfileLinkView {origin}

    @body       = new JCustomHTMLView
      cssClass  : 'comment-body-container'
      pistachio : '{p{KD.utils.applyTextExpansions #(body), yes}}'
    , data

    @formWrapper = new KDCustomHTMLView cssClass: 'edit-comment-wrapper hidden'

    @editInfo   = new JCustomHTMLView
      tagName   : 'span'
      cssClass  : 'hidden edited'
      pistachio : 'edited'

    @editInfo.show()  if updatedAt > createdAt

    # if deleterId? and deleterId isnt origin.id
    #   @deleter = new ProfileLinkView {}, data.getAt 'deletedBy'

    @menuWrapper = new KDCustomHTMLView
    @addMenu()
    @createReplyLink()

    @likeView    = new CommentLikeView {}, data
    @timeAgoView = new KDTimeAgoView {}, createdAt

    JView::viewAppended.call this


  # updateTemplate: (force = no) ->

  #   {meta: {createdAt, deletedAt}} = @getData()

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
    {{> @editInfo}}
    {{> @menuWrapper}}
    {{> @likeView}}
    {{> @replyView}}
    {{> @timeAgoView}}
    </div>
    '''
