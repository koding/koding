module.exports = (konstructor, groupName) ->
  { name } = konstructor
  db = konstructor.getClient()
  collectionBaseName = Inflector(name).decapitalize().pluralize()
  collectionGroupName = groupName.replace /-/g, '_'
  groupedCollectionName = "#{collectionBaseName}__#{collectionGroupName}"
  console.log { groupedCollectionName }
  db.collection groupedCollectionName
