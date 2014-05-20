class BugStatusItemList extends ActivityListItemView

  JView.mixin @prototype

  constructor:( options={}, data)->
    super options, data

    @bugTags = ["valid", "fixed", "not reproducible", "invalid", "in progress"]
    state = tag.title for tag in data.tags when tag.title in @bugTags if data.tags

    @bugstatus     = new KDMultipleChoice
      cssClass     : "clean-gray editor-button control-button bug"
      labels       : @bugTags
      multiple     : no
      defaultValue : state
      size         : "tiny"
      disabled     : not KD.hasAccess "edit posts"
      callback     : (value)=>
        @changeBugStatus value
      click        : (event)->
        if not KD.hasAccess "edit posts"
          new KDNotificationView
            title : "Only Koding staff can set this"
        KD.utils.stopDOMEvent event

    data.on "TagsUpdated",(tags) =>
      state = tag.title for tag in tags when tag.category is "system-tag"
      @bugstatus.setValue state

    KD.utils.defer =>
      @addSubView @bugstatus

  getItemDataId:-> @getData().getId?() or @getData().id or @getData()._id

  changeBugStatus: (status)->
    KD.remote.api.JTag.fetchSystemTags {},limit:50, (err, systemTags)=>

      if err or systemTags.length < 1
        return new KDNotificationView title : err or "no system tag found."

      activity    = @getData()
      {body}      = activity
      statusTags  = activity.tags
      newTags     = []

      tagToRemove = tag for tag in statusTags when tag.title in @bugTags and tag.category is "system-tag"
      tagToAdd    = tag for tag in systemTags when tag.title is status
      return new KDNotificationView title: "Tag not found!" unless tagToAdd

      # if system tag exist, remove it then add new tag
      if tagToRemove
        isSame = tagToRemove.title is tagToAdd.title
        index  = statusTags.indexOf tagToRemove
        statusTags.splice index, 1
        # remove tag from body
        stringToRemove = @utils.tokenizeTag tagToRemove
        stringToAdd    = "|#:JTag:#{tagToAdd.getId()}|"
        if isSame
          stringToAdd = ""
          @bugstatus.setValue "", no
        else
          stringToAdd = "|#:JTag:#{tagToAdd.getId()}|"

        body = body.replace stringToRemove, stringToAdd

      else
        stringToAdd = @utils.tokenizeTag tagToAdd
        body       += " #{stringToAdd}"

      newTags.push id : tagToAdd.getId() unless isSame
      newTags.push id : tag.getId() for tag in statusTags

      options  =
        body   : body
        meta   :
          tags : newTags

      activity.modify options, (err)->
        log err if err
