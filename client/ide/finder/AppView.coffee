# class FinderView extends KDView

#   constructor:(options = {}, data)->

#     options.cssClass = KD.utils.curry 'finder-app', options.cssClass

#     super options, data

#     @finderController   = new NFinderController
#       useStorage        : yes
#       addOrphansToRoot  : no

#     unless KD.singletons.finderController
#       KD.registerSingleton "finderController", @finderController

#   viewAppended:->
#     @addSubView @finderController.getView()
#     @finderController.reset()
