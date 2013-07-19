class ActivityInnerNavigation extends CommonInnerNavigation

  viewAppended:->

    filterController = @setListController
      type: "filterme"
      itemClass: ListGroupShowMeItem
    , @filterMenuData

    @addSubView filterController.getView()
    filterController.selectItem filterController.getItemsOrdered().first

    showMeFilterController = @setListController
      type : "showme"
      itemClass : ListGroupShowMeItem
    , @followerMenuData

    KD.getSingleton('mainController').on "AccountChanged", (account)=>
      filterController.reset()
      filterController.selectItem filterController.getItemsOrdered()[0]

    @addSubView showMeFilterController.getView()
    showMeFilterController.selectItem showMeFilterController.getItemsOrdered()[0]

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
      {title: "Public",    type: "Public" },
      {title: "Following", type: "Followed", role: "member" }
    ]

  followerMenuData :
    title : "SHOW ME"
    items : [
        { title: "Everything",      type: "Everything" }
        { title : "Status Updates", type : "JStatusUpdate" }
        { title : "Blog Posts",     type : "JBlogPost" }
        { title : "Code Snippets",  type : "JCodeSnip" }
        { title : "Discussions",    type : "JDiscussion" }
        { title : "Tutorials",      type : "JTutorial" }
    ]
