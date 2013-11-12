module.exports = [

  # Libs
  "libs/async.js",
  "libs/md5-min.js",
  "libs/accounting.js",

  # --- Application ---
  "app/MainApp/utils.coffee"
  "app/MainApp/KD.extend.coffee" # our extensions to KD global
  "app/MainApp/kodingrouter.coffee",
  "app/MainApp/mq.config.coffee",

  # mainapp controllers
  "app/MainApp/activitycontroller.coffee",
  "app/MainApp/notificationcontroller.coffee",
  "app/MainApp/linkcontroller.coffee",
  "app/MainApp/oauthcontroller.coffee",

  # COMMON VIEWS
  "app/CommonViews/applicationview/applicationtabview.coffee",
  "app/CommonViews/applicationview/applicationtabhandleholder.coffee",
  "app/CommonViews/sharepopup.coffee",
  "app/CommonViews/sharelink.coffee",
  "app/CommonViews/linkviews/linkview.coffee",
  "app/CommonViews/linkviews/customlinkview.coffee",
  "app/CommonViews/linkviews/linkgroup.coffee",
  "app/CommonViews/linkviews/profilelinkview.coffee",
  "app/CommonViews/linkviews/profiletextview.coffee",
  "app/CommonViews/linkviews/profiletextgroup.coffee",
  "app/CommonViews/linkviews/taglinkview.coffee",
  "app/CommonViews/linkviews/applinkview.coffee",
  "app/CommonViews/linkviews/activitychildviewtaggroup.coffee",
  "app/CommonViews/linkviews/autocompleteprofiletextview.coffee",
  "app/CommonViews/linkviews/grouplinkview.coffee",
  "app/CommonViews/splitview.coffee",
  "app/CommonViews/slidingsplit.coffee",
  "app/CommonViews/paymentwidgets.coffee",

  "app/CommonViews/avatarviews/avatarview.coffee",
  "app/CommonViews/avatarviews/avatarstaticview.coffee",
  "app/CommonViews/avatarviews/autocompleteavatarview.coffee",

  "app/MainApp/navigation/navigationcontroller.coffee",

  "app/CommonViews/VideoPopup.coffee",
  "app/CommonViews/LikeView.coffee",
  "app/CommonViews/ShowMoreDataModalView.coffee",
  "app/CommonViews/Tags/TagViews.coffee",
  "app/CommonViews/Tags/TagAutoCompleteController.coffee",
  "app/CommonViews/SkillTagFormView.coffee",
  "app/CommonViews/SkillTagAutoCompleteController.coffee",
  "app/CommonViews/SkillTagAutoCompletedItem.coffee",
  "app/CommonViews/messagesList.coffee",
  "app/CommonViews/CommonInputWithButton.coffee",
  "app/CommonViews/SplitViewWithOlderSiblings.coffee",
  "app/CommonViews/ContentPageSplitBelowHeader.coffee",
  "app/CommonViews/CommonListHeader.coffee",
  "app/CommonViews/CommonInnerNavigation.coffee",
  "app/CommonViews/headers.coffee",
  "app/CommonViews/HelpBox.coffee",
  "app/CommonViews/KeyboardHelper.coffee",
  "app/CommonViews/VerifyPINModal.coffee",

  "app/CommonViews/followbutton.coffee",

  # "app/CommonViews/remotesmodal.coffee",
  # "app/CommonViews/databasesmodal.coffee",

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
  "app/CommonViews/dropboxdownloaditemview.coffee",

  "app/CommonViews/CommonVMUsageBar.coffee",

  # FATIH
  # "app/CommonViews/fatih/plugins/fatihpluginabstract.coffee",
  # "app/CommonViews/fatih/plugins/fatihlistitem.coffee",
  # "app/CommonViews/fatih/plugins/fatihfilelistitem.coffee",
  # "app/CommonViews/fatih/plugins/fatihfilefinderplugin.coffee",
  # "app/CommonViews/fatih/plugins/fatihcontentsearchplugin.coffee",
  # "app/CommonViews/fatih/plugins/fatihopenappplugin.coffee",
  # "app/CommonViews/fatih/plugins/fatihusersearchplugin.coffee",
  # "app/CommonViews/fatih/fatihprefpane.coffee",
  # "app/CommonViews/fatih/fatih.coffee",

  # INTRODUCTION TOOLTIP
  "app/CommonViews/introductiontooltip/introductiontooltip.coffee",
  "app/CommonViews/introductiontooltip/introductiontooltipcontroller.coffee",

  "app/CommonViews/ModalViewWithTerminal.coffee",
  "app/CommonViews/DNDUploader.coffee",
  "app/CommonViews/clonerepomodal.coffee",

  "app/MainApp/kodingappcontroller.coffee",
  "app/MainApp/sidebar/sidebarcontroller.coffee",
  "app/MainApp/sidebar/sidebarview.coffee",
  "app/MainApp/sidebar/sidebarresizehandle.coffee",
  "app/MainApp/sidebar/virtualizationcontrols.coffee",
  "app/MainApp/sidebar/footermenuitem.coffee",
  "app/MainApp/sidebar/modals/introductiontooltip/introductionitem.coffee",
  "app/MainApp/sidebar/modals/introductiontooltip/introductionchilditem.coffee",
  "app/MainApp/sidebar/modals/introductiontooltip/introductionadminform.coffee",
  "app/MainApp/sidebar/modals/introductiontooltip/introductionadmin.coffee",
  "app/MainApp/sidebar/modals/adminmodal.coffee",
  "app/MainApp/sidebar/modals/kiteselector.coffee",

  "app/MainApp/navigation/navigationlist.coffee",
  "app/MainApp/navigation/navigationlink.coffee",
  "app/MainApp/navigation/navigationseparator.coffee",
  "app/MainApp/navigation/navigationadminlink.coffee",
  "app/MainApp/navigation/navigationinvitationlink.coffee",
  "app/MainApp/navigation/navigationactivitylink.coffee",
  "app/MainApp/navigation/navigationappslink.coffee",
  "app/MainApp/navigation/navigationdocsjobslink.coffee",
  "app/MainApp/navigation/navigationpromotelink.coffee",

  # BOOK
  "app/MainApp/book/embedded/tableofcontents.coffee",
  "app/MainApp/book/embedded/updatewidget.coffee",
  "app/MainApp/book/embedded/topics.coffee",
  "app/MainApp/book/embedded/startbutton.coffee",
  "app/MainApp/book/embedded/developbutton.coffee",
  "app/MainApp/book/embedded/socialshare.coffee",
  "app/MainApp/book/bookdata.coffee",
  "app/MainApp/book/pointerview.coffee",
  "app/MainApp/book/bookview.coffee",
  "app/MainApp/book/bookpage.coffee",

  # LOCATION
  "app/MainApp/locationcontroller.coffee",
  "app/CommonViews/location/locationform.coffee",

  # PAYMENT
  "app/MainApp/payment/paymentcontroller.coffee",
  "app/MainApp/payment/paymentmethodchoice.coffee",
  "app/MainApp/payment/paymentform.coffee",
  "app/MainApp/payment/paymentchoiceform.coffee",
  "app/MainApp/payment/paymentformmodal.coffee",
  "app/MainApp/payment/paymentconfirmationmodal.coffee",
  "app/MainApp/payment/paymentdeleteconfirmationmodal.coffee",
  "app/MainApp/payment/vmproductview.coffee",
  "app/MainApp/payment/buyvmconfirmview.coffee",
  "app/MainApp/payment/paymentworkflow.coffee",
  "app/MainApp/payment/buymodal.coffee",
  "app/MainApp/payment/planupgradeform.coffee",
  "app/MainApp/payment/paymentconfirmform.coffee",

  #maintabs

  "app/MainApp/maintabs/maintabview.coffee",
  "app/MainApp/maintabs/maintabpaneview.coffee",
  "app/MainApp/maintabs/maintabhandleholder.coffee",

  # global notifications
  "app/MainApp/globalnotification.coffee",

  #Finder Modals
  "app/MainApp/filetree/modals/openwith/openwithmodalitem.coffee",
  "app/MainApp/filetree/modals/openwith/openwithmodal.coffee",
  "app/MainApp/filetree/modals/vmdangermodalview.coffee",

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
  "app/MainApp/filetree/itemviews/vmitem.coffee",

  "app/MainApp/filetree/itemsubviews/finderitemdeleteview.coffee",
  "app/MainApp/filetree/itemsubviews/finderitemdeletedialog.coffee",
  "app/MainApp/filetree/itemsubviews/finderitemrenameview.coffee",
  "app/MainApp/filetree/itemsubviews/setpermissionsview.coffee",
  "app/MainApp/filetree/itemsubviews/vmtogglebuttonview.coffee",
  "app/MainApp/filetree/itemsubviews/mounttogglebuttonview.coffee",
  "app/MainApp/filetree/itemsubviews/copyurlview.coffee",

  "app/MainApp/filetree/helpers/dropboxuploader.coffee",

  # fs representation
  "app/MainApp/fs/fshelper.coffee",
  "app/MainApp/fs/fswatcher.coffee",
  "app/MainApp/fs/fsitem.coffee",
  "app/MainApp/fs/fsfile.coffee",
  "app/MainApp/fs/fsfolder.coffee",
  "app/MainApp/fs/fsmount.coffee",
  "app/MainApp/fs/fsbrokenlink.coffee",
  "app/MainApp/fs/fsvm.coffee",
  "app/MainApp/fs/appswatcher.coffee",

  # avatararea
  "app/MainApp/avatararea/avatarareapopup.coffee",
  "app/MainApp/avatararea/avatarareapopuplist.coffee",
  "app/MainApp/avatararea/avatarareagroupswitcherpopup.coffee",
  "app/MainApp/avatararea/avatarareaiconlink.coffee",
  "app/MainApp/avatararea/avatarareaiconmenu.coffee",
  "app/MainApp/avatararea/avatarareamessagespopup.coffee",
  "app/MainApp/avatararea/avatarareanotificationspopup.coffee",
  "app/MainApp/avatararea/avatarareapopupmessageslistitem.coffee",
  "app/MainApp/avatararea/avatarareapopupnotificationslistitem.coffee",
  "app/MainApp/avatararea/avatarareasharestatuspopup.coffee",


  # LOGIN VIEWS
  "app/MainApp/login/loginview.coffee",
  "app/MainApp/login/loginform.coffee",
  "app/MainApp/login/logininputs.coffee",
  "app/MainApp/login/loginoptions.coffee",
  "app/MainApp/login/registeroptions.coffee",
  "app/MainApp/login/resendmailconfirmationform.coffee"
  "app/MainApp/login/registerform.coffee",
  "app/MainApp/login/recoverform.coffee",
  "app/MainApp/login/resetform.coffee",
  "app/MainApp/login/redeemform.coffee",

  # BOTTOM PANEL
  # "app/MainApp/bottompanels/bottompanelcontroller.coffee",
  # "app/MainApp/bottompanels/bottompanel.coffee",
  # "app/MainApp/bottompanels/chat/chatpanel.coffee",
  # "app/MainApp/bottompanels/chat/chatroom.coffee",
  # "app/MainApp/bottompanels/chat/chatsidebar.coffee",
  # "app/MainApp/bottompanels/chat/chatuseritem.coffee",
  # "app/MainApp/bottompanels/terminal/terminalpanel.coffee",

  "app/MainApp/maincontroller/mainviews/appsettingsmenubutton.coffee",
  "app/MainApp/maincontroller/mainviews/mainview.coffee",
  "app/MainApp/maincontroller/mainviews/contentpanel.coffee",
  "app/MainApp/maincontroller/mainviewcontroller.coffee",
  "app/MainApp/maincontroller/maincontroller.coffee",

  # --- Applications ---
  "app/MainApp/channels/kitechannel.coffee",
  "app/MainApp/ApplicationManager.coffee",
  "app/MainApp/AppController.coffee",
  "app/MainApp/kodingappscontroller.coffee",
  "app/MainApp/AppStorage.coffee",
  "app/MainApp/localstorage.coffee",

  "app/Applications/Members.kdapplication/AppController.coffee",
  "app/Applications/Account.kdapplication/AppController.coffee",
  "app/Applications/Activity.kdapplication/AppController.coffee",
  "app/Applications/Topics.kdapplication/AppController.coffee",
  "app/Applications/Feeder.kdapplication/AppController.coffee",
  "app/Applications/Environments.kdapplication/AppController.coffee",
  "app/Applications/Apps.kdapplication/AppController.coffee",
  "app/Applications/Inbox.kdapplication/AppController.coffee",
  "app/Applications/Demos.kdapplication/AppController.coffee",
  "app/Applications/StartTab.kdapplication/AppController.coffee",

  # chat
  "app/Applications/Chat.kdapplication/AppController.coffee",
  "app/Applications/Chat.kdapplication/Controllers/commonchatcontroller.coffee",
  "app/Applications/Chat.kdapplication/Controllers/conversationlistcontroller.coffee",
  "app/Applications/Chat.kdapplication/Controllers/chatmessagelistcontroller.coffee",
  "app/Applications/Chat.kdapplication/Views/conversationlistitemtitle.coffee",
  "app/Applications/Chat.kdapplication/Views/conversationlistview.coffee",
  "app/Applications/Chat.kdapplication/Views/conversationlistitem.coffee",
  "app/Applications/Chat.kdapplication/Views/conversationstarter.coffee",
  "app/Applications/Chat.kdapplication/Views/conversationmenu.coffee",
  "app/Applications/Chat.kdapplication/Views/conversationsettings.coffee",
  "app/Applications/Chat.kdapplication/Views/chatconversationwidget.coffee",
  "app/Applications/Chat.kdapplication/Views/chatmessagelistview.coffee",
  "app/Applications/Chat.kdapplication/Views/chatmessagelistitem.coffee",
  "app/Applications/Chat.kdapplication/Views/chatinputwidget.coffee",
  "app/Applications/Chat.kdapplication/Views/mainchathandler.coffee",
  "app/Applications/Chat.kdapplication/Views/mainchatheader.coffee",
  "app/Applications/Chat.kdapplication/Views/mainchatpanel.coffee",

  # new ace
  "app/Applications/Ace.kdapplication/AppController.coffee",
  "app/Applications/Ace.kdapplication/AppView.coffee",
  "app/Applications/Ace.kdapplication/aceapplicationtabview.coffee",
  "app/Applications/Ace.kdapplication/aceappview.coffee",
  "app/Applications/Ace.kdapplication/ace.coffee",
  "app/Applications/Ace.kdapplication/acesettingsview.coffee",
  "app/Applications/Ace.kdapplication/acesettings.coffee",
  "app/Applications/Ace.kdapplication/acefindandreplaceview.coffee",

  # viewer
  'app/Applications/Viewer.kdapplication/topbar.coffee',
  'app/Applications/Viewer.kdapplication/AppController.coffee',
  'app/Applications/Viewer.kdapplication/AppView.coffee',

  # webterm
  "app/Applications/WebTerm.kdapplication/AppController.coffee",
  "app/Applications/WebTerm.kdapplication/AppView.coffee",
  "app/Applications/WebTerm.kdapplication/webtermappview.coffee",
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
  "app/Applications/Activity.kdapplication/views/embedbox.coffee",
  "app/Applications/Activity.kdapplication/views/embedboxviews.coffee",
  "app/Applications/Activity.kdapplication/views/newmemberbucket.coffee",

  # Activity widgets
  "app/Applications/Activity.kdapplication/widgets/widgetcontroller.coffee",
  "app/Applications/Activity.kdapplication/widgets/widgetview.coffee",
  "app/Applications/Activity.kdapplication/widgets/widgetbutton.coffee",
  "app/Applications/Activity.kdapplication/widgets/activitywidgetformview.coffee",
  "app/Applications/Activity.kdapplication/widgets/statuswidget.coffee",
  "app/Applications/Activity.kdapplication/widgets/codesnippetwidget.coffee",
  "app/Applications/Activity.kdapplication/widgets/tutorialwidget.coffee",
  "app/Applications/Activity.kdapplication/widgets/discussionwidget.coffee",
  "app/Applications/Activity.kdapplication/widgets/blogpostwidget.coffee",
  # "app/Applications/Activity.kdapplication/widgets/questionwidget.coffee",
  # "app/Applications/Activity.kdapplication/widgets/linkwidget.coffee",

  # Activity content displays
  "app/Applications/Activity.kdapplication/ContentDisplays/activitycontentdisplay.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/StatusUpdate.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/CodeSnippet.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/Discussion.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/blogpost.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/tutorial.coffee",
  "app/Applications/Activity.kdapplication/ContentDisplays/blogpost.coffee",
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
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemBlogPost.coffee",
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemDiscussion.coffee",
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemFollow.coffee",
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemLink.coffee",
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemQuestion.coffee",
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemTutorial.coffee",
  "app/Applications/Activity.kdapplication/ListItems/ActivityListItemBlogPost.coffee",

  # TOPICS VIEWS
  "app/Applications/Topics.kdapplication/AppView.coffee",
  "app/Applications/Topics.kdapplication/ContentDisplays/Topic.coffee",
  "app/Applications/Topics.kdapplication/ContentDisplays/TopicSplitViewController.coffee",
  "app/Applications/Topics.kdapplication/Views/TopicsListItemView.coffee",

  # VMs

  "app/Applications/Environments.kdapplication/views/scene/colortagselectorview.coffee",
  "app/Applications/Environments.kdapplication/views/scene/environmentcontainer.coffee",
  "app/Applications/Environments.kdapplication/views/scene/environmentdomaincontainer.coffee",
  "app/Applications/Environments.kdapplication/views/scene/environmentrulecontainer.coffee",
  "app/Applications/Environments.kdapplication/views/scene/environmentmachinecontainer.coffee",
  "app/Applications/Environments.kdapplication/views/scene/environmentextracontainer.coffee",
  "app/Applications/Environments.kdapplication/views/scene/environmentitemjointview.coffee",
  "app/Applications/Environments.kdapplication/views/scene/environmentitemsview.coffee",
  "app/Applications/Environments.kdapplication/views/scene/environmentruleitem.coffee",
  "app/Applications/Environments.kdapplication/views/scene/environmentextraitem.coffee",
  "app/Applications/Environments.kdapplication/views/scene/environmentdomainitem.coffee",
  "app/Applications/Environments.kdapplication/views/scene/environmentmachineitem.coffee",
  "app/Applications/Environments.kdapplication/views/scene/environmentsceneview.coffee",
  "app/Applications/Environments.kdapplication/views/environmentsmainscene.coffee",

  # "app/Applications/Environments.kdapplication/views/vmsmainview.coffee",
  # "app/Applications/Environments.kdapplication/views/domainsmainview.coffee",
  # "app/Applications/Environments.kdapplication/views/DomainListItemView.coffee",
  # "app/Applications/Environments.kdapplication/views/domains/domainsroutingview.coffee",
  # "app/Applications/Environments.kdapplication/views/domains/domainsvmlistitemview.coffee",
  "app/Applications/Environments.kdapplication/views/domains/domaincreateform.coffee",
  "app/Applications/Environments.kdapplication/views/domains/commondomaincreateform.coffee",
  "app/Applications/Environments.kdapplication/views/domains/domainproductform.coffee",
  "app/Applications/Environments.kdapplication/views/domains/domainbuyform.coffee",
  "app/Applications/Environments.kdapplication/views/domains/domainbuyitem.coffee",
  "app/Applications/Environments.kdapplication/views/domains/domainpaymentconfirmform.coffee",
  "app/Applications/Environments.kdapplication/views/domains/subdomaincreateform.coffee",
  "app/Applications/Environments.kdapplication/views/domains/domaindeletionmodal.coffee",

  "app/Applications/Environments.kdapplication/views/vms/vmproductform.coffee",
  "app/Applications/Environments.kdapplication/views/vms/vmpaymentconfirmform.coffee",


  # "app/Applications/Environments.kdapplication/views/DomainMapperView.coffee",
  # "app/Applications/Environments.kdapplication/views/DomainRegisterModalFormView.coffee",
  # "app/Applications/Environments.kdapplication/views/FirewallMapperView.coffee",
  # "app/Applications/Environments.kdapplication/views/FirewallFilterListItemView.coffee",
  # "app/Applications/Environments.kdapplication/views/FirewallRuleListItemView.coffee",
  # "app/Applications/Environments.kdapplication/views/FirewallFilterFormView.coffee",
  # "app/Applications/Environments.kdapplication/views/DNSManagerView.coffee",
  # "app/Applications/Environments.kdapplication/views/NewDNSRecordFormView.coffee",
  # "app/Applications/Environments.kdapplication/views/DNSRecordListItemView.coffee",

  "app/Applications/Environments.kdapplication/AppView.coffee",
  # "app/Applications/Environments.kdapplication/Controllers/VMListViewController.coffee",
  # "app/Applications/Environments.kdapplication/Controllers/DomainsListViewController.coffee",
  # "app/Applications/Environments.kdapplication/Controllers/FirewallFilterListController.coffee"
  # "app/Applications/Environments.kdapplication/Controllers/FirewallRuleListController.coffee"
  # "app/Applications/Environments.kdapplication/Controllers/DNSRecordListController.coffee"

  # GROUPS

  # groups controllers
  "app/Applications/Groups.kdapplication/groupdata.coffee"
  "app/Applications/Groups.kdapplication/AppController.coffee",
  "app/Applications/Groups.kdapplication/controllers/invitationrequestlistcontroller.coffee",

  # groups views
  "app/Applications/Home.kdapplication/ContentDisplays/AboutView.coffee"
  "app/Applications/Home.kdapplication/Views/grouphomeview.coffee",
  "app/Applications/Home.kdapplication/Views/homeloginbar.coffee",
  "app/Applications/Groups.kdapplication/Views/generalsettingsview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupseditablewebhookview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupsformgeneratorview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupsinvitationview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupsinvitationtabview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupsinvitationtabpaneview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupsinvitationlistitemview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupsinvitationcodelistitemview.coffee",
  "app/Applications/Groups.kdapplication/Views/GroupsListItemView.coffee",
  "app/Applications/Groups.kdapplication/Views/groupsmemberpermissionslistitemview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupsmemberpermissionsview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupsmemberroleseditview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupsdangermodalview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupsmembershippolicydetailview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupsmembershippolicyeditor.coffee",
  "app/Applications/Groups.kdapplication/Views/groupsbundleview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupsvocabulariesview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupswebhookview.coffee",
  "app/Applications/Groups.kdapplication/Views/grouptabhandleview.coffee",
  "app/Applications/Groups.kdapplication/Views/paymentvmlist.coffee",
  "app/Applications/Groups.kdapplication/Views/groupview.coffee",
  "app/Applications/Groups.kdapplication/Views/joinbutton.coffee",
  "app/Applications/Groups.kdapplication/Views/permissionsform.coffee",
  "app/Applications/Groups.kdapplication/Views/permissionview.coffee",
  "app/Applications/Groups.kdapplication/Views/readmeview.coffee",
  "app/Applications/Groups.kdapplication/Views/groupcreation.coffee",
  "app/Applications/Groups.kdapplication/Views/groupcreationselector.coffee",
  "app/Applications/Groups.kdapplication/Views/blockedusersview.coffee",
  "app/Applications/Groups.kdapplication/Views/blockeduserslistitemview.coffee",

  # app
  "app/Applications/Groups.kdapplication/AppView.coffee",

  # APPS VIEWS
  "app/Applications/Apps.kdapplication/AppView.coffee",

  "app/Applications/Apps.kdapplication/Views/AppsListItemView.coffee",
  "app/Applications/Apps.kdapplication/Views/appinfoview.coffee",
  "app/Applications/Apps.kdapplication/Views/appview.coffee",
  "app/Applications/Apps.kdapplication/Views/appdetailsview.coffee",

  "app/Applications/Apps.kdapplication/ContentDisplays/controller.coffee",

  # MEMBERS CONTROLLERS
  "app/Applications/Members.kdapplication/memberslistcontroller.coffee",

  # MEMBERS VIEWS
  "app/Applications/Members.kdapplication/AppView.coffee",
  "app/Applications/Members.kdapplication/ContentDisplays/ContentDisplayControllerMember.coffee",
  "app/Applications/Members.kdapplication/ContentDisplays/externalprofileview.coffee",
  "app/Applications/Members.kdapplication/ContentDisplays/profileview.coffee",
  "app/Applications/Members.kdapplication/ContentDisplays/contactlink.coffee",
  "app/Applications/Members.kdapplication/newmemberactivitylistitem.coffee",

  # START TAB VIEWS
  "app/Applications/StartTab.kdapplication/AppView.coffee",
  "app/Applications/StartTab.kdapplication/views/appthumbview.coffee",
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
  "app/Applications/Inbox.kdapplication/Views/InboxReplyView.coffee",

  # FEED CONTROLLERS
  "app/Applications/Feeder.kdapplication/FeedController.coffee",
  "app/Applications/Feeder.kdapplication/Controllers/FeederFacetsController.coffee",
  "app/Applications/Feeder.kdapplication/Controllers/FeederResultsController.coffee",
  "app/Applications/Feeder.kdapplication/Controllers/feederheaderfacetscontroller.coffee",
  "app/Applications/Feeder.kdapplication/Controllers/headernavigationcontroller.coffee",

  # FEED VIEWS
  "app/Applications/Feeder.kdapplication/Views/FeederSplitView.coffee",
  "app/Applications/Feeder.kdapplication/Views/feedersingleview.coffee",
  "app/Applications/Feeder.kdapplication/Views/FeederTabView.coffee",
  "app/Applications/Feeder.kdapplication/Views/feederonboardingview.coffee",

  # DEMO VIEWS
  "app/Applications/Demos.kdapplication/AppView.coffee",

  # ACCOUNT CONTROLLERS
  "app/Applications/Account.kdapplication/controllers/accountnavigationcontroller.coffee",
  "app/Applications/Account.kdapplication/controllers/accountcontentwrappercontroller.coffee",
  "app/Applications/Account.kdapplication/controllers/accountsidebarcontroller.coffee",
  "app/Applications/Account.kdapplication/controllers/accountlistcontroller.coffee",

  # ACCOUNT VIEWS
  "app/Applications/Account.kdapplication/views/password.coffee",
  "app/Applications/Account.kdapplication/views/username.coffee",
  "app/Applications/Account.kdapplication/views/linkedaccts.coffee",
  "app/Applications/Account.kdapplication/views/emailnotifications.coffee",
  # "app/Applications/Account.kdapplication/views/devdatabases.coffee",
  "app/Applications/Account.kdapplication/views/editors.coffee",
  "app/Applications/Account.kdapplication/views/sshkeys.coffee",
  "app/Applications/Account.kdapplication/views/kodingkeys.coffee",
  "app/Applications/Account.kdapplication/views/paymenthistory.coffee",
  "app/Applications/Account.kdapplication/views/paymentmethods.coffee",
  "app/Applications/Account.kdapplication/views/subscriptions.coffee",
  "app/Applications/Account.kdapplication/views/referralsystem.coffee",
  "app/Applications/Account.kdapplication/views/deleteaccountview.coffee",
  "app/Applications/Account.kdapplication/views/gmailcontact.coffee",
  "app/Applications/Account.kdapplication/views/referrermodal.coffee",
  "app/Applications/Account.kdapplication/AppView.coffee",

  # GROUP DASHBOARD
  "app/Applications/Dashboard.kdapplication/AppController.coffee",
  "app/Applications/Dashboard.kdapplication/AppView.coffee",

  # Group Dashboard Views:
  "app/Applications/Dashboard.kdapplication/views/paymentmodalview.coffee",
  "app/Applications/Dashboard.kdapplication/views/paymentmethodview.coffee",
  "app/Applications/Dashboard.kdapplication/views/linkablepaymentmethodview.coffee",
  "app/Applications/Dashboard.kdapplication/views/paymentsettingsview.coffee",

  # Product Pane
  # controller:
  "app/Applications/Dashboard.kdapplication/controllers/paymentcontroller.coffee",
  "app/Applications/Dashboard.kdapplication/controllers/productscontroller.coffee",
  # views:
  "app/Applications/Dashboard.kdapplication/views/productsettingsview.coffee",
  "app/Applications/Dashboard.kdapplication/views/productsectionview.coffee",
  "app/Applications/Dashboard.kdapplication/views/producteditform.coffee",
  "app/Applications/Dashboard.kdapplication/views/packeditform.coffee",
  "app/Applications/Dashboard.kdapplication/views/embedcodeview.coffee",
  "app/Applications/Dashboard.kdapplication/views/productview.coffee",
  "app/Applications/Dashboard.kdapplication/views/productadmincontrols.coffee",
  "app/Applications/Dashboard.kdapplication/views/productlistitem.coffee",
  "app/Applications/Dashboard.kdapplication/views/childproductlistitem.coffee",
  "app/Applications/Dashboard.kdapplication/views/planadmincontrols.coffee",
  "app/Applications/Dashboard.kdapplication/views/planlistitem.coffee",
  "app/Applications/Dashboard.kdapplication/views/productsectionlistcontroller.coffee",
  "app/Applications/Dashboard.kdapplication/views/addproductlistitem.coffee",
  "app/Applications/Dashboard.kdapplication/views/planproduct.coffee",
  "app/Applications/Dashboard.kdapplication/views/planaddproductsmodal.coffee",


  # CONTENT DISPLAY VIEWS
  "app/MainApp/ContentDisplay/ContentDisplay.coffee",
  "app/MainApp/ContentDisplay/ContentDisplayController.coffee",

  "app/MainApp/pinger.coffee",

  # KITE CONTROLLER
  "app/MainApp/kite/kite.coffee",
  "app/MainApp/kite/kitecontroller.coffee",
  "app/MainApp/kite/newkite.coffee"
  "app/MainApp/kite/kontrol.coffee"
  # Virtualization CONTROLLER
  "app/MainApp/VirtualizationController.coffee",

  # WORKSPACE
  "app/CommonViews/workspace/panes/pane.coffee",
  "app/CommonViews/workspace/panes/editorpane.coffee",
  "app/CommonViews/workspace/panes/previewpane.coffee",
  "app/CommonViews/workspace/panes/terminalpane.coffee",
  "app/CommonViews/workspace/panes/videopane.coffee",
  "app/CommonViews/workspace/panel/panel.coffee",
  "app/CommonViews/workspace/workspacelayout.coffee",
  "app/CommonViews/workspace/views/workspacefloatingpanelauncher.coffee",
  "app/CommonViews/workspace/workspace.coffee",

  # COLLABORATIVE WORKSPACE
  # i know it's a CommonView and should include at the top but it have to
  # wait for NFinderTreeController etc., so included at the bottom
  "libs/codemirror/lib/codemirror.js",
  "libs/codemirror/addon/mode/loadmode.js",
  "libs/codemirror/mode/javascript/javascript.js",
  "libs/firebase/firepad.js",
  "libs/firepad/firepad.css",
  "libs/codemirror/lib/codemirror.css",
  "app/CommonViews/workspace/panes/collaborativepane.coffee",
  "app/CommonViews/workspace/panes/collaborativetabbededitorpane.coffee",
  "app/CommonViews/workspace/panes/sharableterminalpane.coffee",
  "app/CommonViews/workspace/panes/sharableclientterminalpane.coffee",
  "app/CommonViews/workspace/panes/collaborativefinderpane.coffee",
  "app/CommonViews/workspace/panes/collaborativeclientfinderpane.coffee",
  "app/CommonViews/workspace/panes/collaborativeeditorpane.coffee",
  "app/CommonViews/workspace/panes/collaborativepreviewpane.coffee",
  "app/CommonViews/workspace/panes/collaborativedrawingpane.coffee",
  "app/CommonViews/workspace/panes/chatitem.coffee",
  "app/CommonViews/workspace/panes/chatpane.coffee",
  "app/CommonViews/workspace/panel/collaborativepanel.coffee",
  "app/CommonViews/workspace/collaborativeworkspaceuserlist.coffee",
  "app/CommonViews/workspace/collaborativeworkspace.coffee",

  # TEAMWORK
  "app/Applications/Teamwork.kdapplication/Views/teamworkenvironmentsmodal.coffee",
  "app/Applications/Teamwork.kdapplication/Views/teamworkmarkdownmodal.coffee",
  "app/Applications/Teamwork.kdapplication/Views/facebookteamworkinstructionsmodal.coffee",
  "app/Applications/Teamwork.kdapplication/Views/teamworktools.coffee",
  "app/Applications/Teamwork.kdapplication/Views/teamworkworkspace.coffee",
  "app/Applications/Teamwork.kdapplication/Views/teamworkapp.coffee",
  "app/Applications/Teamwork.kdapplication/Views/facebookteamwork.coffee",
  "app/Applications/Teamwork.kdapplication/Views/golangteamwork.coffee",
  "app/Applications/Teamwork.kdapplication/AppView.coffee",
  "app/Applications/Teamwork.kdapplication/AppController.coffee",

  # CLASSROOM
  # "app/Applications/Classroom.kdapplication/Views/classroomworkspace.coffee",
  # "app/Applications/Classroom.kdapplication/Views/classroomchapterlist.coffee",
  # "app/Applications/Classroom.kdapplication/Views/classroomchapterthumbview.coffee",
  # "app/Applications/Classroom.kdapplication/Views/classroomcoursethumbview.coffee",
  # "app/Applications/Classroom.kdapplication/Views/classroomcoursesview.coffee",
  # "app/Applications/Classroom.kdapplication/Views/classroomcourseview.coffee",
  # "app/Applications/Classroom.kdapplication/AppView.coffee",
  # "app/Applications/Classroom.kdapplication/AppController.coffee",

  "app/CommonViews/modalappslistitemview.coffee",

  # OLD PAGES
  # "app/MainApp/oldPages/pageHome.coffee",
  # "app/MainApp/oldPages/pageRegister.coffee",
  # "app/MainApp/oldPages/pageEnvironment.coffee",

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
  "app/MainApp/status.coffee",
  "app/MainApp/main.coffee",
  "app/MainApp/monitor_status.coffee",
  "app/MainApp/rollbar.coffee",
  "app/MainApp/mixpanel.coffee",
  "app/MainApp/analytic.coffee",

  # STYLES

  "css/highlight-styles/sunburst.css",

  "stylus/kdfn.styl",
  "stylus/appfn.styl",
  "stylus/app.styl",
  # "stylus/app.bottom.styl",
  "stylus/app.splitlayout.styl",
  "stylus/app.commons.styl",
  "stylus/app.editor.styl",
  "stylus/app.finder.styl",
  "stylus/app.aceeditor.styl",
  "stylus/app.activity.styl",
  "stylus/app.contextmenu.styl",
  "stylus/app.environments.styl",
  "stylus/app.chat.styl",
  "stylus/app.settings.styl",
  "stylus/app.inbox.styl",
  "stylus/app.members.styl",
  "stylus/app.comments.styl",
  "stylus/app.bootstrap.styl",
  "stylus/app.login-signup.styl",
  "stylus/app.keyboard.styl",
  "stylus/app.profile.styl",
  "stylus/appstore.styl",
  "stylus/app.topics.styl",
  "stylus/app.contentdisplays.styl",
  "stylus/app.starttab.styl",
  "stylus/app.viewer.styl",
  "stylus/app.book.styl",
  "stylus/app.group.general.styl",
  "stylus/app.group.dashboard.styl",
  "stylus/app.group.creation.styl",
  "stylus/app.user.styl",
  "stylus/app.markdown.styl",
  # "stylus/app.classroom.styl",
  "stylus/third.workspace.styl",
  "stylus/app.teamwork.styl",
  # "stylus/app.predefined.styl",
  # "stylus/app.envsettings.styl",

  # WebTerm Themes
  "app/Applications/WebTerm.kdapplication/themes/green-on-black.styl",
  "app/Applications/WebTerm.kdapplication/themes/gray-on-black.styl",
  "app/Applications/WebTerm.kdapplication/themes/black-on-white.styl",
  "app/Applications/WebTerm.kdapplication/themes/solarized-dark.styl",
  "app/Applications/WebTerm.kdapplication/themes/solarized-light.styl",

  # mediaqueries should stay at the bottom
  "stylus/app.1024.styl",
  "stylus/app.768.styl",
  "stylus/app.480.styl",
  "stylus/app.400.styl",

]
