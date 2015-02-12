class ActivityLikeCount extends ReplyLikeView

  constructor: (options = {}, data) ->

    super options, data

    @syncCountWithData()

    if @actorsCount then @show() else @hide()

    data
      .on 'LikeAdded', @bound 'addLike'
      .on 'LikeRemoved', @bound 'removeLike'
      .on 'LikeChanged', @bound 'setCountNumber'


  syncCountWithData: ->
    { @actorsCount } = @getData().interactions.like

    @setTemplate @pistachio()


  # latency compensation
  setCountNumber: (likeState) ->

    if likeState is yes
      @actorsCount++
      @show()
    else
      @actorsCount--
      @hide()  if @actorsCount is 0

    @setTemplate @pistachio()


  addLike: ->

    @syncCountWithData()

    @show()

    KD.mixpanel "Activity like, success"


  removeLike: ->

    @syncCountWithData()

    @hide()  unless @actorsCount

    KD.mixpanel "Activity unlike, success"


  pistachio: ->
    "#{ @actorsCount }"

