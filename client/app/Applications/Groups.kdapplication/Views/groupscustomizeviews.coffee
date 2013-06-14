class StaticPageCustomizeView extends KDView
  constructor:(options,data)->
    super options,data
    @setClass 'group-customize-view'

    @bgSelectView = new StaticGroupBackgroundSelectView
      cssClass  : 'custom-select-background-view'
      delegate  : @

    @bgColorView = new StaticGroupBackgroundColorSelectView
      cssClass  : 'custom-select-background-view'
      delegate  : @

    @uploadIndicator = new KDView
      partial : 'Your file is being uploaded...'
      cssClass : 'upload-indicator hidden'

    @uploadDropper = new KDImageUploadView
      cssClass : 'upload-dropper hidden'

      limit           : 1
      preview         : "thumbs"
      extensions      : null
      fileMaxSize     : 2048
      totalMaxSize    : 2048
      fieldName       : "thumbnails"
      convertToBlob   : yes
      title           : "Drop Image here to upload"

    @uploadDropper.on 'FileReadComplete', =>
      @uploadDropper.hide()
      @uploadIndicator.show()

    @uploadDropper.on 'FileUploadComplete', (res)=>
      if res.length and res[0].resource
        @staticController.setBackground 'customImage', res[0].resource

        @bgSelectView.thumbsController.addItem
          title : 'User Image'
          url : res[0].resource
          thumbUrl : res[0].resource
          dataIndex : -1
          type : 'customImage'
          userImage : yes
        , 0

        item = @bgSelectView.thumbsController.itemsOrdered.first
        item.$().css backgroundImage : "url(#{res[0].resource})"
        item.customUrl = res[0].resource
        @bgSelectView.thumbsController.selectItem item

        new KDNotificationView
          title : 'Your image was uploaded successfully'

        @uploadIndicator.hide()

        item.emit 'FileUploaded',item

      else
        @uploadDropper.hide()
        new KDNotificationView
          title : 'There was an error uploading your file'


    @settingsLink = new CustomLinkView
      title     : 'Looking for Group Settings?'
      href      : '#'
      cssClass  : 'settings-link'
      click     : =>
        {entryPoint} = KD.config
        KD.getSingleton('lazyDomController')?.openPath "/Activity", {entryPoint}

    @backButton = new CustomLinkView
      title       : ""
      cssClass    : "close-link"
      icon        :
        placement : "right"
      click       : (event)=>
        event.stopPropagation()
        event.preventDefault()
        contentWrapper = @getDelegate().groupContentWrapperView or @getDelegate().profileContentWrapperView
        contentWrapper.unsetClass 'edit'

    @attachListeners()
    @addSettingsButton()

    @fetchStaticPageData =>
      @bgSelectView.decorateList @group
      @bgColorView.decorateList @group

    @staticController = KD.getSingleton('staticGroupController') ? KD.getSingleton('staticProfileController')
    @windowController = KD.getSingleton('windowController')

  addSettingsButton:->
    @settingsLink = new CustomLinkView
      title     : 'Looking for Group Settings?'
      href      : '#'
      cssClass  : 'settings-link'
      click     : =>
        {entryPoint} = KD.config
        KD.getSingleton('lazyDomController')?.openPath "/Activity", {entryPoint}



  fetchStaticPageData:(callback =->)->
    {entryPoint} = KD.config

    KD.remote.cacheable entryPoint.slug, (err,[group],name)=>
      @group = group
      callback group

  attachListeners:->
    @on 'DefaultColorSelected',=>
      @customImageChanged = no
      @defaultColorChanged = yes
      @customColorChanged = no
      @defaultImageChanged = no
      @bgSelectView.thumbsController.deselectAllItems()
      @utils.defer => @emit 'OptionChanged'

    @on 'DefaultImageSelected',=>
      # @emit 'OptionChanged'
      @customImageChanged = no
      @defaultImageChanged = yes
      @customColorChanged = no
      @defaultColorChanged = no
      @bgColorView.thumbsController.deselectAllItems()
      @utils.defer => @emit 'OptionChanged'

    @on 'CustomImageSelected',=>
      @customImageChanged = yes
      @defaultImageChanged = no
      @customColorChanged = no
      @defaultColorChanged = no
      @bgColorView.thumbsController.deselectAllItems()
      @utils.defer => @emit 'OptionChanged'

    @on 'CustomColorSelected',=>
      @customImageChanged = no
      @customColorChanged = yes
      @defaultImageChanged = no
      @defaultColorChanged = no
      @bgSelectView.thumbsController.deselectAllItems()
      @utils.defer => @emit 'OptionChanged'

    @on 'OptionChanged',=>

        if @group

          if @customColorChanged
            defaultIndexItem = @bgColorView.thumbsController.selectedItems.first

            if defaultIndexItem
              pickedColor = defaultIndexItem.color.picker.getValue() or 'fff'
              log pickedColor
              @group.setBackgroundImage 'customColor', pickedColor, (err,res)=>
                unless err
                  new KDNotificationView
                    title : "Background updated with custom color"
                  @customColorChanged = no

          else if @customImageChanged
            url = @bgSelectView.thumbsController.selectedItems.first.customUrl \
            or @bgSelectView.thumbsController.selectedItems.first.getData().url
            if url
              @group.setBackgroundImage 'customImage', url, (err,res)=>
                unless err
                  new KDNotificationView
                    title : "Background updated with custom image"
                  @customImageChanged = no

          else if @defaultImageChanged
              defaultIndexItem = @bgSelectView.thumbsController.selectedItems.first

              if defaultIndexItem
                defaultIndex = defaultIndexItem.getData().dataIndex or 0
                @group.setBackgroundImage 'defaultImage', defaultIndex, (err,res)=>
                  unless err
                    new KDNotificationView
                      title : "Background updated to #{defaultIndexItem.getData().title}"
                    @defaultImageChanged = no

          else if @defaultColorChanged
              defaultIndexItem = @bgColorView.thumbsController.selectedItems.first

              if defaultIndexItem
                defaultHex = defaultIndexItem.getData().colorValue or 0
                @group.setBackgroundImage 'defaultColor', defaultHex, (err,res)=>
                  unless err
                    new KDNotificationView
                      title : "Background updated to color #{defaultIndexItem.getData().title}"
                    @defaultColorChanged = no

    @utils.wait 1000, =>

      @windowController.on 'DragEnterOnWindow', (event)=>
        # log 'ENTERED'
        @windowController.addLayer @uploadDropper
        @uploadDropper.show()

      @windowController.on 'DragExitOnWindow', (event)=>
        # log 'EXITED'
        @windowController.removeLayer @uploadDropper
        @uploadDropper.hide()


  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  getBackgroundData:(data={})->
    if data.customize?.background?
      data.customize.background
    else if data.profile?.staticPage?.customize?.background?
      data.profile.staticPage.customize.background
    else {}

  pistachio:->
    """
    {{> @backButton}}
    <h1 class="customize-title">Customize this Group page
    <span class="settings-span">({{> @settingsLink}})</span>
    </h1>
    {{> @bgSelectView}}
    {{> @bgColorView}}
    {{> @uploadDropper}}
    {{> @uploadIndicator}}
    """


class StaticGroupBackgroundUploadView extends KDView

  constructor:(options,data)->
    super options,data

    @uploader = new KDImageUploadView
      cssClass        : 'image-uploader'
      limit           : 1
      preview         : "thumbs"
      extensions      : null
      fileMaxSize     : 2048
      totalMaxSize    : 2048
      fieldName       : "thumbnails"
      convertToBlob   : yes
      title           : ""

    @uploader.on 'FileUploadComplete', (res)=>
      if res.length and res[0].resource
        @getDelegate().getDelegate().getDelegate().staticController.setBackground 'customImage', res[0].resource
        @$().css backgroundImage : "url(#{res[0].resource})"
        @getDelegate().customUrl = res[0].resource

        @getDelegate().emit 'FileUploaded',@



  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @uploader}}
    """


class StaticGroupBackgroundSelectView extends KDView

  constructor:(options,data)->
    super options,data

    @thumbsController  = new KDListViewController
      itemClass       : StaticGroupBackgroundSelectItemView
      viewOptions     :
        delegate      : @getDelegate()
    @thumbsView = @thumbsController.getView()

    # default items
    items = []
    for i in [1..8]
      items.push
        title     : "Template ##{i}"
        url       : "/images/bg/blurred/#{i}.jpg"
        thumbUrl  : "/images/bg/blurred/th#{i}.jpg"
        dataIndex : i-1
        type      : 'defaultImage'

    items.push
      title       : 'Upload an Image'
      url         : ''
      thumbUrl    : '/images/bg/th/no.png'
      dataIndex   : -1
      type        : 'customImage'

    @thumbsController.instantiateListItems items
    @attachListeners()

  attachListeners:->
    @thumbsController.listView.on 'DefaultImageSelected', (view)=>
      @getDelegate().emit 'DefaultImageSelected', view

    @thumbsController.listView.on 'CustomImageSelected', (view)=>
      @getDelegate().emit 'CustomImageSelected', view

    @thumbsController.listView.on 'FileUploaded', (view)=>
      @thumbsController.selectItem view.getDelegate()
      @getDelegate().emit 'CustomImageSelected', view


  decorateList:(group={})->
    backgroundData = @getDelegate().getBackgroundData group

    if backgroundData.customImages

      for customImage in backgroundData.customImages
        @thumbsController.addItem
          title : 'User Image'
          url : customImage
          thumbUrl : customImage
          dataIndex : -1
          type : 'customImage'
          userImage : yes
        , 0

    if backgroundData.customType is 'defaultImage'
      for item in @thumbsController.itemsOrdered
        if item.getData().dataIndex is backgroundData.customValue
          @thumbsController.selectItem item

    else @thumbsController.deselectAllItems()

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <span class="title">Select a Background</span>
    {{> @thumbsView}}
    """


class StaticGroupBackgroundSelectItemView extends KDListItemView
  constructor:(options,data)->
    super options,data

    @setClass 'custom-image-selectitemview'
    @title = new KDView
      partial : @getData().title

    @type = @getData().type or 'defaultImage'

    if @type is 'defaultImage' or (@type is 'customImage' and @getData().url?.length>0)
      @image = new KDCustomHTMLView
        tagName     : 'img'
        cssClass    : 'custom-image-default'
        attributes  :
          src       : @getData().thumbUrl
          alt       : @getData().title
    else if @type is 'customImage'
      @hide()
      @image = new  StaticGroupBackgroundUploadView
        cssClass : 'custom-image-upload'
        delegate : @
      @image.$().css backgroundImage : "url(#{@getData().thumbUrl})" if @getData().thumbUrl


    if @getData().userImage

      @closeLink =  new CustomLinkView
        title       : ''
        cssClass    : 'close-link'
        icon        :
          placement : 'right'
        click       : (event)=>
          event.preventDefault()
          event.stopPropagation()
          modal = new KDModalView
            title     : 'Remove Custom Image'
            cssClass  : "new-kdmodal"
            content   : '<p>Do you really want to remove this image?</p> '
            buttons   :
              'Remove Image':
                cssClass    : 'modal-clean-red'
                callback    : =>
                  @getDelegate()?.getDelegate()?.group?.removeBackgroundImage 'customImage', @getData().url, =>
                    @destroy()
                  modal.destroy()
              'Cancel'      :
                cssClass    : 'modal-cancel'
                callback    : -> modal.destroy()

    else
      @closeLink = new KDView


    @customUrl = null

    @on 'FileUploaded', (view)=>
      @getDelegate().emit 'FileUploaded', view
  click: ->
    # preview live
    if @getData().type is 'defaultImage'
      @getDelegate().emit 'DefaultImageSelected', @
      @getDelegate().getDelegate().staticController.setBackground @type, @getData().url

    else if  @getData().type is 'customImage'
      @getDelegate().emit 'CustomImageSelected', @
      @getDelegate().getDelegate().staticController.setBackground @type, @customUrl or @getData().url

    else log 'Something weird happened'
  viewAppended:->
      super
      @setTemplate @pistachio()
      @template.update()

  pistachio:->
    """
    {{> @image}}
    {{#(title)}}
    {{> @closeLink}}
    """

## *************************
# COLOR SELECT
## *************************

class StaticGroupBackgroundColorSelectView extends KDView

  constructor:(options,data)->
    super options,data

    @thumbsController = new KDListViewController
      itemClass       : StaticGroupBackgroundColorSelectItemView
      viewOptions     :
        delegate      : @getDelegate()

    @thumbsView = @thumbsController.getView()

    # default items
    items = [
      {title:'Black',colorValue:'#000000', type:'defaultColor'}
      {title:'White',colorValue:'#ffffff', type:'defaultColor'}
      {title:'Transparent',colorValue:'rgba(0,0,0,0.2)', type:'defaultColor'}
      {title:'Koding',colorValue:'#ff9200', type:'defaultColor'}
      {title:'Rhodamine Red C',colorValue:'#E10098', type:'defaultColor'}
      {title:'876 C',colorValue:'#8B634B', type:'defaultColor'}
      {title:'521 C',colorValue:'#A57FB2', type:'defaultColor'}
      {title:'326 C',colorValue:'#00B2A9', type:'defaultColor'}
      {title:'583 C',colorValue:'#B7BF10', type:'defaultColor'}
      {title:'Pick a color',colorValue:@utils.getRandomHex(), type:'customColor'}
    ]


    @thumbsController.instantiateListItems items
    @attachListeners()

  attachListeners:->
    @thumbsController.listView.on 'DefaultColorSelected', (view)=>
      @getDelegate().emit 'DefaultColorSelected', view

    @thumbsController.listView.on 'CustomColorSelected', (view)=>
      @getDelegate().emit 'CustomColorSelected', view

  decorateList:(group={})->
    backgroundData = @getDelegate().getBackgroundData group

    if backgroundData.customColors

      for customColor in backgroundData.customColors
        @thumbsController.addItem
          title : 'User Color'
          colorValue : customColor
          type : 'defaultColor'
          userColor : yes
        , 0

    if backgroundData.customType is 'defaultColor'
      for item in @thumbsController.itemsOrdered
        if item.getData().colorValue is backgroundData.customValue
          @thumbsController.selectItem item

    if backgroundData.customType is 'customColor'
      for item in @thumbsController.itemsOrdered
        if item.getData().type is 'customColor'
          @thumbsController.selectItem item
          item.decorateCustomColor backgroundData.customValue

    else @thumbsController.deselectAllItems()


  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <span class="title">Select a Background</span>
    {{> @thumbsView}}
    """


class StaticGroupBackgroundColorSelectItemView extends KDListItemView
  constructor:(options,data)->
    super options,data

    {@type,colorValue,title,userColor} = data = @getData()

    @setClass 'custom-image-selectitemview color'
    @title = new KDView
      partial : title

    @type ?= 'defaultImage'

    if @type is 'defaultColor'
      @color = new KDView
        cssClass : 'custom-color-default'
      @color.$().css backgroundColor : "#{colorValue}"
      log 'adding close button'

    else if @type is 'customColor'
      @color = new StaticGroupBackgroundColorPickerView
        cssClass : 'custom-color-picker'
        delegate : @getDelegate()
      ,data

    if userColor
      @closeLink =  new CustomLinkView
        title       : ''
        cssClass    : 'close-link'
        icon        :
          placement : 'right'
        click       : (event)=>
          event.preventDefault()
          event.stopPropagation()
          modal = new KDModalView
            title     : 'Remove Custom Color'
            cssClass  : "new-kdmodal"
            content   : '<p>Do you really want to remove this color?</p> '
            buttons   :
              'Remove Color':
                cssClass    : 'modal-clean-red'
                callback    : =>
                  @getDelegate()?.getDelegate()?.group?.removeBackgroundImage 'customColor', colorValue, =>
                    @destroy()
                  modal.destroy()
              'Cancel'      :
                cssClass    : 'modal-cancel'
                callback    : -> modal.destroy()

    else
      @closeLink = new KDView

  click: ->
    {type,colorValue} = @getData()

    if type is 'defaultColor'
      @getDelegate().emit 'DefaultColorSelected', @
      @getDelegate().getDelegate().staticController.setBackground type, colorValue

    else if type is 'customColor'
      @getDelegate().emit 'CustomColorSelected', @
      @getDelegate().getDelegate().staticController.setBackground type, @color.picker.getValue()
    else log 'Something weird happened'

  decorateCustomColor:(color)->
    @utils.defer =>
      @getDelegate().getDelegate().staticController.setBackground @type, color
    @color.decorateCustomColor color or '#ff9200'

  viewAppended:->
      super
      @setTemplate @pistachio()
      @template.update()

  pistachio:->
    """
    {{> @color}}
    {{#(title)}}
    {{> @closeLink}}
    """

class StaticGroupBackgroundColorPickerView extends KDView
  constructor:(options,data)->
    super options,data
    {@type, @colorValue} = @getData()
    @picker         = new KDInputView
      cssClass      : 'color-picker'
      bind          : 'keyup'
      defaultValue  : @colorValue
      keyup         : => @updateColor()
      focus         : => @updateColor()
      blur          : => @updateColor()

    @$().css backgroundColor : @picker.getValue()

  updateColor:->
    @$().css backgroundColor : @picker.getValue()
    @getDelegate().getDelegate().staticController.setBackground @type, @picker.getValue()

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  decorateCustomColor:(color)->
    @picker.setValue color
    @$().css backgroundColor : @picker.getValue()

  pistachio:->
    """
    {{> @picker}}
    """