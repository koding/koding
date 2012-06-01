try {
    module.exports = require('./build/default/src/inotify');
} catch(e) {
    module.exports = require('./build/Release/src/inotify');
}
