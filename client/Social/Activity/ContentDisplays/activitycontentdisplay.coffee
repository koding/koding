class ActivityContentDisplay extends KDScrollView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass or= "content-display activity-related #{options.type}"

    super options, data

    currentGroup = KD.getSingleton("groupsController").getCurrentGroup()

    getContentGroupLinkPartial = (groupSlug, groupName)->
      if currentGroup?.slug is groupSlug
      then ""
      else "In <a href=\"#{groupSlug}\" target=\"#{groupSlug}\">#{groupName}</a>"

    @contentGroupLink = new KDCustomHTMLView
      tagName     : "span"
      partial     : getContentGroupLinkPartial(data.group, data.group)

    if currentGroup?.slug is data.group
      @contentGroupLink.updatePartial getContentGroupLinkPartial(currentGroup.slug, currentGroup.title)
    else
      KD.remote.api.JGroup.one {slug:data.group}, (err, group)=>
        if not err and group
          @contentGroupLink.updatePartial getContentGroupLinkPartial(group.slug, group.title)

    @header = new HeaderViewSection
      type    : "big"
      title   : @getOptions().title

    @back   = new KDCustomHTMLView
      tagName : "a"
      partial : "<span>&laquo;</span> Back"
      click   : (event)=>
        event.stopPropagation()
        event.preventDefault()
        KD.singleton('display').emit "ContentDisplayWantsToBeHidden", @
        KD.singleton('router').back()

    @back = new KDCustomHTMLView  unless KD.isLoggedIn()
