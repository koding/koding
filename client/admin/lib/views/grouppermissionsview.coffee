kd               = require 'kd'
JView            = require 'app/jview'
isKoding         = require 'app/util/isKoding'
showError        = require 'app/util/showError'
KDLoaderView     = kd.LoaderView
PermissionsForm  = require './permissionsform'
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class GroupPermissionsView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'permissions-view'

    super options, data

    @loader     = new KDLoaderView
      showLoader     : yes
      loaderOptions  :
        shape        : 'spiral'
        color        : '#a4a4a4'
      size           :
        width        : 40
        height       : 40

    @addPermissionsView()

    @setClass 'not-koding'  unless isKoding()


  addPermissionsView: ->
    group = @getData()
    group.fetchRoles (err,roles)=>
      return showError err if err
      group.fetchPermissions (err, permissionSet)=>
        return showError err if err

        @addSubView header = new KDCustomHTMLView
          cssClass : 'header'

        for role in roles when role.title isnt 'owner'
          title = role.title.capitalize()

          header.addSubView new KDCustomHTMLView
            partial    : title
            cssClass   : 'header-item'
            attributes : { title }

        @addSubView permissions = new PermissionsForm { permissionSet, roles }, group

        permissions.on 'RoleWasAdded', (newPermissions,role)=>
          permissions.destroy()
          @addPermissionsView()
          @loader.show()

        @loader.hide()

  pistachio:->
    """
    {{> @loader}}
    """


