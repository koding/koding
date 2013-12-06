@partition = (list, fn) ->
  result = [[], []]
  result[+!fn item].push item for item in list
  result