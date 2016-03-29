kd               = require 'kd'
JView            = require 'app/jview'
JCustomHTMLView  = require 'app/jcustomhtmlview'
AvatarStaticView = require 'app/commonviews/avatarviews/avatarstaticview'
isKoding         = require 'app/util/isKoding'
whoami           = require 'app/util/whoami'

# AccountPopup     = require './accountpopup'
# helpers          = require './helpers'


module.exports = class HomeAppAvatarArea extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data)->

    options.tagName    = 'a'
    options.cssClass   = 'HomeAppView-Nav--AvatarArea'
    options.attributes = { href: '/Home/My-Account' }
    data             or= whoami()

    super options, data

    { groupsController } = kd.singletons
    account = @getData()

    # @accountPopup = new AccountPopup

    @avatar = new AvatarStaticView
      cssClass   : 'HomeAppView-Nav--avatar'
      size       : { width: 38, height: 38 }
    , account

    @profileName = new JCustomHTMLView
      cssClass   : 'HomeAppView-Nav--fullname'
      pistachio  : '{{ #(profile.firstName)}} {{ #(profile.lastName)}}'
    , account

    @teamName = new JCustomHTMLView
      cssClass   : 'HomeAppView-Nav--teamName'
      pistachio  : '{{ #(title)}}'
    , groupsController.getCurrentGroup()



  pistachio: ->

    """
    {{> @teamName}}
    {{> @profileName}}
    {{> @avatar}}
    """
