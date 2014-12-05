module.exports = [

  # Libs
  "libs/deb.min.js",
  "libs/md5-min.js",
  "libs/uuid.js",
  'libs/underscore-min.js'
  "libs/accounting.js",
  "libs/kite.js",
  "libs/kontrol.js",
  "libs/algoliasearch.min.js",
  'libs/marked.js'
  'libs/date.format.js'
  'libs/highlight.pack.js'
  'libs/jquery-timeago.js'
  'libs/emojify.js'
  'libs/jspath.js'


  # --- Application ---
  "mq.config.coffee",
  "utils.coffee"
  "KD.extend.coffee" # our extensions to KD global
  "log.config.coffee",
  "algoliaresult.coffee",

  # jview
  "jcustomhtmlview.coffee",

  # mainapp controllers
  "activitycontroller.coffee",
  "messageeventmanager.coffee",
  "socialapicontroller.coffee",
  "notificationcontroller.coffee",
  "linkcontroller.coffee",
  "widgetcontroller.coffee",
  "localsynccontroller.coffee",

  # onboarding
  "onboarding/onboardingviewcontroller.coffee",
  "onboarding/onboardingcontroller.coffee",
  "onboarding/onboardingitemview.coffee",

  # COMMON VIEWS
  'CommonViews/login/loginform.coffee'
  'CommonViews/login/logininputview.coffee'
  'CommonViews/login/logininputwithloader.coffee'
  'CommonViews/login/registerform.coffee'
  "CommonViews/applicationview/applicationtabview.coffee",
  "CommonViews/applicationview/applicationtabhandleholder.coffee",
  "CommonViews/sharepopup.coffee",
  "CommonViews/sharelink.coffee",
  "CommonViews/linkviews/linkview.coffee",
  "CommonViews/linkviews/linkmenuitemview.coffee",
  "CommonViews/linkviews/profilelinkview.coffee",
  "CommonViews/linkviews/profiletextview.coffee",
  "CommonViews/linkviews/taglinkview.coffee",
  "CommonViews/linkviews/applinkview.coffee",
  "CommonViews/linkviews/autocompleteprofiletextview.coffee",
  "CommonViews/linkviews/linkgroup.coffee",
  "CommonViews/splitview.coffee",
  "CommonViews/bidirectionalnavigation.coffee"
  "CommonViews/kodingswitch.coffee",
  "CommonViews/animatedmodalview.coffee",
  "CommonViews/footerview.coffee",

  "CommonViews/tokenview.coffee",
  "CommonViews/suggestedtokenview.coffee",

  "CommonViews/tagcontextmenuitem.coffee",

  "CommonViews/avatarviews/avatarview.coffee",
  "CommonViews/avatarviews/avatartooltipview.coffee",
  "CommonViews/avatarviews/avatarimage.coffee",
  "CommonViews/avatarviews/avatarstaticview.coffee",

  "CommonViews/activitywidgetitem.coffee",
  "CommonViews/activitywidget.coffee",
  "CommonViews/uploadimagemodalview.coffee",
  "CommonViews/helpsupportmodal.coffee",

  # idle detection
  "idleuserdetector.coffee"

  # junction
  "junction/junction.coffee"
  "junction/satisfier.coffee"

  # form workflow
  "CommonViews/formworkflow/formworkflow.coffee",
  "CommonViews/formworkflow/history.coffee",
  "CommonViews/formworkflow/collector.coffee",
  # "CommonViews/formworkflow/modal.coffee",
  # "CommonViews/formworkflow/visualization.coffee",

  # FIXME ~ GG
  "navigation/navigationcontroller.coffee",

  "CommonViews/VideoPopup.coffee",
  "CommonViews/MembersListItemView.coffee",
  "CommonViews/ShowMoreDataModalView.coffee",
  "CommonViews/SkillTagFormView.coffee",
  "CommonViews/SkillTagAutoCompleteController.coffee",
  "CommonViews/SkillTagAutoCompletedItem.coffee",
  "CommonViews/SplitViewWithOlderSiblings.coffee",
  "CommonViews/ContentPageSplitBelowHeader.coffee",
  "CommonViews/CommonListHeader.coffee",
  "CommonViews/CommonInnerNavigation.coffee",
  "CommonViews/headers.coffee",
  "CommonViews/HelpBox.coffee",
  "CommonViews/KeyboardHelper.coffee",
  "CommonViews/VerifyPINModal.coffee",
  "CommonViews/VerifyPasswordModal.coffee",

  "CommonViews/followbutton.coffee",
  "CommonViews/topicfollowbutton.coffee",

  "CommonViews/trollbutton.coffee",
  "CommonViews/metainfobuttonview.coffee",

  "CommonViews/markdownmodal.coffee",
  "CommonViews/dropboxdownloaditemview.coffee",

  "addworkspaceview.coffee",

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

  "CommonViews/ModalViewWithTerminal.coffee",
  "CommonViews/clonerepomodal.coffee",
  "CommonViews/memberautocomplete.coffee",
  "CommonViews/editormodal.coffee",

  "providers/machine.coffee",

  "providers/config.coffee",
  "providers/computecontroller.coffee",
  "providers/computecontroller.ui.coffee",
  "providers/computeeventlistener.coffee",
  "providers/computestatechecker.coffee",

  "providers/dummymachine.coffee",
  "providers/machineitem.coffee",
  "providers/machinelist.coffee",

  "providers/provideritemview.coffee",
  "providers/providerbaseview.coffee",

  "providers/cloudinstanceitemview.coffee",

  "providers/providerdigitalocean.coffee",
  "providers/providerwelcomeview.coffee",
  "providers/providerengineyard.coffee",
  "providers/providerkoding.coffee",
  "providers/provideramazon.coffee",
  "providers/providergoogle.coffee",
  "providers/providerrackspace.coffee",

  "providers/providerview.coffee",
  "providers/modalview.coffee"
  "providers/machinestatemodal.coffee"
  "providers/computeplansmodal.coffee",
  "providers/computeplansmodalloading.coffee",
  "providers/computeplansmodalfree.coffee",
  "providers/computeplansmodalpaid.coffee",
  "providers/computeerrormodal.coffee",
  "providers/computeerrormodalusage.coffee",
  "providers/customplanstorageslider.coffee",
  "providers/machinesettingsview.coffee",

  # Algolia-based search:
  "searchcontroller.coffee",

  "navigation/navigationlink.coffee",
  "navigation/navigationworkspaceitem.coffee",
  "navigation/navigationitem.coffee",
  "navigation/navigationmachineitem.coffee",

  "domains/managedomainsview.coffee",
  "domains/domainitem.coffee",

  "guideslinksview.coffee",
  "workspacesettingspopup.coffee",

  # LOCATION
  "locationcontroller.coffee",
  "CommonViews/location/locationform.coffee",

  # PAYMENT
  # controller
  "payment/paymentcontroller.coffee",
  # # views
  "payment/paymentmethodview.coffee",
  "payment/subscriptionview.coffee",
  # "payment/paymentmethodentryform.coffee",
  # "payment/paymentchoiceform.coffee",
  # "payment/paymentformmodal.coffee",
  # "payment/paymentworkflow.coffee",
  # "payment/paymentconfirmform.coffee",
  # "payment/genericplanview.coffee",
  # "payment/planupgradeconfirmform.coffee",
  # "payment/planproductlist.coffee",
  # "payment/existingaccountworkflow.coffee",

  "payment/workflow.coffee",
  "payment/updatecreditcardworkflow.coffee",
  "payment/stripeformview.coffee",
  "payment/paypalformview.coffee",
  "payment/form.coffee",
  "payment/basemodal.coffee",
  "payment/downgradeerrormodal.coffee",
  "payment/modal.coffee",
  "payment/creditcardmodal.coffee",


  # global notifications
  "globalnotification.coffee",

  # trouble shooter
  "troubleshoot/troubleshoot.coffee",
  "troubleshoot/healthchecker.coffee",
  "troubleshoot/connectionchecker.coffee",
  "troubleshoot/troubleshootmodal.coffee",
  "troubleshoot/troubleshootitemview.coffee",
  "troubleshoot/troubleshootstatusview.coffee",

  "troubleshoot/liveupdatechecker.coffee",
  "troubleshoot/brokerrecovery.coffee",
  "troubleshoot/vmchecker.coffee",
  "troubleshoot/troubleshootresultview.coffee",
  "troubleshoot/troubleshootmessageview.coffee",

  # avatararea
  "avatararea/avatararea.coffee",
  "avatararea/avatarareapopup.coffee",
  "avatararea/avatarareapopuplist.coffee",
  "avatararea/avatarareagroupswitcherpopup.coffee",
  "avatararea/avatarareaiconlink.coffee",

  # notifications
  "notifications/popupnotifications.coffee",
  "notifications/notificationlistitem.coffee",
  "notifications/notificationlistcontroller.coffee",

  "maincontroller/groupdata.coffee",
  "maincontroller/groupscontroller.coffee",
  "maincontroller/helpcontroller.coffee",

  # --- Applications ---
  "channels/kitechannel.coffee",
  "AppStorage.coffee",
  "localstorage.coffee",

  # 3rd Parties
  "extras/github/api.coffee",
  "extras/github/views/githubmodal.coffee",
  "extras/github/views/githubrepoitem.coffee",

  # Application Backend
  "CommonViews/kodingappselectorforgithub.coffee",

  # CONTENT DISPLAY VIEWS
  "ContentDisplay/ContentDisplay.coffee",
  "ContentDisplay/ContentDisplayController.coffee",

  "pinger.coffee",

  # KITE CONTROLLER
  "kite/kitecontroller.coffee",

  # NEW KITES (extending kite.js)
  "kite/kodingkite.coffee",
  "kite/kodingkontrol.coffee",
  "kite/kites/klient.coffee",
  "kite/kites/kloud.coffee",

  # Virtualization CONTROLLER
  "VirtualizationController.coffee",
  "CommonViews/modalappslistitemview.coffee",

  "status.coffee",
  "main.coffee",
  "rollbar.coffee",
  "mixpanel.coffee",
  "analytic.coffee",
  "errorlog.coffee",
  "metric.coffee",

  # ---------- Main APP ENDS ---------- #

  # STYLES

  "styl/resurrection.sidebar.styl",
  "styl/resurrection.account.dropdown.styl",
  "styl/resurrection.anims.styl",
  "styl/troubleshoot.styl",
  "styl/computeproviders.styl"

]
