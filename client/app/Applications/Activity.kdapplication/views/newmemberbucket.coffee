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

    @group.on "moreLinkClicked", =>
      log "expand the view to show more users"

  pistachio:->

    """
    <span class='icon fx out'></span>
    <span class='icon'></span>
    {{> @group}}
    """

class NewMemberLinkGroup extends LinkGroup

  constructor:->

    super

    {totalCount} = @getOptions()
    log @getOptions(), "<<<<<"
    @visibleCount = if totalCount > 4 then 4 else totalCount

  createMoreLink:->

    @more.destroy() if @more
    {totalCount, group} = @getOptions()
    @more = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "more"
      partial     : "#{totalCount-@visibleCount} more"
      attributes  :
        href      : "#"
        title     : "Click to view..."
      click       : (e)=>
        @emit "moreLinkClicked"
        @visibleCount += 20
        @render()

  pistachio:->

    participants = @getData()
    {hasMore, totalCount, group, separator} = @getOptions()

    @createMoreLink()
    log "buraya nolmus", @visibleCount, totalCount
    switch @visibleCount
      when 0 then ""
      when 1 then "{{> @participant0}}"
      when 2 then "{{> @participant0}} and {{> @participant1}}"
      when 3 then "{{> @participant0}}#{separator}{{> @participant1}} and {{> @participant2}}"
      when 4
        if totalCount - 4 > 0
          log "burda"
          "{{> @participant0}}#{separator}{{> @participant1}}#{separator}{{> @participant2}} and {{> @more}}"
        else
          "{{> @participant0}}#{separator}{{> @participant1}}#{separator}{{> @participant2}} and {{> @participant3}}"
      else
        tmpl = ""
        for i in [0...@visibleCount]
          log "yo", i
          tmpl += "{{> @participant#{i}}}"
          tmpl += separator if i isnt @visibleCount

        if totalCount > @visibleCount
          log "yo more"
          tmpl += " and {{> @more}}"
        log tmpl
        tmpl


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
