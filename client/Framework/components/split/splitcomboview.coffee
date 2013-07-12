class KDSplitComboView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass or= "kdsplitcomboview"

    super options, data

    @addSubView @createSplitView options.direction, options.sizes, options.views

  createSplitView: (type, sizes, viewsConfig) ->
    views = []

    for config, index in viewsConfig
      if config.type is "split"
        {options} = config
        views.push @createSplitView options.direction, options.sizes, config.views
      else
        views.push config

    new KDSplitView { type, sizes, views }


# Example Usage
#
# new KDSplitComboView
#   direction           : "horizontal"
#   sizes               : [ "50%", "50%" ]
#   views               : [
#     {
#       type            : "split"
#       options         :
#         direction     : "vertical"
#         sizes         : [ "50%", "50%" ]
#       views           : [
#         kdView
#         {
#           type        : "split"
#           options     :
#             direction : "horizontal"
#             sizes     : [ "50%", "50%" ]
#           views       : [ myKDView, yourKDView ]
#         }
#       ]
#     }
#     {
#       type            : "split"
#       options         :
#         direction     : "vertical"
#         sizes         : [ "66%", "33%" ]
#       views           : [
#         {
#           type        : "split"
#           options     :
#             direction : "vertical"
#             sizes     : [ "50%", "50%" ]
#           views       : [ myKDTabView, yourKDTabView ]
#         },
#         anotherKDView
#       ]
#      }
#     ]
