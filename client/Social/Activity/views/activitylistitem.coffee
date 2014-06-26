class ActivityListItemView extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {},data)->

    options.type              = 'activity'
    options.cssClass          = KD.utils.curry 'activity-item status', options.cssClass
    options.commentSettings or= {}

    super options, data

    data   = @getData()
    list   = @getDelegate()
    origin =
      constructorName : data.account.constructorName
      id              : data.account._id

    @avatar = new AvatarView
      size       :
        width    : 42
        height   : 42
      cssClass   : 'author-avatar'
      origin     : origin

    @author      = new ProfileLinkView { origin }
    @likeSummary = new ActivityLikeSummaryView {}, data

    @commentBox = new CommentView options.commentSettings, data
    @actionLinks = new ActivityActionsView delegate: @commentBox, data

    @commentBox.forwardEvent @actionLinks, "Reply"

    @settingsButton = new ActivitySettingsView
      cssClass : 'settings-menu-wrapper'
      itemView : this
    , data

    @settingsButton.on 'ActivityIsDeleted',     @bound 'delete'
    data.on 'PostIsDeleted',                    @bound 'delete'
    @settingsButton.on 'ActivityEditIsClicked', @bound 'showEditWidget'

    data.watch 'repliesCount', (count) =>
      @commentBox.decorateCommentedState() if count >= 0

    {_id, constructorName} = data.account
    KD.remote.cacheable constructorName, _id, (err, account)=>
      @setClass "exempt" if account and KD.checkFlag 'exempt', account

    embedOptions  =
      hasDropdown : no
      delegate    : this

    @embedBox = if data.link?
      @setClass 'two-columns'  if @twoColumns
      new EmbedBox embedOptions, data.link
    else
      new KDCustomHTMLView

    @timeAgoView = new KDTimeAgoView {}, @getData().meta.createdAt

    @editWidgetWrapper = new KDCustomHTMLView
      cssClass         : 'edit-widget-wrapper'


  showEditWidget : ->

    @editWidget?.destroy()
    @editWidget = new ActivityEditWidget null, @getData()
    @editWidget.on 'Submit', @bound 'resetEditing'
    @editWidget.input.on 'Escape', @bound 'resetEditing'
    @editWidgetWrapper.addSubView @editWidget, null, yes
    @editWidgetWrapper.show()
    @setClass 'editing'


  resetEditing : ->

    @editWidget.destroy()
    @editWidgetWrapper.hide()
    @unsetClass 'editing'


  delete: ->

    @emit 'ActivityIsDeleted'
    list.removeItem this
    @destroy()


  formatContent: (body = '') ->

    fns = [
      @bound 'transformTags'
      @bound 'formatBlockquotes'
      KD.utils.applyMarkdown
    ]

    body = fn body for fn in fns
    body = KD.utils.expandUsernames body, 'pre'

    return body


  transformTags: (text = '') ->

    {slug}   = KD.getGroup()

    return text.replace /#(\w+)/g, (match, tag, offset) ->
      pre  = text[offset - 1]
      post = text[offset + match.length]

      switch
        when (pre?.match /\S/) and offset isnt 0
          return match
        when post?.match /[,.;:!?]/
          break
        when (post?.match /\S/) and (offset + match.length) isnt text.length
          return match

      href = KD.utils.groupifyLink "Activity/Topic/#{tag}", yes
      return "[##{tag}](#{href})"


  formatBlockquotes: (text = '') ->

    parts = text.split '```'
    for part, index in parts
      blockquote = index %% 2 is 1

      if blockquote
        if match = part.match /^\w+/
          [lang] = match
          part = "\n#{part}"  unless hljs.getLanguage lang

        parts[index] = "\n```#{part}\n```\n"

    parts.join ''


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

    JView::viewAppended.call this

    @setAnchors()

    @utils.defer =>
      if @getData().link?.link_url? isnt ''
      then @embedBox.show()
      else @embedBox.hide()


  pistachio: ->
    """
    <div class="activity-content-wrapper">
      {{> @settingsButton}}
      {{> @avatar}}
      <div class='meta'>
        {{> @author}}
        {{> @timeAgoView}} <span class="location">San Francisco</span>
      </div>
      {{> @editWidgetWrapper}}
      {article{@formatContent #(body)}}
      {{> @embedBox}}
      {{> @actionLinks}}
      {{> @likeSummary}}
    </div>
    {{> @commentBox}}
    """
