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
      viewCssClass     : 'avatar-tooltip'
      animate          : yes
      placement        : 'top'#['top','bottom','right','left'][Math.floor(Math.random()*4)]
      direction        : 'left'#['left','right','center','top','bottom'][Math.floor(Math.random()*5)]

    super options, data
    if @avatarPreview?
      @on 'TooltipReady', =>
        @utils.wait =>
          @tooltip?.getView()?.updateData @getData() if @getData()?.profile.nickname?

    @setClass "profile"

  render:->

    nickname = @getData().profile?.nickname
    @$().attr "href", "/#{nickname}"  if nickname
    super

  pistachio:->

    super "{{#(profile.firstName)+' '+#(profile.lastName)}}"

  click:(event)->

    #appManager.tell "Members", "createContentDisplay", @getData()
    KD.getSingleton('router')?.handleRoute "/#{@getData().profile.nickname}"
    event.preventDefault()
    event.stopPropagation()
    no