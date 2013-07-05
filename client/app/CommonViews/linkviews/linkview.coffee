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
    event.stopPropagation()
    event.preventDefault()
    @emit 'LinkClicked'

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

    if origin.constructorName
      KD.remote.cacheable origin.constructorName, origin.id, (err, origin)=>
        callback origin
    else
      callback origin

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()
