class FilterActivityItem extends CommonInnerNavigationListItem
  click: (event) ->
    if @getData().disabledForBeta
      new KDNotificationView
        title : "Coming Soon!"
        duration : 1000
      return no


class ActivityInnerNavigation extends CommonInnerNavigation

  viewAppended:()->

    filterFirstController = @setListController
      type: "filterme"
      itemClass: FilterActivityItem
    , @filterMenuData

    console.log("KONFIG", JSON.stringify(KD.config))

    useNeo4j = false
    if useNeo4j
      @addSubView filterFirstController.getView()
      filterFirstController.selectItem filterFirstController.getItemsOrdered()[0]

    filterController = @setListController
      type : "showme"
      itemClass : ListGroupShowMeItem
    , @followerMenuData
    @addSubView filterController.getView()
    filterController.selectItem filterController.getItemsOrdered()[0]

    @addSubView helpBox = new HelpBox
      subtitle    : "About Your Activity Feed"
      tooltip     :
        title     : "<p class=\"bigtwipsy\">The Activity feed displays posts from the people and topics you follow on Koding. It's also the central place for sharing updates, code, links, discussions and questions with the community. </p>"
        placement : "above"
        offset    : 0
        delayIn   : 300
        html      : yes
        animate   : yes

  filterMenuData :
    title: 'FILTER'
    items: [
      {title: "Public", filterType: "Public" },
      {title: "Following", filterType: "Followed"}
    ]

  followerMenuData :
    title : "SHOW ME"
    items : [
        { title: "Everything", type: "Everything" }
        { title : "Status Updates", type : "JStatusUpdate" }
        { title : "Blog Posts", type : "JBlogPost" }
        { title : "Code Snippets", type : "JCodeSnip" }
        { title : "Discussions", type : "JDiscussion" }
        { title : "Tutorials", type : "JTutorial" }
        { title : "Links", type : "JLink", disabledForBeta : yes }
    ]
