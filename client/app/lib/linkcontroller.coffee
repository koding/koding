getGroup = require './util/getGroup'
remote = require('./remote').getInstance()
kd = require 'kd'
KDController = kd.Controller
module.exports = class LinkController extends KDController

  constructor: ->
    super
    @linkHandlers = {}

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
