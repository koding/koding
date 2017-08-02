proxifyUrl = require '../../util/proxifyUrl'
regexps = require '../../util/regexps'
kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
ErrorlessImageView = require '../../errorlessimageview'

LinkView = require '../linkviews/linkview'
TeamFlux = require 'app/flux/teams'
globals = require 'globals'

module.exports = class AvatarView extends LinkView

  #

  constructor: (options = {}, data) ->

    options.cssClass         = kd.utils.curry 'avatarview', options.cssClass
    options.size           or=
      width                  : 50
      height                 : 50
    options.size.width      ?= 50
    options.size.height     ?= options.size.width
    options.detailed        ?= no
    options.showStatus     or= no
    options.statusDiameter or= 5

    @dpr              = global.devicePixelRatio ? 1
    { width, height } = options.size
    @gravatar         = new ErrorlessImageView { width, height }

    @gravatar.on 'load', =>
      @gravatar.setCss 'opacity', '1'
      @setCss 'background-image', 'none'

    @gravatar.error = =>
      @setAvatar @getDefaultAvatarUri()
      @gravatar.show()
      return no

    @cite = new KDCustomHTMLView
      tagName     : 'cite'
      tooltip     :
        title     : 'Koding Staff'
        placement : 'right'
        direction : 'center'

    @badge = new KDCustomHTMLView
      cssClass : 'badge hidden'

    super options, data

    if @detailedAvatar?
      @on 'TooltipReady', =>
        kd.utils.defer =>
          data = @getData()
          @tooltip.getView().updateData data if data?.profile.nickname


  getAvatar: ->
    @gravatar?.getAttribute 'src' or '/a/images/defaultavatar/avatar.svg'


  setAvatar: (src) ->
    if src and @gravatar.getAttribute('src') isnt src
      @gravatar.show()
      @gravatar.setAttribute 'src', src


  getGravatarUri: ->
    { profile } = @getData()
    return no  unless profile?.hash?

    size = @getUriSize()

    # We have 16-512 all versions of avatar on our CDN ~ GG
    # If you need to update them; after creating a largest version of avatar
    # image (512x512) you can run following command (on OSX pre-installed) to
    # create other sizes
    #
    # $ for i in {16..511}; do; sips -Z $i default.avatar.512.png --out default.avatar.$i.png; done
    #
    # and you need to upload them to koding-cdn/images bucket.
    # Thanks to gravatar to not support svg's, damn.

    defaultAvatarUri = @getDefaultAvatarUri()
    return "//gravatar.com/avatar/#{profile.hash}?size=#{size}&d=#{defaultAvatarUri}&r=g"


  getDefaultAvatarUri: ->
    size = @getUriSize()
    return "https://koding-cdn.s3.amazonaws.com/new-avatars/default.avatar.#{size}.png"


  getUriSize: ->

    { width } = @getOptions().size
    return Math.round width * @dpr


  render: ->

    return  unless account = @getData()

    { profile, type } = account

    return  if type is 'unregistered'

    { width, height } = @getOptions().size
    height            = width unless height
    avatarURI         = @getGravatarUri()

    width         = width * @dpr
    height        = height * @dpr
    minAvatarSize = 30 * @dpr

    if profile.avatar?.match regexps.webProtocolRegExp
      resizedAvatar = proxifyUrl profile.avatar, { crop: yes, width, height }
      avatarURI     = resizedAvatar

    { payload } = @getOptions()
    if payload?.integrationIconPath
      avatarURI = proxifyUrl payload.integrationIconPath, { crop: yes, width, height }

    @setAvatar avatarURI

    flags = if account.globalFlags
      if Array.isArray account.globalFlags
      then account.globalFlags.join(' ')
      else (value for own __, value of account.globalFlags).join(' ')
    else ''

    @cite.setClass flags

    @cite.hide() if height < minAvatarSize

    kd.getSingleton('groupsController').ready =>

      return  unless account = @getData()

      return  if account.fake

      roles =  globals.userRoles
      hasOwner = 'owner' in roles
      hasAdmin = 'admin' in roles
      userRole = if hasOwner then 'owner' else if hasAdmin then 'admin' else 'member'

      return  if userRole is 'member'

      @badge.clear()
      @badge.setClass userRole
      @badge.setAttribute 'title', userRole
      @badge.setPartial userRole.capitalize()
      @badge.show()

      href = if payload?.channelIntegrationId
        "/Admin/Integrations/Configure/#{payload.channelIntegrationId}"
      else
        '/#'

      @setAttribute 'href', href

    @showStatus()  if @getOptions().showStatus


  showStatus: ->

    account = @getData()

    onlineStatus = account.onlineStatus or 'offline'

    if @statusAttr? and onlineStatus isnt @statusAttr
      @setClass 'animate'

    @statusAttr = onlineStatus

    if @statusAttr is 'online'
      @unsetClass 'offline'
      @setClass   'online'
    else
      @unsetClass 'online'
      @setClass   'offline'


  viewAppended: ->

    super

    { width, height } = @getOptions().size
    @setCss 'background-size', "#{width}px #{height}px"

    @render() if @getData()

    if @getOptions().showStatus
      { statusDiameter } = @getOptions()

      @addSubView @statusIndicator = new KDCustomHTMLView
        cssClass : 'statusIndicator hidden'
      @statusIndicator.setWidth statusDiameter
      @statusIndicator.setHeight statusDiameter


  pistachio: ->
    '''
    {{> @badge}}
    {{> @gravatar}}
    {{> @cite}}
    '''
