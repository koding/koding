# FIXME : render runs on every data change in account object which leads to a flash on avatarview. Sinan 08/2012

class AvatarView extends LinkView

  constructor:(options = {},data)->

    options.cssClass or= ""
    options.size     or=
      width            : 50
      height           : 50

    options.cssClass = "avatarview #{options.cssClass}"

    super options,data

    @bgImg = null

    if /localhost/.test location.host
      @fallbackUrl = 'mm'
    else
      @fallbackUrl = encodeURIComponent(host + 'images/defaultavatar/default.avatar.' + options.size.width + '.png')

  click:(event)->

    event.stopPropagation()
    account = @getData()
    appManager.tell "Members", "createContentDisplay", account
    return no

  render:->

    account = @getData()
    return unless account

    {profile} = account
    options   = @getOptions()
    host      = "#{location.protocol}//#{location.host}/"
    # @$().attr "title", options.title or "#{Encoder.htmlDecode profile.firstName}'s avatar"

    # this is a temp fix to avoid avatar flashing on each account change - Sinan 08/2012
    bgImg = "url(#{location.protocol}//gravatar.com/avatar/#{profile.hash}?size=#{options.size.width}&d=#{@fallbackUrl})"
    if @bgImg isnt bgImg
      @$().css "background-image", bgImg
      @bgImg = bgImg

    flags = account.globalFlags?.join(" ") ? ""
    @$('cite').addClass flags

  viewAppended:->
    super
    @render() if @getData()

  pistachio:-> '<cite></cite>'
