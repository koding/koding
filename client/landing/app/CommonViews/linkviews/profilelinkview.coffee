class ProfileLinkView extends LinkView

  constructor:(options = {}, data)->

    super options, data

    # nickname = data?.profile?.nickname
    # @$().attr "href","/#!/member/#{nickname}" if nickname
    @setClass "profile"

  render:->

    nickname = @getData().profile?.nickname
    if nickname
      @$().attr "href","/#!/member/#{nickname}"
      # @updateTooltip title : "@#{nickname}"
    super

  pistachio:->

    super "{{#(profile.firstName)+' '+#(profile.lastName)}}"

  click:(event)->

    #appManager.tell "Members", "createContentDisplay", @getData()
    KD.getSingleton('router')?.handleRoute '/'+@getData().profile.nickname
    event.preventDefault()
    event.stopPropagation()
    no