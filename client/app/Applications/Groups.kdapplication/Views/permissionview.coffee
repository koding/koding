class GroupPermissionsView extends JView

  constructor:->

    super

    @setClass "permissions-view"

    group = @getData()

    @getDelegate().tabView.bindEvent 'scroll'

    @getDelegate().tabView.on 'scroll', =>
      @setButtonPosition @calculateButtonPosition()

    @listenWindowResize()

    @loader           = new KDLoaderView
      cssClass        : 'loader'
    @loaderText       = new KDView
      partial         : 'Loading Permissions…'
      cssClass        : ' loader-text'

    # @permissionsLoader = new KDLoaderView
    #   size          :
    #     width       : 32

    addPermissionsView = (newPermissions)=>
      group.fetchRoles (err,roles)=>
        group.fetchPermissions (err, permissionSet)=>
          @loader.hide()
          @loaderText.hide()
          unless err
            if newPermissions
              permissionSet.permissions = newPermissions
            if @permissions then @removeSubView @permissions
            @addSubView @permissions = new PermissionsModal {
              privacy: group.privacy
              permissionSet
              roles
              delegate : @
            }, group

            @_windowDidResize()
            @utils.defer =>
              @setButtonPosition @calculateButtonPosition()

            @permissions.emit 'RoleViewRefreshed'
            @permissions.on 'RoleWasAdded', (newPermissions,role,copy)=>
              copiedPermissions = []
              for permission of newPermissions
                if newPermissions[permission].role is copy
                  copiedPermissions.push
                    module : newPermissions[permission].module
                    permissions : newPermissions[permission].permissions
                    role : role
              for item in copiedPermissions
                newPermissions.push item
              addPermissionsView(newPermissions)

          else
            @addSubView new KDView
              partial : 'No access'

    @loader.show()
    @loaderText.show()
    addPermissionsView()

  setButtonPosition:(offset)->
    @permissions.$('.formline.button-field').css
        top : "#{offset.buttons}px"
    @permissions?.$('.formline.permissions-header.head').css
        top : "#{offset.header}px"


  calculateButtonPosition:->
    if @permissions
      delegate  = @getDelegate().tabView

      scrollTop = delegate.getDomElement()[0].scrollTop
      buttons   = 15+1+@visibleHeight+scrollTop-@buttonHeight-@headerHeight

      if buttons + @buttonHeight isnt @contentHeight
        @setScrollingBottom()
      else
        @unsetScrollingBottom()

      header = 0 # default abs() is non-sticky with top 0
      if scrollTop > @tabHeight-@subHeaderHeight
        header += scrollTop-@tabHeight+@subHeaderHeight
        @setScrollingTop()
      else @unsetScrollingTop()

      return {buttons,header}
    else return null

  setScrollingTop:->
    @$('.permissions-header').addClass 'scrolling'
  unsetScrollingTop:->
    @$('.permissions-header').removeClass 'scrolling'

  setScrollingBottom:->
    @$('.formline.button-field').addClass 'scrolling'
  unsetScrollingBottom:->
    @$('.formline.button-field').removeClass 'scrolling'



  viewAppended:->
    super
    @loader.show()
    @loaderText.show()

  _windowDidResize: (event) ->

    delegate = @getDelegate().tabView

    @headerHeight    = @getDelegate().parent.parent.$('.group-header').outerHeight(yes)
    @tabHeight       = delegate.$('.kdtabhandlecontainer').outerHeight(yes)
    @buttonHeight    = @permissions.$('.formline.button-field').outerHeight(yes)
    @subHeaderHeight = @getDelegate().parent.parent.$('.sub-header').outerHeight(yes)
    @visibleHeight   = delegate.$().outerHeight(yes)
    @contentHeight   = @getDelegate().parent.parent.$('.group-content').outerHeight(yes)

    @setButtonPosition @calculateButtonPosition()

  pistachio:->
    """
    {{> @loader}}
    {{> @loaderText}}
    """
