module.exports = (element) ->

  if document.body.createTextRange
    range = document.body.createTextRange()
    range.moveToElementText element
    range.select()
  else if window.getSelection
    selection = window.getSelection()
    range = document.createRange()
    range.selectNodeContents element
    selection.removeAllRanges()
    selection.addRange range
