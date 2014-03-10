class LinkController extends KDController

  constructor:->
    super
    @linkHandlers = {}

  handleLinkClick:(link)->
    {JAccount, JGroup, JTag} = KD.remote.api
    data = link.getData?()
    return  unless data?
    options = {}
    route   = switch data.constructor
      when JAccount
        {slug} = KD.getGroup()
        {profile: {nickname}} = data
        href = if slug is "koding" then "/#{nickname}" else "/#{slug}/#{nickname}"
      when JGroup
        "/#{data.slug}"
      when JTag
        {group, slug} = data
        route = if group is KD.defaultSlug then '' else "/#{group}"
        route += "/Activity/?tagged=#{slug}"

    KD.getSingleton('router').handleRoute route, {state : data}  if route?

  registerLink:(link)->
    id = link.getId()
    link.on 'LinkClicked', handler = => @handleLinkClick link
    @linkHandlers[id] = handler

  unregisterLink:(link)->
    id = link.getId()
    link.off @linkHandlers[id]
    delete @linkHandlers[id]
