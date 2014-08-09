class AvatarView extends LinkView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass         = KD.utils.curry 'avatarview', options.cssClass
    options.size           or=
      width                  : 50
      height                 : 50
    options.size.width      ?= 50
    options.size.height     ?= options.size.width
    options.detailed        ?= no
    options.showStatus     or= no
    options.statusDiameter or= 5

    # this needs to be pre-super
    if options.detailed
      @detailedAvatar   =
        constructorName : AvatarTooltipView
        options         :
          delegate      : this
          origin        : options.origin
        data            : data

      options.tooltip or= {}
      options.tooltip.view         or= if options.detailed
      then @detailedAvatar
      else null

      options.tooltip.cssClass     or= 'avatar-tooltip'
      options.tooltip.animate       ?= yes
      options.tooltip.placement    or= 'top'
      options.tooltip.direction    or= 'right'

    @dpr            = window.devicePixelRatio ? 1
    {width, height} = options.size
    @gravatar       = new ErrorlessImageView {width, height}
    @gravatar.on 'load', =>
      @gravatar.setCss 'opacity', '1'
      @setCss 'background-image', 'none'

    super options, data

    if @detailedAvatar?
      @on 'TooltipReady', =>
        @utils.defer =>
          data = @getData()
          @tooltip.getView().updateData data if data?.profile.nickname


  getAvatar: ->
    @gravatar?.getAttribute 'src' or '/a/images/defaultavatar/avatar.svg'


  setAvatar: (src) ->
    if src and @gravatar.getAttribute('src') isnt src
      @gravatar.show()
      @gravatar.setAttribute 'src', src

  getGravatarUri: ->
    {profile} = @getData()
    return no  unless profile?.hash?

    {width} = @getOptions().size
    size    = width * @dpr

    # We have 16-512 all versions of avatar on our CDN ~ GG
    # If you need to update them; after creating a largest version of avatar
    # image (512x512) you can run following command (on OSX pre-installed) to
    # create other sizes
    #
    # $ for i in {16..511}; do; sips -Z $i default.avatar.512.png --out default.avatar.$i.png; done
    #
    # and you need to upload them to koding-cdn/images bucket.
    # Thanks to gravatar to not support svg's, damn.

    defaultAvatarUri = "https://koding-cdn.s3.amazonaws.com/images/default.avatar.#{size}.png"
    return "//gravatar.com/avatar/#{profile.hash}?size=#{size}&d=#{defaultAvatarUri}&r=g"

  render: ->

    return  unless account = @getData()

    {profile, type} = account

    return  if type is 'unregistered'

    {width, height} = @getOptions().size
    height          = width unless height
    avatarURI       = @getGravatarUri()

    if profile.avatar?.match /^https?:\/\//
      resizedAvatar = KD.utils.proxifyUrl profile.avatar, {crop: yes, width, height}
      avatarURI     = resizedAvatar

    @setAvatar avatarURI

    flags = if account.globalFlags
      if Array.isArray account.globalFlags
      then account.globalFlags.join(" ")
      else (value for own key, value of account.globalFlags).join(" ")
    else ""

    @$('cite').addClass flags

    KD.getSingleton("groupsController").ready =>
      {slug} = KD.getSingleton("groupsController").getCurrentGroup()
      href = if slug is "koding" then "/#{profile.nickname}" else "/#{slug}/#{profile.nickname}"
      @setAttribute "href", href

    @showStatus()  if @getOptions().showStatus


  showStatus: ->

    account = @getData()

    onlineStatus = account.onlineStatus or 'offline'

    if @statusAttr? and onlineStatus isnt @statusAttr
      @setClass "animate"

    @statusAttr = onlineStatus

    if @statusAttr is "online"
      @unsetClass "offline"
      @setClass   "online"
    else
      @unsetClass "online"
      @setClass   "offline"


  viewAppended: ->

    JView::viewAppended.call this

    {width, height} = @getOptions().size
    @setCss "background-size", "#{width}px #{height}px"

    @render() if @getData()

    if @getOptions().showStatus
      {statusDiameter} = @getOptions()

      @addSubView @statusIndicator = new KDCustomHTMLView
        cssClass : 'statusIndicator'
      @statusIndicator.setWidth statusDiameter
      @statusIndicator.setHeight statusDiameter


  pistachio: ->
    """
    {{> @gravatar}}
    <cite></cite>
    """

class ErrorlessImageView extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.tagName    = 'img'
    options.cssClass   = 'hidden'
    options.bind       = 'load error'
    options.attributes =
        width          : options.width
        height         : options.height

    super options, data


  error: ->

    @hide()

    return no

