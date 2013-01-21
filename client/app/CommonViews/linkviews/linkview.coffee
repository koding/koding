class LinkView extends KDCustomHTMLView

  constructor:(options = {}, data)->

    options.tagName or= 'a'
    data            or= fake : yes
    data.profile    or= {}

    data.profile.firstName or= "a koding"
    data.profile.lastName  or= "user"

    super options, data

    if data.fake and options.origin
      @loadFromOrigin options.origin

  loadFromOrigin:(origin)->

    callback = (data)=>
      @setData data
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
