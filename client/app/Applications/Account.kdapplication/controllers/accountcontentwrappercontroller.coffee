class AccountContentWrapperController extends KDViewController

  getSectionIndexForScrollOffset:(offset)->

    sectionIndex = 0
    while @sectionLists[sectionIndex + 1]?.$().position().top <= offset
      sectionIndex++
    sectionIndex

  scrollTo:(index)->

    itemToBeScrolled = @sectionLists[index]
    scrollToValue    = itemToBeScrolled.$().position().top
    @getView().parent.$().animate scrollTop : scrollToValue, 300