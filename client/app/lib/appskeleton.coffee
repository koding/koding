globals = require 'globals'
getFullnameFromAccount = require './util/getFullnameFromAccount'
whoami = require './util/whoami'
kd = require 'kd'

module.exports = class AppSkeleton

  @manifest = (type, name)->

    {profile} = whoami()
    raw =
      background    : no
      behavior      : "application"
      version       : "0.1"
      title         : "#{name or type.capitalize()}"
      name          : "#{name or type.capitalize()}"
      identifier    : "com.koding.apps.#{kd.utils.slugify name or type}"
      path          : "~/Applications/#{name or type.capitalize()}.kdapp"
      homepage      : "#{profile.nickname}.#{globals.config.userSitesDomain}/#{kd.utils.slugify name or type}"
      repository    : "git://github.com/#{profile.nickname}/#{kd.utils.slugify name or type}.kdapp.git"
      description   : "#{name or type} : a Koding application created with the #{type} template."
      category      : "web-app" # can be web-app, add-on, server-stack, framework, misc
      source        :
        blocks      :
          app       :
            files   : [ "./index.coffee" ]
        stylesheets : [ "./resources/style.css" ]
      options       :
        type        : "tab"
      icns          :
        "128"       : "./resources/icon.128.png"
      fileTypes     : []

    json = JSON.stringify raw, null, 2


  @changeLog = (name)->

    today = new Date().format('yyyy-mm-dd')
    {profile} = whoami()
    fullName  = getFullnameFromAccount()

    """
     #{today} #{fullName} <@#{profile.nickname}>

        * #{name} (index.coffee): Application created.
    """


  @indexCoffee =

    """
      class %%APPNAME%%MainView extends KDView

        constructor:(options = {}, data)->
          options.cssClass = '%%appname%% main-view'
          super options, data

        viewAppended:->
          @addSubView new KDView
            partial  : "Welcome to %%APPNAME%% app!"
            cssClass : "welcome-view"

      class %%APPNAME%%Controller extends AppController

        constructor:(options = {}, data)->
          options.view    = new %%APPNAME%%MainView
          options.appInfo =
            name : "%%APPNAME%%"
            type : "application"

          super options, data

      do ->

        # In live mode you can add your App view to window's appView
        if appView?

          view = new %%APPNAME%%MainView
          appView.addSubView view

        else

          KD.registerAppClass %%APPNAME%%Controller,
            name     : "%%APPNAME%%"
            routes   :
              "/:name?/%%APPNAME%%" : null
              "/:name?/%%AUTHOR%%/Apps/%%APPNAME%%" : null
            dockPath : "/%%AUTHOR%%/Apps/%%APPNAME%%"
            behavior : "application"
    """

  @styleCss =

    """
      .%%appname%%.main-view {
        background: white;
      }

      .%%appname%% .welcome-view {

        background: #eee;

        height: auto;
        width: auto;
        max-width: 300px;

        margin: 50px auto;

        border: 1px solid #ccc;
        border-radius: 4px;

        padding:10px;

        text-align:center;

      }
    """

  @readmeMd =

    """
      %%APPNAME%%
      -----------

      Yet another awesome Koding application! by %%AUTHOR_FULLNAME%%

    """
