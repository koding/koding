_                  = require 'lodash'
Encoder            = require 'htmlencode'
kd                 = require 'kd'
KDButtonView       = kd.ButtonView
KDView             = kd.View
EmbedBoxImageView  = require './embedbox/embedboximageview'
EmbedBoxLinkView   = require './embedbox/embedboxlinkview'
EmbedBoxLinksView  = require './embedbox/embedboxlinksview'
EmbedBoxObjectView = require './embedbox/embedboxobjectview'
getEmbedType       = require 'app/util/getEmbedType'
regexps            = require 'app/util/regexps'
urlGrabber         = require 'app/util/urlGrabber'


module.exports = class EmbedBoxWidget extends KDView

  { log, noop } = kd
  { addClass, getDescendantsByClassName } = kd.dom

  constructor: (options={}, data={}) ->

    options.cssClass = kd.utils.curry 'link-embed-box hidden clearfix', options.cssClass

    super options, data

    @cache           = {}
    @oembed          = data.link_embed or {}
    @url             = data.link_url ? ''
    @imageIndex      = 0

    @addViews()
    @watchInput()


  addViews: ->
    @addSubView new KDButtonView
      cssClass  : 'hide-embed'
      icon      : yes
      iconOnly  : yes
      iconClass : 'hide'
      callback  : @bound 'close'


  watchInput: ->

    input = @getDelegate()
    input.on ['paste', 'change', 'keyup'], @bound 'checkInputForUrls'
    input.on 'reset', @bound 'close'
    input.on 'BeingEdited', (url) =>
      if url
      then @fetchEmbed url, {}, @bound 'populateEmbed'
      else @checkInputForUrls()


  checkInputForUrls: ->

    input = @getDelegate()
    value = input.getValue()
    urls  = urlGrabber value

    return if not urls.first or @isFetching

    @fetchEmbed urls.first, {}, _.debounce @bound('populateEmbed'), 1000, leading : yes, maxWait : 5000


  close: ->

    @oembed     = {}
    @url        = ''
    @imageIndex = 0
    @hide()


  setImageIndex: (index) -> @imageIndex = index

  getData: ->

    return {}  if _.isEmpty @oembed

    data = @oembed

    filteredData = {}

    data.images = data.images.filter (image, i) =>
      return no  if i isnt @imageIndex

      delete data.images[@imageIndex].colors
      return yes

    @imageIndex = 0

    desiredFields = [
      'title', 'description'
      'url', 'safe', 'type', 'provider_name', 'error_type',
      'error_message', 'safe_type', 'safe_message', 'images'
    ]

    for key in desiredFields
      if 'string' is typeof value = data[key]
      then filteredData[key] = Encoder.htmlDecode value
      else filteredData[key] = value

    return { link_url : @url, link_embed : filteredData }


  displayEmbedType: (embedType, data) ->

    @embedContainer?.destroy()

    containerClass = switch embedType
      when 'image'  then EmbedBoxImageView
      when 'object' then EmbedBoxObjectView
      else               EmbedBoxLinkView

    embedOptions =
      cssClass : 'link-embed clearfix'
      delegate : this

    @addSubView @embedContainer = new containerClass embedOptions, data

    @show()
    @emit 'EmbedIsShown'


  populateEmbed: (data, options = {}) ->

    return  unless data
    return  if data.url is @url

    # embedly uses the https://developers.google.com/safe-browsing/ API
    # to stop phishing/malware sites from being embedded
    if data.safe? and not (data.safe is yes or data.safe is 'true')
      # In the case of unsafe data (most likely phishing), this should be used
      # to log the user, the url and other data to our admins.
      log 'There was unsafe content.', data, data.safe_type, data.safe_message
      return @close()

    # to log the user, the url and other data to our admins.
    if data.error_message
      log 'EmbedBoxWidget encountered an error!', data.error_type, data.error_message
      return @close()

    @oembed = data
    @url    = data.url
    type    = getEmbedType data.type or 'link'

    return @hide()  if type is 'link' and not data.description
    return @hide()  if type in ['video', 'image']

    @displayEmbedType type,
      link_embed   : data
      link_url     : data.url
      link_options : options

    [embedDiv] = getDescendantsByClassName @getElement(), 'embed'
    addClass embedDiv, "custom-#{type}"  if embedDiv?


  fetchEmbed: (url = '', options = {}, callback = noop) ->

    # if there is no protocol, supply one! embedly doesn't support //
    url = "http://#{url}"  unless regexps.hasProtocol.test url

    # prepare embed.ly options
    embedlyOptions = kd.utils.extend {
      maxWidth  : 530
      maxHeight : 200
      wmode     : 'transparent'
    }, options

    { fetchDataFromEmbedly } = kd.singletons.socialapi.message

    # serve from cache if it's fetched already
    if @cache[url]
      kd.utils.defer =>
        @emit 'EmbedFetched', @cache[url]
        callback @cache[url], embedlyOptions
      return

    # fetch embed.ly data from the server api
    @isFetching = yes
    fetchDataFromEmbedly url, embedlyOptions, (err, oembed) =>
      @isFetching = no
      @cache[url] = oembed[0]
      @emit 'EmbedFetched', @cache[url]
      callback oembed[0], embedlyOptions
