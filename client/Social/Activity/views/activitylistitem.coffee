class ActivityListItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type               = 'activity'
    options.commentViewClass or= CommentView
    options.commentSettings  or= {}
    options.attributes       or= {}
    options.attributes.testpath = "ActivityListItemView"
    options.editWidgetClass  or= ActivityEditWidget

    super options, data

    @createSubViews()
    @initViewEvents()
    @initDataEvents()

    {_id, constructorName} = data.account
    KD.remote.cacheable constructorName, _id, (err, account) =>

    @bindTransitionEnd()


  createSubViews: ->

    data    = @getData()
    list    = @getDelegate()
    options = @getOptions()

    origin =
      constructorName : data.account.constructorName
      id              : data.account._id

    @avatar = new AvatarView
      size     :
        width  : 37
        height : 37
      cssClass : 'author-avatar'
      origin   : origin

    @author = new ProfileLinkView { origin }

    {commentViewClass} = options

    {socialapi} = KD.singletons

    @commentBox  = new commentViewClass options.commentSettings, data

    @actionLinks = new ActivityActionsView delegate: @commentBox, data

    @commentBox.forwardEvent @actionLinks, "Reply"

    @settingsButton = new ActivitySettingsView
      cssClass      : 'settings-menu-wrapper'
      itemView      : this
    , data

    {_id, constructorName} = data.account
    KD.remote.cacheable constructorName, _id, (err, account)=>
      @setClass "exempt" if account?.isExempt

    embedOptions  =
      hasDropdown : no
      delegate    : this

    @embedBox = if data.link?
      @setClass 'two-columns'  if @twoColumns
      new EmbedBox embedOptions, data.link
    else
      new KDCustomHTMLView

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


  handleUpdate: (fields) ->

    { createdAt, updatedAt } = @getData()

    if updatedAt > createdAt
    then @setClass 'edited'
    else @unsetClass 'edited'


  showEditWidget: ->

    unless @editWidget
      { editWidgetClass } = @getOptions()
      @editWidget = new editWidgetClass { delegate:this }, @getData()
      @editWidget.on 'SubmitSucceeded', @bound 'destroyEditWidget'
      @editWidget.input.on 'EscapePerformed', @bound 'destroyEditWidget'
      @editWidgetWrapper.addSubView @editWidget, null, yes

    KD.utils.defer =>
      {typeConstant} = @getData()
      {input} = @editWidget
      {body}  = document
      input.setFocus()
      input.resize()
      input.setCaretPosition input.getValue().length

      return  unless typeConstant is 'privatemessage'

      input.getElement().scrollIntoView yes

    @editWidgetWrapper.show()

    @setClass 'editing'
    @unsetClass 'edited'


  destroyEditWidget: ->

    @resetEditing()
    @editWidget.destroy()
    @editWidget = null


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
        { appManager } = KD.singletons

        appManager.tell 'Activity', 'post', {body, clientRequestId}, (err, activity) =>
          return KD.showError err  if err

          @emit 'SubmitSucceeded', activity
          @hideResend()

    @resend.show()


  hideResend: ->
    @unsetClass 'failed'
    @resend.destroySubViews()


  partial: -> ''


  hide: ->

    @isBeingHidden = yes

    @setClass 'half no-anim'
    @isBeingHidden = no


  delete: ->

    @whenSubmitted().then =>

      @unsetClass 'half no-anim'
      @once 'transitionend', =>
        @once 'transitionend', =>
          @emit 'HideAnimationFinished'
          @setClass 'hidden'

        height  = @getHeight()
        element = @getElement()
        style   = window.getComputedStyle element
        margins = ['margin-top', 'margin-bottom'].reduce (old, property) ->
          calculated = parseInt (style.getPropertyValue property), 10
          calculated = 0  if isNaN calculated
          return old + calculated
        , 0

        @setCss 'margin-top', "-#{height + margins}px"

      @setClass 'out'


  show: ->

    @unsetClass 'half no-anim out'

    super


  whenSubmitted: ->

    new Promise (resolve) =>
      if @isBeingHidden
      then @once 'HideAnimationFinished', -> resolve()
      else resolve()


  render: ->

    super

    emojify.run @getElement()
    @checkIfItsTooTall()


  viewAppended: ->

    JView::viewAppended.call this

    emojify.run @getElement()

    { updatedAt, createdAt } = @getData()

    @setClass 'edited'  if updatedAt > createdAt

    KD.utils.defer =>
      if @getData().link?.link_url? isnt ''
      then @embedBox.show()
      else @embedBox.hide()

      @checkIfItsTooTall()


  checkIfItsTooTall: ->

    article          = @$('article.has-markdown')[0]
    { scrollHeight } = article
    { height }       = article.getBoundingClientRect()

    if scrollHeight > height

      @showMore?.destroy()
      list = @getDelegate()
      @showMore = new KDCustomHTMLView
        tagName  : 'a'
        cssClass : 'show-more'
        href     : '#'
        partial  : 'Show more'
        click    : ->
          article.style.maxHeight = "#{scrollHeight}px"
          article.classList.remove 'tall'
          
          KD.utils.wait 500, -> list.emit 'ItemWasExpanded'

          @destroy()

      article.classList.add 'tall'
      
      selector = if @hasShowMoreMark
      then '.mark-for-show-more'
      else '.activity-content-wrapper'
      
      @addSubView @showMore, selector


  pistachio: ->
    @hasShowMoreMark = yes
    """
    <div class="activity-content-wrapper">
      {{> @settingsButton}}
      {{> @avatar}}
      <div class='meta'>
        {{> @author}}
        {{> @timeAgoView}} <span class="location hidden"> from San Francisco</span>
      </div>
      {{> @editWidgetWrapper}}
      {article.has-markdown{KD.utils.formatContent #(body)}}
      {{> @resend}}
      {{> @embedBox}}
      {{> @actionLinks}}
      <mark class="mark-for-show-more"> </mark>
      {{> @likeSummaryView}}
    </div>
    {{> @commentBox}}
    """
