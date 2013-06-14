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

    @lastFetchedDate      = null
    @lastFetchedItemCount = 0
    @isUserViewCreated    = no
    @listViews            = []
    @isLoading            = no

    @group.on "moreLinkClicked", =>

      return warn "not yet implemented, @facet fix pls!!!"

      return if @isLoading or @getData().count <= @lastFetchedItemCount and @showMore
      @isLoading = yes
      @groupLoader = new KDLoaderView
        cssClass : "new-members-loader"
        size     :
          width  : 24

      @addSubView @groupLoader
      @groupLoader.show()
      @showMore?.hide()

      count = 10

      if not @isUserViewCreated
        @createCloseButton()
        @isUserViewCreated = yes

      selector    =
        type      : { $in : [options.type or= 'CNewMemberBucketActivity'] }
        createdAt :
          $gt     : @lastFetchedDate or @getData().createdAtTimestamps[0]
          $lt     : @getData().createdAtTimestamps[1]

      options     =
        limit     : count

      KD.getSingleton("appManager").tell "Activity", "fetch", selector, options, (teasers, activities) =>
        @getData().anchors = @getData().anchors.concat teasers.map (item)-> item.anchor
        @group.setData @getData().anchors

        items = @getData().anchors.slice @lastFetchedItemCount, @lastFetchedItemCount + count

        newMembersList = new KDListViewController
          view        : new NewMemberList
          wrapper     : no
          scrollView  : no
        , items: items

        @listViews.push newMembersList
        @addSubView newMembersList.getView()
        @lastFetchedItemCount = @lastFetchedItemCount + count
        @showMore.hide() if @getData().count <= @lastFetchedItemCount and @showMore
        @lastFetchedDate = activities.last.createdAt
        @groupLoader.destroy()
        @createShowMore count
        @isLoading = no

  createCloseButton: ->
    @addSubView @closeButton = new KDView
      cssClass : "close-button"
      partial  : "Close"
      click    : =>
        list.getView().destroy() for list in @listViews
        @closeButton.destroy()
        @showMore?.destroy()
        @groupLoader?.destroy()
        @lastFetchedItemCount = 0
        @isUserViewCreated    = no
        @isLoading            = no
        @lastFetchedDate      = null
        @listViews            = []

  createShowMore: (count) ->
    return if @getData().count < @lastFetchedItemCount
    @addSubView @showMore = new KDView
      cssClass : "show-more"
      partial  : "Show More"
      click    : =>
        @group.emit "moreLinkClicked"
        @showMore.hide() if @getData().count <= @lastFetchedItemCount + count

  pistachio:->
    """
    <span class='icon fx out'></span>
    <span class='icon'></span>
    {{> @group}}
    """


class NewMemberList extends KDListView
  constructor: (options = {}, data) ->
    options.tagName   = "ul"
    options.cssClass  = "activity-new-members"
    options.itemClass = NewMemberListItem

    super options, data


class NewMemberLinkGroup extends LinkGroup

  constructor:(options = {}, data)->

    options.suffix or= " became a member."
    super options, data

  createMoreLink:->

    @more.destroy() if @more
    {totalCount, group} = @getOptions()
    @more = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "more"
      partial     : "#{totalCount-3} more"
      attributes  :
        href      : "#"
        title     : "Click to view..."
      click       : (e)=>
        @emit "moreLinkClicked"



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
