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

    input       = @getDelegate()
    previousUrl = null
    timer       = null
    kallback    = (url) => @fetchEmbed url, {}, @bound 'populateEmbed'

    input.on ['paste', 'change', 'keyup'], =>
      return @close()  unless url = @checkInputForUrls()
      kd.utils.killWait timer  if timer
      if previousUrl is url
      then kallback url
      else timer = kd.utils.wait 1000, -> kallback url
      previousUrl = url

    input.on 'reset', @bound 'close'
    input.on 'BeingEdited', (url) =>
      if url
      then @fetchEmbed url, {}, @bound 'populateEmbed'
      else
        if url = @checkInputForUrls()
          @fetchEmbed url, {}, @bound('populateEmbed')
        else
          @close()


  checkInputForUrls: ->

    input = @getDelegate()
    value = input.getValue()
    urls  = urlGrabber value

    return null  if not urls.first or @isFetching
    return urls.first


  close: ->

    @oembed     = {}
    @url        = ''
    @imageIndex = 0
    @hide()


  setImageIndex: (index) -> @imageIndex = index


  getData: ->

    return { link_url : null, link_embed : null  }  if _.isEmpty @oembed

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


  populateEmbed: (options = {}) ->

    data = @oembed

    return close()  unless data

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
    # add / at the end of url if it doesn't exist there - it will improve
    # performance avoiding requests to the same url (embedly urls have / at the end)
    url = "#{url}/"  unless url.lastIndexOf('/') is url.length - 1

    return  if @url is url

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
        @processEmbedResponse @cache[url]
        callback embedlyOptions
      return

    # fetch embed.ly data from the server api
    @isFetching = yes
    fetchDataFromEmbedly url, embedlyOptions, (err, oembed) =>
      @isFetching = no

      if err
        @onFetchComplete err
        return console.warn 'Embedly error:', err

      @cache[url] = oembed[0]
      @processEmbedResponse oembed[0]
      callback embedlyOptions


  processEmbedResponse: (data) ->

    return @onFetchComplete()  unless data

    # embedly uses the https://developers.google.com/safe-browsing/ API
    # to stop phishing/malware sites from being embedded
    if data.safe? and not (data.safe is yes or data.safe is 'true')
      # In the case of unsafe data (most likely phishing), this should be used
      # to log the user, the url and other data to our admins.
      log 'There was unsafe content.', data, data.safe_type, data.safe_message
      return @onFetchComplete()

    if data.error_message
      log 'EmbedBoxWidget encountered an error!', data.error_type, data.error_message
      @onFetchComplete()

    @onFetchComplete null, data


  onFetchComplete: (err, data) ->

    @oembed = data
    @url    = data?.url

    @emit 'EmbedFetched', err, data

