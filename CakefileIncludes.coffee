Includes =
  changedAt : Math.round(Date.now()/1000)
  order:
    Cake :
      Main    :
        includes        : "./CakefileIncludes.coffee"
    Server:
      Stuff:
        config          : "./empty.coffee"

    Client:
      Framework :
        sockjs                      : "./client/libs/sockjs-0.3-patched.js"
        broker                      : "./node_modules/koding-broker-client/browser/broker.js"
        bongojs                     : "./node_modules/bongo-client/browser/bongo.js"
        # core
        __utils             : "./client/Framework/core/utils.coffee"
        KD                  : "./client/Framework/core/KD.coffee"
        KDEventEmitter      : "./client/Framework/core/KDEventEmitter.coffee"
        KDObject            : "./client/Framework/core/KDObject.coffee"
        KDView              : "./client/Framework/core/KDView.coffee"
        JView               : "./client/Framework/core/JView.coffee"
        KDCustomHTMLView    : "./client/Framework/core/KDCustomHTMLView.coffee"
        KDScrollView        : "./client/Framework/core/KDScrollView.coffee"
        KDRouter            : "./client/Framework/core/KDRouter.coffee"

        KDController        : "./client/Framework/core/KDController.coffee"
        KDWindowController  : "./client/Framework/core/KDWindowController.coffee"
        KDViewController    : "./client/Framework/core/KDViewController.coffee"

        # components

        # image
        KDImage             : "./client/Framework/components/image/KDImage.coffee"

        # split
        KDSplitView         : "./client/Framework/components/split/splitview.coffee"
        KDSplitResizer      : "./client/Framework/components/split/splitresizer.coffee"
        KDSplitPanel        : "./client/Framework/components/split/splitpanel.coffee"

        # header
        KDHeaderView        : "./client/Framework/components/header/KDHeaderView.coffee"

        # loader
        KDLoaderView        : "./client/Framework/components/loader/KDLoaderView.coffee"

        #list
        KDListViewController  : "./client/Framework/components/list/KDListViewController.coffee"
        KDListView            : "./client/Framework/components/list/KDListView.coffee"
        KDListItemView        : "./client/Framework/components/list/KDListItemView.coffee"

        #tree
        JTreeViewController   : "./client/Framework/components/tree/treeviewcontroller.coffee"
        JTreeView             : "./client/Framework/components/tree/treeview.coffee"
        JTreeItemView         : "./client/Framework/components/tree/treeitemview.coffee"

        #tabs
        KDTabHandleView       : "./client/Framework/components/tabs/KDTabHandleView.coffee"
        KDTabView             : "./client/Framework/components/tabs/KDTabView.coffee"
        KDTabPaneView         : "./client/Framework/components/tabs/KDTabPaneView.coffee"
        KDTabViewWithForms    : "./client/Framework/components/tabs/KDTabViewWithForms.coffee"

        # menus
        JContextMenu          : "./client/Framework/components/contextmenu/contextmenu.coffee"
        JContextMenuTreeViewController : "./client/Framework/components/contextmenu/contextmenutreeviewcontroller.coffee"
        JContextMenuTreeView  : "./client/Framework/components/contextmenu/contextmenutreeview.coffee"
        JContextMenuItem      : "./client/Framework/components/contextmenu/contextmenuitem.coffee"

        # inputs
        KDInputValidator      : "./client/Framework/components/inputs/KDInputValidator.coffee"
        KDLabelView           : "./client/Framework/components/inputs/KDLabelView.coffee"
        KDInputView           : "./client/Framework/components/inputs/KDInputView.coffee"
        KDInputViewWithPreview: "./client/Framework/components/inputs/KDInputViewWithPreview.coffee"
        KDHitEnterInputView   : "./client/Framework/components/inputs/KDHitEnterInputView.coffee"
        KDInputRadioGroup     : "./client/Framework/components/inputs/KDInputRadioGroup.coffee"
        KDInputSwitch         : "./client/Framework/components/inputs/KDInputSwitch.coffee"
        KDOnOffSwitch         : "./client/Framework/components/inputs/KDOnOffSwitch.coffee"
        KDMultipleChoice      : "./client/Framework/components/inputs/KDMultipleChoice.coffee"
        KDSelectBox           : "./client/Framework/components/inputs/KDSelectBox.coffee"
        KDSliderView          : "./client/Framework/components/inputs/KDSliderView.coffee"
        KDWmdInput            : "./client/Framework/components/inputs/KDWmdInput.coffee"
        KDTokenizedMenu       : "./client/Framework/components/inputs/tokenizedmenu.coffee"
        KDTokenizedInput      : "./client/Framework/components/inputs/tokenizedinput.coffee"

        # upload
        kdmultipartuploader : "./client/Framework/components/upload/kdmultipartuploader.coffee"
        KDFileUploadView    : "./client/Framework/components/upload/KDFileUploadView.coffee"
        KDImageUploadView   : "./client/Framework/components/upload/KDImageUploadView.coffee"

        # buttons
        KDButtonView          : "./client/Framework/components/buttons/KDButtonView.coffee"
        KDButtonViewWithMenu  : "./client/Framework/components/buttons/KDButtonViewWithMenu.coffee"
        KDButtonMenu          : "./client/Framework/components/buttons/KDButtonMenu.coffee"
        KDButtonGroupView     : "./client/Framework/components/buttons/KDButtonGroupView.coffee"

        # forms
        KDFormView            : "./client/Framework/components/forms/KDFormView.coffee"
        KDFormViewWithFields  : "./client/Framework/components/forms/KDFormViewWithFields.coffee"

        # modal
        KDModalController     : "./client/Framework/components/modals/KDModalController.coffee"
        KDModalView           : "./client/Framework/components/modals/KDModalView.coffee"
        KDModalViewLoad       : "./client/Framework/components/modals/KDModalViewLoad.coffee"
        KDBlockingModalView   : "./client/Framework/components/modals/KDBlockingModalView.coffee"
        KDModalViewWithForms  : "./client/Framework/components/modals/KDModalViewWithForms.coffee"

        # notification
        KDNotificationView    : "./client/Framework/components/notifications/KDNotificationView.coffee"

        # dialog
        KDDialogView          : "./client/Framework/components/dialog/KDDialogView.coffee"

        #tooltip
        KDToolTipMenu         : "./client/Framework/components/tooltip/KDToolTipMenu.coffee"
        KDTooltip             : "./client/Framework/components/tooltip/KDTooltip.coffee"

        # autocomplete
        KDAutoCompleteC       : "./client/Framework/components/autocomplete/autocompletecontroller.coffee"
        KDAutoComplete        : "./client/Framework/components/autocomplete/autocomplete.coffee"
        KDAutoCompleteList    : "./client/Framework/components/autocomplete/autocompletelist.coffee"
        KDAutoCompleteListItem: "./client/Framework/components/autocomplete/autocompletelistitem.coffee"
        MultipleInput         : "./client/Framework/components/autocomplete/multipleinputview.coffee"
        KDAutoCompleteMisc    : "./client/Framework/components/autocomplete/autocompletemisc.coffee"
        KDAutoCompletedItems  : "./client/Framework/components/autocomplete/autocompleteditems.coffee"
        registry              : "./client/Framework/classregistry.coffee"

      Applications :
        KiteChannel           : "./client/app/MainApp/channels/kitechannel.coffee"
        ApplicationManager    : "./client/app/MainApp/ApplicationManager.coffee"
        AppController         : "./client/app/MainApp/AppController.coffee"
        KodingAppController   : "./client/app/MainApp/kodingappcontroller.coffee"
        KodingAppsController  : "./client/app/MainApp/kodingappscontroller.coffee"
        AppStorage            : "./client/app/MainApp/AppStorage.coffee"

        MonitorController     : "./client/app/MainApp/monitor.coffee"
        MonitorView           : "./client/app/MainApp/monitorview.coffee"
        MembersAppController       : "./client/app/Applications/Members.kdapplication/AppController.coffee"
        AccountAppController       : "./client/app/Applications/Account.kdapplication/AppController.coffee"
        HomeAppController          : "./client/app/Applications/Home.kdapplication/AppController.coffee"
        ActivityAppController      : "./client/app/Applications/Activity.kdapplication/AppController.coffee"
        TopicsAppController        : "./client/app/Applications/Topics.kdapplication/AppController.coffee"
        FeederAppController        : "./client/app/Applications/Feeder.kdapplication/AppController.coffee"
        # EnvironmentAppController   : "./client/app/Applications/Environment.kdapplication/AppController.coffee"
        AppsAppController          : "./client/app/Applications/Apps.kdapplication/AppController.coffee"
        InboxAppController         : "./client/app/Applications/Inbox.kdapplication/AppController.coffee"
        DemosAppController         : "./client/app/Applications/Demos.kdapplication/AppController.coffee"
        StartTabAppController      : "./client/app/Applications/StartTab.kdapplication/AppController.coffee"

        # new ace
        AceAppView            : "./client/app/Applications/Ace.kdapplication/aceappview.coffee"
        AceAppController      : "./client/app/Applications/Ace.kdapplication/AppController.coffee"
        AceView               : "./client/app/Applications/Ace.kdapplication/AppView.coffee"
        Ace                   : "./client/app/Applications/Ace.kdapplication/ace.coffee"
        AceSettingsView       : "./client/app/Applications/Ace.kdapplication/acesettingsview.coffee"
        AceSettings           : "./client/app/Applications/Ace.kdapplication/acesettings.coffee"

        # groups
        # GroupsController      : "./client/app/Applications/Groups.kdapplication/groupscontroller.coffee"
        GroupData                : "./client/app/Applications/Groups.kdapplication/groupdata.coffee"
        GroupsAppController      : "./client/app/Applications/Groups.kdapplication/AppController.coffee"

        # localStorage
        LocalStorage                  : "./client/app/MainApp/localstorage.coffee"

        # termlib shell
        # AppRequirements :  './client/app/Applications/Shell.kdapplication/AppRequirements.coffee'
        # term            :  './client/app/Applications/Shell.kdapplication/termlib/src/termlib.js'
        # viewer
        Viewer          : './client/app/Applications/Viewer.kdapplication/AppController.coffee'

        # webterm
        WebTermAppView        : "./client/app/Applications/WebTerm.kdapplication/webtermappview.coffee"
        WebTermController     : "./client/app/Applications/WebTerm.kdapplication/AppController.coffee"
        WebTermView           : "./client/app/Applications/WebTerm.kdapplication/AppView.coffee"
        WebtermSettingsView   : "./client/app/Applications/WebTerm.kdapplication/webtermsettingsview.coffee"
        WebtermSettings       : "./client/app/Applications/WebTerm.kdapplication/webtermsettings.coffee"
        WebTerm1              : "./client/app/Applications/WebTerm.kdapplication/src/ControlCodeReader.coffee"
        WebTerm2              : "./client/app/Applications/WebTerm.kdapplication/src/Cursor.coffee"
        WebTerm3              : "./client/app/Applications/WebTerm.kdapplication/src/InputHandler.coffee"
        WebTerm4              : "./client/app/Applications/WebTerm.kdapplication/src/ScreenBuffer.coffee"
        WebTerm5              : "./client/app/Applications/WebTerm.kdapplication/src/StyledText.coffee"
        WebTerm6              : "./client/app/Applications/WebTerm.kdapplication/src/Terminal.coffee"

      ApplicationPageViews :

        ActivityListController      : "./client/app/Applications/Activity.kdapplication/activitylistcontroller.coffee"
        # ACTIVITY VIEWS
        ActivityAppView             : "./client/app/Applications/Activity.kdapplication/AppView.coffee"
        # Activity commons
        actActions                  : "./client/app/Applications/Activity.kdapplication/views/activityactions.coffee"
        activityinnernavigation     : "./client/app/Applications/Activity.kdapplication/views/activityinnernavigation.coffee"
        activitylistheader          : "./client/app/Applications/Activity.kdapplication/views/activitylistheader.coffee"
        activitysplitview           : "./client/app/Applications/Activity.kdapplication/views/activitysplitview.coffee"
        listgroupshowmeitem         : "./client/app/Applications/Activity.kdapplication/views/listgroupshowmeitem.coffee"
        ActivityItemChild           : "./client/app/Applications/Activity.kdapplication/views/activityitemchild.coffee"
        discussionactivityaction    : "./client/app/Applications/Activity.kdapplication/views/discussionactivityactions.coffee"
        tutorialactivityaction      : "./client/app/Applications/Activity.kdapplication/views/tutorialactivityactions.coffee"
        embedbox                    : "./client/app/Applications/Activity.kdapplication/views/embedbox.coffee"
        embedboxviews               : "./client/app/Applications/Activity.kdapplication/views/embedboxviews.coffee"
        NewMemberBucket             : "./client/app/Applications/Activity.kdapplication/views/newmemberbucket.coffee"

        # Activity widgets
        activityWidgetController    : "./client/app/Applications/Activity.kdapplication/widgets/widgetcontroller.coffee"
        activityWidget              : "./client/app/Applications/Activity.kdapplication/widgets/widgetview.coffee"
        activityWidgetButton        : "./client/app/Applications/Activity.kdapplication/widgets/widgetbutton.coffee"
        statusWidget                : "./client/app/Applications/Activity.kdapplication/widgets/statuswidget.coffee"
        questionWidget              : "./client/app/Applications/Activity.kdapplication/widgets/questionwidget.coffee"
        codeSnippetWidget           : "./client/app/Applications/Activity.kdapplication/widgets/codesnippetwidget.coffee"
        tutorialWidget              : "./client/app/Applications/Activity.kdapplication/widgets/tutorialwidget.coffee"
        discussionWidget            : "./client/app/Applications/Activity.kdapplication/widgets/discussionwidget.coffee"
        blogPostWidget              : "./client/app/Applications/Activity.kdapplication/widgets/blogpostwidget.coffee"

        # Activity content displays
        activityContentDisplay      : "./client/app/Applications/Activity.kdapplication/ContentDisplays/activitycontentdisplay.coffee"
        actUpdateDisplay            : "./client/app/Applications/Activity.kdapplication/ContentDisplays/StatusUpdate.coffee"
        actCodeSnippetDisplay       : "./client/app/Applications/Activity.kdapplication/ContentDisplays/CodeSnippet.coffee"
        actDiscussionDisplay        : "./client/app/Applications/Activity.kdapplication/ContentDisplays/Discussion.coffee"
        actTutorialDisplay          : "./client/app/Applications/Activity.kdapplication/ContentDisplays/tutorial.coffee"
        acBlogPostDisplay           : "./client/app/Applications/Activity.kdapplication/ContentDisplays/blogpost.coffee"

        actQADisplay                : "./client/app/Applications/Activity.kdapplication/ContentDisplays/QA.coffee"
        actLinkDisplay              : "./client/app/Applications/Activity.kdapplication/ContentDisplays/link.coffee"
        # Activity content displays commons
        ContentDisplayAvatar        : "./client/app/Applications/Activity.kdapplication/ContentDisplays/ContentDisplayAuthorAvatar.coffee"
        ContentDisplayMeta          : "./client/app/Applications/Activity.kdapplication/ContentDisplays/ContentDisplayMeta.coffee"
        ContentDisplayMetaTags      : "./client/app/Applications/Activity.kdapplication/ContentDisplays/ContentDisplayTags.coffee"
        ContentDisplayComments      : "./client/app/Applications/Activity.kdapplication/ContentDisplays/ContentDisplayComments.coffee"
        ContentDisplayScoreBoard    : "./client/app/Applications/Activity.kdapplication/ContentDisplays/ContentDisplayScoreBoard.coffee"
        # Activity List Items
        ActListItem                 : "./client/app/Applications/Activity.kdapplication/ListItems/ActivityListItem.coffee"
        ActListItemStatusUpdate     : "./client/app/Applications/Activity.kdapplication/ListItems/ActivityListItemStatusUpdate.coffee"
        ActListItemCodeSnippet      : "./client/app/Applications/Activity.kdapplication/ListItems/ActivityListItemCodeSnippet.coffee"
        ActListItemBlogPost         : "./client/app/Applications/Activity.kdapplication/ListItems/ActivityListItemBlogPost.coffee"
        ActListItemDiscussion       : "./client/app/Applications/Activity.kdapplication/ListItems/ActivityListItemDiscussion.coffee"
        ActListItemFollow           : "./client/app/Applications/Activity.kdapplication/ListItems/ActivityListItemFollow.coffee"
        ActListItemLink             : "./client/app/Applications/Activity.kdapplication/ListItems/ActivityListItemLink.coffee"
        ActListItemQuestion         : "./client/app/Applications/Activity.kdapplication/ListItems/ActivityListItemQuestion.coffee"
        ActListItemTutorial         : "./client/app/Applications/Activity.kdapplication/ListItems/ActivityListItemTutorial.coffee"
        SelActListItem              : "./client/app/Applications/Activity.kdapplication/ListItems/SelectableActivityListItem.coffee"
        SelActListItemTutorial      : "./client/app/Applications/Activity.kdapplication/ListItems/SelectableActivityListItemTutorial.coffee"

        # TOPICS VIEWS
        topicsAppView                 : "./client/app/Applications/Topics.kdapplication/AppView.coffee"
        topicContentDisplay           : "./client/app/Applications/Topics.kdapplication/ContentDisplays/Topic.coffee"
        TopicSplitViewController      : "./client/app/Applications/Topics.kdapplication/ContentDisplays/TopicSplitViewController.coffee"
        topicsInnerNavigation         : "./client/app/Applications/Topics.kdapplication/Views/TopicsInnerNavigation.coffee"
        topicsListItemView            : "./client/app/Applications/Topics.kdapplication/Views/TopicsListItemView.coffee"

        # GROUPS CONTROLLERS
        invitationrequestlistcontroller: "./client/app/Applications/Groups.kdapplication/controllers/invitationrequestlistcontroller.coffee"

        # GROUPS VIEWS
        groupsWebhookView             : "./client/app/Applications/Groups.kdapplication/Views/groupswebhookview.coffee"
        groupsEditableWebhookView     : "./client/app/Applications/Groups.kdapplication/Views/groupseditablewebhookview.coffee"
        groupsMembershipPolicyEditor  : "./client/app/Applications/Groups.kdapplication/Views/groupsmembershippolicyeditor.coffee"
        groupsMembershipPolicyDetailView: "./client/app/Applications/Groups.kdapplication/Views/groupsmembershippolicydetailview.coffee"
        groupsrequestview             : "./client/app/Applications/Groups.kdapplication/Views/groupsrequestview.coffee"
        groupsinvitationrequestlistitemview: "./client/app/Applications/Groups.kdapplication/Views/groupsinvitationrequestlistitemview.coffee"
        groupsinvitationrequestsview  : "./client/app/Applications/Groups.kdapplication/Views/groupsinvitationrequestsview.coffee"
        groupsmemberpermissionslistitemview: "./client/app/Applications/Groups.kdapplication/Views/groupsmemberpermissionslistitemview.coffee"
        groupsmemberpermissionsview   : "./client/app/Applications/Groups.kdapplication/Views/groupsmemberpermissionsview.coffee"
        groupsmemberroleseditview     : "./client/app/Applications/Groups.kdapplication/Views/groupsmemberroleseditview.coffee"
        groupsmembershippolicyview    : "./client/app/Applications/Groups.kdapplication/Views/groupsmembershippolicyview.coffee"
        groupsformgeneratorview       : "./client/app/Applications/Groups.kdapplication/Views/groupsformgeneratorview.coffee"
        groupslandingpageloginlink    : "./client/app/Applications/Groups.kdapplication/Views/groupslandingpageloginlink.coffee"

        groupTabHandleView            : "./client/app/Applications/Groups.kdapplication/Views/grouptabhandleview.coffee"

        joinButton                    : "./client/app/Applications/Groups.kdapplication/Views/joinbutton.coffee"
        groupsAppView                 : "./client/app/Applications/Groups.kdapplication/AppView.coffee"
        groupsInnerNavigation         : "./client/app/Applications/Groups.kdapplication/Views/GroupsInnerNavigation.coffee"
        groupsListItemView            : "./client/app/Applications/Groups.kdapplication/Views/GroupsListItemView.coffee"
        permissionsGrid               : "./client/app/Applications/Groups.kdapplication/Views/PermissionsGrid.coffee"
        permissionsModal              : "./client/app/Applications/Groups.kdapplication/Views/permissionsmodal.coffee"
        groupView                     : "./client/app/Applications/Groups.kdapplication/Views/groupview.coffee"
        groupReadmeView               : "./client/app/Applications/Groups.kdapplication/Views/readmeview.coffee"
        groupPermissionView           : "./client/app/Applications/Groups.kdapplication/Views/permissionview.coffee"
        groupGeneralSettingsView      : "./client/app/Applications/Groups.kdapplication/Views/generalsettingsview.coffee"
        groupsDisplay                 : "./client/app/Applications/Groups.kdapplication/ContentDisplays/controller.coffee"
        groupsAdminModal              : "./client/app/Applications/Groups.kdapplication/Views/groupadminmodal.coffee"

        # APPS VIEWS
        appsAppView                   : "./client/app/Applications/Apps.kdapplication/AppView.coffee"

        appsInnerNavigation           : "./client/app/Applications/Apps.kdapplication/Views/AppsInnerNavigation.coffee"
        appslistItemView              : "./client/app/Applications/Apps.kdapplication/Views/AppsListItemView.coffee"
        appSubmissionModal            : "./client/app/Applications/Apps.kdapplication/Views/AppSubmission.coffee"
        appInfoView                   : "./client/app/Applications/Apps.kdapplication/Views/appinfoview.coffee"
        appView                       : "./client/app/Applications/Apps.kdapplication/Views/appview.coffee"
        appScreenshotListItem         : "./client/app/Applications/Apps.kdapplication/Views/appscreenshotlistitem.coffee"
        appScreenshotsView            : "./client/app/Applications/Apps.kdapplication/Views/appscreenshotsview.coffee"
        appDetailsView                : "./client/app/Applications/Apps.kdapplication/Views/appdetailsview.coffee"

        appsDisplay                   : "./client/app/Applications/Apps.kdapplication/ContentDisplays/controller.coffee"
        singleAppNavigation           : "./client/app/Applications/Apps.kdapplication/ContentDisplays/SingleAppNavigation.coffee"

        # MEMBERS VIEWS
        membersAppView                : "./client/app/Applications/Members.kdapplication/AppView.coffee"
        membersCDisplayController     : "./client/app/Applications/Members.kdapplication/ContentDisplays/ContentDisplayControllerMember.coffee"
        ownprofileview                : "./client/app/Applications/Members.kdapplication/ContentDisplays/ownprofileview.coffee"
        profileview                   : "./client/app/Applications/Members.kdapplication/ContentDisplays/profileview.coffee"
        contactlink                   : "./client/app/Applications/Members.kdapplication/ContentDisplays/contactlink.coffee"

        # START TAB VIEWS
        startTabAppView               : "./client/app/Applications/StartTab.kdapplication/AppView.coffee"
        startTabAppThumbView          : "./client/app/Applications/StartTab.kdapplication/views/appthumbview.coffee"
        startTabAppThumbViewOld       : "./client/app/Applications/StartTab.kdapplication/views/appthumbview.old.coffee"
        startTabRecentFileView        : "./client/app/Applications/StartTab.kdapplication/views/recentfileview.coffee"
        startTabAppThumbContainer     : "./client/app/Applications/StartTab.kdapplication/views/appcontainer.coffee"

        # INBOX CONTROLLERS
        inboxMessageListController    : "./client/app/Applications/Inbox.kdapplication/Controllers/InboxMessageListController.coffee"
        inboxNotificationsController  : "./client/app/Applications/Inbox.kdapplication/Controllers/InboxNotificationsController.coffee"

        # INBOX VIEWS
        inboxAppView                  : "./client/app/Applications/Inbox.kdapplication/AppView.coffee"
        inboxInnerNavigation          : "./client/app/Applications/Inbox.kdapplication/Views/InboxInnerNavigation.coffee"
        inboxMessagesList             : "./client/app/Applications/Inbox.kdapplication/Views/InboxMessagesList.coffee"
        inboxMessageThreadView        : "./client/app/Applications/Inbox.kdapplication/Views/InboxMessageThreadView.coffee"
        inboxNewMessageBar            : "./client/app/Applications/Inbox.kdapplication/Views/InboxNewMessageBar.coffee"
        inboxMessageDetail            : "./client/app/Applications/Inbox.kdapplication/Views/InboxMessageDetail.coffee"
        inboxReplyForm                : "./client/app/Applications/Inbox.kdapplication/Views/InboxReplyForm.coffee"
        # inboxReplyMessageView         : "./client/app/Applications/Inbox.kdapplication/Views/InboxReplyMessageView.coffee"
        inboxReplyView                : "./client/app/Applications/Inbox.kdapplication/Views/InboxReplyView.coffee"

        # FEED CONTROLLERS
        FeedController                : "./client/app/Applications/Feeder.kdapplication/FeedController.coffee"
        FeederFacetsController        : "./client/app/Applications/Feeder.kdapplication/Controllers/FeederFacetsController.coffee"
        FeederResultsController       : "./client/app/Applications/Feeder.kdapplication/Controllers/FeederResultsController.coffee"

        # FEED VIEWS
        FeederSplitView               : "./client/app/Applications/Feeder.kdapplication/Views/FeederSplitView.coffee"
        FeederTabView                 : "./client/app/Applications/Feeder.kdapplication/Views/FeederTabView.coffee"


        # HOME VIEWS
        homeAppView                   : "./client/app/Applications/Home.kdapplication/AppView.coffee"

        aboutView                     : "./client/app/Applications/Home.kdapplication/ContentDisplays/AboutView.coffee"

        footerView                    : "./client/app/Applications/Home.kdapplication/Views/FooterBarContents.coffee"

        #ABOUT VIEWS

        # DEMO VIEWS
        demoAppView                   : "./client/app/Applications/Demos.kdapplication/AppView.coffee"

        # GroupsFakeController          : "./client/app/Applications/GroupsFake.kdapplication/AppController.coffee"

        # ACCOUNT SETTINGS

        accountPass                   : "./client/app/Applications/Account.kdapplication/account/accSettingsPersPassword.coffee"
        accountUsername               : "./client/app/Applications/Account.kdapplication/account/accSettingsPersUsername.coffee"
        accountLinked                 : "./client/app/Applications/Account.kdapplication/account/accSettingsPersLinkedAccts.coffee"
        accountEmailNotifications     : "./client/app/Applications/Account.kdapplication/account/accSettingsPersEmailNotifications.coffee"
        # accountDatabases              : "./client/app/Applications/Account.kdapplication/account/accSettingsDevDatabases.coffee"
        accountEditors                : "./client/app/Applications/Account.kdapplication/account/accSettingsDevEditors.coffee"
        accountMounts                 : "./client/app/Applications/Account.kdapplication/account/accSettingsDevMounts.coffee"
        accountRepos                  : "./client/app/Applications/Account.kdapplication/account/accSettingsDevRepos.coffee"
        accountSshKeys                : "./client/app/Applications/Account.kdapplication/account/accSettingsDevSshKeys.coffee"

        accountPayMethods             : "./client/app/Applications/Account.kdapplication/account/accSettingsPaymentHistory.coffee"
        accountPayHistory             : "./client/app/Applications/Account.kdapplication/account/accSettingsPaymentMethods.coffee"
        accountSubs                   : "./client/app/Applications/Account.kdapplication/account/accSettingsSubscriptions.coffee"
        accountMain                   : "./client/app/Applications/Account.kdapplication/AppView.coffee"

        # CONTENT DISPLAY VIEWS
        contentDisplay                : "./client/app/MainApp/ContentDisplay/ContentDisplay.coffee"
        contentDisplayController      : "./client/app/MainApp/ContentDisplay/ContentDisplayController.coffee"

        # KITE CONTROLLER
        KiteController                : "./client/app/MainApp/KiteController.coffee"

        #
        # OLD PAGES
        #
        # pageHome              : "./client/app/MainApp/oldPages/pageHome.coffee"
        # pageRegister          : "./client/app/MainApp/oldPages/pageRegister.coffee"
        # pageEnvironment       : "./client/app/MainApp/oldPages/pageEnvironment.coffee"


        # ENVIRONMENT SETTINGS
        # envSideBar            : "./client/app/MainApp/oldPages/environment/envSideBar.coffee"
        # envViewMenu           : "./client/app/MainApp/oldPages/environment/envViewMenu.coffee"
        # envViewSummary        : "./client/app/MainApp/oldPages/environment/envViewSummary.coffee"
        # envViewUsage          : "./client/app/MainApp/oldPages/environment/envViewUsage.coffee"
        # envViewTopProcess     : "./client/app/MainApp/oldPages/environment/envViewTopProcesses.coffee"
        # envViewMounts         : "./client/app/MainApp/oldPages/environment/envViewMounts.coffee"

        # PAYMENT
        # tabs                  : "./client/app/MainApp/oldPages/payment/tabs.coffee"
        # overview              : "./client/app/MainApp/oldPages/payment/overview.coffee"
        # settings              : "./client/app/MainApp/oldPages/payment/settings.coffee"
        # history               : "./client/app/MainApp/oldPages/payment/history.coffee"

        # IRC
        # ircCustomViews        : "./client/app/MainApp/oldPages/irc/customViews.coffee"
        # ircLists              : "./client/app/MainApp/oldPages/irc/lists.coffee"
        # ircTabs               : "./client/app/MainApp/oldPages/irc/tabs.coffee"
        accountMixins             : "./client/app/MainApp/account-mixins.coffee"
        main                      : "./client/app/MainApp/main.coffee"

      Application :
        sharedRoutes                : "./routes/index.coffee"
        kodingrouter                : "./client/app/MainApp/kodingrouter.coffee"
        #broker                      : "./broker/apps/broker/priv/www/js/broker.js"
        bongo_mq                    : "./client/app/MainApp/mq.config.coffee"
        pistachio                   : "./node_modules/pistachio/browser/pistachio.js"

        # mainapp controllers
        activitycontroller          : "./client/app/MainApp/activitycontroller.coffee"
        notificationcontroller      : "./client/app/MainApp/notificationcontroller.coffee"

        # COMMON VIEWS

        ApplicationTabHandleHolder : "./client/app/CommonViews/applicationview/applicationtabhandleholder.coffee"
        ApplicationTabView         : "./client/app/CommonViews/applicationview/applicationtabview.coffee"

        linkView                    : "./client/app/CommonViews/linkviews/linkview.coffee"
        customLinkView              : "./client/app/CommonViews/linkviews/customlinkview.coffee"
        linkGroup                   : "./client/app/CommonViews/linkviews/linkgroup.coffee"
        profileLinkView             : "./client/app/CommonViews/linkviews/profilelinkview.coffee"
        profileTextView             : "./client/app/CommonViews/linkviews/profiletextview.coffee"
        profileTextGroup            : "./client/app/CommonViews/linkviews/profiletextgroup.coffee"
        tagLinkView                 : "./client/app/CommonViews/linkviews/taglinkview.coffee"
        appLinkView                 : "./client/app/CommonViews/linkviews/applinkview.coffee"
        activityTagGroup            : "./client/app/CommonViews/linkviews/activitychildviewtaggroup.coffee"
        autoCompleteProfileTextView : "./client/app/CommonViews/linkviews/autocompleteprofiletextview.coffee"
        splitView                   : "./client/app/CommonViews/splitview.coffee"
        slidingSplitView            : "./client/app/CommonViews/slidingsplit.coffee"

        avatarView                  : "./client/app/CommonViews/avatarviews/avatarview.coffee"
        avatarStaticView            : "./client/app/CommonViews/avatarviews/avatarstaticview.coffee"
        avatarSwapView              : "./client/app/CommonViews/avatarviews/avatarswapview.coffee"
        autoCompleteAvatarView      : "./client/app/CommonViews/avatarviews/autocompleteavatarview.coffee"

        LinkViews                   : "./client/app/CommonViews/LinkViews.coffee"
        VideoPopup                  : "./client/app/CommonViews/VideoPopup.coffee"

        LikeView                    : "./client/app/CommonViews/LikeView.coffee"
        TagGroups                   : "./client/app/CommonViews/Tags/TagViews.coffee"
        FormViews                   : "./client/app/CommonViews/FormViews.coffee"
        messagesList                : "./client/app/CommonViews/messagesList.coffee"
        inputWithButton             : "./client/app/CommonViews/CommonInputWithButton.coffee"
        SplitWithOlderSiblings      : "./client/app/CommonViews/SplitViewWithOlderSiblings.coffee"
        ContentPageSplitBelowHeader : "./client/app/CommonViews/ContentPageSplitBelowHeader.coffee"
        CommonListHeader            : "./client/app/CommonViews/CommonListHeader.coffee"
        CommonInnerNavigation       : "./client/app/CommonViews/CommonInnerNavigation.coffee"
        Headers                     : "./client/app/CommonViews/headers.coffee"
        # Logo                        : "./client/app/CommonViews/logo.coffee"
        HelpBox                     : "./client/app/CommonViews/HelpBox.coffee"
        KeyboardHelperView          : "./client/app/CommonViews/KeyboardHelper.coffee"
        Navigation                  : "./client/app/CommonViews/Navigation.coffee"
        TagAutoCompleteController   : "./client/app/CommonViews/Tags/TagAutoCompleteController.coffee"
        VerifyPINModal              : "./client/app/CommonViews/VerifyPINModal.coffee"

        FollowButton                : "./client/app/CommonViews/followbutton.coffee"

        ManageRemotesModal          : "./client/app/CommonViews/remotesmodal.coffee"
        ManageDatabaseModal         : "./client/app/CommonViews/databasesmodal.coffee"

        CommentView                 : "./client/app/CommonViews/comments/commentview.coffee"
        CommentListViewController   : "./client/app/CommonViews/comments/commentlistviewcontroller.coffee"
        CommentViewHeader           : "./client/app/CommonViews/comments/commentviewheader.coffee"
        CommentListItemView         : "./client/app/CommonViews/comments/commentlistitemview.coffee"
        CommentNewCommentForm       : "./client/app/CommonViews/comments/newcommentform.coffee"

        ReviewView                  : "./client/app/CommonViews/reviews/reviewview.coffee"
        ReviewListViewController    : "./client/app/CommonViews/reviews/reviewlistviewcontroller.coffee"
        ReviewListItemView          : "./client/app/CommonViews/reviews/reviewlistitemview.coffee"
        ReviewNewReviewForm         : "./client/app/CommonViews/reviews/newreviewform.coffee"

        OpinionView                   : "./client/app/CommonViews/opinions/opinionview.coffee"
        DiscussionActivityOpinionView : "./client/app/CommonViews/opinions/discussionactivityopinionview.coffee"
        DiscussionActivityOpinionLI   : "./client/app/CommonViews/opinions/discussionactivityopinionlistitemview.coffee"
        TutorialActivityOpinionView   : "./client/app/CommonViews/opinions/tutorialactivityopinionview.coffee"
        TutorialActivityOpinionLI     : "./client/app/CommonViews/opinions/tutorialactivityopinionlistitemview.coffee"
        TutorialOpinionViewHeader     : "./client/app/CommonViews/opinions/tutorialopinionviewheader.coffee"
        OpinionViewHeader             : "./client/app/CommonViews/opinions/opinionviewheader.coffee"
        OpinionListViewController     : "./client/app/CommonViews/opinions/opinionlistviewcontroller.coffee"
        OpinionListItemView           : "./client/app/CommonViews/opinions/opinionlistitemview.coffee"
        OpinionCommentListItemView    : "./client/app/CommonViews/opinions/opinioncommentlistitemview.coffee"
        OpinionFormView               : "./client/app/CommonViews/opinions/opinionformview.coffee"
        OpinionCommentView            : "./client/app/CommonViews/opinions/opinioncommentview.coffee"
        DiscussionFormView            : "./client/app/CommonViews/opinions/discussionformview.coffee"
        TutorialFormView              : "./client/app/CommonViews/opinions/tutorialformview.coffee"

        MarkdownText                  : "./client/app/CommonViews/markdownmodal.coffee"


        # foreign_auth                : "./client/app/MainApp/foreign_auth.coffee"
        sidebarController           : "./client/app/MainApp/sidebar/sidebarcontroller.coffee"
        sidebar                     : "./client/app/MainApp/sidebar/sidebarview.coffee"
        sidebarResizeHandle         : "./client/app/MainApp/sidebar/sidebarresizehandle.coffee"
        sidebarFooterMenuItem       : "./client/app/MainApp/sidebar/footermenuitem.coffee"
        sidebarAdminModal           : "./client/app/MainApp/sidebar/modals/adminmodal.coffee"
        sidebarKiteSelector         : "./client/app/MainApp/sidebar/modals/kiteselector.coffee"

        # BOOK
        bookTOC                     : "./client/app/MainApp/book/embedded/tableofcontents.coffee"
        bookUpdateWidget            : "./client/app/MainApp/book/embedded/updatewidget.coffee"
        bookTopics                  : "./client/app/MainApp/book/embedded/topics.coffee"
        bookDevelopButton           : "./client/app/MainApp/book/embedded/developbutton.coffee"
        bookData                    : "./client/app/MainApp/book/bookdata.coffee"
        bookView                    : "./client/app/MainApp/book/bookview.coffee"
        bookPage                    : "./client/app/MainApp/book/bookpage.coffee"

        #maintabs

        MainTabView                 : "./client/app/MainApp/maintabs/maintabview.coffee"
        MainTabPane                 : "./client/app/MainApp/maintabs/maintabpaneview.coffee"
        MainTabHandleHolder         : "./client/app/MainApp/maintabs/maintabhandleholder.coffee"

        # global notifications
        GlobalNotification          : "./client/app/MainApp/globalnotification.coffee"

        ### SINANS FINDER ###

        NFinderController             : "./client/app/MainApp/filetree/controllers/findercontroller.coffee"
        NFinderTreeController         : "./client/app/MainApp/filetree/controllers/findertreecontroller.coffee"
        NFinderContextMenuController  : "./client/app/MainApp/filetree/controllers/findercontextmenucontroller.coffee"

        NFinderItem                   : "./client/app/MainApp/filetree/itemviews/finderitem.coffee"
        NFileItem                     : "./client/app/MainApp/filetree/itemviews/fileitem.coffee"
        NFolderItem                   : "./client/app/MainApp/filetree/itemviews/folderitem.coffee"
        NMountItem                    : "./client/app/MainApp/filetree/itemviews/mountitem.coffee"
        NBrokenLinkItem               : "./client/app/MainApp/filetree/itemviews/brokenlinkitem.coffee"
        NSectionItem                  : "./client/app/MainApp/filetree/itemviews/sectionitem.coffee"

        NFinderItemDeleteView         : "./client/app/MainApp/filetree/itemsubviews/finderitemdeleteview.coffee"
        NFinderItemDeleteDialog       : "./client/app/MainApp/filetree/itemsubviews/finderitemdeletedialog.coffee"
        NFinderItemRenameView         : "./client/app/MainApp/filetree/itemsubviews/finderitemrenameview.coffee"
        NSetPermissionsView           : "./client/app/MainApp/filetree/itemsubviews/setpermissionsview.coffee"
        NCopyUrlView                  : "./client/app/MainApp/filetree/itemsubviews/copyurlview.coffee"
        # re-used files
        FinderBottomControlsListItem  : "./client/app/MainApp/filetree/bottomlist/finderbottomlist.coffee"
        FinderBottomControls          : "./client/app/MainApp/filetree/bottomlist/finderbottomlistitem.coffee"

        # fs representation
        FSHelper                  : "./client/app/MainApp/fs/fshelper.coffee"
        FSItem                    : "./client/app/MainApp/fs/fsitem.coffee"
        FSFile                    : "./client/app/MainApp/fs/fsfile.coffee"
        FSFolder                  : "./client/app/MainApp/fs/fsfolder.coffee"
        FSMount                   : "./client/app/MainApp/fs/fsmount.coffee"
        FSBrokenLink              : "./client/app/MainApp/fs/fsbrokenlink.coffee"

        avatarPopup                      : "./client/app/MainApp/avatararea/avatarareapopup.coffee"
        avatarAreaIconMenu               : "./client/app/MainApp/avatararea/avatarareaiconmenu.coffee"
        avatarAreaIconLink               : "./client/app/MainApp/avatararea/avatarareaiconlink.coffee"
        avatarAreaStatusPopup            : "./client/app/MainApp/avatararea/avatarareasharestatuspopup.coffee"
        avatarAreaMessagesPopup          : "./client/app/MainApp/avatararea/avatarareamessagespopup.coffee"
        avatarAreaNotificationsPopup     : "./client/app/MainApp/avatararea/avatarareanotificationspopup.coffee"
        avatarAreaGroupSwitcherPopup     : "./client/app/MainApp/avatararea/avatarareagroupswitcherpopup.coffee"
        avatarPopupList                  : "./client/app/MainApp/avatararea/avatarareapopuplist.coffee"
        avatarPopupMessagesListItem      : "./client/app/MainApp/avatararea/avatarareapopupmessageslistitem.coffee"
        avatarPopupNotificationsListItem : "./client/app/MainApp/avatararea/avatarareapopupnotificationslistitem.coffee"


        # LOGIN VIEWS
        loginView                 : "./client/app/MainApp/login/loginview.coffee"
        loginform                 : "./client/app/MainApp/login/loginform.coffee"
        logininputs               : "./client/app/MainApp/login/logininputs.coffee"
        loginoptions              : "./client/app/MainApp/login/loginoptions.coffee"
        registeroptions           : "./client/app/MainApp/login/registeroptions.coffee"
        registerform              : "./client/app/MainApp/login/registerform.coffee"
        recoverform               : "./client/app/MainApp/login/recoverform.coffee"
        resetform                 : "./client/app/MainApp/login/resetform.coffee"
        requestform               : "./client/app/MainApp/login/requestform.coffee"

        # static profile views
        staticprofilesettings       : "./client/app/MainApp/staticprofilesettings.coffee"

        # BOTTOM PANEL
        # bottomPanelController     : "./client/app/MainApp/bottompanels/bottompanelcontroller.coffee"
        # bottomPanel               : "./client/app/MainApp/bottompanels/bottompanel.coffee"
        # bottomChatPanel           : "./client/app/MainApp/bottompanels/chat/chatpanel.coffee"
        # bottomChatRoom            : "./client/app/MainApp/bottompanels/chat/chatroom.coffee"
        # bottomChatSidebar         : "./client/app/MainApp/bottompanels/chat/chatsidebar.coffee"
        # bottomChatUserItem        : "./client/app/MainApp/bottompanels/chat/chatuseritem.coffee"
        # bottomTerminalPanel       : "./client/app/MainApp/bottompanels/terminal/terminalpanel.coffee"

        KodingMainView            : "./client/app/MainApp/maincontroller/mainview.coffee"
        KodingMainViewController  : "./client/app/MainApp/maincontroller/mainviewcontroller.coffee"
        KodingMainController      : "./client/app/MainApp/maincontroller/maincontroller.coffee"

        # these are libraries, but adding it here so they are minified properly
        # minifying jquery breaks the code.


        jqueryHash        : "./client/libs/jquery-hashchange.js"
        jqueryTimeAgo     : "./client/libs/jquery-timeago.js"
        jqueryDateFormat  : "./client/libs/date.format.js"
        jqueryCookie      : "./client/libs/jquery.cookie.js"
        jqueryGetCss      : "./client/libs/jquery.getcss.js"
        # keypress          : "./client/libs/keypress.js"
        mousetrap         : "./client/libs/mousetrap.js"
        # jqueryWmd         : "./client/libs/jquery.wmd.js"
        # jqueryFieldSelect : "./client/libs/jquery.fieldselection.js"
        # multiselect       : "./client/libs/jquery.multiselect.min.js"
        # log4js            : "./client/libs/log4js.js"
        # jsonh             : "./client/libs/jsonh.js"
        md5               : "./client/libs/md5-min.js"
        # froogaloop        : "./client/libs/frogaloop.min.js"

        bootstrapTwipsy   : "./client/libs/bootstrap-twipsy.js"
        jTipsy            : "./client/libs/jquery.tipsy.js"
        async             : "./client/libs/async.js"
        jMouseWheel       : "./client/libs/jquery.mousewheel.js"
        jMouseWheelIntent : "./client/libs/mwheelIntent.js"
        inflector         : "./client/libs/inflector.js"
        canvasLoader      : "./client/libs/canvas-loader.js"

        marked            : "./client/libs/marked.js"
        # google_code_prettify : "./client/libs/google-code-prettify/prettify.js"
        # lessCompiler      : "./client/libs/less.min.js"

        # xml2json          : "./client/libs/xml2json.js"
        # zeroClipboard     : "./client/libs/ZeroClipboard.js"

        jspath             : "./client/app/Helpers/jspath.coffee"

        # Command            : "./client/app/Helpers/Command.coffee"
        # FileEmitter        : "./client/app/Helpers/FileEmitter.coffee"
        # polyfills          : "./client/app/Helpers/polyfills.coffee"
        # command_parser     : "./client/app/Helpers/CommandParser.coffee"

      Libraries :
        jquery            : "./client/libs/jquery-1.8.2.js"
        # jqueryUI          : "./client/libs/jquery-ui-1.8.16.custom.min.js"
        #pusher            : "./client/libs/pusher.min.js"
        underscore        : "./client/libs/underscore.1.4.4.js"
        sharedRoutes      : "./routes/index.coffee"
        html_encoder      : "./client/libs/encode.js"
        docwriteNoop      : "./client/libs/docwritenoop.js"
        sha1              : "./client/libs/sha1.encapsulated.coffee"
        # highlightjs       : "./client/libs/highlight.pack.js"
        # threeJS           : "./client/libs/three.js" ==> added for testplay, please dont delete
        # jqueryEmit        : "./client/libs/jquery-emit.js"


      StylusFiles  :

        kdfn                : "./client/Framework/themes/default/kdfn.styl"
        appfn               : "./client/stylus/appfn.styl"


        kd                  : "./client/Framework/themes/default/kd.styl"
        kdInput             : "./client/Framework/themes/default/kd.input.styl"
        kdTreeView          : "./client/Framework/themes/default/kd.treeview.styl"
        kdContextMenu       : "./client/Framework/themes/default/kd.contextmenu.styl"
        kdDialog            : "./client/Framework/themes/default/kd.dialog.styl"
        kdButtons           : "./client/Framework/themes/default/kd.buttons.styl"
        kdScrollView        : "./client/Framework/themes/default/kd.scrollview.styl"
        kdModalView         : "./client/Framework/themes/default/kd.modal.styl"
        kdFormView          : "./client/Framework/themes/default/kd.form.styl"
        kdTooltip           : "./client/Framework/themes/default/kd.tooltip.styl"
        kdFileUploader      : "./client/Framework/themes/default/kd.fileuploader.styl"
        # kdTipTip            : "./client/stylus/kd.tiptip.styl" => discarded

        app                 : "./client/stylus/app.styl"
        appBottom           : "./client/stylus/app.bottom.styl"
        appabout            : "./client/stylus/app.about.styl"
        appcommons          : "./client/stylus/app.commons.styl"
        appeditor           : "./client/stylus/app.editor.styl"
        appfinder           : "./client/stylus/app.finder.styl"
        appaceeditor        : "./client/stylus/app.aceeditor.styl"
        activity            : "./client/stylus/app.activity.styl"
        appcontextmenu      : "./client/stylus/app.contextmenu.styl"
        # appchat             : "./client/stylus/app.chat.styl"
        appsettings         : "./client/stylus/app.settings.styl"
        appinbox            : "./client/stylus/app.inbox.styl"
        # appenvsettings      : "./client/stylus/app.envsettings.styl"
        appmembers          : "./client/stylus/app.members.styl"
        comments            : "./client/stylus/app.comments.styl"
        bootstrap           : "./client/stylus/app.bootstrap.styl"
        apploginsignup      : "./client/stylus/app.login-signup.styl"
        appkeyboard         : "./client/stylus/app.keyboard.styl"
        appmarkdown         : "./client/stylus/app.markdown.styl"
        appprofile          : "./client/stylus/app.profile.styl"
        appstore            : "./client/stylus/appstore.styl"
        apphome             : "./client/stylus/app.home.styl"
        appTopics           : "./client/stylus/app.topics.styl"
        appContentDisplays  : "./client/stylus/app.contentdisplays.styl"
        starttab            : "./client/stylus/app.starttab.styl"
        viewer              : "./client/stylus/app.viewer.styl"
        book                : "./client/stylus/app.book.styl"
        codeshare           : "./client/stylus/app.codeshare.styl"
        groups              : "./client/stylus/app.group.styl"
        user                : "./client/stylus/app.user.styl"

        temp             : "./client/stylus/temp.styl"

        # mediaqueries should stay at the bottom
        app1200             : "./client/stylus/app.1200.styl"
        app1024             : "./client/stylus/app.1024.styl"
        app768              : "./client/stylus/app.768.styl"
        app480              : "./client/stylus/app.480.styl"

        WebTermTheme1 :     "./client/app/Applications/WebTerm.kdapplication/themes/green-on-black.styl"
        WebTermTheme2 :     "./client/app/Applications/WebTerm.kdapplication/themes/gray-on-black.styl"
        WebTermTheme3 :     "./client/app/Applications/WebTerm.kdapplication/themes/black-on-white.styl"

      CssFiles  :
        reset               : "./client/css/style.css"
        highlightSunburst   : "./client/css/highlight-styles/sunburst.css"
        tipsy               : "./client/css/tipsy.css"

module.exports = Includes
