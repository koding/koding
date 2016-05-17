module.exports =

  changePage: (currentPage, nextPage) ->

    return currentPage  if currentPage is nextPage

    currentPage.hide()  if currentPage
    nextPage.show()
    return nextPage
