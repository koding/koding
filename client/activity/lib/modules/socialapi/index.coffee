module.exports =
  models:
    message: require './models/message'
    channel:
      public: require './models/publicchannel'
      private: require './models/privatechannel'

