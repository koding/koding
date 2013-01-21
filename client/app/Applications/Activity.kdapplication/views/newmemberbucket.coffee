class NewMemberBucketData extends KDObject

  constructor:(data)->

    @[key] = val for key,val of data

    @bongo_ = {}
    @bongo_.constructorName = "NewMemberBucketData"

    super

class NewMemberBucketView extends JView

  constructor: (options = {}, data)->

    options.cssClass = "new-member"

    super

    @group = new NewMemberLinkGroup (totalCount : @getData().count), @getData().anchors

    lastFetchedDate = null

    @group.on "moreLinkClicked", =>
      # TBDL an accordion view
      return
      log "expand the view to show more users"
      selector    =
        type      : { $in : ['CNewMemberBucketActivity'] }
        createdAt :
          $lt     : lastFetchedDate or @getData().createdAt[0]
          $gt     : @getData().createdAt[1]

      options     =
        limit     : 20

      @group.loader.show()
      KD.remote.api.CActivity.some selector, options, (err, activities)=>
        if err then warn err
        else
          activities = ActivityAppController.clearQuotes activities
          lastFetchedDate = activities.last.createdAt
          KD.remote.reviveFromSnapshots activities, (err, teasers)=>
            if err then warn err
            else
              @getData().anchors = @getData().anchors.concat teasers.map (item)-> item.anchor
              @group.setData @getData().anchors
              @group.visibleCount += 20
              @group.render()
              @group.loader.hide()

  pistachio:->

    """
    <span class='icon fx out'></span>
    <span class='icon'></span>
    {{> @group}}
    """

class NewMemberLinkGroup extends LinkGroup

  constructor:->

    super

    @loader = new KDLoaderView

  createMoreLink:->

    @more.destroy() if @more
    {totalCount, group} = @getOptions()
    @more = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "more"
      partial     : "#{totalCount-@getData().length} more"
      attributes  :
        href      : "#"
        title     : "Click to view..."
      click       : (e)=>
        @emit "moreLinkClicked"

  pistachio:->

    participants = @getData()
    {hasMore, totalCount, group, separator} = @getOptions()

    @createMoreLink()
    l = if @getData().length < 4 then @getData().length else 3
    tmpl = ""
    for i in [0...l]
      tmpl += "{{> @participant#{i}}}"
      tmpl += separator if i isnt l-1

    if totalCount > @getData().length
      tmpl += " and {{> @more}}"

    tmpl += "{{> @loader }}"


# SLIGHTLY OLD

# class NewMemberBucketData extends KDObject

#   constructor:(options, @buckets)->

#     @bongo_ = {}
#     @meta   = @buckets[0].meta
#     @bongo_.constructorName = "NewMemberBucketData"
#     super

# class NewMemberBucketView extends JView

#   constructor: (options = {}, data)->

#     options.cssClass = "new-member"

#     super

#     @group = new LinkGroup {}, @getData().buckets.map (bucket)-> bucket.anchor

#   viewAppended:->

#     super

#     @timer = @utils.wait 800, =>
#       @$('.fx').removeClass "out hidden"
#       @timer = @utils.wait 400, =>
#         @$('.fx').addClass "hidden"

#   pistachio:->
#     """
#     <span class='icon fx out'></span>
#     <span class='icon'></span>
#     {{> @group}}
#     <span class='action'>became member.</span>
#     """




# OLD

class NewMemberBucketItemView extends KDView

  constructor:(options,data)->
    options = $.extend options,
      cssClass : "new-member"
    super options,data

    @anchor = new ProfileLinkView origin: data.anchor

  render:->

  addCommentBox:->

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <span class='icon'></span>
    {{> @anchor}}
    <span class='action'>became a member.</span>
    """
