class LinkView extends KDCustomHTMLView

  constructor:(options = {}, data)->

    options.tagName or= 'a'
    data            or= fake : yes
    data              = @_addDefaultProfile data
    super options, data

    if data.fake and options.origin
      @loadFromOrigin options.origin
    KD.getSingleton('linkController').registerLink this

  _addDefaultProfile:(data)->
    data.profile    or= {}
    data.profile.firstName ?= "a koding"
    data.profile.lastName  ?= "user"
    return data

  click:(event)->
    @emit 'LinkClicked'
    @utils.stopDOMEvent event

  destroy:->
    super
    KD.getSingleton('linkController').unregisterLink this

  loadFromOrigin:(origin)->

    callback = (data)=>
      data = @_addDefaultProfile data
      @setData data
      data.on? 'update', @bound 'render'
      @render()
      @emit "OriginLoadComplete", data

    kallback = (err, originModel)->
      originModel = originModel.first  if Array.isArray originModel
      unless originModel
      then warn "couldn't get the model via cacheable", origin
      else callback originModel

    if origin.constructorName
      KD.remote.cacheable origin.constructorName, origin.id, kallback
    else if 'string' is typeof origin
      KD.remote.cacheable origin, kallback
    else
      callback origin

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()
