class BugStatusItemList extends StatusActivityItemView

  constructor:( options={}, data)->
    super options, data

    @bugTags = ["fixed", "postponed", "not reproducible","duplicate","by design"]
    state   = tag.title for tag in data.tags when tag.title in @bugTags
    return unless KD.hasAccess "edit posts"
    @bugstatus  = new KDMultipleChoice
      cssClass     : "clean-gray editor-button control-button bug"
      labels       : @bugTags
      multiple     : no
      defaultValue : state
      size         : "tiny"
      callback     : (value)=>
        @changeBugStatus value

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

      tagToRemove = tag for tag in statusTags when tag.title in @bugTags
      tagToAdd    = tag for tag in systemTags when tag.title is status
      return new KDNotificationView title: "Tag not found!" unless tagToAdd

      # if system tag exist, remove it then add new tag
      if tagToRemove
        index = statusTags.indexOf tagToRemove
        statusTags.splice index, 1
        # remove tag from body
        stringToRemove = "|#:JTag:#{tagToRemove.getId()}|"
        stringToAdd    = "|#:JTag:#{tagToAdd.getId()}|"
        body = body.replace stringToRemove, stringToAdd
      else
        stringToAdd = "|#:JTag:#{tagToAdd.getId()}|"
        body       += " #{stringToAdd}"

      newTags.push id : tagToAdd.getId()
      newTags.push id:tag.getId() for tag in statusTags

      options  =
        body   : body
        meta   :
          tags : newTags
      activity.modify options, (err)->
        log err if err

  viewAppended: JView::viewAppended
