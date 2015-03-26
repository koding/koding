kd                     = require 'kd'
KDButtonView           = kd.ButtonView
KDCustomHTMLView       = kd.CustomHTMLView
KDListItemView         = kd.ListItemView
KDTimeAgoView          = kd.TimeAgoView
KDView                 = kd.View
emojify                = require 'emojify.js'
CommentDeleteModal     = require './commentdeletemodal'
CommentInputEditWidget = require './commentinputeditwidget'
CommentLikeView        = require './commentlikeview'
CommentSettingsButton  = require './commentsettingsbutton'
remote                 = require('app/remote').getInstance()
formatContent          = require 'app/util/formatContent'
showError              = require 'app/util/showError'
ProfileLinkView        = require 'app/commonviews/linkviews/profilelinkview'
JView                  = require 'app/jview'
JCustomHTMLView        = require 'app/jcustomhtmlview'
CustomLinkView         = require 'app/customlinkview'
AvatarView             = require 'app/commonviews/avatarviews/avatarview'
isMyPost               = require 'app/util/isMyPost'
hasPermission          = require 'app/util/hasPermission'
updateEmbedBox         = require 'activity/mixins/updateembedbox'
animatedRemoveMixin    = require 'activity/mixins/animatedremove'

module.exports = class CommentListItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type = 'comment'

    super options, data

    (kd.singleton 'mainController').on 'AccountChanged', @bound 'addMenu'

    @initDataEvents()

    @bindTransitionEnd()


  initDataEvents: ->

    data = @getData()

    data.on 'update', @bound 'handleUpdate'


  handleUpdate: require 'activity/mixins/handleupdate'

  handleInternalLink: (event) ->

    kd.utils.stopDOMEvent event
    href = event.target.getAttribute 'href'
    kd.singletons.router.handleRoute href


  showEditForm: ->

    @menuWrapper.hide()
    @body.hide()
    @unsetClass 'edited'
    @likeView.hide()
    @replyView?.hide()
    @embedBoxWrapper.hide()

    activity   = @getData()
    @editInput = new CommentInputEditWidget {}, activity

    @formWrapper.addSubView @editInput
    @formWrapper.show()

    kd.utils.defer => @editInput.input.resize()

    @editInput
      .once 'SubmitStarted', @bound 'hideEditForm'
      .once 'Cancel', @bound 'hideEditForm'
      .once 'SubmitSucceeded', @bound 'updateEmbedBox'
      .once 'EditSucceeded', @bound 'updateEmbedBox'


  showResend: ->

    @setClass 'failed'

    @resend.addSubView text = new KDCustomHTMLView
      tagName : 'span'
      partial : 'Comment could not be send'

    @resend.addSubView button = new KDButtonView
      cssClass : 'solid green medium'
      partial  : 'RESEND'
      callback : =>
        { activity }              = @getOptions()
        { body, clientRequestId } = @getData()
        { appManager }            = kd.singletons

        appManager.tell 'Activity', 'reply', {activity, body, clientRequestId}, (err, reply) =>
          return showError err  if err

          @emit 'SubmitSucceeded', reply
          @hideResend()

    @resend.show()

  hideResend: ->
    @unsetClass 'failed'
    @resend.destroySubViews()


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
    modal.once 'DeleteClicked'   , @bound 'hide'
    modal.once 'DeleteConfirmed' , @bound 'delete'
    modal.once 'DeleteError'     , @bound 'show'


  hide                 : animatedRemoveMixin.hide
  show                 : animatedRemoveMixin.show
  delete               : animatedRemoveMixin.remove
  whenRemovingFinished : animatedRemoveMixin.whenRemovingFinished


  createReplyLink: ->

    return @replyView = new KDView tagName: 'span'  if isMyPost @getData()

    @replyView   = new CustomLinkView
      cssClass   : 'action-link reply-link'
      title      : 'Mention'
      bind       : 'mouseenter mouseleave'
      click      : @bound 'reply'
      mouseenter : => @emit 'MouseEnterHappenedOnMention', this
      mouseleave : => @emit 'MouseLeaveHappenedOnMention', this


  reply: (event) ->

    kd.utils.stopDOMEvent event

    @emit "MentionStarted", this

    {account: {constructorName, _id}} = @getData()
    remote.cacheable constructorName, _id, (err, account) =>

      return showError err  if err

      @emit 'MentionHappened', account.profile.nickname


  updateEmbedBox: ->
    updateEmbedBox.call this
    @embedBoxWrapper.show()


  addMenu: ->

    comment       = @getData()
    {activity}    = @getOptions()
    owner         = isMyPost comment
    postOwner     = isMyPost activity

    kd.singletons.mainController.ready =>

      canEdit       = hasPermission 'edit posts'
      canEditOwn    = hasPermission 'edit own posts'

      if canEdit or (owner and canEditOwn)
        @addMenuView edit: yes, delete: yes


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
        width     : 30
        height    : 30

    @author = new ProfileLinkView {origin}

    @body       = new JCustomHTMLView
      cssClass        : 'comment-body-container'
      pistachio       : '{p.has-markdown{formatContent #(body), yes}}'
      pistachioParams : { formatContent }
    , data

    @formWrapper = new KDCustomHTMLView cssClass: 'edit-comment-wrapper hidden'

    @setClass 'edited'  if updatedAt > createdAt

    # if deleterId? and deleterId isnt origin.id
    #   @deleter = new ProfileLinkView {}, data.getAt 'deletedBy'

    @menuWrapper = new KDCustomHTMLView

    @resend = new KDCustomHTMLView cssClass: 'resend hidden'


    @embedOptions  =
      hasDropdown : no
      delegate    : this
      type        : 'comment'

    @embedBoxWrapper = new KDCustomHTMLView
    @updateEmbedBox()

    @addMenu()
    @createReplyLink()

    @likeView    = new CommentLikeView {}, data
    @timeAgoView = new KDTimeAgoView {}, createdAt

    JView::viewAppended.call this

    kd.utils.defer => emojify.run @getElement()

    # @setAnchors()


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
    {{> @resend}}
    {{> @timeAgoView}}
    {{> @likeView}}
    {{> @replyView}}
    {{> @embedBoxWrapper}}
    </div>
    '''
