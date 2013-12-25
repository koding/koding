class AvatarView extends LinkView

  constructor:(options = {},data)->

    options.cssClass       or= ""
    options.size           or=
      width                  : 50
      height                 : 50
    options.detailed        ?= no
    options.showStatus     or= no
    options.statusDiameter or= 5

    # this needs to be pre-super
    if options.detailed
      @detailedAvatar   =
        constructorName : AvatarTooltipView
        options         :
          delegate      : @
          origin        : options.origin
        data            : data

      options.tooltip or= {}
      options.tooltip.view         or= if options.detailed then @detailedAvatar else null
      options.tooltip.cssClass     or= 'avatar-tooltip'
      options.tooltip.animate       ?= yes
      options.tooltip.placement    or= 'top'
      options.tooltip.direction    or= 'right'

    options.cssClass = "avatarview #{options.cssClass}"

    super options, data

    @dpr = window.devicePixelRatio ? 1

    if @detailedAvatar?
      @on 'TooltipReady', =>
        @utils.defer =>
          data = @getData()
          @tooltip.getView().updateData data if data?.profile.nickname

    @bgImg = null
    @fallbackUri = "#{KD.apiUri}/a/images/defaultavatar/avatar.svg"

  setAvatar:(uri)->
    if @bgImg isnt uri
      @setCss "background-image", "url(#{uri})"
      {width, height} = @getOptions().size
      # do prefixing elsewhere - SY
      @setCss "-webkit-background-size", "#{width}px #{height}px"
      @setCss "-moz-background-size", "#{width}px #{height}px"
      @setCss "background-size", "#{width}px #{height}px"
      @bgImg = uri

  getAvatar:->
    return @bgImg

  getGravatarUri:->
    {profile} = @getData()
    {width} = @getOptions().size
    if profile.hash \
      then "//gravatar.com/avatar/#{profile.hash}?size=#{width * @dpr}&d=#{encodeURIComponent @fallbackUri}"
      else "#{@fallbackUri}"

  render:->
    account = @getData()
    return unless account

    {profile, type} = account
    return @setAvatar "url(#{@fallbackUri})"  if type is 'unregistered'

    {width, height} = @getOptions().size

    height = width unless height

    avatarURI = @getGravatarUri()

    if profile.avatar?.match /^https?:\/\//
      resizedAvatar = KD.utils.proxifyUrl profile.avatar, {crop: yes, width, height}
      avatarURI = "#{resizedAvatar}"

    @setAvatar avatarURI

    flags = ""
    if account.globalFlags
      if Array.isArray account.globalFlags
        flags = account.globalFlags.join(" ")
      else
        flags = (value for own key, value of account.globalFlags).join(" ")

    @$('cite').addClass flags

    @setAttribute "href", "/#{profile.nickname}"

    if @getOptions().showStatus
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

  viewAppended:->
    super
    @render() if @getData()

    if @getOptions().showStatus
      {statusDiameter} = @getOptions()

      @addSubView @statusIndicator = new KDCustomHTMLView
        cssClass : 'statusIndicator'
      @statusIndicator.setWidth statusDiameter
      @statusIndicator.setHeight statusDiameter

  pistachio:->
    """
