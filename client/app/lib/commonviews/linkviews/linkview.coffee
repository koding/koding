remote = require('../../remote')
kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView



module.exports = class LinkView extends KDCustomHTMLView



  constructor: (options = {}, data) ->

    options.tagName or= 'a'
    data            or= { fake : yes }
    data              = @_addDefaultProfile data
    super options, data

    if data.fake and options.origin
      @loadFromOrigin options.origin
    kd.getSingleton('linkController').registerLink this

  _addDefaultProfile: (data) ->
    data.profile          or= {}
    data.profile.firstName ?= 'a koding'
    data.profile.lastName  ?= 'user'
    return data

  click: (event) ->
    @emit 'LinkClicked'
    kd.utils.stopDOMEvent event

  destroy: ->
    super
    kd.getSingleton('linkController').unregisterLink this

  loadFromOrigin: (origin) ->

    callback = (data) =>
      data = @_addDefaultProfile data
      @setData data
      data.on? 'update', @bound 'render'
      @render()
      @emit 'OriginLoadComplete', data

    kallback = (err, originModel) ->
      originModel = originModel.first  if Array.isArray originModel
      unless originModel
      then kd.warn "couldn't get the model via cacheable", origin
      else callback originModel

    if origin.constructorName
      remote.cacheable origin.constructorName, origin.id, kallback
    else if 'string' is typeof origin
      remote.cacheable origin, kallback
    else
      callback origin
