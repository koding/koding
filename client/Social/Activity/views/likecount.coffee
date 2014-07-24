class ActivityLikeCount extends ReplyLikeView

  constructor: (options = {}, data) ->

    super options, data

    {interactions: {like}} =  @getData()
    {actorsCount} = like

    if actorsCount then @show() else @hide()

    data
      .on 'LikeAdded', @bound 'addLike'
      .on 'LikeRemoved', @bound 'removeLike'


  addLike: ->
    @show()
    KD.mixpanel "Activity like, success"


  removeLike: ->
    @hide()  unless @getData().interactions.like.actorsCount
    KD.mixpanel "Activity unlike, success"


  pistachio: -> "{{ #(interactions.like.actorsCount)}}"
