


onFileLoaded = (doc) ->

  string = doc.getModel().getRoot().get("text")

  # Keeping one box updated with a String binder.
  textArea1 = document.getElementById("editor1")
  gapi.drive.realtime.databinding.bindString string, textArea1

  # Keeping one box updated with a custom EventListener.
  textArea2 = document.getElementById("editor2")
  updateTextArea2 = (e) ->
    textArea2.value = string


  string.addEventListener gapi.drive.realtime.EventType.TEXT_INSERTED, updateTextArea2
  string.addEventListener gapi.drive.realtime.EventType.TEXT_DELETED, updateTextArea2
  textArea2.onkeyup = ->
    string.setText textArea2.value

  updateTextArea2()

  textArea1.disabled = false
  textArea2.disabled = false

  model = doc.getModel()
  undoButton = document.getElementById("undoButton")
  redoButton = document.getElementById("redoButton")
  undoButton.onclick = (e) ->
    model.undo()


  redoButton.onclick = (e) ->
    model.redo()

  # Add event handler for UndoRedoStateChanged events.
  onUndoRedoStateChanged = (e) ->
    undoButton.disabled = not e.canUndo
    redoButton.disabled = not e.canRedo

  model.addEventListener gapi.drive.realtime.EventType.UNDO_REDO_STATE_CHANGED, onUndoRedoStateChanged



opt_initializerFn = (model) ->
  # console.log "opt_initializerFn -->", arguments
  string = model.createString "Hello Realtime World!"
  model.getRoot().set("text", string)

opt_errorFn = ->

initializeModel = (model) ->


ready = ->
  # gapi.client.drive.files.insert
  #   resource    :
  #     mimeType  : "application/vnd.google-apps.drive-sdk"
  #     title     : "hello-collab"
  # .execute (file)->
  #   console.log "-- file -->",file
  #   gapi.drive.realtime.load file.id, onFileLoaded, opt_initializerFn, opt_errorFn

  gapi.client.drive.files.get(fileId:"0B9RGB7N0fDPuOEhLTFg4NmhZNzQ").execute (file)->
    console.log "-- file -->",file
    gapi.drive.realtime.load file.id, onFileLoaded, opt_initializerFn, opt_errorFn




  # gapi.client.drive.files.list().execute ->
  #   console.log "lups",arguments


window.startRealtime = ->
   $.ajax
      url: "/-/google-api",
      dataType: "JSON"
      success: (authToken)->
        gapi.load "client",->
          gapi.client.load "drive","v2",->
            gapi.load "auth:client,drive-realtime,drive-share", ->
              gapi.auth.setToken authToken
              ready()
