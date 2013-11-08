class NavigationLink extends KDListItemView

  constructor:(options = {}, data={})->

    data.type        or= ''
    options.tagName  or= 'a'
    options.type     or= 'main-nav'
    options.attributes =
      href             : '#'
    options.cssClass   = KD.utils.curry @utils.slugify(data.title), options.cssClass

    super options,data

    @name = data.title

  click:(event)->
    {appPath, title, path, type, topLevel} = @getData()

    # This check is for custom items which isn't connected to an app
    # or if the item is a separator
    return unless path

    mc = KD.getSingleton 'mainController'
    mc.emit "NavigationLinkTitleClick",
      pageName  : title
      appPath   : appPath or title
      path      : path
      topLevel  : topLevel
      navItem   : this

  partial:(data)->
    "<span class='icon'></span><cite>#{data.title}</cite>"
