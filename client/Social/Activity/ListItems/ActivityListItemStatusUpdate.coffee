class StatusActivityItemView extends ActivityItemChild
  constructor:(options = {}, data={})->
    options.cssClass or= "activity-item status"
    options.tooltip  or=
      title            : "Status Update"
      selector         : "span.type-icon"
      offset           :
        top            : 3
        left           : -5

    if data.link?.link_embed?.type is "image"
      @twoColumns      = yes

      options.commentSettings = fixedHeight: 300

    super options, data

    @embedOptions = $.extend {}, options,
      hasDropdown : no
      delegate    : this

    if data.link?
      @embedBox = new EmbedBox @embedOptions, data.link
      @setClass "two-columns"  if @twoColumns
    else
      @embedBox = new KDView

    @timeAgoView = new KDTimeAgoView {}, @getData().meta.createdAt

    @tags = @getTokenMap(data.tags) or {}

  getTokenMap: (tokens) ->
    return  unless tokens
    map = {}
    tokens.forEach (token) -> map[token.getId()] = token
    return  map

  expandTokens: (str = "") ->
    return  str  unless tokenMatches = str.match /\|.+?\|/g

    data = @getData()

    viewParams = []
    for tokenString in tokenMatches
      [prefix, constructorName, id] = @decodeToken tokenString

      switch prefix
        when "#"
          token     = @tags[id]
        else
          continue

      continue  unless token

      domId = @utils.getUniqueId()
      str   = str.replace tokenString, TokenView.getPlaceholder domId
      viewParams.push {options: {domId, itemClass: tokenClassMap[prefix]}, token}

      @utils.defer ->
        for params in viewParams
          {options, token} = params
          new TokenView options, token

    return  str

  decodeToken: (str) ->
    return  match[1].split /:/g  if match = str.match /^\|(.+)\|$/

  formatContent: (str = "")->
    str = @utils.applyTextExpansions str, yes
    str = @expandTokens str
    return  str

  viewAppended:->
    return if @getData().constructor is KD.remote.api.CStatusActivity
    super
    @setTemplate @pistachio()
    @template.update()

    # load embed on next callstack
    @utils.defer =>
      # If there is embed data in the model, use that!
      if @getData().link?.link_url? and @getData().link.link_url isnt ''
        @embedBox.show()
        @embedBox.$().fadeIn 200

        firstUrl = @getData().body.match(/(([a-zA-Z]+\:)?\/\/)+(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g)
        @embedBox.embedLinks.setLinks firstUrl if firstUrl?

        embedOptions = maxWidth: 700, maxHeight: 300
        @embedBox.embedExistingData @getData().link.link_embed, embedOptions, =>
          @embedBox.setActiveLink @getData().link.link_url
          @embedBox.hide()  unless @embedBox.hasValidContent
        @embedBox.embedLinks.hide()
      else
        @embedBox.hide()

  render:->
    super

    {link} = @getData()
    if link?
      if @embedBox.constructor.name is "KDView"
        @embedBox = new EmbedBox @embedOptions, link

      # render embedBox only when the embed changed, else there will be ugly
      # re-rendering (particularly of the image)
      unless @embedBox.oembed is link.link_embed
        @embedBox.embedExistingData link.link_embed, {}, =>
          @embedBox.hide()  unless @embedBox.hasValidContent

      @embedBox.setActiveLink link.link_url
    else
      @embedBox = new KDView

  pistachio:->
    if @twoColumns
      """
      {{> @settingsButton}}
      <span class="avatar">{{> @avatar}}</span>
      <div class='activity-item-right-col'>
        {{> @settingsButton}}
        <p class="status-body">{{@formatContent #(body)}}</p>
        <footer class='clearfix'>
          <div class='type-and-time'>
            <span class='type-icon'></span>{{> @contentGroupLink }} by {{> @author}}
            {{> @timeAgoView}}
          </div>
          {{> @actionLinks}}
        </footer>
        {{> @embedBox}}
        {{> @commentBox}}
      </div>
      """
    else
      """
        {{> @avatar}}
        <div class="activity-item-right-col">
          {{> @settingsButton}}
          <span class="author-name">{{> @author}}</span>
          <p class="status-body">{{@formatContent #(body)}}</p>
        </div>
        <footer>
          {{> @actionLinks}}
          {{> @timeAgoView}}
        </footer>
        {{> @commentBox}}
      """

  tokenClassMap =
    "#"         : TagLinkView
