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

    embedOptions  =
      hasDropdown : no
      delegate    : this

    if data.link?
      @embedBox = new EmbedBox embedOptions, data.link
      @setClass "two-columns"  if @twoColumns
    else
      @embedBox = new KDView

    @timeAgoView = new KDTimeAgoView {}, @getData().meta.createdAt

  getTokenMap: (tokens) ->
    return  unless tokens
    map = {}
    tokens.forEach (token) -> map[token.getId()] = token
    return  map

  expandTokens: (str = "") ->
    return  str unless tokenMatches = str.match /\|.+?\|/g

    data = @getData()
    tagMap = @getTokenMap data.tags  if data.tags

    for tokenString in tokenMatches
      [prefix, constructorName, id] = @decodeToken tokenString

      switch prefix
        when "#" then token = tagMap?[id]
        else continue

      continue  unless token

      domId     = @utils.getUniqueId()
      itemClass = tokenClassMap[prefix]
      tokenView = new TokenView {domId, itemClass}, token
      tokenView.emit "viewAppended"

      str = str.replace tokenString, tokenView.getElement().outerHTML

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

    @utils.defer =>
      predicate = @getData().link?.link_url? and @getData().link.link_url isnt ''
      if predicate
      then @embedBox.show()
      else @embedBox.hide()

  pistachio:->
    if @twoColumns
      """
      {{> @avatar}}
      <div class='activity-item-right-col'>
        {{> @settingsButton}}
        {p.status-body{@formatContent #(body)}}
        <footer class="clearfix">
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
          {p.status-body{@formatContent #(body)}}
        </div>
        <footer>
          {{> @actionLinks}}
          {{> @timeAgoView}}
        </footer>
        {{> @commentBox}}
      """

  tokenClassMap =
    "#"         : TagLinkView
