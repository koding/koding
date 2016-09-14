remote = require('./remote')
kd = require 'kd'


module.exports = class LinkController extends kd.Controller

  constructor: ->

    super

    @linkHandlers = {}
    @windowReferences = {}


  handleLinkClick: (link) ->

    { JAccount, JGroup } = remote.api
    data = link.getData?()

    return  unless data?

    options = {}
    route   = switch data.constructor
      when JAccount
        { profile : { nickname } } = data
        "/#{nickname}"
      when JGroup
        "/#{data.slug}"

    return  unless route

    kd.getSingleton('router').handleRoute route, { state : data }  if route?


  registerLink: (link) ->

    id = link.getId()
    link.on 'LinkClicked', handler = => @handleLinkClick link
    @linkHandlers[id] = handler


  unregisterLink: (link) ->

    id = link.getId()
    link.off @linkHandlers[id]
    delete @linkHandlers[id]


  openOrFocus: (url) ->

    if reference = @windowReferences[url]
      unless reference.closed
        return reference.focus()

    @windowReferences[url] = window.open url, '_blank'
