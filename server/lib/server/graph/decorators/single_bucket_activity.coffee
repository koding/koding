module.exports = class SingleBucketActivityDecorator
  constructor:(@datum)->

  decorate:-> @decorateActivity()

  decorateActivity:->
    activity =
      # I think this is used for new member buckets
      #bongo_ :
        #constructorName : @datum.name
        #instanceId      : @datum._id
      constructorName : @datum.name
      instanceId      : @datum._id

    return activity
