class ActivityListItemView extends KDListItemView

  constructor:(options = {},data)->

    options.type              = "activity"
    options.cssClass          = "activity-item status"
    options.commentSettings or= {}

    super options, data

    data   = @getData()
    list   = @getDelegate()
    origin =
      constructorName : data.originType
      id              : data.originId

    @avatar = new AvatarView
      size       :
        width    : 55
        height   : 55
      cssClass   : "author-avatar"
      origin     : origin
      showStatus : yes

    @author     = new ProfileLinkView { origin }
    @commentBox = new CommentView options.commentSettings, data

    @actionLinks = new ActivityActionsView
      cssClass : "comment-header"
      delegate : @commentBox.commentList
    , data

    @settingsButton = new ActivitySettingsView
      itemView : this
    , data

    @settingsButton.on 'ActivityIsDeleted',     @bound 'delete'
    data.on 'PostIsDeleted',                    @bound 'delete'
    @settingsButton.on 'ActivityEditIsClicked', @bound 'showEditWidget'

    data.watch 'repliesCount', (count) =>
      @commentBox.decorateCommentedState() if count >= 0

    KD.remote.cacheable data.originType, data.originId, (err, account)=>
      @setClass "exempt" if account and KD.checkFlag 'exempt', account

    embedOptions  =
      hasDropdown : no
      delegate    : this

    @embedBox = if data.link?
      @setClass "two-columns"  if @twoColumns
      new EmbedBox embedOptions, data.link
    else
      new KDCustomHTMLView

    @timeAgoView = new KDTimeAgoView {}, @getData().meta.createdAt

    @editWidgetWrapper = new KDCustomHTMLView
      cssClass         : "edit-widget-wrapper hidden"


  showEditWidget : ->

    @editWidget?.destroy()
    @editWidget = new ActivityEditWidget null, data
    @editWidget.on 'Submit', @bound 'resetEditing'
    @editWidget.on 'Cancel', @bound 'resetEditing'
    @editWidgetWrapper.addSubView @editWidget, null, yes
    @editWidgetWrapper.unsetClass "hidden"


  resetEditing : ->

    @editWidget.destroy()
    @editWidgetWrapper.setClass "hidden"


  delete: ->

    @emit 'ActivityIsDeleted'
    list.removeItem this
    @destroy()


  formatContent: (str = '') ->

    return @utils.applyMarkdown @utils.expandTokens str, @getData()


  setAnchors: ->

    @$("article a").each (index, element) ->
      {location: {origin}} = window
      href = element.getAttribute "href"
      return  unless href

      beginning = href.substring 0, origin.length
      rest      = href.substring origin.length + 1

      if beginning is origin
        element.setAttribute "href", "/#{rest}"
        element.classList.add "internal"
        element.classList.add "teamwork"  if rest.match /^Teamwork/
      else
        element.setAttribute "target", "_blank"


  click: (event) ->

    {target} = event

    if $(target).is "article a.internal"
      @utils.stopDOMEvent event
      href = target.getAttribute "href"

      if target.classList.contains("teamwork") and KD.singleton("appManager").get "Teamwork"
      then window.open "#{window.location.origin}#{href}", "_blank"
      else KD.singleton("router").handleRoute href


  partial:-> ''


  hide:-> @setClass   'hidden-item'
  show:-> @unsetClass 'hidden-item'


  viewAppended:->

    return if @getData().constructor is KD.remote.api.CStatusActivity

    JView::viewAppended.call this

    @setAnchors()

    @utils.defer =>
      if @getData().link?.link_url? isnt ''
      then @embedBox.show()
      else @embedBox.hide()


  pistachio: ->

    """
    {{> @settingsButton}}
    {{> @avatar}}
    <div class='meta'>
      {{> @author}}
      {{> @timeAgoView}} · San Francisco
    </div>
    {{> @editWidgetWrapper}}
    {article{@formatContent #(body)}}
    {{> @embedBox}}
    {{> @actionLinks}}
    {{> @commentBox}}
    """