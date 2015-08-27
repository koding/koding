kd                   = require 'kd'
KDView               = kd.View
isKoding             = require 'app/util/isKoding'
showError            = require 'app/util/showError'
KDInputView          = kd.InputView
KDLabelView          = kd.LabelView
KDModalView          = kd.ModalView
KDSelectBox          = kd.SelectBox
KDButtonView         = kd.ButtonView
PermissionSwitch     = require './permissionswitch'
KDNotificationView   = kd.NotificationView
KDFormViewWithFields = kd.FormViewWithFields
limitedPermissions   =
  JGroup             : [ 'send invitations', 'send private message', 'browse content by tag', 'edit tags' ]
  ComputeProvider    : [ 'sudoer', 'create machines', 'update machines' ]
  JStackTemplate     : [ 'create stack template', 'update stack template' ]


module.exports = class PermissionsForm extends KDFormViewWithFields

  # TODO: this class is a bit of a mess.  I did some light refactoring, but
  # I decided that at least some of the concerns I have with this file are
  # dependent upon a cleaner intermediate data structure in the form api.


  constructor: (options, data) ->

    @group           = data
    {@permissionSet} = options

    @roles = (role.title for role in options.roles when role.title isnt 'owner')
    options.buttons or=
      Add             :
        title         : 'Add'
        style         : 'solid medium green'
        callback      : @bound 'showNewRoleModal'
        cssClass      : if isKoding() then '' else 'hidden'

    options.fields or= optionizePermissions.call this, @roles, @permissionSet

    super options,data

    @setClass "permissions-form col-#{@roles.length}"


  showNewRoleModal: ->

    roleSelectOptions = []
    @selectRoleModal  = new KDModalView title: "Select Role to Copy", overlay: yes
    roleSelectOptions.push {title: role, value: role} for role in @roles

    roleNameLabel   = new KDLabelView title: "Role name"
    @roleName       = new KDInputView
      name          : "rolename"
      placeholder   : "role name..."

    roleSelectLabel = new KDLabelView title: "Select role to copy from"
    @roleSelectBox   = new KDSelectBox
      name          : "roletocopy"
      selectOptions : roleSelectOptions

    confirmButton   = new KDButtonView
      title         : "Select"
      callback      : =>
        titleOfRole = @roleName.getValue()
        unless titleOfRole
          @roleName.setClass "kdinput text validation-error"
        else
          @group.addCustomRole title: titleOfRole , (err, newRole)=>
            return showError err if err
            duplicatedRole = @roleSelectBox.getValue()
            newPermissions = @getPermissionsOfRole duplicatedRole
            currentPermissionSet = @reducedList()
            permission.role = titleOfRole for permission in newPermissions
            currentPermissionSet.push perm for perm in newPermissions
            @group.updatePermissions currentPermissionSet, (err,res)=>
              return showError err if err
              @emit "RoleWasAdded", currentPermissionSet, newRole.title

    @selectRoleModal.addSubView roleNameLabel
    @selectRoleModal.addSubView @roleName
    @selectRoleModal.addSubView roleSelectLabel
    @selectRoleModal.addSubView @roleSelectBox
    @selectRoleModal.addSubView confirmButton


  readableText = (text) ->

    dictionary =
      # JNewApp            : 'Apps'
      JGroup             : 'Groups'
      SocialMessage      : 'Social API'
      JGroupBundle       : 'Group Bundles'
      JProposedDomain    : 'Domains'
      JProxyFilter       : 'Proxy Filters'
      JInvitation        : 'Invitations'
      JStack             : 'Stacks'
      JStackTemplate     : 'Stack Templates'
      JCredential        : 'Credentials'
      ComputeProvider    : 'Compute Providers'
      JComputeStack      : 'Compute Stacks'
      JDomainAlias       : 'Domain Aliases'
      JKite              : 'Kites'
      JMachine           : 'Machines'
      JProvisioner       : 'Provisioners'
      JRewardCampaign    : 'Campaigns'
      JSnapshot          : 'Snapshots'
      SocialNotification : 'Social Notifications'

    return dictionary[text] or text.capitalize()


  _getCheckboxName = (module, permission, role) ->

    ['permission', module].join('-')+'|'+[role, permission].join('|')


  checkForPermission = (permissions,module,permission,role) ->

    for perm in permissions
      if perm.module is module and perm.role is role
        for perm1 in perm.permissions
          if perm1? and perm1 is permission
            return yes
        return no


  cascadeFormElements = (set, roles, module, permission, roleCount = 0) ->

    [current,remainder...] = roles
    cascadeData = {}

    isChecked = checkForPermission set.permissions, module, permission, current

    cssClass = 'permission-switch tiny ' + kd.utils.slugify(permission)+' '+current

    name = _getCheckboxName module, permission, current

    cascadeData[current] = {
      name
      cssClass
      itemClass    : PermissionSwitch
      defaultValue : isChecked ? no
      delegate     : this
      callback     : ->

        switches = @parent.subViews.filter (item) -> item instanceof PermissionSwitch

        # If the swicth is on now.
        if @getValue()
          switches = switches.slice 0, switches.indexOf this

          switches.forEach (item) ->
            item.setOn no  unless item.getValue()
        else
          switches = switches.slice switches.indexOf this

          switches.forEach (item) ->
            item.setOff no  if item.getValue()

        @getDelegate().save()
    }

    if current in ['admin', 'owner']
      cascadeData[current].defaultValue = yes
      cascadeData[current].disabled = yes

    if current and remainder.length > 0
      cascadeData[current].nextElement = cascadeFormElements.call this, set, remainder, module, permission, roleCount

    return cascadeData


  optionizePermissions = (roles, set) ->

    permissionOptions = {}

    # set.permissionsByModule is giving all the possible permissions
    # module is collection name (JComment, JProposedDomain etc..)
    # var permissions is permission under collection (module)
    # like "edit comments" for JComment
    for own module, permissions of set.permissionsByModule
      headerTitle    = "header #{module.toLowerCase()}"
      headerCssClass = 'permissions-module text'

      if not isKoding() and not limitedPermissions[module]
        headerCssClass += ' hidden'

      permissionOptions[headerTitle] =
        itemClass       : KDView
        partial         : readableText module
        cssClass        : headerCssClass

      for permission in permissions
        cssClass = 'text'

        unless isKoding()
          if limitedPermissions[module]
            if limitedPermissions[module].indexOf(permission) is -1
              cssClass += ' hidden'
          else
            cssClass += ' hidden'

        permissionOptions[ module + '-' + kd.utils.slugify(permission) ] =
          itemClass     : KDView
          partial       : readableText permission
          cssClass      : cssClass
          attributes    :
            title       : readableText permission
          nextElement :
            cascadeFormElements.call this, set, roles, module, permission, roles.length

    return permissionOptions


  createTree = (values) ->
    values.reduce (acc, { module, role, permission }) ->
      acc[module] ?= {}
      acc[module][role] ?= []
      acc[module][role].push permission
      return acc
    , {}


  createReducedList = (values) ->
    cache = {}
    values.reduce (acc, { module, role, permission }) ->
      storageKey = "#{module}:#{role}"
      cached = cache[storageKey]
      if cached?
        cached.permissions.push permission
      else
        cache[storageKey] = {module, role, permissions: [permission]}
        acc.push cache[storageKey]
      return acc
    , []


  getFormValues: ->

    @$().serializeArray().map ({ name }) ->
      [facet, role, permission] = name.split '|'
      module = facet.split('-')[1]
      {module, role, permission}


  ['list','reducedList','tree'].forEach (method) =>
    @::[method] = -> @getPermissions method


  getPermissions: (structure = 'reducedList') ->

    values = @getFormValues()
    switch structure
      when 'reducedList'  then return createReducedList values
      when 'list'         then return values
      when 'tree'         then return createTree values
      else throw new Error "Unknown structure #{structure}"


  getPermissionsOfRole: (role) ->

    allValues = @list()
    selectedRoleValues = []
    selectedRoleValues.push permission for permission in allValues when permission.role is role
    createReducedList selectedRoleValues


  save: ->

    @group.updatePermissions @reducedList(), (err, res) =>
      return showError err if err
      new KDNotificationView title: 'Group permissions have been updated.'
