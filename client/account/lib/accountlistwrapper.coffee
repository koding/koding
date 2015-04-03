kd = require 'kd'
KDListView = kd.ListView
KDView = kd.View
AccountBilling = require './views/accountbilling'
AccountCredentialList = require './accountcredentiallist'
AccountCredentialListController = require './views/accountcredentiallistcontroller'
AccountEditSecurity = require './views/accounteditsecurity'
AccountEditUsername = require './views/accounteditusername'
AccountEditorList = require './accounteditorlist'
AccountEditorListController = require './views/accounteditorlistcontroller'
AccountEmailNotifications = require './views/accountemailnotifications'
AccountKodingKeyList = require './accountkodingkeylist'
AccountKodingKeyListController = require './views/accountkodingkeylistcontroller'
AccountLinkedAccountsList = require './accountlinkedaccountslist'
AccountLinkedAccountsListController = require './views/accountlinkedaccountslistcontroller'
AccountReferralSystem = require './views/referral/accountreferralsystem'
AccountSshKeyList = require './accountsshkeylist'
AccountSshKeyListController = require './views/accountsshkeylistcontroller'
DeleteAccountView = require './views/deleteaccountview'
PrivacyPolicyView = require './views/privacypolicyview'
TermsOfServiceView = require './views/termsofserviceview'


module.exports = class AccountListWrapper extends KDView

  listClasses =
    username                   : AccountEditUsername
    security                   : AccountEditSecurity
    emailNotifications         : AccountEmailNotifications
    billing                    : AccountBilling
    linkedAccountsController   : AccountLinkedAccountsListController
    linkedAccounts             : AccountLinkedAccountsList
    referralSystem             : AccountReferralSystem
    editorsController          : AccountEditorListController
    editors                    : AccountEditorList
    keysController             : AccountSshKeyListController
    keys                       : AccountSshKeyList
    kodingKeysController       : AccountKodingKeyListController
    kodingKeys                 : AccountKodingKeyList
    credentialsController      : AccountCredentialListController
    credentials                : AccountCredentialList
    deleteAccount              : DeleteAccountView
    termsOfService             : TermsOfServiceView
    privacyPolicy              : PrivacyPolicyView

  viewAppended:->
    {listType} = @getData()

    type = if listType then listType or ''

    listViewClass   = if listClasses[type] then listClasses[type] else KDListView
    controllerClass = if listClasses["#{type}Controller"] then listClasses["#{type}Controller"]

    @addSubView view = new listViewClass cssClass : type, delegate: this
    if controllerClass
      controller   = new controllerClass
        view       : view
        wrapper    : no
        scrollView : no
