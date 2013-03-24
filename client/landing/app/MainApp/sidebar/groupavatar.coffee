class GroupAvatar extends JView

  constructor:(options = {}, data)->

    options.cssClass = 'group-avatar-drop'
    groupsController = KD.getSingleton 'groupsController'
    super options, groupsController.getCurrentGroupData()

    groupsController.on 'GroupChanged', @bound 'render'

  render:(slug, group)->
    if group
      @setTooltip
        title : """You are now in <strong>#{group.title}</strong> group.
                   <br> Click here to see group's homepage"""

      if slug is 'koding'
        @$().css backgroundImage : "url(images/logos/50.png)"
      else
        @$().css backgroundImage : \
          "url(#{group.avatar or 'http://lorempixel.com/60/60/?' + @utils.getRandomNumber()})"

  click:->
    super
    if KD.config.groupEntryPoint?
      KD.getSingleton('lazyDomController').showLandingPage()
