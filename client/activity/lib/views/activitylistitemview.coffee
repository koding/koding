kd                        = require 'kd'
KDButtonView              = kd.ButtonView
KDCustomHTMLView          = kd.CustomHTMLView
KDTimeAgoView             = kd.TimeAgoView
KDView                    = kd.View
ActivityActionsView       = require './activityactionsview'
ActivityEditWidget        = require './activityeditwidget'
ActivityLikeSummaryView   = require './activitylikesummaryview'
ActivitySettingsView      = require './activitysettingsview'
CommentView               = require './comments/commentview'
remote                    = require('app/remote').getInstance()
showError                 = require 'app/util/showError'
formatContent             = require 'app/util/formatContent'
ProfileLinkView           = require 'app/commonviews/linkviews/profilelinkview'
JView                     = require 'app/jview'
AvatarView                = require 'app/commonviews/avatarviews/avatarview'
Promise                   = require 'bluebird'
emojifyMarkdown           = require 'activity/util/emojifyMarkdown'
htmlencode                = require 'htmlencode'
animatedRemoveMixin       = require 'activity/mixins/animatedremove'
ActivityBaseListItemView  = require './activitybaselistitemview'


module.exports = class ActivityListItemView extends ActivityBaseListItemView

  constructor: (options = {}, data) ->

    options.type                    = 'activity'
    options.commentViewClass      or= CommentView
    options.commentSettings       or= {}
    options.attributes            or= {}
    options.attributes.testpath     = "ActivityListItemView"
    options.editWidgetClass       or= ActivityEditWidget
    options.pistachioParams         = { formatContent }
    options.showMoreWrapperSelector = 'article.has-markdown'
    options.showMoreMarkSelector    = '.mark-for-show-more'

    super options, data

    @createSubViews()
    @initViewEvents()
    @initDataEvents()

    {_id, constructorName} = data.account
    remote.cacheable constructorName, _id, (err, account) =>

    @bindTransitionEnd()

  updateEmbedBox: require 'activity/mixins/updateembedbox'
  handleUpdate:   require 'activity/mixins/handleupdate'

  createSubViews: ->

    data    = @getData()
    list    = @getDelegate()
    options = @getOptions()

    origin =
      constructorName : data.account.constructorName
      id              : data.account._id

    @avatar = new AvatarView
      size        :
        width     : 37
        height    : 37
      cssClass    : 'author-avatar'
      origin      : origin
      payload     : data.payload


    @author = new ProfileLinkView { origin, payload : data.payload }

    {commentViewClass} = options

    {socialapi} = kd.singletons

    @commentBox  = new commentViewClass options.commentSettings, data

    @actionLinks = new ActivityActionsView delegate: @commentBox, data

    @commentBox.forwardEvent @actionLinks, "Reply"

    @settingsButton = new ActivitySettingsView
      cssClass      : 'settings-menu-wrapper'
      itemView      : this
    , data

    {_id, constructorName} = data.account
    remote.cacheable constructorName, _id, (err, account)=>
      @setClass "exempt" if account?.isExempt

    @embedOptions  =
      hasDropdown : no
      delegate    : this
      type        : 'activity'

    @embedBoxWrapper = new KDCustomHTMLView
    @updateEmbedBox()

    @timeAgoView =
      if @getData().createdAt
      then new KDTimeAgoView {}, @getData().createdAt
      else new KDView

    @editWidgetWrapper = new KDCustomHTMLView
      cssClass         : 'edit-widget-wrapper clearfix'

    @editWidgetWrapper.addSubView new KDButtonView
      style     : 'solid green mini fr done-button'
      title     : 'DONE'
      callback  : =>
        @editWidget.submit @editWidget.input.getValue()

    @editWidgetWrapper.addSubView new KDButtonView
      style     : 'solid mini fr'
      cssClass  : 'cancel-editing'
      title     : 'CANCEL'
      callback  : =>
        @editWidget.input.emit 'EscapePerformed'

    @resend = new KDCustomHTMLView cssClass: 'resend hidden'

    @likeSummaryView  = new ActivityLikeSummaryView {}, data


  initViewEvents: ->

    @settingsButton.on 'ActivityDeleteStarted'   , @bound 'hide'
    @settingsButton.on 'ActivityDeleteSucceeded' , @bound 'delete'
    @settingsButton.on 'ActivityDeleteFailed'    , @bound 'show'
    @settingsButton.on 'ActivityEditIsClicked'   , @bound 'showEditWidget'


  initDataEvents: ->

    data = @getData()

    data.on 'PostIsDeleted', @bound 'delete'
    data.on 'update',        @bound 'handleUpdate'

    data.watch 'repliesCount', (count) =>
      @commentBox.decorateCommentedState() if count >= 0

  showEditWidget: ->

    unless @editWidget
      { editWidgetClass } = @getOptions()
      @editWidget = new editWidgetClass { delegate:this }, @getData()
      @editWidget.on 'SubmitSucceeded', =>
        @updateEmbedBox()
        @destroyEditWidget()
        @checkIfItsTooTall()
      @editWidget.input.on 'EscapePerformed', @bound 'destroyEditWidget'
      @editWidgetWrapper.addSubView @editWidget, null, yes
      @embedBoxWrapper.hide()

    kd.utils.defer =>
      { typeConstant }  = @getData()
      { input }         = @editWidget
      { body }          = global.document
      input.setFocus()
      input.resize()
      input.setCaretPosition input.getValue().length

      return  unless typeConstant is 'privatemessage'

    @editWidgetWrapper.show()

    @setClass 'editing'
    @unsetClass 'edited'


  destroyEditWidget: ->

    @resetEditing()
    @editWidget.destroy()
    @editWidget = null
    @embedBoxWrapper.show()


  resetEditing: ->

    @editWidgetWrapper.hide()
    @unsetClass 'editing'
    list = @getDelegate()
    list.emit 'EditMessageReset'


  showResend: ->

    @setClass 'failed'

    @resend.addSubView text = new KDCustomHTMLView
      tagName : 'span'
      partial : 'Post could not be send'

    @resend.addSubView button = new KDButtonView
      cssClass : 'solid green medium'
      partial  : 'RESEND'
      callback : =>
        { body, clientRequestId } = @getData()
        { appManager } = kd.singletons

        appManager.tell 'Activity', 'post', {body, clientRequestId}, (err, activity) =>
          return showError err  if err

          @emit 'SubmitSucceeded', activity
          @hideResend()

    @resend.show()


  hideResend: ->
    @unsetClass 'failed'
    @resend.destroySubViews()


  partial: -> ''

  delete               : animatedRemoveMixin.remove
  hide                 : animatedRemoveMixin.hide
  show                 : animatedRemoveMixin.show
  whenRemovingFinished : animatedRemoveMixin.whenRemovingFinished


  render: ->

    super

    emojifyMarkdown @getElement()


  viewAppended: ->

    JView::viewAppended.call this

    emojifyMarkdown @getElement()

    { updatedAt, createdAt } = @getData()

    @setClass 'edited'  if updatedAt > createdAt

    kd.utils.defer =>
      if @getData().link?.link_url isnt ''
      then @embedBoxWrapper.show()
      else @embedBoxWrapper.hide()

      @checkIfItsTooTall()


  pistachio: ->

    location = ""
    if @getData().payload?.location?
      location =  "<span class='location'> from #{@getData().payload.location}</span>"

    """
    <div class="activity-content-wrapper">
      {{> @settingsButton}}
      {{> @avatar}}
      <div class='meta'>
        {{> @author}}
        <div class='edited-right'>
          {{> @timeAgoView}}#{location}
        </div>
      </div>
      {{> @editWidgetWrapper}}
      {article.has-markdown.has-show-more{formatContent #(body)}}
      {{> @resend}}
      {{> @embedBoxWrapper}}
      {{> @actionLinks}}
      <mark class="mark-for-show-more"> </mark>
      {{> @likeSummaryView}}
    </div>
    {{> @commentBox}}
    """
