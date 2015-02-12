class ActivityWidget extends KDView
  constructor: (options = {}, data) ->
    options.cssClass       = KD.utils.curry "status-update-widget", options.cssClass
    options.showForm     or= yes
    options.childOptions or= {}
    super options, data
    @activity = null

  showForm: (callback) ->
    @inputWidget?.show()
    @inputWidget.once "Submit", callback

  hideForm: ->
    @inputWidget?.hide()

  display: (id, callback = noop) ->
    return callback { message: "not implemented feature" }
    KD.remote.cacheable "JNewStatusUpdate", id, (err, activity) =>
      KD.showError err
      callback err, activity
      activity.fetchTags (err, tags) =>
        activity.tags = tags
        @addActivity activity  if activity and not err

  create: (body, callback = noop) ->
    return callback { message: "not implemented feature" }
    KD.remote.api.JNewStatusUpdate.create {body}, (err, activity) =>
      KD.showError err
      callback err, activity
      @addActivity activity  if activity and not err

  reply: (body, callback = noop) ->
    @activity?.reply body, callback

  addActivity: (activity) ->
    @activity = activity
    @addSubView new ActivityWidgetItem @getOptions().childOptions, activity

  setInputContent: (str = "") ->
    @inputWidget?.input.setContent str

  viewAppended: ->
    {defaultValue, showForm} = @getOptions()
    KD.singleton("appManager").require "Activity", =>
      @addSubView @inputWidget = new ActivityInputWidget {defaultValue}
      @inputWidget.once "Submit", (err, activity) =>
        return  KD.showError err if err
        @addActivity activity  if activity
