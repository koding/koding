class ReplyPreviousLink extends CommentListPreviousLink

  constructor: (options = {}, data) ->
    super options, data


  updateView: (replies) ->
    {SocialChannel} = KD.remote.api
    data = @getData()
    SocialChannel.fetchActivityCount {channelId: data.id}, (err, {totalCount}) =>
      return warn err if err
      if data
        data.repliesCount = totalCount
        data.replies = replies
      if totalCount <= replies.length
      then @hide()
      else @update()


  viewAppended: ->
  #   {SocialChannel} = KD.remote.api
  #   data = @getData()
  #   SocialChannel.fetchActivityCount {channelId: data.id}, (err, {totalCount}) =>
  #     return warn err if err
  #     data.repliesCount = totalCount if data
  #     super
