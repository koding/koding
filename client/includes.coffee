module.exports = [
  # --- Libraries ---
  # "libs/pusher.min.js",
  "routes.coffee",
  "libs/encode.js",
  "libs/docwritenoop.js",
  "libs/sha1.encapsulated.coffee",
  # "libs/highlight.pack.js",
  # "libs/jquery-1.7.1.js",
  # "libs/jquery-1.7.1.min.js",
  # "libs/jquery-ui-1.8.16.custom.min.js",
  # "libs/three.js" ==> added for testplay, please dont delete,
  # "libs/jquery-emit.js",

  # --- Framework ---
  "libs/sockjs-0.3-patched.js",
  "libs/broker.js",
  "libs/bongo.js",
  
  # core
  "Framework/core/utils.coffee",
  "Framework/core/KD.coffee",
  "Framework/core/KDEventEmitter.coffee",
  "Framework/core/KDObject.coffee",
  "Framework/core/KDView.coffee",
  "Framework/core/JView.coffee",
  "Framework/core/KDCustomHTMLView.coffee",
  "Framework/core/KDScrollView.coffee",
  "Framework/core/KDRouter.coffee",

  "Framework/core/KDController.coffee",
  "Framework/core/KDWindowController.coffee",
  "Framework/core/KDViewController.coffee",

  # components

  # image
  "Framework/components/image/KDImage.coffee",

  # split
  "Framework/components/split/splitview.coffee",
  "Framework/components/split/splitresizer.coffee",
  "Framework/components/split/splitpanel.coffee",

  # header
  "Framework/components/header/KDHeaderView.coffee",

  # loader
  "Framework/components/loader/KDLoaderView.coffee",

  #list
  "Framework/components/list/KDListViewController.coffee",
  "Framework/components/list/KDListView.coffee",
  "Framework/components/list/KDListItemView.coffee",

  #tree
  "Framework/components/tree/KDTreeViewController.coffee",
  "Framework/components/tree/KDTreeView.coffee",
  "Framework/components/tree/KDTreeItemView.coffee",
  "Framework/components/tree/treeviewcontroller.coffee",
  "Framework/components/tree/treeview.coffee",
  "Framework/components/tree/treeitemview.coffee",

  #tabs
  "Framework/components/tabs/KDTabViewController.coffee",
  "Framework/components/tabs/KDTabView.coffee",
  "Framework/components/tabs/KDTabPaneView.coffee",
  "Framework/components/tabs/KDTabViewWithForms.coffee",

  # menus
  "Framework/components/menus/KDContextMenu.coffee",

  # menus
  "Framework/components/contextmenu/contextmenu.coffee",
  "Framework/components/contextmenu/contextmenutreeviewcontroller.coffee",
  "Framework/components/contextmenu/contextmenutreeview.coffee",
  "Framework/components/contextmenu/contextmenuitem.coffee",

  # inputs
  "Framework/components/inputs/KDInputValidator.coffee",
  "Framework/components/inputs/KDLabelView.coffee",
  "Framework/components/inputs/KDInputView.coffee",
  "Framework/components/inputs/KDInputViewWithPreview.coffee",
  "Framework/components/inputs/KDHitEnterInputView.coffee",
  "Framework/components/inputs/KDInputRadioGroup.coffee",
  "Framework/components/inputs/KDInputSwitch.coffee",
  "Framework/components/inputs/KDOnOffSwitch.coffee",
  "Framework/components/inputs/KDMultipleChoice.coffee",
  "Framework/components/inputs/KDSelectBox.coffee",
  "Framework/components/inputs/KDSliderView.coffee",
  "Framework/components/inputs/KDWmdInput.coffee",
  "Framework/components/inputs/tokenizedmenu.coffee",
  "Framework/components/inputs/tokenizedinput.coffee",

  # upload
  "Framework/components/upload/KDFileUploadView.coffee",
  "Framework/components/upload/KDImageUploadView.coffee",

  # buttons
  "Framework/components/buttons/KDButtonView.coffee",
  "Framework/components/buttons/KDButtonViewWithMenu.coffee",
  "Framework/components/buttons/KDButtonMenu.coffee",
  "Framework/components/buttons/KDButtonGroupView.coffee",

  # forms
  "Framework/components/forms/KDFormView.coffee",
  "Framework/components/forms/KDFormViewWithFields.coffee",

  # modal
  "Framework/components/modals/KDModalController.coffee",
  "Framework/components/modals/KDModalView.coffee",
  "Framework/components/modals/KDModalViewLoad.coffee",
  "Framework/components/modals/KDBlockingModalView.coffee",
  "Framework/components/modals/KDModalViewWithForms.coffee",

  # notification
  "Framework/components/notifications/KDNotificationView.coffee",

  # dialog
  "Framework/components/dialog/KDDialogView.coffee",

  #tooltip
  "Framework/components/tooltip/KDToolTipMenu.coffee",
  "Framework/components/tooltip/KDTooltip.coffee",

  # autocomplete
  "Framework/components/autocomplete/autocompletecontroller.coffee",
  "Framework/components/autocomplete/autocomplete.coffee",
  "Framework/components/autocomplete/autocompletelist.coffee",
  "Framework/components/autocomplete/autocompletelistitem.coffee",
  "Framework/components/autocomplete/multipleinputview.coffee",
  "Framework/components/autocomplete/autocompletemisc.coffee",
  "Framework/components/autocomplete/autocompleteditems.coffee",
  "Framework/classregistry.coffee",

  # --- Application ---
  "routes.coffee",
  "app/MainApp/kodingrouter.coffee",
  "app/MainApp/mq.config.coffee",
  "libs/pistachio.js",

  # mainapp controllers
  "app/MainApp/activitycontroller.coffee",
  "app/MainApp/notificationcontroller.coffee",

  # COMMON VIEWS
  "app/CommonViews/linkviews/linkview.coffee",
  "app/CommonViews/linkviews/linkgroup.coffee",
  "app/CommonViews/linkviews/profilelinkview.coffee",
  "app/CommonViews/linkviews/profiletextview.coffee",
  "app/CommonViews/linkviews/profiletextgroup.coffee",
  "app/CommonViews/linkviews/taglinkview.coffee",
  "app/CommonViews/linkviews/applinkview.coffee",
  "app/CommonViews/linkviews/activitychildviewtaggroup.coffee",
  "app/CommonViews/linkviews/autocompleteprofiletextview.coffee",
  "app/CommonViews/splitview.coffee",
  "app/CommonViews/slidingsplit.coffee",

  "app/CommonViews/avatarviews/avatarview.coffee",
  "app/CommonViews/avatarviews/avatarstaticview.coffee",
  "app/CommonViews/avatarviews/avatarswapview.coffee",
  "app/CommonViews/avatarviews/autocompleteavatarview.coffee",

  "app/CommonViews/LinkViews.coffee",
  "app/CommonViews/VideoPopup.coffee",

  "app/CommonViews/LikeView.coffee",
  "app/CommonViews/Tags/TagViews.coffee",
  "app/CommonViews/FormViews.coffee",
  "app/CommonViews/messagesList.coffee",
  "app/CommonViews/CommonInputWithButton.coffee",
  "app/CommonViews/SplitViewWithOlderSiblings.coffee",
  "app/CommonViews/ContentPageSplitBelowHeader.coffee",
  "app/CommonViews/CommonListHeader.coffee",
  "app/CommonViews/CommonInnerNavigation.coffee",
  "app/CommonViews/CommonFeedMessage.coffee",
  "app/CommonViews/headers.coffee",
  # "app/CommonViews/logo.coffee",
  "app/CommonViews/HelpBox.coffee",
  "app/CommonViews/KeyboardHelper.coffee",
  "app/CommonViews/Navigation.coffee",
  "app/CommonViews/Tags/TagAutoCompleteController.coffee",
  "app/CommonViews/VerifyPINModal.coffee",

  "app/CommonViews/followbutton.coffee",

  "app/CommonViews/remotesmodal.coffee",
  "app/CommonViews/databasesmodal.coffee",

  "app/CommonViews/comments/commentview.coffee",
  "app/CommonViews/comments/commentlistviewcontroller.coffee",
  "app/CommonViews/comments/commentviewheader.coffee",
  "app/CommonViews/comments/commentlistitemview.coffee",
  "app/CommonViews/comments/newcommentform.coffee",

  "app/CommonViews/reviews/reviewview.coffee",
  "app/CommonViews/reviews/reviewlistviewcontroller.coffee",
  "app/CommonViews/reviews/reviewlistitemview.coffee",
  "app/CommonViews/reviews/newreviewform.coffee",

  "app/CommonViews/opinions/opinionview.coffee",
  "app/CommonViews/opinions/discussionactivityopinionview.coffee",
  "app/CommonViews/opinions/discussionactivityopinionlistitemview.coffee",
  "app/CommonViews/opinions/tutorialactivityopinionview.coffee",
  "app/CommonViews/opinions/tutorialactivityopinionlistitemview.coffee",
  "app/CommonViews/opinions/tutorialopinionviewheader.coffee",
  "app/CommonViews/opinions/opinionviewheader.coffee",
  "app/CommonViews/opinions/opinionlistviewcontroller.coffee",
  "app/CommonViews/opinions/opinionlistitemview.coffee",
  "app/CommonViews/opinions/opinioncommentlistitemview.coffee",
  "app/CommonViews/opinions/opinionformview.coffee",
  "app/CommonViews/opinions/opinioncommentview.coffee",
  "app/CommonViews/opinions/discussionformview.coffee",
  "app/CommonViews/opinions/tutorialformview.coffee",

  "app/CommonViews/markdownmodal.coffee",

  # "app/MainApp/foreign_auth.coffee",
  "app/MainApp/sidebar/sidebarcontroller.coffee",
  "app/MainApp/sidebar/sidebarview.coffee",
  "app/MainApp/sidebar/sidebarresizehandle.coffee",
  "app/MainApp/sidebar/footermenuitem.coffee",
  "app/MainApp/sidebar/modals/adminmodal.coffee",
  "app/MainApp/sidebar/modals/kiteselector.coffee",

  # BOOK
  "app/MainApp/book/embedded/tableofcontents.coffee",
  "app/MainApp/book/embedded/updatewidget.coffee",
  "app/MainApp/book/embedded/topics.coffee",
  "app/MainApp/book/embedded/developbutton.coffee",
  "app/MainApp/book/bookdata.coffee",
  "app/MainApp/book/bookview.coffee",
  "app/MainApp/book/bookpage.coffee",

  #maintabs

  "app/MainApp/maintabs/maintabview.coffee",
  "app/MainApp/maintabs/maintabpaneview.coffee",
  "app/MainApp/maintabs/maintabhandleholder.coffee",

  # global notifications
  "app/MainApp/globalnotification.coffee",

  # SINANS FINDER
  "app/MainApp/filetree/controllers/findercontroller.coffee",
  "app/MainApp/filetree/controllers/findertreecontroller.coffee",
  "app/MainApp/filetree/controllers/findercontextmenucontroller.coffee",

  "app/MainApp/filetree/itemviews/finderitem.coffee",
  "app/MainApp/filetree/itemviews/fileitem.coffee",
  "app/MainApp/filetree/itemviews/folderitem.coffee",
  "app/MainApp/filetree/itemviews/mountitem.coffee",
  "app/MainApp/filetree/itemviews/brokenlinkitem.coffee",
  "app/MainApp/filetree/itemviews/sectionitem.coffee",

  "app/MainApp/filetree/itemsubviews/finderitemdeleteview.coffee",
  "app/MainApp/filetree/itemsubviews/finderitemdeletedialog.coffee",
  "app/MainApp/filetree/itemsubviews/finderitemrenameview.coffee",
  "app/MainApp/filetree/itemsubviews/setpermissionsview.coffee",
  "app/MainApp/filetree/itemsubviews/copyurlview.coffee",
  # re-used files
  "app/MainApp/filetree/bottomlist/finderbottomlist.coffee",
  "app/MainApp/filetree/bottomlist/finderbottomlistitem.coffee",

  # fs representation
  "app/MainApp/fs/fshelper.coffee",
  "app/MainApp/fs/fsitem.coffee",
  "app/MainApp/fs/fsfile.coffee",
  "app/MainApp/fs/fsfolder.coffee",
  "app/MainApp/fs/fsmount.coffee",
  "app/MainApp/fs/fsbrokenlink.coffee",

  "app/MainApp/avatararea.coffee",

  # LOGIN VIEWS
  "app/MainApp/login/loginview.coffee",
  "app/MainApp/login/loginform.coffee",
  "app/MainApp/login/logininputs.coffee",
  "app/MainApp/login/loginoptions.coffee",
  "app/MainApp/login/registeroptions.coffee",
  "app/MainApp/login/registerform.coffee",
  "app/MainApp/login/recoverform.coffee",
  "app/MainApp/login/resetform.coffee",
  "app/MainApp/login/requestform.coffee",

  # BOTTOM PANEL
  # "app/MainApp/bottompanels/bottompanelcontroller.coffee",
  # "app/MainApp/bottompanels/bottompanel.coffee",
  # "app/MainApp/bottompanels/chat/chatpanel.coffee",
  # "app/MainApp/bottompanels/chat/chatroom.coffee",
  # "app/MainApp/bottompanels/chat/chatsidebar.coffee",
  # "app/MainApp/bottompanels/chat/chatuseritem.coffee",
  # "app/MainApp/bottompanels/terminal/terminalpanel.coffee",

  "app/MainApp/maincontroller/mainview.coffee",
  "app/MainApp/maincontroller/mainviewcontroller.coffee",
  "app/MainApp/maincontroller/maincontroller.coffee",

  # these are libraries, but adding it here so they are minified properly
  # minifying jquery breaks the code.


  "libs/jquery-hashchange.js",
  "libs/jquery-timeago.js",
  "libs/date.format.js",
  "libs/jquery.cookie.js",
  "libs/jquery.getcss.js",
  # "libs/keypress.js",
  "libs/mousetrap.js",
  # "libs/jquery.wmd.js",
  # "libs/jquery.fieldselection.js",
  # "libs/jquery.multiselect.min.js",
  # "libs/log4js.js",
  # "libs/jsonh.js",
  "libs/md5-min.js",
  # "libs/frogaloop.min.js",

  "libs/bootstrap-twipsy.js",
  "libs/jquery.tipsy.js",
  "libs/async.js",
  "libs/jquery.mousewheel.js",
  "libs/mwheelIntent.js",
  # "libs/underscore.js",
  "libs/inflector.js",
  "libs/canvas-loader.js",

  "libs/marked.js",
  # "libs/google-code-prettify/prettify.js",
  # "libs/less.min.js",

  # "libs/xml2json.js",
  # "libs/ZeroClipboard.js",

  "app/Helpers/jspath.coffee",

  # "app/Helpers/Command.coffee",
  # "app/Helpers/FileEmitter.coffee",
  # "app/Helpers/polyfills.coffee",
  # "app/Helpers/CommandParser.coffee",

  # --- Applications ---
  "app/MainApp/channels/kitechannel.coffee",
  "app/MainApp/ApplicationManager.coffee",
  "app/MainApp/AppController.coffee",
  "app/MainApp/DocumentManager.coffee",
  "app/MainApp/kodingappscontroller.coffee",
  "app/MainApp/AppStorage.coffee",

  "app/MainApp/monitor.coffee",
  "app/MainApp/monitorview.coffee",
  "app/Applications/Members.kdapplication/AppController.coffee",
  "app/Applications/Account.kdapplication/AppController.coffee",
  "app/Applications/Home.kdapplication/AppController.coffee",
  "app/Applications/Activity.kdapplication/AppController.coffee",
  "app/Applications/Topics.kdapplication/AppController.coffee",
  "app/Applications/Feeder.kdapplication/AppController.coffee",
  # "app/Applications/Environment.kdapplication/AppController.coffee",
  "app/Applications/Apps.kdapplication/AppController.coffee",
  "app/Applications/Inbox.kdapplication/AppController.coffee",
  "app/Applications/Demos.kdapplication/AppController.coffee",
  "app/Applications/StartTab.kdapplication/AppController.coffee",

  # new ace
  "app/Applications/Ace.kdapplication/AppController.coffee",
  "app/Applications/Ace.kdapplication/AppView.coffee",
  "app/Applications/Ace.kdapplication/ace.coffee",
  "app/Applications/Ace.kdapplication/acesettingsview.coffee",
  "app/Applications/Ace.kdapplication/acesettings.coffee",

  # groups
  "app/Applications/Groups.kdapplication/AppController.coffee",
  "app/Applications/Groups.kdapplication/groupscontroller.coffee",

  # termlib shell
  #  'app/Applications/Shell.kdapplication/AppRequirements.coffee',
  #  'app/Applications/Shell.kdapplication/termlib/src/termlib.js',
  # viewer
  'app/Applications/Viewer.kdapplication/AppController.coffee',

  # webterm
  "app/Applications/WebTerm.kdapplication/AppController.coffee",
  "app/Applications/WebTerm.kdapplication/AppView.coffee",
  "app/Applications/WebTerm.kdapplication/webtermsettingsview.coffee",
  "app/Applications/WebTerm.kdapplication/webtermsettings.coffee",
  "app/Applications/WebTerm.kdapplication/src/ControlCodeReader.coffee",
  "app/Applications/WebTerm.kdapplication/src/Cursor.coffee",
  "app/Applications/WebTerm.kdapplication/src/InputHandler.coffee",
  "app/Applications/WebTerm.kdapplication/src/ScreenBuffer.coffee",
  "app/Applications/WebTerm.kdapplication/src/StyledText.coffee",
  "app/Applications/WebTerm.kdapplication/src/Terminal.coffee",

  # --- ApplicationPageViews ---
  "app/Applications/Activity.kdapplication/activitylistcontroller.coffee",
  # ACTIVITY VIEWS
  "app/Applications/Activity.kdapplication/AppView.coffee",
  # Activity commons
  "app/Applications/Activity.kdapplication/views/activityactions.coffee",
  "app/Applications/Activity.kdapplication/views/activityinnernavigation.coffee",
  "app/Applications/Activity.kdapplication/views/activitylistheader.coffee",
  "app/Applications/Activity.kdapplication/views/activitysplitview.coffee",
  "app/Applications/Activity.kdapplication/views/listgroupshowmeitem.coffee",
  "app/Applications/Activity.kdapplication/views/activityitemchild.coffee",
  "app/Applications/Activity.kdapplication/views/discussionactivityactions.coffee",
  "app/Applications/Activity.kdapplication/views/tutorialactivityactions.coffee",
  "app/Applications/Activity.kdapplication/views/codesharebox.coffee",
  "app/Applications/Activity.kdapplication/views/codesharetabview.coffee",
  "app/Applications/Activity.kdapplication/views/codesharetabpaneview.coffee",
  "app/Applications/Activity.kdapplication/views/embedbox.coffee",
  "app/Applications/Activity.kdapplication/views/embedboxviews.coffee",
  "app/Applications/Activity.kdapplication/views/newmemberbucket.coffee",

  # Activity widgets
  "app/Applications/Activity.kdapplication/widgets/widgetcontroller.coffee",
  "app/Applications/Activity.kdapplication/widgets/widgetview.coffee",
  "app/Applications/Activity.kdapplication/widgets/widgetbutton.coffee",
  "app/Applications/Activity.kdapplication/widgets/statuswidget.coffee",
  "app/Applications/Activity.kdapplication/widgets/questionwidget.coffee",
  "app/Applications/Activity.kdapplication/widgets/codesnippetwidget.coffee",
  "app/Applications/Activity.kdapplication/widgets/codesharewidget.coffee",
  "app/Applications/Activity.kdapplication/widgets/linkwidget.coffee",
  "app/Applications/Activity.kdapplication/widgets/tutorialwidget.coffee",
  "app/Applications/Activity.kdapplication/widgets/discussionwidget.coffee",

  # Activity content displays
  "app/Applications/Activity.kdapplication/ContentDisplays/activitycontentdisplay.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/StatusUpdate.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/CodeSnippet.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/Discussion.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/tutorial.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/codeshare.coffee",

  "app/Applications/Activity.kdapplication/ContentDisplays/QA.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/link.coffee",
  # Activity content displays commons
  "app/Applications/Activity.kdapplication/ContentDisplays/ContentDisplayAuthorAvatar.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/ContentDisplayMeta.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/ContentDisplayTags.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/ContentDisplayComments.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/ContentDisplayScoreBoard.coffee",
  # Activity List Items
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItem.coffee",
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemStatusUpdate.coffee",
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemCodeSnippet.coffee",
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemCodeShare.coffee",
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemDiscussion.coffee",
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemFollow.coffee",
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemLink.coffee",
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemQuestion.coffee",
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemTutorial.coffee",
  "app/Applications/Activity.kdapplication/ListItems/SelectableActivityListItem.coffee",
  "app/Applications/Activity.kdapplication/ListItems/SelectableActivityListItemTutorial.coffee",

  # TOPICS VIEWS
  "app/Applications/Topics.kdapplication/AppView.coffee",
  "app/Applications/Topics.kdapplication/ContentDisplays/Topic.coffee",
  "app/Applications/Topics.kdapplication/ContentDisplays/TopicSplitViewController.coffee",
  "app/Applications/Topics.kdapplication/Views/TopicsInnerNavigation.coffee",
  "app/Applications/Topics.kdapplication/Views/TopicsListItemView.coffee",

  # GROUPS VIEWS
  "app/Applications/Groups.kdapplication/Views/joinbutton.coffee",
  "app/Applications/Groups.kdapplication/AppView.coffee",
  "app/Applications/Groups.kdapplication/Views/GroupsInnerNavigation.coffee",
  "app/Applications/Groups.kdapplication/Views/GroupsListItemView.coffee",
  "app/Applications/Groups.kdapplication/Views/PermissionsGrid.coffee",
  "app/Applications/Groups.kdapplication/Views/groupview.coffee",
  "app/Applications/Groups.kdapplication/ContentDisplays/controller.coffee",

  # APPS VIEWS
  "app/Applications/Apps.kdapplication/AppView.coffee",
  "app/Applications/Apps.kdapplication/AppController.coffee",

  "app/Applications/Apps.kdapplication/Views/AppsInnerNavigation.coffee",
  "app/Applications/Apps.kdapplication/Views/AppsListItemView.coffee",
  "app/Applications/Apps.kdapplication/Views/AppSubmission.coffee",
  "app/Applications/Apps.kdapplication/Views/appinfoview.coffee",
  "app/Applications/Apps.kdapplication/Views/appview.coffee",
  "app/Applications/Apps.kdapplication/Views/appscreenshotlistitem.coffee",
  "app/Applications/Apps.kdapplication/Views/appscreenshotsview.coffee",
  "app/Applications/Apps.kdapplication/Views/appdetailsview.coffee",

  "app/Applications/Apps.kdapplication/ContentDisplays/controller.coffee",
  "app/Applications/Apps.kdapplication/ContentDisplays/SingleAppNavigation.coffee",

  # MEMBERS VIEWS
  "app/Applications/Members.kdapplication/AppView.coffee",
  "app/Applications/Members.kdapplication/ContentDisplays/ContentDisplayControllerMember.coffee",
  "app/Applications/Members.kdapplication/ContentDisplays/ownprofileview.coffee",
  "app/Applications/Members.kdapplication/ContentDisplays/profileview.coffee",
  "app/Applications/Members.kdapplication/ContentDisplays/contactlink.coffee",

  # START TAB VIEWS
  "app/Applications/StartTab.kdapplication/AppView.coffee",
  "app/Applications/StartTab.kdapplication/views/appthumbview.coffee",
  "app/Applications/StartTab.kdapplication/views/appthumbview.old.coffee",
  "app/Applications/StartTab.kdapplication/views/recentfileview.coffee",
  "app/Applications/StartTab.kdapplication/views/appcontainer.coffee",

  # INBOX CONTROLLERS
  "app/Applications/Inbox.kdapplication/Controllers/InboxMessageListController.coffee",
  "app/Applications/Inbox.kdapplication/Controllers/InboxNotificationsController.coffee",

  # INBOX VIEWS
  "app/Applications/Inbox.kdapplication/AppView.coffee",
  "app/Applications/Inbox.kdapplication/Views/InboxInnerNavigation.coffee",
  "app/Applications/Inbox.kdapplication/Views/InboxMessagesList.coffee",
  "app/Applications/Inbox.kdapplication/Views/InboxMessageThreadView.coffee",
  "app/Applications/Inbox.kdapplication/Views/InboxNewMessageBar.coffee",
  "app/Applications/Inbox.kdapplication/Views/InboxMessageDetail.coffee",
  "app/Applications/Inbox.kdapplication/Views/InboxReplyForm.coffee",
  "app/Applications/Inbox.kdapplication/Views/InboxReplyMessageView.coffee",
  "app/Applications/Inbox.kdapplication/Views/InboxReplyView.coffee",

  # FEED CONTROLLERS
  "app/Applications/Feeder.kdapplication/FeedController.coffee",
  "app/Applications/Feeder.kdapplication/Controllers/FeederFacetsController.coffee",
  "app/Applications/Feeder.kdapplication/Controllers/FeederResultsController.coffee",

  # FEED VIEWS
  "app/Applications/Feeder.kdapplication/Views/FeederSplitView.coffee",
  "app/Applications/Feeder.kdapplication/Views/FeederTabView.coffee",


  # HOME VIEWS
  "app/Applications/Home.kdapplication/AppView.coffee",

  "app/Applications/Home.kdapplication/ContentDisplays/AboutContentDisplayController.coffee",
  "app/Applications/Home.kdapplication/ContentDisplays/AboutView.coffee",

  "app/Applications/Home.kdapplication/Views/FooterBarContents.coffee",

  #ABOUT VIEWS

  # DEMO VIEWS
  "app/Applications/Demos.kdapplication/AppView.coffee",

  # "app/Applications/GroupsFake.kdapplication/AppController.coffee",

  # ACCOUNT SETTINGS

  "app/Applications/Account.kdapplication/account/accSettingsPersPassword.coffee",
  "app/Applications/Account.kdapplication/account/accSettingsPersUsername.coffee",
  "app/Applications/Account.kdapplication/account/accSettingsPersLinkedAccts.coffee",
  "app/Applications/Account.kdapplication/account/accSettingsPersEmailNotifications.coffee",
  # "app/Applications/Account.kdapplication/account/accSettingsDevDatabases.coffee",
  "app/Applications/Account.kdapplication/account/accSettingsDevEditors.coffee",
  "app/Applications/Account.kdapplication/account/accSettingsDevMounts.coffee",
  "app/Applications/Account.kdapplication/account/accSettingsDevRepos.coffee",
  "app/Applications/Account.kdapplication/account/accSettingsDevSshKeys.coffee",

  "app/Applications/Account.kdapplication/account/accSettingsPaymentHistory.coffee",
  "app/Applications/Account.kdapplication/account/accSettingsPaymentMethods.coffee",
  "app/Applications/Account.kdapplication/account/accSettingsSubscriptions.coffee",
  "app/Applications/Account.kdapplication/AppView.coffee",

  # CONTENT DISPLAY VIEWS
  "app/MainApp/ContentDisplay/ContentDisplay.coffee",
  "app/MainApp/ContentDisplay/ContentDisplayController.coffee",

  # KITE CONTROLLER
  "app/MainApp/KiteController.coffee",

  # OLD PAGES
  # "app/MainApp/oldPages/pageHome.coffee",
  # "app/MainApp/oldPages/pageRegister.coffee",
  "app/MainApp/oldPages/pageEnvironment.coffee",

  # ENVIRONMENT SETTINGS
  # "app/MainApp/oldPages/environment/envSideBar.coffee",
  # "app/MainApp/oldPages/environment/envViewMenu.coffee",
  # "app/MainApp/oldPages/environment/envViewSummary.coffee",
  # "app/MainApp/oldPages/environment/envViewUsage.coffee",
  # "app/MainApp/oldPages/environment/envViewTopProcesses.coffee",
  # "app/MainApp/oldPages/environment/envViewMounts.coffee",

  # PAYMENT
  # "app/MainApp/oldPages/payment/tabs.coffee",
  # "app/MainApp/oldPages/payment/overview.coffee",
  # "app/MainApp/oldPages/payment/settings.coffee",
  # "app/MainApp/oldPages/payment/history.coffee",

  # IRC
  # "app/MainApp/oldPages/irc/customViews.coffee",
  # "app/MainApp/oldPages/irc/lists.coffee",
  # "app/MainApp/oldPages/irc/tabs.coffee",
  "app/MainApp/account-mixins.coffee",
  "app/MainApp/main.coffee",

  # --- Styles ---
  "css/style.css",
  "css/highlight-styles/sunburst.css",
  "css/tipsy.css",

  "Framework/themes/default/kdfn.styl",
  "stylus/appfn.styl",

  "Framework/themes/default/kd.styl",
  "Framework/themes/default/kd.input.styl",
  "Framework/themes/default/kd.treeview.styl",
  "Framework/themes/default/kd.contextmenu.styl",
  "Framework/themes/default/kd.dialog.styl",
  "Framework/themes/default/kd.buttons.styl",
  "Framework/themes/default/kd.scrollview.styl",
  "Framework/themes/default/kd.modal.styl",
  "Framework/themes/default/kd.form.styl",
  "Framework/themes/default/kd.tooltip.styl",
  # "stylus/kd.tiptip.styl" => discarded,

  "stylus/app.styl",
  "stylus/app.bottom.styl",
  "stylus/app.about.styl",
  "stylus/app.commons.styl",
  "stylus/app.editor.styl",
  "stylus/app.finder.styl",
  "stylus/app.aceeditor.styl",
  "stylus/app.activity.styl",
  "stylus/app.contextmenu.styl",
  # "stylus/app.chat.styl",
  "stylus/app.settings.styl",
  "stylus/app.inbox.styl",
  # "stylus/app.envsettings.styl",
  "stylus/app.members.styl",
  "stylus/app.comments.styl",
  "stylus/app.bootstrap.styl",
  "stylus/app.login-signup.styl",
  "stylus/app.keyboard.styl",
  "stylus/app.profile.styl",
  "stylus/appstore.styl",
  "stylus/app.home.styl",
  "stylus/app.topics.styl",
  "stylus/app.contentdisplays.styl",
  "stylus/app.starttab.styl",
  "stylus/app.viewer.styl",
  "stylus/app.book.styl",
  "stylus/app.codeshare.styl",

  "stylus/temp.styl",

  # mediaqueries should stay at the bottom
  "stylus/app.1200.styl",
  "stylus/app.1024.styl",
  "stylus/app.768.styl",
  "stylus/app.480.styl",

  "app/Applications/WebTerm.kdapplication/themes/green-on-black.styl",
  "app/Applications/WebTerm.kdapplication/themes/gray-on-black.styl",
  "app/Applications/WebTerm.kdapplication/themes/black-on-white.styl",
]