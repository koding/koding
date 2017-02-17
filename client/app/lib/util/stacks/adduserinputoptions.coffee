# TODO move this to backend ~GG
# This function checks koding section of template,
# exracts user input options from there and adds them to userInput data
module.exports = addUserInputOptions = (template, requiredData) ->

  { userInput } = requiredData
  return  if not userInput or not template.koding

  options = template.koding.userInput ? {}
  requiredData.userInput = userInput.map (item) ->
    if itemOptions = options[item]
      return { name: item, type: itemOptions }  if typeof itemOptions is 'string'
      { type, values } = itemOptions
      return { name: item, type, values }
    else
      return item
