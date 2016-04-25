kd                         = require 'kd'
headerize                  = require '../commons/headerize'
HomeAccountEditProfile     = require './homeaccounteditprofile'
HomeAccountChangePassword  = require './homeaccountchangepassword'
HomeAccountSecurityView    = require './homeaccountsecurityview'
HomeAccountSessionsView    = require './homeaccountsessionsview'


SECTIONS =
  Profile     : HomeAccountEditProfile
  Password    : HomeAccountChangePassword
  Security    : HomeAccountSecurityView
  Credentials : HomeAccountCredentialsView
  Sessions    : HomeAccountSessionsView

section = (name) ->
  new (SECTIONS[name] or kd.View)
    tagName  : 'section'
    cssClass : "HomeAppView--section #{kd.utils.slugify name}"


module.exports = class HomeAccount extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    @wrapper.addSubView headerize 'My Account'
    @wrapper.addSubView profile     = section 'Profile'

    @wrapper.addSubView headerize 'Password'
    @wrapper.addSubView password    = section 'Password'

    @wrapper.addSubView headerize 'Security'
    @wrapper.addSubView security    = section 'Security'


    @wrapper.addSubView headerize 'Sessions'
    @wrapper.addSubView sessions    = section 'Sessions'

