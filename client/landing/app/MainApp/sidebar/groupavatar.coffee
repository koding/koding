class GroupAvatar extends JView

  constructor:(options = {}, data)->

    options.cssClass = 'group-avatar'
    groupsController = KD.getSingleton 'groupsController'
    super options, groupsController.getCurrentGroupData()

    groupsController.on 'GroupChanged', @bound 'render'

  render:(slug, group)->
    if group
      @setTooltip
        title : "You are now in <strong>#{group.title}</strong> group."
      @$().css backgroundImage : \
        "url(#{group.avatar or 'http://lorempixel.com/60/60/?' + @utils.getRandomNumber()})"

  click:->
    super
    if KD.config.groupEntryPoint?
      KD.getSingleton('lazyDomController').showLandingPage()
