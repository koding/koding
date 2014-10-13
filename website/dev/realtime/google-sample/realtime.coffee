
initializeModel = (model) ->
  string = model.createString("Hello Realtime World!")
  model.getRoot().set "text", string
  return

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


window.startRealtime = ->
  realtimeLoader = new rtclient.RealtimeLoader(realtimeOptions)
  realtimeLoader.start()
  return
realtimeOptions =
  clientId: "753589381435-qhjkc4bl6ctdttn8mgjdo6v3bvh2vp0f.apps.googleusercontent.com"
  authButtonElementId: "authorizeButton"
  initializeModel: initializeModel
  autoCreate: true
  defaultTitle: "New Realtime Quickstart File"
  newFileMimeType: null
  onFileLoaded: onFileLoaded
  registerTypes: null
  afterAuth: null
