
class PricingGroupForm extends KDFormViewWithFields
  constructor: (options = {}, data) ->
    options =
      title                 : "Enter new group name"
      cssClass              : KD.utils.curry "pricing-create-group", options.cssClass
      callback              : =>
        @buttons.Create.showLoader()
        @emit "Submit"
      buttons               :
        Create              :
          title             : "CREATE YOUR GROUP"
          type              : "submit"
          style             : "solid green medium"
          loader            : yes
          callback          : ->
      fields                :
        GroupName           :
          label             : "Group Name"
          name              : "groupName"
          placeholder       : "My Awesome Group"
          validate          :
            rules           :
              required      : yes
          keyup             : => @checkSlug()
          validate          :
            rules           :
              required      : yes
            messages        :
              required      : "Group name required"
        GroupURL            :
          label             : "Group address"
          defaultValue      : "#{window.location.origin}/"
          # disabled          : yes
          keyup             : =>
            @checkSlug @inputs.GroupURL.getValue().split("/").last

          # don't push it in if you can't do it right! - SY

          # nextElement       :
          #   changeURL       :
          #     itemClass     : KDCustomHTMLView
          #     tagName       : "a"
          #     partial       : 'change'
          #     click         : =>
          #       @groupForm.inputs.GroupURL.makeEnabled()
          #       @groupForm.inputs.GroupURL.focus()
        GroupSlug           :
          type              : "hidden"
          name              : "groupSlug"
          validate          :
            rules           :
              minLength     : 3

        Visibility          :
          itemClass         : KDSelectBox
          label             : "Visibility"
          type              : "select"
          name              : "visibility"
          defaultValue      : "hidden"
          selectOptions     : [
            { title : "Hidden" ,   value : "hidden"  }
            { title : "Visible",   value : "visible" }
          ]

    super options, data

  checkSlug: (input) ->
    {GroupName, GroupURL, GroupSlug} = @inputs
    input ?= GroupName.getValue()

    return  if input.length < 3

    slugy = KD.utils.slugify input
    KD.remote.api.JGroup.suggestUniqueSlug slugy, (err, newSlug)->
      GroupURL.setValue "#{location.origin}/#{newSlug}"
      GroupSlug.setValue newSlug
