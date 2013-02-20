class PermissionsModal extends KDFormViewWithFields

  ['list','reducedList','tree'].forEach (method)=>
    @::[method] =-> @getPermissions method

  constructor:(options,data)->

    readableText = (text)->
      dictionary =
        "JTag" : "Tags"
        "JGroup": 'Groups'
        "JReview": 'Reviews'
        "JPost":'Posts'
        "JVocabulary": 'Vocabularies'
      return dictionary[text] or text.charAt(0).toUpperCase()+text.slice(1)

    _getCheckboxName =(module, permission, role)->
      ['permission', module].join('-')+'|'+[role, permission].join('|')

    checkForPermission = (permissions,module,permission,role)->
      for perm in permissions
        if perm.module is module and perm.role is role
          for perm1 in perm.permissions
            return yes  if perm1 is permission
          return no

    cascadeFormElements = (set,roles,module,permission)->
      [current,remainder...] = roles.slice()
      cascadeData = {}
      cascadeData[current]=
        itemClass     : KDCheckBox
        cssClass      : 'permission-checkbox '+__utils.slugify(permission)+' '+current
        name          : _getCheckboxName module, permission, current
        defaultValue  : checkForPermission set.permissions,module,permission,current
      if current in ['admin','owner']
        cascadeData[current].defaultValue = yes
        cascadeData[current].disabled = yes
      if current and remainder.length > 0
        cascadeData[current].nextElementFlat = cascadeFormElements set, remainder, module, permission
      return cascadeData

    cascadeHeaderElements = (roles)->
      [current,remainder...] = roles.slice()
      cascadeData = {}
      cascadeData[current]=
        itemClass     : KDView
        partial       : readableText current
        cssClass      : 'text header-item role-'+__utils.slugify(current)
        tooltip       :
          showOnlyWhenOverflowing : yes
          title       : readableText current
          placement   : 'top'
          direction   : 'center'
          offset      :
            top       : 5
            left      : 0
      if current and remainder.length > 0
        cascadeData[current].nextElementFlat = cascadeHeaderElements remainder
      return cascadeData

    optionizePermissions = (set)->
      permissionOptions =
        head              :
          itemClass       : KDView
          cssClass        : 'permissions-header col-'+roles.length
          nextElementFlat :
            cascadeHeaderElements roles

      for module, permissions of set.permissionsByModule
        permissionOptions['header '+module.toLowerCase()] =
          itemClass       : KDView
          partial         : readableText module
          cssClass        : 'permissions-module text'

        for permission in permissions
          permissionOptions[module+'-'+__utils.slugify(permission)] =
            itemClass     : KDView
            partial       : readableText permission
            cssClass      : 'text'
            tooltip       :
              title       : readableText permission
              direction   : 'center'
              placement   : 'left'
              offset      :
                top       : 3
                left      : 0
              showOnlyWhenOverflowing : yes
            nextElementFlat :
              cascadeFormElements set, roles, module, permission
      permissionOptions

    group                   = data # @getData()
    {privacy,permissionSet} = options #@getOptions()

    roles = []
    roles.push role.title for role in options.roles

    roles.splice(roles.indexOf('owner'),1)
    # roles.splice(roles.indexOf('admin'),1)

    options.buttons or=
      "Add Role"          :
        style             : "modal-clean-gray"
        cssClass          : 'add-role'
        loader      :
          color     : "#444444"
          diameter  : 12
        callback          : =>
          @addSubView addRoleDialog = new KDDialogView
            cssClass      : "add-role-dialog"
            duration      : 200
            topOffset     : 21
            overlay       : yes
            height        : 'auto'
            buttons       :

              "Add Role"        :
                style     : "add-role-button modal-clean-gray"
                cssClass  : 'add-role-button'
                loader      :
                  color     : "#444444"
                  diameter  : 12

                callback  : ()=>
                  name    = @inputRoleName.getValue()
                  nameSlug= @utils.slugify name
                  copy    = @inputCopyPermissions.getValue()

                  group.addCustomRole
                    title : nameSlug
                    isConfigureable : yes
                  , (err,role)=>
                    log err if err
                    # TODO add copied permissions here

                    unless copy is null
                      log 'copying permissions from ',copy,' to ',role

                    @emit 'RoleWasAdded',@reducedList(),nameSlug,copy
                    @on 'RoleViewRefreshed', =>
                      @utils.wait 500, =>
                        addRoleDialog.buttons["Add Role"].hideLoader()
                        addRoleDialog.hide()

              Cancel :
                style     : "add-role-cancel modal-cancel"
                cssClass  : 'add-role-cancel'
                callback  : ()=>
                  @buttons["Save"].hideLoader()
                  addRoleDialog.hide()

          addRoleDialog.addSubView wrapper = new KDView
            cssClass      : "kddialog-wrapper"

          wrapper.addSubView title = new KDCustomHTMLView
            tagName       : 'h1'
            cssClass      : 'add-role-header'
            partial       : 'Add new Role'

          wrapper.addSubView form = new KDFormView

          form.addSubView labelRoleName = new KDLabelView
            cssClass      : 'label-role-name'
            title         : "Role Name:"

          form.addSubView @inputRoleName = inputRoleName = new KDInputView
            cssClass      : 'role-name'
            label         : labelRoleName
            defaultValue  : ''
            placeholder   : 'new-role'

          form.addSubView labelCopyPermissions = new KDLabelView
            cssClass      : 'label-copy-permissions'
            title         : "Copy Permissions from"

          selectOptions   = [{title:'None',value:null}]
          selectOptions.push {title:readableText(role),value:role} for role in roles

          form.addSubView @inputCopyPermissions = inputCopyPermissions = new KDSelectBox
            cssClass      : 'copy-permissions'
            selectOptions : selectOptions
            defaultValue  : null

          addRoleDialog.show()

      Save          :
        style       : "modal-clean-gray"
        loader      :
          color     : "#444444"
          diameter  : 12
        callback    : =>

          group.updatePermissions @reducedList(), (err,res)=>
            log 'updated permissions',err,res
            @buttons["Save"].hideLoader()
            # TODO: do something with this callback

    options.fields or= optionizePermissions permissionSet
    super options,data
    @setClass 'permissions-form col-'+roles.length

    @bindEvent 'scroll'
    @on 'scroll', (event={})=>
      @applyScrollShadow event

  applyScrollShadow:(event)->
    isAtTop = @$().scrollTop() is 0
    isAtBottom = @$().scrollTop()+@getHeight() is @$()[0].scrollHeight

    unless isAtTop
      @$('.permissions-header').addClass 'scrolling'
    else
      @$('.permissions-header').remove 'scrolling'

    unless isAtBottom
      @$('.formline.button-field').addClass 'scrolling'
    else
      @$('.formline.button-field').removeClass 'scrolling'


  createTree =(values)->
    values.reduce (acc, {module, role, permission})->
      acc[module] ?= {}
      acc[module][role] ?= []
      acc[module][role].push permission
      return acc
    , {}

  createReducedList =(values)->
    cache = {}
    values.reduce (acc, {module, role, permission})->
      storageKey = module+':'+role
      cached = cache[storageKey]
      if cached?
        cached.permissions.push permission
      else
        cache[storageKey] = {module, role, permissions: [permission]}
        acc.push cache[storageKey]
      return acc
    , []

  getFormValues:->
    @$().serializeArray()
    .map ({name})->
      [facet, role, permission] = name.split '|'
      module = facet.split('-')[1]
      {module, role, permission}

  getPermissions:(structure='reducedList')->
    values = @getFormValues()
    switch structure
      when 'reducedList'  then return createReducedList values
      when 'list'         then return values
      when 'tree'         then return createTree values
      else throw new Error "Unknown structure #{structure}"

  viewAppended:->
    super
    @applyScrollShadow()
