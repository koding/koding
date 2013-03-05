# we don't use this deprecate 02/2013 sinan

class KDModalController extends KDViewController
  modalViewTypes =
    blocking      : KDBlockingModalView
    loading       : KDModalViewLoad

  listeningTo = []
  systemModals = {}

  @createAndShowNewModal = (options)->
    {
      type                     # type of modal view to be created (string type or constructor of subClass of KDModalView)
      view                     # a KDView subClass to be placed in the modal view (should propagate event for close, etc)
      overlay                  # a Boolean
      height                   # a Number for pixel value or a String e.g. "100px" or "20%"
      width                    # a Number for pixel value or a String e.g. "100px" or "20%"
      position                 # an Object holding top and left values
      title                    # a String of text or HTML
      content                  # a String of text or HTML
      cssClass                 # a String
      buttons                  # an Object of button options
      fx                       # a Boolean
      draggable
      # TO BE IMPLEMENTED
      resizable                 # a Boolean
    } = options


    modalView = (new type? options) or (new modalViewTypes[type]? options) or new KDModalView options

    modalView.on 'KDModalViewDestroyed', (modalView)=> delete systemModals[modalView.getId()]
    systemModals[id = modalView.getId()] = modalView

    (view or modalView).on 'KDModalShouldClose', do (modalView)->
      -> modalView.destroy()

    return id

  @getModalById = (id)->
    systemModals[id]

  @setListeningTo = (obj)->
    listeningTo.push obj
