class EmbedBoxWidget extends KDView

  { addClass, getDescendantsByClassName } = KD.dom

  JView.mixin @prototype

  constructor: (options={}, data={}) ->
    options.cssClass = KD.utils.curry 'link-embed-box', options.cssClass

    super options, data

    @oembed     = data.link_embed or {}
    @url        = data.link_url ? ''

    @urls       = []

    @locks = {}
    @embedCache = {}

    @imageIndex = 0
    @hasValidContent = no

    @watchInput()

    @settingsButton = new KDButtonView
      cssClass    : 'hide-embed'
      icon        : yes
      iconOnly    : yes
      iconClass   : 'hide'
      title       : 'hide'
      callback    : @bound 'resetEmbedAndHide'

    @embedType  = data.link_embed?.object?.type or data.link_embed?.type or 'link'

    @embedLinks = new EmbedBoxLinksView { delegate: this }

    @embedLinks.on 'LinkAdded', ({ url }) =>
      @show()
      # if the embed index isn't set, set it to 0
      @setEmbedIndex 0  unless @getEmbedIndex()?

    @embedLinks.on 'LinkRemoved', ({ url, index }) =>
      @hide()  if @embedLinks.getLinkCount() is 0

      if index is @getEmbedIndex()
        console.log 'we need to set a new embed index'

    @embedLinks.on 'LinkSelected', ({ url }) =>
      @addEmbed url

    @embedLinks.on 'LinksCleared', => @urls = []

    @embedLinks.hide()

    @embedContainer = new KDView options, data

    @hide()

  watchInput: ->
    input = @getDelegate()

    fn = @bound 'checkInputForUrls'

    input.on 'keydown', (event) =>
      fn()  if event.which in [9, 13, 32]

    input.on 'paste', fn
    input.on 'change', fn

  checkInputForUrls: ->
    KD.utils.defer =>
      input = @getDelegate()
      text = input.getValue()

      urls = _.uniq (text.match @utils.botchedUrlRegExp) || []

      staleUrls = _.difference @urls, urls
      newUrls   = _.difference urls, @urls


      @embedLinks.addLink     newUrl    for newUrl    in newUrls
      @embedLinks.removeLink  staleUrl  for staleUrl  in staleUrls

      @urls = urls

  isLocked: (url) -> url of @locks

  addLock: (url)->
    @locks[url] = yes
    this

  removeLock: (url) ->
    delete @locks[url]
    this

  addEmbed: (url) ->
    @loadEmbed url
    this

  removeEmbed: (url) ->
    console.log 'need to remove this url'

  loadEmbed: (url) ->
    return this  if @isLocked url
    @addLock url

    cached = @embedCache[url]

    if cached? then @utils.defer =>
      @removeLock url
      @handleEmbedlyResponse url, cached.data, cached.options

    else
      @fetchEmbed url, {}, (data, options) =>
        @removeLock url
        @handleEmbedlyResponse url, data, options
        @addToCache url, data, options

    this

  handleEmbedlyResponse: (url, data, options) ->
    if data.type is 'error'
      @hide()
      return

    @populateEmbed data, options
    @show()

  addToCache: (url, data, options) ->
    @embedCache[url] = { data, options }

  setImageIndex:(@imageIndex)->

  setEmbedIndex: (@embedIndex) ->
    @embedLinks.setActiveLinkIndex @embedIndex

  getEmbedIndex: -> @embedIndex

  refreshEmbed:-> @populateEmbed @oembed, @url, {}

  resetEmbedAndHide: ->

    @resetEmbed()
    @embedLinks.clearLinks()
    @hasValidContent = no
    @hide()
    @emit "EmbedIsHidden"

  # these resets only concern the currently displayed embed
  resetEmbed:->
    @oembed     = {}
    @url        = ''
    @embedContainer?.destroy()
    @embedIndex = null
    @imageIndex = 0

  getDataForSubmit:->
    return {}  if _.isEmpty @oembed

    data = @oembed

    { embedContent } = @embedContainer

    wantedData = {}

    if embedContent?
      wantedData.title       = embedContent.embedTitle?.titleInput?.getValue?() or ''
      wantedData.description = embedContent.embedDescription?.descriptionInput?.getValue?() or ''

      unless data.original_title?
        wantedData.original_title = embedContent.embedTitle?.getOriginalValue() or ''

      unless data.original_description?
        wantedData.original_description = embedContent.embedDescription?.getOriginalValue() or ''

    data.images = data.images.filter (image, i) =>
      return no  if i isnt @imageIndex

      delete data.images[@imageIndex].colors
      return yes

    @imageIndex = 0

    desiredFields = [
      'url', 'safe', 'type', 'provider_name', 'error_type', 'content',
      'error_message', 'safe_type', 'safe_message', 'images'
    ]

    for key in desiredFields
      wantedData[key] = data[key]

    for key, value of wantedData when "string" is typeof value
      wantedData[key] = Encoder.htmlDecode value

    return wantedData

  displayEmbedType: (embedType, data) ->
    @hasValidContent = yes

    containerClass = switch embedType
      when 'image'  then EmbedBoxImageView
      when 'object' then EmbedBoxObjectView
      else               EmbedBoxLinkView

    embedOptions =
      cssClass : 'link-embed clearfix'
      delegate : this

    @embedContainer?.destroy()
    @embedContainer = new containerClass embedOptions, data
    # @embedContainer.show()
    @addSubView @embedContainer
    @emit "EmbedIsShown"
    @show()

  populateEmbed: (data={}, options={}) ->
    return  unless data?

    @oembed = data
    @url    = data.url

    # embedly uses the https://developers.google.com/safe-browsing/ API
    # to stop phishing/malware sites from being embedded
    if data.safe? and not (data.safe is yes or data.safe is 'true')
      # In the case of unsafe data (most likely phishing), this should be used
      # to log the user, the url and other data to our admins.
      log 'There was unsafe content.', data, data.safe_type, data.safe_message
      @hide()
      return

    # to log the user, the url and other data to our admins.
    if data.error_message
      log 'EmbedBoxWidget encountered an error!', data.error_type, data.error_message
      @hide()
      return

    # types should be covered, but if the embed call fails partly, default to link
    type = data.type or 'link'

    @displayEmbedType (@utils.getEmbedType type),
      link_embed   : data
      link_url     : data.url
      link_options : options

    [embedDiv] = getDescendantsByClassName @getElement(), 'embed'
    addClass embedDiv, "custom-#{type}"  if embedDiv?

  fetchEmbed:(url='', options={}, callback=noop)->

    # if there is no protocol, supply one! embedly doesn't support //
    unless @utils.webProtocolRegExp.test url then url = 'http://'+url

    # prepare embed.ly options
    embedlyOptions = @utils.extend {
      maxWidth  : 530
      maxHeight : 200
      wmode     : 'transparent'
    }, options

    # fetch embed.ly data from the server api
    KD.remote.api.JNewStatusUpdate.fetchDataFromEmbedly url, embedlyOptions, (err, oembed)=>
      callback oembed[0], embedlyOptions

  pistachio:->
    """
    {{> @settingsButton}}
    """
