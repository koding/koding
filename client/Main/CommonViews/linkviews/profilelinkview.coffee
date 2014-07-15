class ProfileLinkView extends LinkView

  JView.mixin @prototype

  constructor:(options = {}, data)->
    options.noTooltip ?= yes

    # this needs to be pre-super
    unless options.noTooltip
      @avatarPreview =
        constructorName : AvatarTooltipView
        options         :
          delegate      : @
          origin        : options.origin
        data            : data

    if @avatarPreview then options.tooltip or=
      view             : unless options.noTooltip then @avatarPreview else null
      cssClass         : 'avatar-tooltip'
      animate          : yes
      placement        : 'top'#['top','bottom','right','left'][Math.floor(Math.random()*4)]
      direction        : 'left'#['left','right','center','top','bottom'][Math.floor(Math.random()*5)]

    super options, data
    if @avatarPreview?
      @on 'TooltipReady', =>
        @utils.defer =>
          @tooltip?.getView()?.updateData @getData() if @getData()?.profile.nickname?

    @troll = new KDCustomHTMLView
      tagName   : 'span'

    @setClass "profile"

  render: (fields) ->
    nickname = @getData().profile?.nickname
    slug = KD.getGroup()?.slug or 'koding'
    href = if slug is "koding" then "/#{nickname}" else "/#{slug}/#{nickname}"
    @setAttribute "href", href  if nickname

    # only admin can see troll users
    if KD.checkFlag "super-admin"
      trollField = if KD.checkFlag "exempt", @getData() then " (T)" else ""
      @troll.updatePartial trollField  if @troll

    super fields

  pistachio:->
    {profile} = @getData()
    JView::pistachio.call this,
      if profile.firstName is "" and profile.lastName is ""
      then "{{#(profile.nickname)}} {{> @troll}}"
      else "{{#(profile.firstName)+' '+#(profile.lastName)}} {{> @troll}}"
