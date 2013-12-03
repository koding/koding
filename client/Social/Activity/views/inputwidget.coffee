class ActivityInputWidget extends KDView
  {daisy, dash}         = Bongo
  {JStatusUpdate, JTag} = KD.remote.api

  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "input-wrapper", options.cssClass
    super options, data
    @input    = new ActivityInputView
    @embedBox = new EmbedBoxWidget delegate: @input, data

    @submit    = new KDButtonView
      type     : "submit"
      cssClass : "fr"
      title    : "Submit"
      callback : @bound "submit"

  submit: (callback) ->
    tags          = []
    suggestedTags = []
    createdTags   = {}

    unless KD.checkFlag "exempt"
      for token in @input.getTokens()
        {data, type} = token
        if type is "tag"
          if data instanceof JTag then tags.push id: data.getId()
          else if data.$suggest?  then suggestedTags.push data.$suggest

    daisy queue = [
      =>
        tagCreateJobs = suggestedTags.map (title) ->
          ->
            JTag.create {title}, (err, tag) ->
              tags.push id: tag.getId()
              createdTags[title] = tag
              tagCreateJobs.fin()

        dash tagCreateJobs, ->
          queue.next()
    , =>
        body  = @input.getValue()
        body  = body.replace /\|(.*?):\$suggest:(.*?)\|/g, (match, prefix, title) ->
          tag = createdTags[title]
          return  "" unless tag
          return  "|#{prefix}:JTag:#{tag.getId()}|"

        data     =
          group  : KD.getSingleton('groupsController').getGroupSlug()
          body   : body
          meta   :
            tags : tags

        data.link_url   = @embedBox.url or ""
        data.link_embed = @embedBox.getDataForSubmit() or {}

        JStatusUpdate.create data, (err, activity) =>
          unless err
            @input.setContent ""
            @submit.setTitle "Submit"
            @editing = off

          callback? err, activity
          KD.getSingleton("appManager").tell "Activity", "ownActivityArrived", activity  unless @editing

          KD.showError err,
            AccessDenied :
              title      : 'You are not allowed to #{action} activities'
              content    : 'This activity will only be visible to you'
              duration   : 5000
            KodingError  : 'Something went wrong while creating activity'
    ]

  viewAppended: ->
    @addSubView @input
    @addSubView @embedBox
    @addSubView @submit
