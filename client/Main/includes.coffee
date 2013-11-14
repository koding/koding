module.exports = [

  # Libs
  "libs/async.js",
  "libs/md5-min.js",

  # --- Application ---
  "utils.coffee"
  "KD.extend.coffee" # our extensions to KD global
  "kodingrouter.coffee",
  "mq.config.coffee",

  # mainapp controllers
  "activitycontroller.coffee",
  "notificationcontroller.coffee",
  "linkcontroller.coffee",
  "paymentcontroller.coffee",
  "oauthcontroller.coffee",

  # COMMON VIEWS
  "CommonViews/applicationview/applicationtabview.coffee",
  "CommonViews/applicationview/applicationtabhandleholder.coffee",
  "CommonViews/sharepopup.coffee",
  "CommonViews/sharelink.coffee",
  "CommonViews/linkviews/linkview.coffee",
  "CommonViews/linkviews/customlinkview.coffee",
  "CommonViews/linkviews/linkgroup.coffee",
  "CommonViews/linkviews/profilelinkview.coffee",
  "CommonViews/linkviews/profiletextview.coffee",
  "CommonViews/linkviews/profiletextgroup.coffee",
  "CommonViews/linkviews/taglinkview.coffee",
  "CommonViews/linkviews/applinkview.coffee",
  "CommonViews/linkviews/activitychildviewtaggroup.coffee",
  "CommonViews/linkviews/autocompleteprofiletextview.coffee",
  "CommonViews/linkviews/grouplinkview.coffee",
  "CommonViews/splitview.coffee",
  "CommonViews/slidingsplit.coffee",

  "CommonViews/avatarviews/avatarview.coffee",
  "CommonViews/avatarviews/avatarstaticview.coffee",
  "CommonViews/avatarviews/autocompleteavatarview.coffee",

  # FIXME ~ GG
  "navigation/navigationcontroller.coffee",

  "CommonViews/VideoPopup.coffee",
  "CommonViews/LikeView.coffee",
  "CommonViews/ShowMoreDataModalView.coffee",
  "CommonViews/Tags/TagViews.coffee",
  "CommonViews/Tags/TagAutoCompleteController.coffee",
  "CommonViews/SkillTagFormView.coffee",
  "CommonViews/SkillTagAutoCompleteController.coffee",
  "CommonViews/SkillTagAutoCompletedItem.coffee",
  "CommonViews/messagesList.coffee",
  "CommonViews/CommonInputWithButton.coffee",
  "CommonViews/SplitViewWithOlderSiblings.coffee",
  "CommonViews/ContentPageSplitBelowHeader.coffee",
  "CommonViews/CommonListHeader.coffee",
  "CommonViews/CommonInnerNavigation.coffee",
  "CommonViews/headers.coffee",
  "CommonViews/HelpBox.coffee",
  "CommonViews/KeyboardHelper.coffee",
  "CommonViews/VerifyPINModal.coffee",

  "CommonViews/followbutton.coffee",

  # "CommonViews/remotesmodal.coffee",
  # "CommonViews/databasesmodal.coffee",

  "CommonViews/comments/commentview.coffee",
  "CommonViews/comments/commentlistviewcontroller.coffee",
  "CommonViews/comments/commentviewheader.coffee",
  "CommonViews/comments/commentlistitemview.coffee",
  "CommonViews/comments/newcommentform.coffee",

  "CommonViews/reviews/reviewview.coffee",
  "CommonViews/reviews/reviewlistviewcontroller.coffee",
  "CommonViews/reviews/reviewlistitemview.coffee",
  "CommonViews/reviews/newreviewform.coffee",

  "CommonViews/opinions/opinionview.coffee",
  "CommonViews/opinions/discussionactivityopinionview.coffee",
  "CommonViews/opinions/discussionactivityopinionlistitemview.coffee",
  "CommonViews/opinions/tutorialactivityopinionview.coffee",
  "CommonViews/opinions/tutorialactivityopinionlistitemview.coffee",
  "CommonViews/opinions/tutorialopinionviewheader.coffee",
  "CommonViews/opinions/opinionviewheader.coffee",
  "CommonViews/opinions/opinionlistviewcontroller.coffee",
  "CommonViews/opinions/opinionlistitemview.coffee",
  "CommonViews/opinions/opinioncommentlistitemview.coffee",
  "CommonViews/opinions/opinionformview.coffee",
  "CommonViews/opinions/opinioncommentview.coffee",
  "CommonViews/opinions/discussionformview.coffee",
  "CommonViews/opinions/tutorialformview.coffee",

  "CommonViews/markdownmodal.coffee",
  "CommonViews/dropboxdownloaditemview.coffee",

  "CommonViews/CommonVMUsageBar.coffee",

  # FATIH
  # "CommonViews/fatih/plugins/fatihpluginabstract.coffee",
  # "CommonViews/fatih/plugins/fatihlistitem.coffee",
  # "CommonViews/fatih/plugins/fatihfilelistitem.coffee",
  # "CommonViews/fatih/plugins/fatihfilefinderplugin.coffee",
  # "CommonViews/fatih/plugins/fatihcontentsearchplugin.coffee",
  # "CommonViews/fatih/plugins/fatihopenappplugin.coffee",
  # "CommonViews/fatih/plugins/fatihusersearchplugin.coffee",
  # "CommonViews/fatih/fatihprefpane.coffee",
  # "CommonViews/fatih/fatih.coffee",

  # INTRODUCTION TOOLTIP
  "CommonViews/introductiontooltip/introductiontooltip.coffee",
  "CommonViews/introductiontooltip/introductiontooltipcontroller.coffee",

  "CommonViews/ModalViewWithTerminal.coffee",
  "CommonViews/DNDUploader.coffee",
  "CommonViews/clonerepomodal.coffee",

  "kodingappcontroller.coffee",
  "sidebar/sidebarcontroller.coffee",
  "sidebar/sidebarview.coffee",
  "sidebar/sidebarresizehandle.coffee",
  "sidebar/virtualizationcontrols.coffee",
  "sidebar/footermenuitem.coffee",
  "sidebar/modals/introductiontooltip/introductionitem.coffee",
  "sidebar/modals/introductiontooltip/introductionchilditem.coffee",
  "sidebar/modals/introductiontooltip/introductionadminform.coffee",
  "sidebar/modals/introductiontooltip/introductionadmin.coffee",
  "sidebar/modals/adminmodal.coffee",
  "sidebar/modals/kiteselector.coffee",

  "navigation/navigationlist.coffee",
  "navigation/navigationlink.coffee",
  "navigation/navigationseparator.coffee",
  "navigation/navigationadminlink.coffee",
  "navigation/navigationinvitationlink.coffee",
  "navigation/navigationactivitylink.coffee",
  "navigation/navigationappslink.coffee",
  "navigation/navigationdocsjobslink.coffee",
  "navigation/navigationpromotelink.coffee",

  # BOOK
  "book/embedded/tableofcontents.coffee",
  "book/embedded/updatewidget.coffee",
  "book/embedded/topics.coffee",
  "book/embedded/startbutton.coffee",
  "book/embedded/developbutton.coffee",
  "book/embedded/socialshare.coffee",
  "book/bookdata.coffee",
  "book/pointerview.coffee",
  "book/bookview.coffee",
  "book/bookpage.coffee",

  #maintabs

  "maintabs/maintabview.coffee",
  "maintabs/maintabpaneview.coffee",
  "maintabs/maintabhandleholder.coffee",

  # global notifications
  "globalnotification.coffee",

  #Finder Modals
  "filetree/modals/openwith/openwithmodalitem.coffee",
  "filetree/modals/openwith/openwithmodal.coffee",
  "filetree/modals/vmdangermodalview.coffee",

  # SINANS FINDER
  "filetree/controllers/findercontroller.coffee",
  "filetree/controllers/findertreecontroller.coffee",
  "filetree/controllers/findercontextmenucontroller.coffee",

  "filetree/itemviews/finderitem.coffee",
  "filetree/itemviews/fileitem.coffee",
  "filetree/itemviews/folderitem.coffee",
  "filetree/itemviews/mountitem.coffee",
  "filetree/itemviews/brokenlinkitem.coffee",
  "filetree/itemviews/sectionitem.coffee",
  "filetree/itemviews/vmitem.coffee",

  "filetree/itemsubviews/finderitemdeleteview.coffee",
  "filetree/itemsubviews/finderitemdeletedialog.coffee",
  "filetree/itemsubviews/finderitemrenameview.coffee",
  "filetree/itemsubviews/setpermissionsview.coffee",
  "filetree/itemsubviews/vmtogglebuttonview.coffee",
  "filetree/itemsubviews/mounttogglebuttonview.coffee",
  "filetree/itemsubviews/copyurlview.coffee",

  "filetree/helpers/dropboxuploader.coffee",

  # fs representation
  "fs/fshelper.coffee",
  "fs/fswatcher.coffee",
  "fs/fsitem.coffee",
  "fs/fsfile.coffee",
  "fs/fsfolder.coffee",
  "fs/fsmount.coffee",
  "fs/fsbrokenlink.coffee",
  "fs/fsvm.coffee",
  "fs/appswatcher.coffee",

  # avatararea
  "avatararea/avatararea.coffee",
  "avatararea/avatarareapopup.coffee",
  "avatararea/avatarareapopuplist.coffee",
  "avatararea/avatarareagroupswitcherpopup.coffee",
  "avatararea/avatarareaiconlink.coffee",
  "avatararea/avatarareaiconmenu.coffee",
  "avatararea/avatarareamessagespopup.coffee",
  "avatararea/avatarareanotificationspopup.coffee",
  "avatararea/avatarareapopupmessageslistitem.coffee",
  "avatararea/avatarareapopupnotificationslistitem.coffee",
  "avatararea/avatarareasharestatuspopup.coffee",


  # LOGIN VIEWS
  "login/loginview.coffee",
  "login/loginform.coffee",
  "login/logininputs.coffee",
  "login/loginoptions.coffee",
  "login/registeroptions.coffee",
  "login/resendmailconfirmationform.coffee"
  "login/registerform.coffee",
  "login/recoverform.coffee",
  "login/resetform.coffee",
  "login/redeemform.coffee",

  # BOTTOM PANEL
  # "bottompanels/bottompanelcontroller.coffee",
  # "bottompanels/bottompanel.coffee",
  # "bottompanels/chat/chatpanel.coffee",
  # "bottompanels/chat/chatroom.coffee",
  # "bottompanels/chat/chatsidebar.coffee",
  # "bottompanels/chat/chatuseritem.coffee",
  # "bottompanels/terminal/terminalpanel.coffee",

  "maincontroller/mainviews/appsettingsmenubutton.coffee",
  "maincontroller/mainviews/mainview.coffee",
  "maincontroller/mainviews/contentpanel.coffee",
  "maincontroller/mainviewcontroller.coffee",
  "maincontroller/dockcontroller.coffee",
  "maincontroller/maincontroller.coffee",

  # --- Applications ---
  "channels/kitechannel.coffee",
  "ApplicationManager.coffee",
  "AppController.coffee",
  "kodingappscontroller.coffee",
  "AppStorage.coffee",
  "localstorage.coffee",

  # CONTENT DISPLAY VIEWS
  "ContentDisplay/ContentDisplay.coffee",
  "ContentDisplay/ContentDisplayController.coffee",

  "pinger.coffee",

  # KITE CONTROLLER
  "kite/kite.coffee",
  "kite/kitecontroller.coffee",
  "kite/newkite.coffee"
  "kite/kontrol.coffee"
  # Virtualization CONTROLLER
  "VirtualizationController.coffee",

  # # WORKSPACE
  # "CommonViews/workspace/panes/pane.coffee",
  # "CommonViews/workspace/panes/editorpane.coffee",
  # "CommonViews/workspace/panes/previewpane.coffee",
  # "CommonViews/workspace/panes/terminalpane.coffee",
  # "CommonViews/workspace/panes/videopane.coffee",
  # "CommonViews/workspace/panel/panel.coffee",
  # "CommonViews/workspace/workspacelayout.coffee",
  # "CommonViews/workspace/views/workspacefloatingpanelauncher.coffee",
  # "CommonViews/workspace/workspace.coffee",

  # # COLLABORATIVE WORKSPACE
  # # i know it's a CommonView and should include at the top but it have to
  # # wait for NFinderTreeController etc., so included at the bottom
  # "libs/codemirror/lib/codemirror.js",
  # "libs/codemirror/addon/mode/loadmode.js",
  # "libs/codemirror/mode/javascript/javascript.js",
  # "libs/firebase/firepad.js",
  # "libs/firepad/firepad.css",
  # "libs/codemirror/lib/codemirror.css",
  # "CommonViews/workspace/panes/collaborativepane.coffee",
  # "CommonViews/workspace/panes/collaborativetabbededitorpane.coffee",
  # "CommonViews/workspace/panes/sharableterminalpane.coffee",
  # "CommonViews/workspace/panes/sharableclientterminalpane.coffee",
  # "CommonViews/workspace/panes/collaborativefinderpane.coffee",
  # "CommonViews/workspace/panes/collaborativeclientfinderpane.coffee",
  # "CommonViews/workspace/panes/collaborativeeditorpane.coffee",
  # "CommonViews/workspace/panes/collaborativepreviewpane.coffee",
  # "CommonViews/workspace/panes/collaborativedrawingpane.coffee",
  # "CommonViews/workspace/panes/chatitem.coffee",
  # "CommonViews/workspace/panes/chatpane.coffee",
  # "CommonViews/workspace/panel/collaborativepanel.coffee",
  # "CommonViews/workspace/collaborativeworkspaceuserlist.coffee",
  # "CommonViews/workspace/collaborativeworkspace.coffee",

  "CommonViews/modalappslistitemview.coffee",

  "status.coffee",
  "main.coffee",
  "monitor_status.coffee",
  "rollbar.coffee",
  "mixpanel.coffee",
  "analytic.coffee",

  # ---------- Main APP ENDS ---------- #

  # STYLES

  "styl/kdfn.styl",
  "styl/appfn.styl",
  "styl/resurrection.styl",
  # "styl/resurrection.activity.styl",
  "styl/resurrection.account.dropdown.styl",
  "styl/resurrection.anims.styl",
  # "styl/resurrection.activity.styl",
  # "styl/resurrection.apps.styl",
  "styl/resurrection.commons.styl",
  # "styl/resurrection.feeder.styl",

]
