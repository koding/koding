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

    name = KD.utils.getFullnameFromAccount account, yes

    dom = $ """
      <div>In #{activity.group} by <a href="#">#{name}</a> <time class='timeago' datetime="#{activity.createdAt}"></time></div>
    """
    dom.find("time.timeago").timeago()
    dom
