class CommentLikeLink extends ActivityLikeLink
  click: ->

    {socialapi: {message: {like, unlike}}} = KD.singletons

    fn = if @state then unlike else like
    fn id: @getData().message.id, @bound "toggleState"
