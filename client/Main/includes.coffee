module.exports = [

  # Libs
  "libs/deb.min.js",
  "libs/md5-min.js",
  "libs/uuid.js",
  "libs/accounting.js",
  "libs/bluebird.js",
  "libs/kite.js",
  "libs/kontrol.js",
  "libs/algoliasearch.min.js",


  # --- Application ---
  "utils.coffee"
  "KD.extend.coffee" # our extensions to KD global
  "kodingrouter.coffee",
  "mq.config.coffee",
  "log.config.coffee",

  # jview
  "jview.coffee",
  "jcustomhtmlview.coffee",

  # mainapp controllers
  "activitycontroller.coffee",
  "messageeventmanager.coffee",
  "socialapicontroller.coffee",
  "notificationcontroller.coffee",
  "linkcontroller.coffee",
  "oauthcontroller.coffee",
  "widgetcontroller.coffee",
  "localsynccontroller.coffee",

  # onboarding
  "onboarding/onboardingviewcontroller.coffee",
  "onboarding/onboardingcontroller.coffee",
  "onboarding/onboardingitemview.coffee",

  # COMMON VIEWS
  "CommonViews/testimonialsquoteview.coffee",
  "CommonViews/testimonialsview.coffee",
  "CommonViews/applicationview/applicationtabview.coffee",
  "CommonViews/applicationview/applicationtabhandleholder.coffee",
  "CommonViews/sharepopup.coffee",
  "CommonViews/sharelink.coffee",
  "CommonViews/linkviews/linkview.coffee",
  "CommonViews/linkviews/linkmenuitemview.coffee",
  "CommonViews/linkviews/customlinkview.coffee",
  "CommonViews/linkviews/linkgroup.coffee",
  "CommonViews/linkviews/profilelinkview.coffee",
  "CommonViews/linkviews/profiletextview.coffee",
  "CommonViews/linkviews/profiletextgroup.coffee",
  "CommonViews/linkviews/taglinkview.coffee",
  "CommonViews/linkviews/activitylinkview.coffee",
  "CommonViews/linkviews/applinkview.coffee",
  "CommonViews/linkviews/activitychildviewtaggroup.coffee",
  "CommonViews/linkviews/autocompleteprofiletextview.coffee",
  "CommonViews/linkviews/grouplinkview.coffee",
  "CommonViews/splitview.coffee",
  "CommonViews/nominatemodal.coffee",
  "CommonViews/slidingsplit.coffee",
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
  "CommonViews/avatarviews/autocompleteavatarview.coffee",

  "CommonViews/activitywidgetitem.coffee",
  "CommonViews/activitywidget.coffee",
  "CommonViews/uploadimagemodalview.coffee",

  # idle detection
  "idleuserdetector.coffee"

  # junction
  "junction/junction.coffee"
  "junction/satisfier.coffee"

  # form workflow
  "CommonViews/formworkflow/formworkflow.coffee",
  "CommonViews/formworkflow/history.coffee",
  "CommonViews/formworkflow/collector.coffee",
  "CommonViews/formworkflow/modal.coffee",
  # "CommonViews/formworkflow/visualization.coffee",

  # FIXME ~ GG
  "navigation/navigationcontroller.coffee",

  "CommonViews/VideoPopup.coffee",
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

  # "CommonViews/remotesmodal.coffee",
  # "CommonViews/databasesmodal.coffee",

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

  "CommonViews/ModalViewWithTerminal.coffee",
  "CommonViews/clonerepomodal.coffee",
  "CommonViews/memberautocomplete.coffee",
  "CommonViews/editormodal.coffee",

  "providers/config.coffee",
  "providers/computecontroller.coffee",
  "providers/computecontroller.ui.coffee",
  "providers/computeeventlistener.coffee",

  "providers/machine.coffee",
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

  # Algolia-based autocomplete:
  "autocompletecontroller.coffee",

  "navigation/topnavigation.coffee",

  "navigation/navigationlist.coffee",
  "navigation/navigationlink.coffee",
  "navigation/navigationmachineitem.coffee",
  "navigation/navigationseparator.coffee",
  "navigation/navigationadminlink.coffee",
  "navigation/navigationinvitationlink.coffee",
  "navigation/navigationactivitylink.coffee",
  "navigation/navigationappslink.coffee",
  "navigation/navigationdocsjobslink.coffee",
  "navigation/navigationpromotelink.coffee",

  "machinesettingsmodal.coffee",

  # LOCATION
  "locationcontroller.coffee",
  "CommonViews/location/locationform.coffee",

  # PAYMENT
  # controller
  "payment/paymentcontroller.coffee",
  # views
  "payment/paymentmethodview.coffee",
  "payment/subscriptionview.coffee",
  "payment/subscriptionusageview.coffee",
  "payment/subscriptiongaugeitem.coffee",
  "payment/paymentmethodentryform.coffee",
  "payment/paymentchoiceform.coffee",
  "payment/paymentformmodal.coffee",
  "payment/vmproductview.coffee",
  "payment/paymentworkflow.coffee",
  "payment/paymentconfirmform.coffee",
  "payment/genericplanview.coffee",
  "payment/planupgradeform.coffee",
  "payment/planupgradeconfirmform.coffee",
  "payment/packchoiceform.coffee",
  "payment/planproductlist.coffee",
  "payment/existingaccountworkflow.coffee",


  #maintabs

  "maintabs/maintabview.coffee",
  "maintabs/maintabpaneview.coffee",

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
  "avatararea/avatarareasharestatuspopup.coffee",

  "maincontroller/groupdata.coffee",
  "maincontroller/mainviews/appsettingsmenubutton.coffee",
  "maincontroller/mainviews/mainview.coffee",
  "maincontroller/mainviewcontroller.coffee",
  "maincontroller/dockcontroller.coffee",
  "maincontroller/groupscontroller.coffee",
  "maincontroller/maincontroller.coffee",
  "maincontroller/helpcontroller.coffee",

  # --- Applications ---
  "channels/kitechannel.coffee",
  "ApplicationManager.coffee",
  "AppController.coffee",
  "AppStorage.coffee",
  "localstorage.coffee",

  # 3rd Parties
  "extras/github/api.coffee",
  "extras/github/views/githubmodal.coffee",
  "extras/github/views/githubrepoitem.coffee",

  # Application Backend
  "kodingappscontroller.coffee",
  "CommonViews/kodingappselectorforgithub.coffee",

  # CONTENT DISPLAY VIEWS
  "ContentDisplay/ContentDisplay.coffee",
  "ContentDisplay/ContentDisplayController.coffee",

  "pinger.coffee",

  # KITE CONTROLLER
  "kite/kite.coffee",
  "kite/kite2.coffee",
  "kite/oskite.coffee",
  "kite/terminalkite.coffee",
  "kite/kitecontroller.coffee",
  "kite/kitehelper.coffee",

  # NEW KITES (extending kite.js)
  "kite/kodingkite.coffee",
  "kite/kodingkontrol.coffee",
  "kite/kites/vmkite.coffee",
  "kite/kites/klient.coffee",
  "kite/kites/kloud.coffee",
  "kite/kites/oskite.coffee",
  "kite/kites/terminalkite.coffee",

  # Virtualization CONTROLLER
  "VirtualizationController.coffee",
  "CommonViews/modalappslistitemview.coffee",

  # these are generated dependencies
  # do not delete they're ignored in git
  # created in compile time.
  "__generatedapps__.coffee",
  "__generatedroutes__.coffee",

  "status.coffee",
  "main.coffee",
  "rollbar.coffee",
  "mixpanel.coffee",
  "analytic.coffee",
  "errorlog.coffee",
  "metric.coffee",

  # ---------- Main APP ENDS ---------- #

  # STYLES

  "styl/appfn.styl",
  "styl/resurrection.styl",
  "styl/resurrection.sidebar.styl",
  "styl/resurrection.account.dropdown.styl",
  "styl/resurrection.anims.styl",
  "styl/resurrection.commons.styl",
  "styl/troubleshoot.styl",
  "styl/computeproviders.styl",

  "styl/dock.responsive.styl"
  "styl/app.markdown.styl"

]
