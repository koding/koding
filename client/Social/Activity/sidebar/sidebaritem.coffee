class SidebarItem extends KDListItemView

  constructor: (options = {}, data) ->

    groupSlug = KD.getGroup().slug
    groupSlug = if groupSlug is 'koding' then '' else "/#{groupSlug}"

    options.type       or= 'sidebar-item'
    options.route        = "#{groupSlug}/Activity/#{options.route}"
    options.tagName    or= 'a'
    options.attributes or= href : options.route

    super options, data

    @count       = 0
    @unreadCount = new KDCustomHTMLView
      tagName  : 'cite'
      cssClass : 'count hidden'

    # this is used to store the last timestamp once it is clicked
    # to avoid selecting multiple items in case of having the same item
    # on multiple sidebar sections e.g. having the same topic on both
    # "FOLLOWED Topics" and "HOT Topics" sections
    @lastClickedTimestamp = 0

    @on 'click', =>
      @getDelegate().emit 'ItemShouldBeSelected', this
      @lastClickedTimestamp = Date.now()

    @once 'viewAppended', => @setUnreadCount @getData().unreadCount


  setUnreadCount: (unreadCount = 0) ->

    @count = unreadCount

    if unreadCount is 0
      @unreadCount.hide()
      @unsetClass 'unread'
    else
      @unreadCount.updatePartial unreadCount
      @unreadCount.show()
      @setClass 'unread'
