// glorious streaming json parser, built specifically for the twitter streaming api
// assumptions:
//   1) ninjas are mammals
//   2) tweets come in chunks of text, surrounded by {}'s, separated by line breaks
//   3) only one tweet per chunk
//
//   p = new parser.instance()
//   p.addListener('object', function...)
//   p.receive(data)
//   p.receive(data)
//   ...

var EventEmitter = require('events').EventEmitter;

var Parser = module.exports = function Parser() {
  // Make sure we call our parents constructor
  EventEmitter.call(this);
  this.buffer = '';
  return this;
};

// The parser emits events!
Parser.prototype = Object.create(EventEmitter.prototype);

Parser.END        = '\r\n';
Parser.END_LENGTH = 2;

Parser.prototype.receive = function receive(buffer) {
  this.buffer += buffer.toString('utf8');
  var index, json;

  // We have END?
  while ((index = this.buffer.indexOf(Parser.END)) > -1) {
    json = this.buffer.slice(0, index);
    this.buffer = this.buffer.slice(index + Parser.END_LENGTH);
    if (json.length > 0) {
      try {
        json = JSON.parse(json);
        switch(json.event){
          case 'follow':
            this.emit('follow', json);
            break;
          case 'favorite':
            this.emit('favorite', json);
            break;
          case 'unfavorite':
            this.emit('unfavorite', json);
            break;
          case 'block':
            this.emit('block', json);
            break;
          case 'unblock':
            this.emit('unblock', json);
            break;
          case 'list_created':
            this.emit('list_created', json);
            break;
          case 'list_destroyed':
            this.emit('list_destroyed', json);
            break;
          case 'list_updated':
            this.emit('list_updated', json);
            break;
          case 'list_member_added':
            this.emit('list_member_added', json);
            break;
          case 'list_member_removed':
            this.emit('list_member_removed', json);
            break;
          case 'list_user_subscribed':
            this.emit('list_user_subscribed', json);
            break;
          case 'list_user_unsubscribed':
            this.emit('list_user_unsubscribed', json);
            break;
          case 'user_update':
            this.emit('user_update', json);
            break;
          default:
            this.emit('data', json);
            break;
        }
      } catch (error) {
        error.source = json;
        this.emit('error', error);
      }
    }
  }
};
