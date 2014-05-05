class ActivityLikeCount extends CustomLinkView

  click: (event) ->

    KD.utils.stopDOMEvent event

    data = @getData()
    {interactions: {like: {isInteracted, actors}}} = @getData()

    return  unless isInteracted

    origins = actors.map (id) => constructorName: "JAccount", _id: id

    KD.remote.cacheable origins, (err, likers) =>

      return KD.showError err  if err

      new ShowMoreDataModalView title: "", likers


  viewAppended: ->

    super

    {interactions: {like: {actorsCount}}} = @getData()
    if actorsCount then @show() else @hide()


  pistachio: ->

    "{{ #(interactions.like.actorsCount)}}"
