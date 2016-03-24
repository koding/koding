kd                         = require 'kd'
HomeTopNav                 = require '../commons/hometopnav'
HomeAccountEditProfile     = require './homeaccounteditprofile'
HomeAccountChangePassword  = require './homeaccountchangepassword'
HomeAccountChangePassword  = require './homeaccountchangepassword'
HomeAccountCredentialsView = require './credentials/homeaccountcredentialsview'

SECTIONS =
  Profile     : HomeAccountEditProfile
  Password    : HomeAccountChangePassword
  Credentials : HomeAccountCredentialsView

section = (name) ->
  new (SECTIONS[name] or kd.View)
    tagName  : 'section'
    cssClass : "HomeAppView--section #{name}"


module.exports = class HomeAccountView extends kd.View

  constructor: (options = {}, data) ->

    super options, data

    @addSubView topNav     = new HomeTopNav
      cssClass : 'HomeAppView--topNav'
      route    : '/Home/My-Account'
      items    : Object.keys SECTIONS

    @addSubView scrollView = new kd.CustomScrollView
      cssClass : 'HomeAppView--scroller'

    { wrapper } = scrollView

    wrapper.addSubView profile     = section 'Profile'
    wrapper.addSubView password    = section 'Password'
    wrapper.addSubView credentials = section 'Credentials'
