class ContentDisplayMeta extends KDView
  viewAppended: ->
    @unsetClass 'kdview'
    {activity, account} = @getData()
    @setPartial @partial activity, account

  click:(event)->
    if $(event.target).is "a"
      {account} = @getData()
      KD.getSingleton("appManager").tell "Members", "createContentDisplay", account

  partial: (activity, account) ->
    dom = $ """
      <div>by <a href="#">#{account.profile.firstName}</a> <time class='timeago' datetime="#{new Date(activity.meta.createdAt).format 'isoUtcDateTime'}"></time></div>
    """
    dom.find("time.timeago").timeago()
    dom
