class ProfileLinkView extends LinkView

  constructor:(options = {}, data)->

    super options, data

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