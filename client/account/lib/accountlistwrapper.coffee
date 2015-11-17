kd                                  = require 'kd'
KDListView                          = kd.ListView
KDView                              = kd.View

AccountBilling                      = require './views/accountbilling'
LeaveGroupView                      = require './views/leavegroupview'
AccountEditorList                   = require './accounteditorlist'
AccountSshKeyList                   = require './accountsshkeylist'
PrivacyPolicyView                   = require './views/privacypolicyview'
DeleteAccountView                   = require './views/deleteaccountview'
TermsOfServiceView                  = require './views/termsofserviceview'
AccountEditUsername                 = require './views/accounteditusername'
AccountEditSecurity                 = require './views/accounteditsecurity'
AccountTwoFactorAuth                = require './accounttwofactorauth'
AccountEditShortcuts                = require './views/accounteditshortcuts'
AccountKodingKeyList                = require './accountkodingkeylist'
AccountReferralSystem               = require './views/referral/accountreferralsystem'
AccountCredentialListWrapper        = require './accountcredentiallistwrapper'
AccountEmailNotifications           = require './views/accountemailnotifications'
AccountLinkedAccountsList           = require './accountlinkedaccountslist'
AccountSshKeyListController         = require './views/accountsshkeylistcontroller'
AccountEditorListController         = require './views/accounteditorlistcontroller'
AccountKodingKeyListController      = require './views/accountkodingkeylistcontroller'
AccountLinkedAccountsListController = require './views/accountlinkedaccountslistcontroller'


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
    credentials                : AccountCredentialListWrapper
    twofactorauth              : AccountTwoFactorAuth
    deleteAccount              : DeleteAccountView
    leaveGroup                 : LeaveGroupView
    termsOfService             : TermsOfServiceView
    privacyPolicy              : PrivacyPolicyView
    shortcuts                  : AccountEditShortcuts

  viewAppended:->

    { listType } = @getData()
    type         = if listType then listType or ''

    listViewClass   = if listClasses[type] then listClasses[type] else KDListView
    controllerClass = if listClasses["#{type}Controller"] then listClasses["#{type}Controller"]

    @addSubView view = new listViewClass cssClass : type, delegate: this

    if controllerClass
      controller   = new controllerClass
        view       : view
        wrapper    : no
        scrollView : no
