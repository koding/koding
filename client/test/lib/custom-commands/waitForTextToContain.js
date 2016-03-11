var util = require('util');
var events = require('events');


function WaitForTextToContain() {
    events.EventEmitter.call(this);
    this.startTimeInMilliseconds = null;
}

util.inherits(WaitForTextToContain, events.EventEmitter);

WaitForTextToContain.prototype.command = function (element, textToContain, timeoutInMilliseconds) {
    this.startTimeInMilliseconds = new Date().getTime();
    var self = this;
    var message;

    if (!timeoutInMilliseconds) {
        timeoutInMilliseconds = 20000;
    }

    var checkerFn = function(content) {
        return content.indexOf(textToContain) > -1;
    }

    this.check(element, checkerFn, function (result, loadedTimeInMilliseconds) {
        if (result) {
            message = 'Element <' + element + '> contains text "' + textToContain + '" in ' + (loadedTimeInMilliseconds - self.startTimeInMilliseconds) + ' ms.';
        } else {
            message = 'Element <' + element + '> wasn\'t contains text "' + textToContain + '" in ' + timeoutInMilliseconds + ' ms.';
        }
        self.client.assertion(result, 'expression false', 'expression true', message, true);
        self.emit('complete');
    }, timeoutInMilliseconds);

    return this;
};

WaitForTextToContain.prototype.check = function (element, checker, callback, maxTimeInMilliseconds) {
    var self = this;

    this.api.getText(element, function (result) {
        var now = new Date().getTime();
        if (result.status === 0 && checker(result.value)) {
            callback(true, now);
        } else if (now - self.startTimeInMilliseconds < maxTimeInMilliseconds) {
            setTimeout(function () {
                self.check(element, checker, callback, maxTimeInMilliseconds);
            }, 300);
        } else {
            callback(false);
        }
    });
};

module.exports = WaitForTextToContain;
