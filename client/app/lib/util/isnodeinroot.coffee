module.exports = (node, root) ->

  while node
    if node is root
      return yes
    node = node.parentNode;
  return no