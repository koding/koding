class AvatarView extends LinkView

  constructor:(options = {},data)->

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
          delegate      : @
          origin        : options.origin
        data            : data

      options.tooltip or= {}
      options.tooltip.view         or= if options.detailed then @detailedAvatar else null
      options.tooltip.cssClass     or= 'avatar-tooltip'
      options.tooltip.animate       ?= yes
      options.tooltip.placement    or= 'top'
      options.tooltip.direction    or= 'right'

    @dpr            = window.devicePixelRatio ? 1
    {width, height} = options.size
    @gravatar       = new KDCustomHTMLView
      tagName       : 'img'
      cssClass      : 'hidden'
      bind          : 'load error'
      load          : => @setCss 'background-image', 'none'
      error         : -> @hide()
      attributes    :
        width       : width
        height      : height

    super options, data

    src = @getGravatarUri()

    if @detailedAvatar?
      @on 'TooltipReady', =>
        @utils.defer =>
          data = @getData()
          @tooltip.getView().updateData data if data?.profile.nickname

  getAvatar:->
    @gravatar?.getAttribute 'src' or '/a/images/defaultavatar/avatar.svg'

  setAvatar:(src)->
    if src and @gravatar.getAttribute('src') isnt src
      @gravatar.show()
      @gravatar.setAttribute 'src', src

  getGravatarUri:->
    {profile} = @getData()
    {width} = @getOptions().size
    if profile.hash
    then "//gravatar.com/avatar/#{profile.hash}?size=#{width * @dpr}&d=404&r=pg"
    else no

  render:->

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

    @setAttribute "href", "/#{profile.nickname}"

    @showStatus()  if @getOptions().showStatus

  showStatus:->

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

  viewAppended:->

    super

    {width, height} = @getOptions().size
    @setCss "background-size", "#{width}px #{height}px"

    @render() if @getData()

    if @getOptions().showStatus
      {statusDiameter} = @getOptions()

      @addSubView @statusIndicator = new KDCustomHTMLView
        cssClass : 'statusIndicator'
      @statusIndicator.setWidth statusDiameter
      @statusIndicator.setHeight statusDiameter

  pistachio:->
    """
    {{> @gravatar}}
    <cite></cite>
    """