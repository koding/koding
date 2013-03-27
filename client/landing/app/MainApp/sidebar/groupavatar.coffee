class GroupAvatar extends JView

  constructor:(options = {}, data)->

    options.cssClass = 'group-avatar-drop hidden'
    groupsController = KD.getSingleton 'groupsController'
    super options, groupsController.getCurrentGroupData()

    groupsController.on 'GroupChanged', @bound 'render'

  render:(slug, group)->
    if group

      @$().css backgroundImage : \
        "url(#{group.avatar or 'http://lorempixel.com/60/60/?' + @utils.getRandomNumber()})"

      @setTooltip
        title : """You are now in <strong>#{group.title}</strong> group.
                  <br> Click here to see group's homepage."""

      @show() unless slug is 'koding'

  click:->
    super
    if KD.config.groupEntryPoint?
      KD.getSingleton('lazyDomController').showLandingPage()
