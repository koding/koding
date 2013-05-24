module.exports = class SingleBucketActivityDecorator
  constructor:(@datum)->

  decorate:-> @decorateActivity()

  decorateActivity:->
    activity =
      id              : @datum._id
      constructorName : @datum.name

    return activity
