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

  click:(event)->
    event.stopPropagation()
    event.preventDefault()
    account = @getData()
    @utils.wait =>
      KD.getSingleton('router').handleRoute "/#{account.profile.nickname}", state:account
    return no

  render:->

    account = @getData()
    return unless account
    {profile} = account
    options = @getOptions()
    fallbackUri = "#{KD.apiUri}/images/defaultavatar/default.avatar.#{options.size.width}.png"
    # @$().attr "title", options.title or "#{Encoder.htmlDecode profile.firstName}'s avatar"

    # this is a temp fix to avoid avatar flashing on every account change - Sinan 08/2012
    bgImg = "url(//gravatar.com/avatar/#{profile.hash}?size=#{options.size.width}&d=#{encodeURIComponent fallbackUri})"

    if @bgImg isnt bgImg
      @$().css "background-image", bgImg
      @bgImg = bgImg

    flags = account.globalFlags?.join(" ") ? ""
    @$('cite').addClass flags

  viewAppended:->
    super
    @render() if @getData()

  pistachio:-> '<cite></cite>'
