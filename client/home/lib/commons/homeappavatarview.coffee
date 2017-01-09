kd               = require 'kd'
JView            = require 'app/jview'
JCustomHTMLView  = require 'app/jcustomhtmlview'
AvatarStaticView = require 'app/commonviews/avatarviews/avatarstaticview'
whoami           = require 'app/util/whoami'

# AccountPopup     = require './accountpopup'
# helpers          = require './helpers'


module.exports = class HomeAppAvatarArea extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.tagName    = 'a'
    options.cssClass   = 'HomeAppView-Nav--AvatarArea'
    options.attributes = { href: '/Home/my-account' }
    data             or= whoami()

    super options, data

    { groupsController } = kd.singletons
    account = @getData()

    # @accountPopup = new AccountPopup

    @avatar = new AvatarStaticView
      cssClass   : 'HomeAppView-Nav--avatar'
      size       : { width: 38, height: 38 }
    , account

    { profile } = account

    pistachio = if profile.firstName is '' and profile.lastName is ''
    then '{{#(profile.nickname)}}'
    else "{{#(profile.firstName)+' '+#(profile.lastName)}}"

    @profileName = new JCustomHTMLView
      cssClass   : 'HomeAppView-Nav--fullname'
      pistachio  : pistachio
    , account

    @teamName = new JCustomHTMLView
      cssClass   : 'HomeAppView-Nav--teamName'
      pistachio  : '{{ #(title)}}'
    , groupsController.getCurrentGroup()



  pistachio: ->

    '''
    {{> @teamName}}
    {{> @profileName}}
    {{> @avatar}}
    '''
