Includes =
  changedAt : Math.round(Date.now()/1000)
  order:
    Cake :
      Main    :
        includes        : "./CakefileIncludes.coffee"
    Server:
      Stuff:
        config          : "./empty.coffee"
        # dependencies    : "./server/dependencies.coffee"
        # errors          : "./server/app/errors.coffee"
        # initConfig      : "./server/app/initConfig.coffee"
        # emailer         : "./server/app/emailer.coffee"
        # base            : "./server/app/base.coffee"
        # utils           : "./server/app/utils.coffee"
        #jspath          : "./server/app/jspath.coffee"
        # access_control  : "./server/app/access_control.coffee"
        # output_filters  : "./server/app/output_filters.coffee"
        # api             : "./server/app/api.coffee"
        # auth            : "./server/app/auth.coffee"
        # exec            : "./server/app/exec.coffee"
        # ftp             : "./server/app/ftp.coffee"
        # job             : "./server/app/job.coffee"
        # jobq            : "./server/app/jobq.coffee"
        # resource        : "./server/app/resource.coffee"
        # server          : "./server/app/server.coffee"
        # foreign_auth    : "./server/app/foreign_auth.coffee"
        # shell           : "./server/app/shell.coffee"
        # status          : "./server/app/status.coffee"
        # team            : "./server/app/team.coffee"
        # Irc             : "./server/app/irc.coffee"


        #KiteController  : "./server/app/core/KiteController.coffee"
        # archiver        : "./server/app/core/archiver.coffee"
        # limit           : "./server/app/core/limit.coffee"
        # allocation      : "./server/app/core/allocation.coffee"
        # register        : "./server/app/core/register.coffee"
        #localization    : "./server/app/core/localization.coffee"
        # relationship    : "./server/app/core/relationship.coffee"
        # permission      : "./server/app/core/permission.coffee"
        # tag             : "./server/app/core/taxonomy.coffee"
        # uniqueid        : "./server/app/core/uniqueid.coffee"
        # module          : "./server/app/core/module.coffee"
        # moduleSelection : "./server/app/core/module.selection.coffee"
        # modulecapsule   : "./server/app/core/modulecapsule.coffee"
        # notifier        : "./server/app/core/notifier.coffee"
        # session         : "./server/app/core/session.coffee"
        # message         : "./server/app/core/message.coffee"
        # messageNotifier : "./server/app/core/message.notifier.coffee"
        # cronJob         : "./server/app/core/cronjob.coffee"

        # flag                        : "./server/app/metadata/flag.coffee"
        # metadata                    : "./server/app/metadata/metadata.coffee"
        # metadataUniqueView          : "./server/app/metadata/metadata.uniqueview.coffee"
        # metadataVote                : "./server/app/metadata/metadata.vote.coffee"
        # metadataInappropriate       : "./server/app/metadata/metadata.inappropriate.coffee"
        # metadataLike                : "./server/app/metadata/metadata.like.coffee"
        # metadataExperiencepoints    : "./server/app/metadata/metadata.experiencepoints.coffee"

      #Models :
        # jchannel                  : "./server/app/bongo/models/channel.coffee"
        # jemailnotification        : "./server/app/bongo/models/emailnotification.coffee"
        # jemailconfirmation        : "./server/app/bongo/models/emailconfirmation.coffee"
        # # bongo models:
        # jactivity                 : "./server/app/bongo/models/activity/activity.coffee"
        # jreplyactivity            : "./server/app/bongo/models/activity/reply.coffee"
        # jabstractActivity         : "./server/app/bongo/models/activity/abstract.coffee"
        # jstatusactivity           : "./server/app/bongo/models/activity/status.coffee"
        # jcodeactivity             : "./server/app/bongo/models/activity/code.coffee"
        # jquestionactivity         : "./server/app/bongo/models/activity/question.coffee"
        # jdiscussionactivity       : "./server/app/bongo/models/activity/discussion.coffee"
        # jlinkactivity             : "./server/app/bongo/models/activity/link.coffee"

        # activity redo:


        # # abstractions
        # followable                : "./server/app/bongo/abstractions/followable.coffee"
        # filterable                : "./server/app/bongo/abstractions/filterable.coffee"
        # taggable                  : "./server/app/bongo/abstractions/taggable.coffee"
        # notifying                 : "./server/app/bongo/abstractions/notifying.coffee"
        # notifiable                : "./server/app/bongo/abstractions/notifiable.coffee"
        # flaggable                 : "./server/app/bongo/abstractions/flaggable.coffee"


        # cactivity                 : "./server/app/bongo/models/activity.coffee"
        # cbucket                   : "./server/app/bongo/models/bucket.coffee"

        # jlimit                    : "./server/app/bongo/models/limit.coffee"
        # jmount                    : "./server/app/bongo/models/mount.coffee"
        # jrepo                     : "./server/app/bongo/models/repo.coffee"
        # jdatabase                 : "./server/app/bongo/models/database.coffee"
        # jappstorage               : "./server/app/bongo/models/appStorage.coffee"
        # jaccount                  : "./server/app/bongo/models/account.coffee"
        # jsession                  : "./server/app/bongo/models/session.coffee"
        # juser                     : "./server/app/bongo/models/user.coffee"
        # jguest                    : "./server/app/bongo/models/guest.coffee"
        # jvisitor                  : "./server/app/bongo/models/visitor.coffee"
        # jhyperlink                : "./server/app/bongo/models/hyperlink.coffee"

        # jregistrationpreferences  : "./server/app/bongo/models/registrationpreferences.coffee"

        # # jterminal                  : "./server/app/bongo/models/terminal.coffee"

        # fsWatcher                  : "./server/app/bongo/models/fsWatcher.coffee"

        # jtag                      : "./server/app/bongo/models/tag.coffee"

        # jcomment                  : "./server/app/bongo/models/messages/comment.coffee"
        # jpost                     : "./server/app/bongo/models/messages/post.coffee"
        # jstatusupdate             : "./server/app/bongo/models/messages/status.coffee"
        # jcodesnip                 : "./server/app/bongo/models/messages/codesnip.coffee"
        # janswer                   : "./server/app/bongo/models/messages/answer.coffee"
        # jquestion                 : "./server/app/bongo/models/messages/question.coffee"
        # jprivatemessage           : "./server/app/bongo/models/messages/privatemessage.coffee"
        # japp                      : "./server/app/bongo/models/app.coffee"
        # jreview                   : "./server/app/bongo/models/messages/review.coffee"

        # jinvitation               : "./server/app/bongo/models/invitation.coffee"
        # jinvitationrequest        : "./server/app/bongo/models/invitationrequest.coffee"
        # jpasswordrecovery         : "./server/app/bongo/models/passwordrecovery.coffee"
        # jkitecluster              : "./server/app/bongo/models/kitecontroller/kitecluster.coffee"
        # jkiteconnection           : "./server/app/bongo/models/kitecontroller/kiteconnection.coffee"


      # OtherStuff :
        # moduledata            : "./server/app/core/moduledata.coffee"
        # moduledata_deprecated : "./server/app/core/moduledata_deprecated.coffee"
        # defaultAllocations    : "./server/app/defaults/defaultallocations.coffee"
        # defaultProducts       : "./server/app/defaults/defaultproducts.coffee"
        # migrant               : "./server/migrate/migrant.coffee"
        # mysqlMigrant          : "./server/migrate/mysqlmigrant.coffee"
        # ohlohDump             : "./server/migrate/migrants/ohlohdump.coffee"
        # userDump              : "./server/migrate/migrants/userdump.coffee"
        # groupsDump            : "./server/migrate/migrants/groupsdump.coffee"
        # postsDump             : "./server/migrate/migrants/postsdump.coffee"
        # unwrapper             : "./server/migrate/migrants/unwrapper.coffee"
        # main                  : "./server/app/main.coffee"

    Client:
      Framework :

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
        KDTreeViewController  : "./client/Framework/components/tree/KDTreeViewController.coffee"
        KDTreeView            : "./client/Framework/components/tree/KDTreeView.coffee"
        KDTreeItemView        : "./client/Framework/components/tree/KDTreeItemView.coffee"
        JTreeViewController   : "./client/Framework/components/tree/treeviewcontroller.coffee"
        JTreeView             : "./client/Framework/components/tree/treeview.coffee"
        JTreeItemView         : "./client/Framework/components/tree/treeitemview.coffee"

        #tabs
        KDTabViewController   : "./client/Framework/components/tabs/KDTabViewController.coffee"
        KDTabView             : "./client/Framework/components/tabs/KDTabView.coffee"
        KDTabPaneView         : "./client/Framework/components/tabs/KDTabPaneView.coffee"
        KDTabViewWithForms    : "./client/Framework/components/tabs/KDTabViewWithForms.coffee"

        # menus
        KDContextMenu         : "./client/Framework/components/menus/KDContextMenu.coffee"

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
        KDSelectBox           : "./client/Framework/components/inputs/KDSelectBox.coffee"
        KDSliderView          : "./client/Framework/components/inputs/KDSliderView.coffee"
        KDWmdInput            : "./client/Framework/components/inputs/KDWmdInput.coffee"
        KDTokenizedMenu       : "./client/Framework/components/inputs/tokenizedmenu.coffee"
        KDTokenizedInput      : "./client/Framework/components/inputs/tokenizedinput.coffee"

        # upload
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
        ApplicationManager    : "./client/app/MainApp/ApplicationManager.coffee"
        AppController         : "./client/app/MainApp/AppController.coffee"
        DocumentManager       : "./client/app/MainApp/DocumentManager.coffee"
        KodingAppsController  : "./client/app/MainApp/kodingappscontroller.coffee"
        AppStorage            : "./client/app/MainApp/AppStorage.coffee"

        Members12345          : "./client/app/Applications/Members.kdapplication/AppController.coffee"
        Account12345          : "./client/app/Applications/Account.kdapplication/AppController.coffee"
        Home12345             : "./client/app/Applications/Home.kdapplication/AppController.coffee"
        Activity12345         : "./client/app/Applications/Activity.kdapplication/AppController.coffee"
        Topics12345           : "./client/app/Applications/Topics.kdapplication/AppController.coffee"
        Feeder12345           : "./client/app/Applications/Feeder.kdapplication/AppController.coffee"
        # Environment12345      : "./client/app/Applications/Environment.kdapplication/AppController.coffee"
        Apps12345             : "./client/app/Applications/Apps.kdapplication/AppController.coffee"
        Inbox12345            : "./client/app/Applications/Inbox.kdapplication/AppController.coffee"
        Demos12345            : "./client/app/Applications/Demos.kdapplication/AppController.coffee"
        StartTab12345         : "./client/app/Applications/StartTab.kdapplication/AppController.coffee"

        # new ace
        Ace12345              : "./client/app/Applications/Ace.kdapplication/AppController.coffee"
        AceView               : "./client/app/Applications/Ace.kdapplication/AppView.coffee"
        Ace                   : "./client/app/Applications/Ace.kdapplication/ace.coffee"
        AceSettingsView       : "./client/app/Applications/Ace.kdapplication/acesettingsview.coffee"
        AceSettings           : "./client/app/Applications/Ace.kdapplication/acesettings.coffee"

        # groups
        GroupsController      : "./client/app/Applications/Groups.kdapplication/AppController.coffee"
        # termlib shell
        # AppRequirements :  './client/app/Applications/Shell.kdapplication/AppRequirements.coffee'
        # term            :  './client/app/Applications/Shell.kdapplication/termlib/src/termlib.js'
        # viewer
        Viewer          : './client/app/Applications/Viewer.kdapplication/AppController.coffee'

        # webterm
        WebTermController     : "./client/app/Applications/WebTerm.kdapplication/AppController.coffee"
        WebTermView           : "./client/app/Applications/WebTerm.kdapplication/AppView.coffee"
        WebTerm1              : "./client/app/Applications/WebTerm.kdapplication/src/ControlCodeReader.coffee"
        WebTerm2              : "./client/app/Applications/WebTerm.kdapplication/src/Cursor.coffee"
        WebTerm3              : "./client/app/Applications/WebTerm.kdapplication/src/InputHandler.coffee"
        WebTerm4              : "./client/app/Applications/WebTerm.kdapplication/src/ScreenBuffer.coffee"
        WebTerm5              : "./client/app/Applications/WebTerm.kdapplication/src/StyledText.coffee"
        WebTerm6              : "./client/app/Applications/WebTerm.kdapplication/src/Terminal.coffee"

      ApplicationPageViews :

        # ACTIVITY VIEWS

        # Activity commons
        actActions                  : "./client/app/Applications/Activity.kdapplication/views/activityactions.coffee"
        activityinnernavigation     : "./client/app/Applications/Activity.kdapplication/views/activityinnernavigation.coffee"
        activitylistheader          : "./client/app/Applications/Activity.kdapplication/views/activitylistheader.coffee"
        activitysplitview           : "./client/app/Applications/Activity.kdapplication/views/activitysplitview.coffee"
        listgroupshowmeitem         : "./client/app/Applications/Activity.kdapplication/views/listgroupshowmeitem.coffee"
        ActivityItemChild           : "./client/app/Applications/Activity.kdapplication/views/activityitemchild.coffee"
        discussionactivityaction    : "./client/app/Applications/Activity.kdapplication/views/discussionactivityactions.coffee"
        tutorialactivityaction      : "./client/app/Applications/Activity.kdapplication/views/tutorialactivityactions.coffee"
        codesharebox                : "./client/app/Applications/Activity.kdapplication/views/codesharebox.coffee"
        codesharetab                : "./client/app/Applications/Activity.kdapplication/views/codesharetabview.coffee"
        codesharetabpane            : "./client/app/Applications/Activity.kdapplication/views/codesharetabpaneview.coffee"
        embedbox                    : "./client/app/Applications/Activity.kdapplication/views/embedbox.coffee"
        embedboxviews               : "./client/app/Applications/Activity.kdapplication/views/embedboxviews.coffee"

        # Activity widgets
        activityWidgetController    : "./client/app/Applications/Activity.kdapplication/widgets/widgetcontroller.coffee"
        activityWidget              : "./client/app/Applications/Activity.kdapplication/widgets/widgetview.coffee"
        activityWidgetButton        : "./client/app/Applications/Activity.kdapplication/widgets/widgetbutton.coffee"
        statusWidget                : "./client/app/Applications/Activity.kdapplication/widgets/statuswidget.coffee"
        questionWidget              : "./client/app/Applications/Activity.kdapplication/widgets/questionwidget.coffee"
        codeSnippetWidget           : "./client/app/Applications/Activity.kdapplication/widgets/codesnippetwidget.coffee"
        codeShareWidget             : "./client/app/Applications/Activity.kdapplication/widgets/codesharewidget.coffee"
        linkWidget                  : "./client/app/Applications/Activity.kdapplication/widgets/linkwidget.coffee"
        tutorialWidget              : "./client/app/Applications/Activity.kdapplication/widgets/tutorialwidget.coffee"
        discussionWidget            : "./client/app/Applications/Activity.kdapplication/widgets/discussionwidget.coffee"

        # Activity content displays
        activityContentDisplay      : "./client/app/Applications/Activity.kdapplication/ContentDisplays/activitycontentdisplay.coffee"
        actUpdateDisplay            : "./client/app/Applications/Activity.kdapplication/ContentDisplays/StatusUpdate.coffee"
        actCodeSnippetDisplay       : "./client/app/Applications/Activity.kdapplication/ContentDisplays/CodeSnippet.coffee"
        actDiscussionDisplay        : "./client/app/Applications/Activity.kdapplication/ContentDisplays/Discussion.coffee"
        actTutorialDisplay          : "./client/app/Applications/Activity.kdapplication/ContentDisplays/tutorial.coffee"
        actCodeShareDisplay         : "./client/app/Applications/Activity.kdapplication/ContentDisplays/codeshare.coffee"

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
        ActListItemCodeShare        : "./client/app/Applications/Activity.kdapplication/ListItems/ActivityListItemCodeShare.coffee"
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

        # GROUPS VIEWS
        groupsAppView                 : "./client/app/Applications/Groups.kdapplication/AppView.coffee"
        groupsInnerNavigation         : "./client/app/Applications/Groups.kdapplication/Views/GroupsInnerNavigation.coffee"
        groupsListItemView            : "./client/app/Applications/Groups.kdapplication/Views/GroupsListItemView.coffee"
        permissionsGrid               : "./client/app/Applications/Groups.kdapplication/Views/PermissionsGrid.coffee"
        groupView                     : "./client/app/Applications/Groups.kdapplication/Views/groupview.coffee"
        groupsDisplay                 : "./client/app/Applications/Groups.kdapplication/ContentDisplays/controller.coffee"

        # APPS VIEWS
        appsAppView                   : "./client/app/Applications/Apps.kdapplication/AppView.coffee"
        appsController                : "./client/app/Applications/Apps.kdapplication/AppController.coffee"

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
        inboxReplyMessageView         : "./client/app/Applications/Inbox.kdapplication/Views/InboxReplyMessageView.coffee"
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

        aboutContentDisplayController : "./client/app/Applications/Home.kdapplication/ContentDisplays/AboutContentDisplayController.coffee"
        aboutView                     : "./client/app/Applications/Home.kdapplication/ContentDisplays/AboutView.coffee"

        footerView                    : "./client/app/Applications/Home.kdapplication/Views/FooterBarContents.coffee"

        #ABOUT VIEWS

        # DEMO VIEWS
        demoAppView                   : "./client/app/Applications/Demos.kdapplication/AppView.coffee"

        # GroupsFakeController          : "./client/app/Applications/GroupsFake.kdapplication/AppController.coffee"

        # ACCOUNT SETTINGS

        accountPass                   : "./client/app/Applications/Account.kdapplication/account/accSettingsPersPassword.coffee"
        accountUsername               : "./client/app/Applications/Account.kdapplication/account/accSettingsPersUsernameEmail.coffee"
        accountLinked                 : "./client/app/Applications/Account.kdapplication/account/accSettingsPersLinkedAccts.coffee"

        accountDatabases              : "./client/app/Applications/Account.kdapplication/account/accSettingsDevDatabases.coffee"
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
        pageEnvironment       : "./client/app/MainApp/oldPages/pageEnvironment.coffee"


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
        sockjs                      : "./client/libs/sockjs-0.3.js"
        broker                      : "./node_modules/broker-client/browser/broker.js"
        bongojs                     : "./node_modules/bongo-client/browser/bongo.js"
        bongo_mq                    : "./client/app/MainApp/mq.config.coffee"
        pistachio                   : "./node_modules/pistachio/browser/pistachio.js"

        # mainapp controllers
        activitycontroller          : "./client/app/MainApp/activitycontroller.coffee"
        notificationcontroller      : "./client/app/MainApp/notificationcontroller.coffee"

        # COMMON VIEWS

        linkView                    : "./client/app/CommonViews/linkviews/linkview.coffee"
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
        CommonFeedMessage           : "./client/app/CommonViews/CommonFeedMessage.coffee"
        Headers                     : "./client/app/CommonViews/headers.coffee"
        # Logo                        : "./client/app/CommonViews/logo.coffee"
        HelpBox                     : "./client/app/CommonViews/HelpBox.coffee"
        KeyboardHelperView          : "./client/app/CommonViews/KeyboardHelper.coffee"
        Navigation                  : "./client/app/CommonViews/Navigation.coffee"
        TagAutoCompleteController   : "./client/app/CommonViews/Tags/TagAutoCompleteController.coffee"
        VerifyPINModal              : "./client/app/CommonViews/VerifyPINModal.coffee"

        FollowButton                : "./client/app/CommonViews/followbutton.coffee"

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

        ### SINANS FINDER ###

        NFinderController             : "./client/app/MainApp/filetree/controllers/findercontroller.coffee"
        NFinderTreeController         : "./client/app/MainApp/filetree/controllers/findertreecontroller.coffee"
        NFinderContextMenuController  : "./client/app/MainApp/filetree/controllers/findercontextmenucontroller.coffee"

        NFinderItem                   : "./client/app/MainApp/filetree/itemviews/finderitem.coffee"
        NFileItem                     : "./client/app/MainApp/filetree/itemviews/fileitem.coffee"
        NFolderItem                   : "./client/app/MainApp/filetree/itemviews/folderitem.coffee"
        NMountItem                    : "./client/app/MainApp/filetree/itemviews/mountitem.coffee"
        NSectionItem                  : "./client/app/MainApp/filetree/itemviews/sectionitem.coffee"

        NFinderItemDeleteView         : "./client/app/MainApp/filetree/itemsubviews/finderitemdeleteview.coffee"
        NFinderItemDeleteDialog       : "./client/app/MainApp/filetree/itemsubviews/finderitemdeletedialog.coffee"
        NFinderItemRenameView         : "./client/app/MainApp/filetree/itemsubviews/finderitemrenameview.coffee"
        NSetPermissionsView           : "./client/app/MainApp/filetree/itemsubviews/setpermissionsview.coffee"
        # re-used files
        FinderBottomControlsListItem  : "./client/app/MainApp/filetree/bottomlist/finderbottomlist.coffee"
        FinderBottomControls          : "./client/app/MainApp/filetree/bottomlist/finderbottomlistitem.coffee"

        # fs representation
        FSHelper                  : "./client/app/MainApp/fs/fshelper.coffee"
        FSItem                    : "./client/app/MainApp/fs/fsitem.coffee"
        FSFile                    : "./client/app/MainApp/fs/fsfile.coffee"
        FSFolder                  : "./client/app/MainApp/fs/fsfolder.coffee"
        FSMount                   : "./client/app/MainApp/fs/fsmount.coffee"

        avatarArea                : "./client/app/MainApp/avatararea.coffee"

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
        # underscore        : "./client/libs/underscore.js"
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
        #pusher            : "./client/libs/pusher.min.js"
        sharedRoutes      : "./routes/index.coffee"
        html_encoder      : "./client/libs/encode.js"
        docwriteNoop      : "./client/libs/docwritenoop.js"
        sha1              : "./client/libs/sha1.encapsulated.coffee"
        # highlightjs       : "./client/libs/highlight.pack.js"
        # jquery            : "./client/libs/jquery-1.7.1.js"
        # jquery            : "./client/libs/jquery-1.7.1.min.js"
        # jqueryUi          : "./client/libs/jquery-ui-1.8.16.custom.min.js"
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
        appprofile          : "./client/stylus/app.profile.styl"
        appstore            : "./client/stylus/appstore.styl"
        apphome             : "./client/stylus/app.home.styl"
        appTopics           : "./client/stylus/app.topics.styl"
        appContentDisplays  : "./client/stylus/app.contentdisplays.styl"
        starttab            : "./client/stylus/app.starttab.styl"
        viewer              : "./client/stylus/app.viewer.styl"
        book                : "./client/stylus/app.book.styl"
        codeshare           : "./client/stylus/app.codeshare.styl"

        temp             : "./client/stylus/temp.styl"

        # mediaqueries should stay at the bottom
        app1200             : "./client/stylus/app.1200.styl"
        app1024             : "./client/stylus/app.1024.styl"
        app768              : "./client/stylus/app.768.styl"
        app480              : "./client/stylus/app.480.styl"

        WebTermDefaultTheme : "./client/app/Applications/WebTerm.kdapplication/themes/default.styl"

      CssFiles  :
        reset               : "./client/css/style.css"
        highlightSunburst   : "./client/css/highlight-styles/sunburst.css"
        tipsy               : "./client/css/tipsy.css"

module.exports = Includes
