class ProfileLinkView extends LinkView

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

    @setClass "profile"

  render: (fields) ->
    nickname = @getData().profile?.nickname
    @setAttribute "href", "/#{nickname}"  if nickname
    super fields

  pistachio:->
    {profile} = @getData()
    if profile.firstName is "" and profile.lastName is ""
      super "{{#(profile.nickname)}}" 
    else
      super "{{#(profile.firstName)+' '+#(profile.lastName)}}"
