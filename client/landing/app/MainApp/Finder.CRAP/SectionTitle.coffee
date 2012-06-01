class SectionTitle extends FinderItemView
  partial:(data)->
    $ "<div class='finder-item section-title clearfix'>
        <span class='icon #{data.source}'></span>
        <span class='title'>#{data.name}</span>
      </div>
      <span class='chevron-arrow'></span>"

  isDraggable:()->
    return @draggingEnabled ? no #make yes for class draggability