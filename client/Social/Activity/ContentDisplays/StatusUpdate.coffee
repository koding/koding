class ContentDisplayStatusUpdate extends ActivityContentDisplay

  constructor:(options = {}, data={})->

    options.tooltip or=
      title     : "Status Update"
      offset    : 3
      selector  : "span.type-icon"

    super options,data

    @activityItem = new StatusActivityItemView delegate: this, @getData()

    @activityItem.on 'ActivityIsDeleted', ->
      KD.singleton('router').back()

  viewAppended: JView::viewAppended

  pistachio:->
    """
    <h2 class="sub-header">{{> @back}}</h2>
    {{> @activityItem}}
    """


    # """
    # {{> @header}}
    # <h2 class="sub-header">{{> @back}}</h2>
    # <div class='kdview content-display-main-section activity-item status'>
    #   <span>
    #     {{> @avatar}}
    #     <span class="author">AUTHOR</span>
    #   </span>
    #   <div class='activity-item-right-col'>
    #     <h3 class='hidden'></h3>
    #     <p class="status-body">{{@applyTextExpansions #(body)}}</p>
    #     {{> @embedBox}}
    #     <footer class='clearfix'>
    #       <div class='type-and-time'>
    #         <span class='type-icon'></span>{{> @contentGroupLink }} by {{> @author}}
    #         {{> @timeAgoView}}
    #         {{> @tags}}
    #       </div>
    #       {{> @actionLinks}}
    #     </footer>
    #     {{> @commentBox}}
    #   </div>
    # </div>
    # """
