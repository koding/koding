class SidebarItem extends KDListItemView

  constructor: (options = {}, data) ->

    options.tagName    or= 'a'
    options.attributes or= href : options.route or Sidebar.getRoute data

    super options, data

    # this is used to store the last timestamp once it is clicked
    # to avoid selecting multiple items in case of having the same item
    # on multiple sidebar sections e.g. having the same topic on both
    # "FOLLOWED Topics" and "HOT Topics" sections
    @lastClickedTimestamp = 0

    @on 'click', =>
      @getDelegate().emit 'ItemShouldBeSelected', this
      @lastClickedTimestamp = Date.now()
