module.exports = (html) ->
  tmp = document.createElement 'DIV'
  tmp.innerHTML = html

  return tmp.textContent or tmp.innerText or ''
