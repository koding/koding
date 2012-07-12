/*
 * jQuery wmd plugin.
 */

(function($) {
    var counter = 0;
    
    $.fn.wmd = function(_options) {
        this.each(function() {
            var defaults = {"preview": true};
            var options = $.extend({}, _options || {}, defaults);
            
            if (!options.button_bar) {
                options.button_bar = "wmd-button-bar-" + counter;
                $("<div/>")
                    .attr("class", "wmd-button-bar")
                    .attr("id", options.button_bar)
                    .insertBefore(this);
            }
                
            if (typeof(options.preview) == "boolean" && options.preview) {
                options.preview = "wmd-preview-" + counter;
                $("<div/>")
                    .attr("class", "wmd-preview")
                    .attr("id", options.preview)
                    .insertAfter(this);
            }

            if (typeof(options.output) == "boolean" && options.output) {
                options.output = "wmd-output-" + counter;
                $("<div/>")
                    .attr("class", "wmd-output")
                    .attr("id", options.output)
                    .insertAfter(this);
            }
                
            this.id = this.id || "wmd-input-" + counter;
            options.input = this.id;
            
            setup_wmd(options);
            counter++;
        });
    };
})(jQuery);
;(function() {
    
WMDEditor = function(options) {
    this.options = WMDEditor.util.extend({}, WMDEditor.defaults, options || {});
    wmdBase(this, this.options);

    this.startEditor();
};
top.WMDEditor = WMDEditor;

WMDEditor.defaults = { // {{{
    version: 2.0, 
    output_format:"markdown", 
    lineLength:40, 

    button_bar: "wmd-button-bar",
    preview: "wmd-preview",
    output: "wmd-output",
    input: "wmd-input",
    
    // The text that appears on the upper part of the dialog box when
    // entering links.
    imageDialogText: 
        "<p style='margin-top: 0px'><b>Enter the image URL.</b></p>" + 
        "<p>You can also add a title, which will be displayed as a tool tip.</p>" +
        "<p>Example:<br />http://wmd-editor.com/images/cloud1.jpg   \"Optional title\"</p>",
    linkDialogText: 
        "<p style='margin-top: 0px'><b>Enter the web address.</b></p>" + 
        "<p>You can also add a title, which will be displayed as a tool tip.</p>" + 
        "<p>Example:<br />http://wmd-editor.com/   \"Optional title\"</p>",

    // The default text that appears in the dialog input box when entering
    // links.
    imageDefaultText: "http://",
    linkDefaultText: "http://",
    imageDirectory: "images/",

    // The link and title for the help button
    helpLink: "http://wmd-editor.com/",
    helpHoverTitle: "WMD website",
    helpTarget: "_blank",

    // Some intervals in ms.  These can be adjusted to reduce the control's load.
    previewPollInterval: 500,
    pastePollInterval: 100,

    buttons: "bold italic link blockquote code image ol ul heading hr"
}; // }}}

WMDEditor.prototype = {
    getPanels: function() {
        return {
            buttonBar: doc.getElementById(this.options.button_bar),
            preview: doc.getElementById(this.options.preview),
            output: doc.getElementById(this.options.output),
            input: doc.getElementById(this.options.input)
        };
    },

    startEditor: function() {
        this.panels = this.getPanels();
        this.previewMgr = new PreviewManager(this);
        edit = new this.editor(this.previewMgr.refresh);
        this.previewMgr.refresh(true);
    }
};


var util = { // {{{

    // Returns true if the DOM element is visible, false if it's hidden.
    // Checks if display is anything other than none.
    isVisible: function (elem) {
        // shamelessly copied from jQuery
        return elem.offsetWidth > 0 || elem.offsetHeight > 0;
    },

    // Adds a listener callback to a DOM element which is fired on a specified
    // event.
    addEvent: function(elem, event, listener){
        if (elem.attachEvent) {
            // IE only.  The "on" is mandatory.
            elem.attachEvent("on" + event, listener);
        }
        else {
            // Other browsers.
            elem.addEventListener(event, listener, false);
        }
    },

    // Removes a listener callback from a DOM element which is fired on a specified
    // event.
    removeEvent: function(elem, event, listener){
        if (elem.detachEvent) {
            // IE only.  The "on" is mandatory.
            elem.detachEvent("on" + event, listener);
        }
        else {
            // Other browsers.
            elem.removeEventListener(event, listener, false);
        }
    },

    // Converts \r\n and \r to \n.
    fixEolChars: function(text){
        text = text.replace(/\r\n/g, "\n");
        text = text.replace(/\r/g, "\n");
        return text;
    },

    // Extends a regular expression.  Returns a new RegExp
    // using pre + regex + post as the expression.
    // Used in a few functions where we have a base
    // expression and we want to pre- or append some
    // conditions to it (e.g. adding "$" to the end).
    // The flags are unchanged.
    //
    // regex is a RegExp, pre and post are strings.
    extendRegExp: function(regex, pre, post){
    
        if (pre === null || pre === undefined)
        {
            pre = "";
        }
        if(post === null || post === undefined)
        {
            post = "";
        }
    
        var pattern = regex.toString();
        var flags = "";
    
        // Replace the flags with empty space and store them.
        // Technically, this can match incorrect flags like "gmm".
        var result = pattern.match(/\/([gim]*)$/);
        if (result === null) {
            flags = result[0];
        }
        else {
            flags = "";
        }
    
        // Remove the flags and slash delimiters from the regular expression.
        pattern = pattern.replace(/(^\/|\/[gim]*$)/g, "");
        pattern = pre + pattern + post;
    
        return new RegExp(pattern, flags);
    },

    // Sets the image for a button passed to the WMD editor.
    // Returns a new element with the image attached.
    // Adds several style properties to the image.
    //
    // XXX-ANAND: Is this used anywhere?
    createImage: function(img){
    
        var imgPath = imageDirectory + img;
    
        var elem = doc.createElement("img");
        elem.className = "wmd-button";
        elem.src = imgPath;

        return elem;
    },

    // This simulates a modal dialog box and asks for the URL when you
    // click the hyperlink or image buttons.
    //
    // text: The html for the input box.
    // defaultInputText: The default value that appears in the input box.
    // makeLinkMarkdown: The function which is executed when the prompt is dismissed, either via OK or Cancel
    prompt: function(text, defaultInputText, makeLinkMarkdown){

        // These variables need to be declared at this level since they are used
        // in multiple functions.
        var dialog;            // The dialog box.
        var background;        // The background beind the dialog box.
        var input;            // The text box where you enter the hyperlink.
    

        if (defaultInputText === undefined) {
            defaultInputText = "";
        }
    
        // Used as a keydown event handler. Esc dismisses the prompt.
        // Key code 27 is ESC.
        var checkEscape = function(key){
            var code = (key.charCode || key.keyCode);
            if (code === 27) {
                close(true);
            }
        };
    
        // Dismisses the hyperlink input box.
        // isCancel is true if we don't care about the input text.
        // isCancel is false if we are going to keep the text.
        var close = function(isCancel){
            util.removeEvent(doc.body, "keydown", checkEscape);
            var text = input.value;

            if (isCancel){
                text = null;
            }
            else{
                // Fixes common pasting errors.
                text = text.replace('http://http://', 'http://');
                text = text.replace('http://https://', 'https://');
                text = text.replace('http://ftp://', 'ftp://');
                
                if (text.indexOf('http://') === -1 && text.indexOf('ftp://') === -1 && text.indexOf('https://') === -1) {
                    text = 'http://' + text;
                }
            }
            
            dialog.parentNode.removeChild(dialog);
            background.parentNode.removeChild(background);
            makeLinkMarkdown(text);
            return false;
        };
    
        // Creates the background behind the hyperlink text entry box.
        // Most of this has been moved to CSS but the div creation and
        // browser-specific hacks remain here.
        var createBackground = function(){
            background = doc.createElement("div");
            background.className = "wmd-prompt-background";
            style = background.style;
            style.position = "absolute";
            style.top = "0";
            
            style.zIndex = "1000";
            
            // Some versions of Konqueror don't support transparent colors
            // so we make the whole window transparent.
            //
            // Is this necessary on modern konqueror browsers?
            if (browser.isKonqueror){
                style.backgroundColor = "transparent";
            }
            else if (browser.isIE){
                style.filter = "alpha(opacity=50)";
            }
            else {
                style.opacity = "0.5";
            }
            
            var pageSize = position.getPageSize();
            style.height = pageSize[1] + "px";
            
            if(browser.isIE){
                style.left = doc.documentElement.scrollLeft;
                style.width = doc.documentElement.clientWidth;
            }
            else {
                style.left = "0";
                style.width = "100%";
            }
            
            doc.body.appendChild(background);
        };
    
        // Create the text input box form/window.
        var createDialog = function(){
    
            // The main dialog box.
            dialog = doc.createElement("div");
            dialog.className = "wmd-prompt-dialog";
            dialog.style.padding = "10px;";
            dialog.style.position = "fixed";
            dialog.style.width = "400px";
            dialog.style.zIndex = "1001";
            
            // The dialog text.
            var question = doc.createElement("div");
            question.innerHTML = text;
            question.style.padding = "5px";
            dialog.appendChild(question);
            
            // The web form container for the text box and buttons.
            var form = doc.createElement("form");
            form.onsubmit = function(){ return close(false); };
            style = form.style;
            style.padding = "0";
            style.margin = "0";
            style.cssFloat = "left";
            style.width = "100%";
            style.textAlign = "center";
            style.position = "relative";
            dialog.appendChild(form);
            
            // The input text box
            input = doc.createElement("input");
            input.type = "text";
            input.value = defaultInputText;
            style = input.style;
            style.display = "block";
            style.width = "80%";
            style.marginLeft = style.marginRight = "auto";
            form.appendChild(input);
            
            // The ok button
            var okButton = doc.createElement("input");
            okButton.type = "button";
            okButton.onclick = function(){ return close(false); };
            okButton.value = "OK";
            style = okButton.style;
            style.margin = "10px";
            style.display = "inline";
            style.width = "7em";

            
            // The cancel button
            var cancelButton = doc.createElement("input");
            cancelButton.type = "button";
            cancelButton.onclick = function(){ return close(true); };
            cancelButton.value = "Cancel";
            style = cancelButton.style;
            style.margin = "10px";
            style.display = "inline";
            style.width = "7em";

            // The order of these buttons is different on macs.
            if (/mac/.test(nav.platform.toLowerCase())) {
                form.appendChild(cancelButton);
                form.appendChild(okButton);
            }
            else {
                form.appendChild(okButton);
                form.appendChild(cancelButton);
            }

            util.addEvent(doc.body, "keydown", checkEscape);
            dialog.style.top = "50%";
            dialog.style.left = "50%";
            dialog.style.display = "block";
            if(browser.isIE_5or6){
                dialog.style.position = "absolute";
                dialog.style.top = doc.documentElement.scrollTop + 200 + "px";
                dialog.style.left = "50%";
            }
            doc.body.appendChild(dialog);
            
            // This has to be done AFTER adding the dialog to the form if you
            // want it to be centered.
            dialog.style.marginTop = -(position.getHeight(dialog) / 2) + "px";
            dialog.style.marginLeft = -(position.getWidth(dialog) / 2) + "px";
        };
    
        createBackground();
    
        // Why is this in a zero-length timeout?
        // Is it working around a browser bug?
        top.setTimeout(function(){
            createDialog();

            var defTextLen = defaultInputText.length;
            if (input.selectionStart !== undefined) {
                input.selectionStart = 0;
                input.selectionEnd = defTextLen;
            }
            else if (input.createTextRange) {
                var range = input.createTextRange();
                range.collapse(false);
                range.moveStart("character", -defTextLen);
                range.moveEnd("character", defTextLen);
                range.select();
            }
            input.focus();
        }, 0);
    },
    
    extend: function() {
        function _update(a, b) {
            for (var k in b) {
                a[k] = b[k];
            }
            return a;
        }
        
        var d = {};
        for (var i=0; i < arguments.length; i++) {
            _update(d, arguments[i]);
        }
        return d;
    }
}; // }}}

var position = { // {{{ 

    // UNFINISHED
    // The assignment in the while loop makes jslint cranky.
    // I'll change it to a better loop later.
    getTop: function(elem, isInner){
        var result = elem.offsetTop;
        if (!isInner) {
            while (elem = elem.offsetParent) {
                result += elem.offsetTop;
            }
        }
        return result;
    },

    getHeight: function (elem) {
        return elem.offsetHeight || elem.scrollHeight;
    },

    getWidth: function (elem) {
        return elem.offsetWidth || elem.scrollWidth;
    },

    getPageSize: function() {
        var scrollWidth, scrollHeight;
        var innerWidth, innerHeight;
        
        // It's not very clear which blocks work with which browsers.
        if(self.innerHeight && self.scrollMaxY){
            scrollWidth = doc.body.scrollWidth;
            scrollHeight = self.innerHeight + self.scrollMaxY;
        }
        else if(doc.body.scrollHeight > doc.body.offsetHeight){
            scrollWidth = doc.body.scrollWidth;
            scrollHeight = doc.body.scrollHeight;
        }
        else{
            scrollWidth = doc.body.offsetWidth;
            scrollHeight = doc.body.offsetHeight;
        }
        
        if(self.innerHeight){
            // Non-IE browser
            innerWidth = self.innerWidth;
            innerHeight = self.innerHeight;
        }
        else if(doc.documentElement && doc.documentElement.clientHeight){
            // Some versions of IE (IE 6 w/ a DOCTYPE declaration)
            innerWidth = doc.documentElement.clientWidth;
            innerHeight = doc.documentElement.clientHeight;
        }
        else if(doc.body){
            // Other versions of IE
            innerWidth = doc.body.clientWidth;
            innerHeight = doc.body.clientHeight;
        }
            
        var maxWidth = Math.max(scrollWidth, innerWidth);
        var maxHeight = Math.max(scrollHeight, innerHeight);
        return [maxWidth, maxHeight, innerWidth, innerHeight];
    }
}; // }}}

// The input textarea state/contents.
// This is used to implement undo/redo by the undo manager.
var TextareaState = function(textarea){ // {{{
    // Aliases
    var stateObj = this;
    var inputArea = textarea;
    
    this.init = function() {
    
        if (!util.isVisible(inputArea)) {
            return;
        }
            
        this.setInputAreaSelectionStartEnd();
        this.scrollTop = inputArea.scrollTop;
        if (!this.text && inputArea.selectionStart || inputArea.selectionStart === 0) {
            this.text = inputArea.value;
        }
        
    }
    
    // Sets the selected text in the input box after we've performed an
    // operation.
    this.setInputAreaSelection = function(){
    
        if (!util.isVisible(inputArea)) {
            return;
        }
        
        if (inputArea.selectionStart !== undefined && !browser.isOpera) {
        
            inputArea.focus();
            inputArea.selectionStart = stateObj.start;
            inputArea.selectionEnd = stateObj.end;
            inputArea.scrollTop = stateObj.scrollTop;
        }
        else if (doc.selection) {
            
            if (doc.activeElement && doc.activeElement !== inputArea) {
                return;
            }
                
            inputArea.focus();
            var range = inputArea.createTextRange();
            range.moveStart("character", -inputArea.value.length);
            range.moveEnd("character", -inputArea.value.length);
            range.moveEnd("character", stateObj.end);
            range.moveStart("character", stateObj.start);
            range.select();
        }
    };
    
    this.setInputAreaSelectionStartEnd = function(){
    
        if (inputArea.selectionStart || inputArea.selectionStart === 0) {
        
            stateObj.start = inputArea.selectionStart;
            stateObj.end = inputArea.selectionEnd;
        }
        else if (doc.selection) {
            
            stateObj.text = util.fixEolChars(inputArea.value);
            
            // IE loses the selection in the textarea when buttons are
            // clicked.  On IE we cache the selection and set a flag
            // which we check for here.
            var range;
            if(wmd.ieRetardedClick && wmd.ieCachedRange) {
                range = wmd.ieCachedRange;
                wmd.ieRetardedClick = false;
            }
            else {
                range = doc.selection.createRange();
            }

            var fixedRange = util.fixEolChars(range.text);
            var marker = "\x07";
            var markedRange = marker + fixedRange + marker;
            range.text = markedRange;
            var inputText = util.fixEolChars(inputArea.value);
                
            range.moveStart("character", -markedRange.length);
            range.text = fixedRange;

            stateObj.start = inputText.indexOf(marker);
            stateObj.end = inputText.lastIndexOf(marker) - marker.length;
                
            var len = stateObj.text.length - util.fixEolChars(inputArea.value).length;
                
            if (len) {
                range.moveStart("character", -fixedRange.length);
                while (len--) {
                    fixedRange += "\n";
                    stateObj.end += 1;
                }
                range.text = fixedRange;
            }
                
            this.setInputAreaSelection();
        }
    };
    
    // Restore this state into the input area.
    this.restore = function(){
    
        if (stateObj.text != undefined && stateObj.text != inputArea.value) {
            inputArea.value = stateObj.text;
        }
        this.setInputAreaSelection();
        inputArea.scrollTop = stateObj.scrollTop;
    };
    
    // Gets a collection of HTML chunks from the inptut textarea.
    this.getChunks = function(){
    
        var chunk = new Chunks();
        
        chunk.before = util.fixEolChars(stateObj.text.substring(0, stateObj.start));
        chunk.startTag = "";
        chunk.selection = util.fixEolChars(stateObj.text.substring(stateObj.start, stateObj.end));
        chunk.endTag = "";
        chunk.after = util.fixEolChars(stateObj.text.substring(stateObj.end));
        chunk.scrollTop = stateObj.scrollTop;
        
        return chunk;
    };
    
    // Sets the TextareaState properties given a chunk of markdown.
    this.setChunks = function(chunk){
    
        chunk.before = chunk.before + chunk.startTag;
        chunk.after = chunk.endTag + chunk.after;
        
        if (browser.isOpera) {
            chunk.before = chunk.before.replace(/\n/g, "\r\n");
            chunk.selection = chunk.selection.replace(/\n/g, "\r\n");
            chunk.after = chunk.after.replace(/\n/g, "\r\n");
        }
        
        this.start = chunk.before.length;
        this.end = chunk.before.length + chunk.selection.length;
        this.text = chunk.before + chunk.selection + chunk.after;
        this.scrollTop = chunk.scrollTop;
    };

    this.init();
}; // }}}

// Chunks {{{

// before: contains all the text in the input box BEFORE the selection.
// after: contains all the text in the input box AFTER the selection.
var Chunks = function(){
};

// startRegex: a regular expression to find the start tag
// endRegex: a regular expresssion to find the end tag
Chunks.prototype.findTags = function(startRegex, endRegex){

    var chunkObj = this;
    var regex;
    
    if (startRegex) {
        
        regex = util.extendRegExp(startRegex, "", "$");
        
        this.before = this.before.replace(regex, 
            function(match){
                chunkObj.startTag = chunkObj.startTag + match;
                return "";
            });
        
        regex = util.extendRegExp(startRegex, "^", "");
        
        this.selection = this.selection.replace(regex, 
            function(match){
                chunkObj.startTag = chunkObj.startTag + match;
                return "";
            });
    }
    
    if (endRegex) {
        
        regex = util.extendRegExp(endRegex, "", "$");
        
        this.selection = this.selection.replace(regex,
            function(match){
                chunkObj.endTag = match + chunkObj.endTag;
                return "";
            });

        regex = util.extendRegExp(endRegex, "^", "");
        
        this.after = this.after.replace(regex,
            function(match){
                chunkObj.endTag = match + chunkObj.endTag;
                return "";
            });
    }
};

// If remove is false, the whitespace is transferred
// to the before/after regions.
//
// If remove is true, the whitespace disappears.
Chunks.prototype.trimWhitespace = function(remove){

    this.selection = this.selection.replace(/^(\s*)/, "");
    
    if (!remove) {
        this.before += re.$1;
    }
    
    this.selection = this.selection.replace(/(\s*)$/, "");
    
    if (!remove) {
        this.after = re.$1 + this.after;
    }
};


Chunks.prototype.addBlankLines = function(nLinesBefore, nLinesAfter, findExtraNewlines){

    if (nLinesBefore === undefined) {
        nLinesBefore = 1;
    }
    
    if (nLinesAfter === undefined) {
        nLinesAfter = 1;
    }
    
    nLinesBefore++;
    nLinesAfter++;
    
    var regexText;
    var replacementText;
    
    this.selection = this.selection.replace(/(^\n*)/, "");
    this.startTag = this.startTag + re.$1;
    this.selection = this.selection.replace(/(\n*$)/, "");
    this.endTag = this.endTag + re.$1;
    this.startTag = this.startTag.replace(/(^\n*)/, "");
    this.before = this.before + re.$1;
    this.endTag = this.endTag.replace(/(\n*$)/, "");
    this.after = this.after + re.$1;
    
    if (this.before) {
    
        regexText = replacementText = "";
        
        while (nLinesBefore--) {
            regexText += "\\n?";
            replacementText += "\n";
        }
        
        if (findExtraNewlines) {
            regexText = "\\n*";
        }
        this.before = this.before.replace(new re(regexText + "$", ""), replacementText);
    }
    
    if (this.after) {
    
        regexText = replacementText = "";
        
        while (nLinesAfter--) {
            regexText += "\\n?";
            replacementText += "\n";
        }
        if (findExtraNewlines) {
            regexText = "\\n*";
        }
        
        this.after = this.after.replace(new re(regexText, ""), replacementText);
    }
}; 
// }}} - END CHUNKS

// Watches the input textarea, polling at an interval and runs
// a callback function if anything has changed.
var InputPoller = function(textarea, callback, interval){ // {{{

    var pollerObj = this;
    var inputArea = textarea;
    
    // Stored start, end and text.  Used to see if there are changes to the input.
    var lastStart;
    var lastEnd;
    var markdown;
    
    var killHandle; // Used to cancel monitoring on destruction.
    // Checks to see if anything has changed in the textarea.
    // If so, it runs the callback.
    this.tick = function(){
    
        if (!util.isVisible(inputArea)) {
            return;
        }
        
        // Update the selection start and end, text.
        if (inputArea.selectionStart || inputArea.selectionStart === 0) {
            var start = inputArea.selectionStart;
            var end = inputArea.selectionEnd;
            if (start != lastStart || end != lastEnd) {
                lastStart = start;
                lastEnd = end;
                
                if (markdown != inputArea.value) {
                    markdown = inputArea.value;
                    return true;
                }
            }
        }
        return false;
    };
    
    
    var doTickCallback = function(){
    
        if (!util.isVisible(inputArea)) {
            return;
        }
        
        // If anything has changed, call the function.
        if (pollerObj.tick()) {
            callback();
        }
    };
    
    // Set how often we poll the textarea for changes.
    var assignInterval = function(){
        killHandle = top.setInterval(doTickCallback, interval);
    };
    
    this.destroy = function(){
        top.clearInterval(killHandle);
    };
    
    assignInterval();
}; // }}}
    
var PreviewManager = function(wmd){ // {{{
    var managerObj = this;
    var converter;
    var poller;
    var timeout;
    var elapsedTime;
    var oldInputText;
    var htmlOut;
    var maxDelay = 3000;
    var startType = "delayed"; // The other legal value is "manual"
    
    // Adds event listeners to elements and creates the input poller.
    var setupEvents = function(inputElem, listener){
    
        util.addEvent(inputElem, "input", listener);
        inputElem.onpaste = listener;
        inputElem.ondrop = listener;
        
        util.addEvent(inputElem, "keypress", listener);
        util.addEvent(inputElem, "keydown", listener);
        // previewPollInterval is set at the top of this file.
        poller = new InputPoller(wmd.panels.input, listener, wmd.options.previewPollInterval);
    };
    
    var getDocScrollTop = function(){
    
        var result = 0;
        
        if (top.innerHeight) {
            result = top.pageYOffset;
        }
        else 
            if (doc.documentElement && doc.documentElement.scrollTop) {
                result = doc.documentElement.scrollTop;
            }
            else 
                if (doc.body) {
                    result = doc.body.scrollTop;
                }
        
        return result;
    };
    
    var makePreviewHtml = function(){
    
        // If there are no registered preview and output panels
        // there is nothing to do.
        if (!wmd.panels.preview && !wmd.panels.output) {
            return;
        }
        
        var text = wmd.panels.input.value;
        if (text && text == oldInputText) {
            return; // Input text hasn't changed.
        }
        else {
            oldInputText = text;
        }
        
        var prevTime = new Date().getTime();
        
        if (!converter && wmd.showdown) {
            converter = new wmd.showdown.converter();
        }
        
        if (converter) {
            text = converter.makeHtml(text);
        }
        
        // Calculate the processing time of the HTML creation.
        // It's used as the delay time in the event listener.
        var currTime = new Date().getTime();
        elapsedTime = currTime - prevTime;
        
        pushPreviewHtml(text);
        htmlOut = text;
    };
    
    // setTimeout is already used.  Used as an event listener.
    var applyTimeout = function(){
    
        if (timeout) {
            top.clearTimeout(timeout);
            timeout = undefined;
        }
        
        if (startType !== "manual") {
        
            var delay = 0;
            
            if (startType === "delayed") {
                delay = elapsedTime;
            }
            
            if (delay > maxDelay) {
                delay = maxDelay;
            }
            timeout = top.setTimeout(makePreviewHtml, delay);
        }
    };
    
    var getScaleFactor = function(panel){
        if (panel.scrollHeight <= panel.clientHeight) {
            return 1;
        }
        return panel.scrollTop / (panel.scrollHeight - panel.clientHeight);
    };
    
    var setPanelScrollTops = function(){
    
        if (wmd.panels.preview) {
            wmd.panels.preview.scrollTop = (wmd.panels.preview.scrollHeight - wmd.panels.preview.clientHeight) * getScaleFactor(wmd.panels.preview);
            ;
        }
        
        if (wmd.panels.output) {
            wmd.panels.output.scrollTop = (wmd.panels.output.scrollHeight - wmd.panels.output.clientHeight) * getScaleFactor(wmd.panels.output);
            ;
        }
    };
    
    this.refresh = function(requiresRefresh){
    
        if (requiresRefresh) {
            oldInputText = "";
            makePreviewHtml();
        }
        else {
            applyTimeout();
        }
    };
    
    this.processingTime = function(){
        return elapsedTime;
    };
    
    // The output HTML
    this.output = function(){
        return htmlOut;
    };
    
    // The mode can be "manual" or "delayed"
    this.setUpdateMode = function(mode){
        startType = mode;
        managerObj.refresh();
    };
    
    var isFirstTimeFilled = true;
    
    var pushPreviewHtml = function(text){
    
        var emptyTop = position.getTop(wmd.panels.input) - getDocScrollTop();
        
        // Send the encoded HTML to the output textarea/div.
        if (wmd.panels.output) {
            // The value property is only defined if the output is a textarea.
            if (wmd.panels.output.value !== undefined) {
                wmd.panels.output.value = text;
                wmd.panels.output.readOnly = true;
            }
            // Otherwise we are just replacing the text in a div.
            // Send the HTML wrapped in <pre><code>
            else {
                var newText = text.replace(/&/g, "&amp;");
                newText = newText.replace(/</g, "&lt;");
                wmd.panels.output.innerHTML = "<pre><code>" + newText + "</code></pre>";
            }
        }
        
        if (wmd.panels.preview) {
            wmd.panels.preview.innerHTML = text;
        }
        
        setPanelScrollTops();
        
        if (isFirstTimeFilled) {
            isFirstTimeFilled = false;
            return;
        }
        
        var fullTop = position.getTop(wmd.panels.input) - getDocScrollTop();
        
        if (browser.isIE) {
            top.setTimeout(function(){
                top.scrollBy(0, fullTop - emptyTop);
            }, 0);
        }
        else {
            top.scrollBy(0, fullTop - emptyTop);
        }
    };
    
    var init = function(){
    
        setupEvents(wmd.panels.input, applyTimeout);
        makePreviewHtml();
        
        if (wmd.panels.preview) {
            wmd.panels.preview.scrollTop = 0;
        }
        if (wmd.panels.output) {
            wmd.panels.output.scrollTop = 0;
        }
    };
    
    this.destroy = function(){
        if (poller) {
            poller.destroy();
        }
    };
    
    init();
}; // }}}

// Handles pushing and popping TextareaStates for undo/redo commands.
// I should rename the stack variables to list.
var UndoManager = function(textarea, pastePollInterval, callback){ // {{{

    var undoObj = this;
    var undoStack = []; // A stack of undo states
    var stackPtr = 0; // The index of the current state
    var mode = "none";
    var lastState; // The last state
    var poller;
    var timer; // The setTimeout handle for cancelling the timer
    var inputStateObj;
    
    // Set the mode for later logic steps.
    var setMode = function(newMode, noSave){
    
        if (mode != newMode) {
            mode = newMode;
            if (!noSave) {
                saveState();
            }
        }
        
        if (!browser.isIE || mode != "moving") {
            timer = top.setTimeout(refreshState, 1);
        }
        else {
            inputStateObj = null;
        }
    };
    
    var refreshState = function(){
        inputStateObj = new TextareaState(textarea);
        poller.tick();
        timer = undefined;
    };
    
    this.setCommandMode = function(){
        mode = "command";
        saveState();
        timer = top.setTimeout(refreshState, 0);
    };
    
    this.canUndo = function(){
        return stackPtr > 1;
    };
    
    this.canRedo = function(){
        if (undoStack[stackPtr + 1]) {
            return true;
        }
        return false;
    };
    
    // Removes the last state and restores it.
    this.undo = function(){
    
        if (undoObj.canUndo()) {
            if (lastState) {
                // What about setting state -1 to null or checking for undefined?
                lastState.restore();
                lastState = null;
            }
            else {
                undoStack[stackPtr] = new TextareaState(textarea);
                undoStack[--stackPtr].restore();
                
                if (callback) {
                    callback();
                }
            }
        }
        
        mode = "none";
        textarea.focus();
        refreshState();
    };
    
    // Redo an action.
    this.redo = function(){
    
        if (undoObj.canRedo()) {
        
            undoStack[++stackPtr].restore();
            
            if (callback) {
                callback();
            }
        }
        
        mode = "none";
        textarea.focus();
        refreshState();
    };
    
    // Push the input area state to the stack.
    var saveState = function(){
    
        var currState = inputStateObj || new TextareaState(textarea);
        
        if (!currState) {
            return false;
        }
        if (mode == "moving") {
            if (!lastState) {
                lastState = currState;
            }
            return;
        }
        if (lastState) {
            if (undoStack[stackPtr - 1].text != lastState.text) {
                undoStack[stackPtr++] = lastState;
            }
            lastState = null;
        }
        undoStack[stackPtr++] = currState;
        undoStack[stackPtr + 1] = null;
        if (callback) {
            callback();
        }
    };
    
    var handleCtrlYZ = function(event){
    
        var handled = false;
        
        if (event.ctrlKey || event.metaKey) {
        
            // IE and Opera do not support charCode.
            var keyCode = event.charCode || event.keyCode;
            var keyCodeChar = String.fromCharCode(keyCode);
            
            switch (keyCodeChar) {
            
                case "y":
                    undoObj.redo();
                    handled = true;
                    break;
                    
                case "z":
                    if (!event.shiftKey) {
                        undoObj.undo();
                    }
                    else {
                        undoObj.redo();
                    }
                    handled = true;
                    break;
            }
        }
        
        if (handled) {
            if (event.preventDefault) {
                event.preventDefault();
            }
            if (top.event) {
                top.event.returnValue = false;
            }
            return;
        }
    };
    
    // Set the mode depending on what is going on in the input area.
    var handleModeChange = function(event){
    
        if (!event.ctrlKey && !event.metaKey) {
        
            var keyCode = event.keyCode;
            
            if ((keyCode >= 33 && keyCode <= 40) || (keyCode >= 63232 && keyCode <= 63235)) {
                // 33 - 40: page up/dn and arrow keys
                // 63232 - 63235: page up/dn and arrow keys on safari
                setMode("moving");
            }
            else if (keyCode == 8 || keyCode == 46 || keyCode == 127) {
                // 8: backspace
                // 46: delete
                // 127: delete
                setMode("deleting");
            }
            else if (keyCode == 13) {
                // 13: Enter
                setMode("newlines");
            }
            else if (keyCode == 27) {
                // 27: escape
                setMode("escape");
            }
            else if ((keyCode < 16 || keyCode > 20) && keyCode != 91) {
                // 16-20 are shift, etc. 
                // 91: left window key
                // I think this might be a little messed up since there are
                // a lot of nonprinting keys above 20.
                setMode("typing");
            }
        }
    };
    
    var setEventHandlers = function(){
    
        util.addEvent(textarea, "keypress", function(event){
            // keyCode 89: y
            // keyCode 90: z
            if ((event.ctrlKey || event.metaKey) && (event.keyCode == 89 || event.keyCode == 90)) {
                event.preventDefault();
            }
        });
        
        var handlePaste = function(){
            if (browser.isIE || (inputStateObj && inputStateObj.text != textarea.value)) {
                if (timer == undefined) {
                    mode = "paste";
                    saveState();
                    refreshState();
                }
            }
        };
        
        poller = new InputPoller(textarea, handlePaste, pastePollInterval);
        
        util.addEvent(textarea, "keydown", handleCtrlYZ);
        util.addEvent(textarea, "keydown", handleModeChange);
        
        util.addEvent(textarea, "mousedown", function(){
            setMode("moving");
        });
        textarea.onpaste = handlePaste;
        textarea.ondrop = handlePaste;
    };
    
    var init = function(){
        setEventHandlers();
        refreshState();
        saveState();
    };
    
    this.destroy = function(){
        if (poller) {
            poller.destroy();
        }
    };
    
    init();
}; //}}}

WMDEditor.util = util;
WMDEditor.position = position;
WMDEditor.TextareaState = TextareaState;
// WMDEditor.Checks = Checks;
WMDEditor.InputPoller = InputPoller;
WMDEditor.PreviewManager = PreviewManager;
WMDEditor.UndoManager = UndoManager;

// A few handy aliases for readability.
var doc  = top.document;
var re   = top.RegExp;
var nav  = top.navigator;
    
function get_browser() {
    var b = {};
    b.isIE         = /msie/.test(nav.userAgent.toLowerCase());
    b.isIE_5or6     = /msie 6/.test(nav.userAgent.toLowerCase()) || /msie 5/.test(nav.userAgent.toLowerCase());
    b.isIE_7plus     = b.isIE && !b.isIE_5or6;
    b.isOpera         = /opera/.test(nav.userAgent.toLowerCase());
    b.isKonqueror     = /konqueror/.test(nav.userAgent.toLowerCase());
    return b;
}

// Used to work around some browser bugs where we can't use feature testing.
var browser = get_browser();

var wmdBase = function(wmd, wmd_options){ // {{{

    // Some namespaces.
    //wmd.Util = {};
    //wmd.Position = {};
    wmd.Command = {};
    wmd.Global = {};
    wmd.buttons = {};
    
    wmd.showdown = top.Attacklab && top.Attacklab.showdown;
    
    var util = WMDEditor.util;
    var position = WMDEditor.position;
    var command = wmd.Command;
    
    // Internet explorer has problems with CSS sprite buttons that use HTML
    // lists.  When you click on the background image "button", IE will 
    // select the non-existent link text and discard the selection in the
    // textarea.  The solution to this is to cache the textarea selection
    // on the button's mousedown event and set a flag.  In the part of the
    // code where we need to grab the selection, we check for the flag
    // and, if it's set, use the cached area instead of querying the
    // textarea.
    //
    // This ONLY affects Internet Explorer (tested on versions 6, 7
    // and 8) and ONLY on button clicks.  Keyboard shortcuts work
    // normally since the focus never leaves the textarea.
    wmd.ieCachedRange = null;        // cached textarea selection
    wmd.ieRetardedClick = false;    // flag
    
    // I think my understanding of how the buttons and callbacks are stored in the array is incomplete.
    wmd.editor = function(previewRefreshCallback){ // {{{
    
        if (!previewRefreshCallback) {
            previewRefreshCallback = function(){};
        }
        
        var inputBox = wmd.panels.input;
        
        var offsetHeight = 0;
        
        var editObj = this;
        
        var mainDiv;
        var mainSpan;
        
        var div; // This name is pretty ambiguous.  I should rename this.
        
        // Used to cancel recurring events from setInterval.
        var creationHandle;
        
        var undoMgr; // The undo manager
        
        // Perform the button's action.
        var doClick = function(button){
        
            inputBox.focus();
            
            if (button.textOp) {
                
                if (undoMgr) {
                    undoMgr.setCommandMode();
                }
                
                var state = new TextareaState(wmd.panels.input);
                
                if (!state) {
                    return;
                }
                
                var chunks = state.getChunks();
                
                // Some commands launch a "modal" prompt dialog.  Javascript
                // can't really make a modal dialog box and the WMD code
                // will continue to execute while the dialog is displayed.
                // This prevents the dialog pattern I'm used to and means
                // I can't do something like this:
                //
                // var link = CreateLinkDialog();
                // makeMarkdownLink(link);
                // 
                // Instead of this straightforward method of handling a
                // dialog I have to pass any code which would execute
                // after the dialog is dismissed (e.g. link creation)
                // in a function parameter.
                //
                // Yes this is awkward and I think it sucks, but there's
                // no real workaround.  Only the image and link code
                // create dialogs and require the function pointers.
                var fixupInputArea = function(){
                
                    inputBox.focus();
                    
                    if (chunks) {
                        state.setChunks(chunks);
                    }
                    
                    state.restore();
                    previewRefreshCallback();
                };
                
                var useDefaultText = true;
                var noCleanup = button.textOp(chunks, fixupInputArea, useDefaultText);
                
                if(!noCleanup) {
                    fixupInputArea();
                }
                
            }
            
            if (button.execute) {
                button.execute(editObj);
            }
        };
            
        var setUndoRedoButtonStates = function(){
            if(undoMgr){
                setupButton(wmd.buttons["wmd-undo-button"], undoMgr.canUndo());
                setupButton(wmd.buttons["wmd-redo-button"], undoMgr.canRedo());
            }
        };
        
        var setupButton = function(button, isEnabled) {
        
            var normalYShift = "0px";
            var disabledYShift = "-20px";
            var highlightYShift = "-40px";
            
            if(isEnabled) {
                button.style.backgroundPosition = button.XShift + " " + normalYShift;
                button.onmouseover = function(){
                    this.style.backgroundPosition = this.XShift + " " + highlightYShift;
                };
                            
                button.onmouseout = function(){
                    this.style.backgroundPosition = this.XShift + " " + normalYShift;
                };
                
                // IE tries to select the background image "button" text (it's
                // implemented in a list item) so we have to cache the selection
                // on mousedown.
                if(browser.isIE) {
                    button.onmousedown =  function() { 
                        wmd.ieRetardedClick = true;
                        wmd.ieCachedRange = document.selection.createRange(); 
                    };
                }
                
                if (!button.isHelp)
                {
                    button.onclick = function() {
                        if (this.onmouseout) {
                            this.onmouseout();
                        }
                        doClick(this);
                        return false;
                    }
                }
            }
            else {
                button.style.backgroundPosition = button.XShift + " " + disabledYShift;
                button.onmouseover = button.onmouseout = button.onclick = function(){};
            }
        }
    
        var makeSpritedButtonRow = function(){
             
            var buttonBar = document.getElementById(wmd_options.button_bar || "wmd-button-bar");
     
            var normalYShift = "0px";
            var disabledYShift = "-20px";
            var highlightYShift = "-40px";
            
            var buttonRow = document.createElement("ul");
            buttonRow.className = "wmd-button-row"
            buttonRow = buttonBar.appendChild(buttonRow);
            
            var xoffset = 0;
            
            function createButton(name, title, textOp) {
                var button = document.createElement("li");
                wmd.buttons[name] = button;
                button.className = "wmd-button " + name;
                            button.XShift = xoffset + "px";
                            xoffset -= 20;
                
                if (title)
                    button.title = title;
                    
                if (textOp)
                    button.textOp = textOp;

                return button;
            }
            
            function addButton(name, title, textOp) {
                var button = createButton(name, title, textOp);

                setupButton(button, true);
                buttonRow.appendChild(button);
                return button;
            }
            
            function addSpacer() {
                var spacer = document.createElement("li");
                spacer.className = "wmd-spacer";
                buttonRow.appendChild(spacer);
                return spacer;
            }
            
            var boldButton = addButton("wmd-bold-button", "Strong <strong> Ctrl+B", command.doBold);
            var italicButton = addButton("wmd-italic-button", "Emphasis <em> Ctrl+I", command.doItalic);
            var spacer1 = addSpacer();
            
            var linkButton = addButton("wmd-link-button", "Hyperlink <a> Ctrl+L", function(chunk, postProcessing, useDefaultText) {
                return command.doLinkOrImage(chunk, postProcessing, false);
            });        
            var quoteButton = addButton("wmd-quote-button", "Blockquote <blockquote> Ctrl+Q", command.doBlockquote);
            var codeButton = addButton("wmd-code-button", "Code Sample <pre><code> Ctrl+K", command.doCode);
            var imageButton = addButton("wmd-image-button", "Image <img> Ctrl+G", function(chunk, postProcessing, useDefaultText) {
                return command.doLinkOrImage(chunk, postProcessing, true);
            });
            
            var spacer2 = addSpacer();

            var olistButton = addButton("wmd-olist-button", "Numbered List <ol> Ctrl+O", function(chunk, postProcessing, useDefaultText) {
                command.doList(chunk, postProcessing, true, useDefaultText);
            });
            var ulistButton = addButton("wmd-ulist-button", "Bulleted List <ul> Ctrl+U", function(chunk, postProcessing, useDefaultText) {
                command.doList(chunk, postProcessing, false, useDefaultText);
            });
            var headingButton = addButton("wmd-heading-button", "Heading <h1>/<h2> Ctrl+H", command.doHeading);
            var hrButton = addButton("wmd-hr-button", "Horizontal Rule <hr> Ctrl+R", command.doHorizontalRule);
            var spacer3 = addSpacer();
            
            var undoButton = addButton("wmd-undo-button", "Undo - Ctrl+Z");
            undoButton.execute = function(manager){
                manager.undo();
            };
            
            var redo_title = null;
            
            var redoButton = addButton("wmd-redo-button", "Redo - Ctrl+Y");
            if (/win/.test(nav.platform.toLowerCase())) {
                redoButton.title = "Redo - Ctrl+Y";
            }
            else {
                // mac and other non-Windows platforms
                redoButton.title = "Redo - Ctrl+Shift+Z";
            }
            redoButton.execute = function(manager){
                manager.redo();
            };
            
            var helpButton = createButton("wmd-help-button");
            helpButton.isHelp = true;
            setupButton(helpButton, true);
            buttonRow.appendChild(helpButton);
            
            var helpAnchor = document.createElement("a");
            helpAnchor.href = wmd_options.helpLink;
            helpAnchor.target = wmd_options.helpTarget
            helpAnchor.title = wmd_options.helpHoverTitle;
            helpButton.appendChild(helpAnchor);
                        
            setUndoRedoButtonStates();
        }
        
        var setupEditor = function(){
        
            if (/\?noundo/.test(doc.location.href)) {
                wmd.nativeUndo = true;
            }
            
            if (!wmd.nativeUndo) {
                undoMgr = new UndoManager(wmd.panels.input, wmd.options.pastePollInterval, function(){
                    previewRefreshCallback();
                    setUndoRedoButtonStates();
                });
            }
            
            makeSpritedButtonRow();
            
            
            var keyEvent = "keydown";
            if (browser.isOpera) {
                keyEvent = "keypress";
            }
            
            util.addEvent(inputBox, keyEvent, function(key){
                
                // Check to see if we have a button key and, if so execute the callback.
                if (key.ctrlKey || key.metaKey) {
            
                    var keyCode = key.charCode || key.keyCode;
                    var keyCodeStr = String.fromCharCode(keyCode).toLowerCase();
                    
                    switch(keyCodeStr) {
                        case "b":
                            doClick(wmd.buttons["wmd-bold-button"]);
                            break;
                        case "i":
                            doClick(wmd.buttons["wmd-italic-button"]);
                            break;
                        case "l":
                            doClick(wmd.buttons["wmd-link-button"]);
                            break;
                        case "q":
                            doClick(wmd.buttons["wmd-quote-button"]);
                            break;
                        case "k":
                            doClick(wmd.buttons["wmd-code-button"]);
                            break;
                        case "g":
                            doClick(wmd.buttons["wmd-image-button"]);
                            break;
                        case "o":
                            doClick(wmd.buttons["wmd-olist-button"]);
                            break;
                        case "u":
                            doClick(wmd.buttons["wmd-ulist-button"]);
                            break;
                        case "h":
                            doClick(wmd.buttons["wmd-heading-button"]);
                            break;
                        case "r":
                            doClick(wmd.buttons["wmd-hr-button"]);
                            break;
                        case "y":
                            doClick(wmd.buttons["wmd-redo-button"]);
                            break;
                        case "z":
                            if(key.shiftKey) {
                                doClick(wmd.buttons["wmd-redo-button"]);
                            }
                            else {
                                doClick(wmd.buttons["wmd-undo-button"]);
                            }
                            break;
                        default:
                            return;
                    }
                    

                    if (key.preventDefault) {
                        key.preventDefault();
                    }
                    
                    if (top.event) {
                        top.event.returnValue = false;
                    }
                }
            });
            
            // Auto-continue lists, code blocks and block quotes when
            // the enter key is pressed.
            util.addEvent(inputBox, "keyup", function(key){
                if (!key.shiftKey && !key.ctrlKey && !key.metaKey) {
                    var keyCode = key.charCode || key.keyCode;
                    // Key code 13 is Enter
                    if (keyCode === 13) {
                        fakeButton = {};
                        fakeButton.textOp = command.doAutoindent;
                        doClick(fakeButton);
                    }
                }
            });
            
            // Disable ESC clearing the input textarea on IE
            if (browser.isIE) {
                util.addEvent(inputBox, "keydown", function(key){
                    var code = key.keyCode;
                    // Key code 27 is ESC
                    if (code === 27) {
                        return false;
                    }
                });
            }
            
            if (inputBox.form) {
                var submitCallback = inputBox.form.onsubmit;
                inputBox.form.onsubmit = function(){
                    convertToHtml();
                    if (submitCallback) {
                        return submitCallback.apply(this, arguments);
                    }
                };
            }
        };
        
        // Convert the contents of the input textarea to HTML in the output/preview panels.
        var convertToHtml = function(){
        
            if (wmd.showdown) {
                var markdownConverter = new wmd.showdown.converter();
            }
            var text = inputBox.value;
            
            var callback = function(){
                inputBox.value = text;
            };
            
            if (!/markdown/.test(wmd_options.output_format.toLowerCase())) {
                if (markdownConverter) {
                    inputBox.value = markdownConverter.makeHtml(text);
                    top.setTimeout(callback, 0);
                }
            }
            return true;
        };
        
        
        this.undo = function(){
            if (undoMgr) {
                undoMgr.undo();
            }
        };
        
        this.redo = function(){
            if (undoMgr) {
                undoMgr.redo();
            }
        };
        
        // This is pretty useless.  The setupEditor function contents
        // should just be copied here.
        var init = function(){
            setupEditor();
        };
        
        this.destroy = function(){
            if (undoMgr) {
                undoMgr.destroy();
            }
            if (div.parentNode) {
                div.parentNode.removeChild(div);
            }
            if (inputBox) {
                inputBox.style.marginTop = "";
            }
            top.clearInterval(creationHandle);
        };
        
        init();
    }; // }}}

    // command {{{

    // The markdown symbols - 4 spaces = code, > = blockquote, etc.
    command.prefixes = "(?:\\s{4,}|\\s*>|\\s*-\\s+|\\s*\\d+\\.|=|\\+|-|_|\\*|#|\\s*\\[[^\n]]+\\]:)";
    
    // Remove markdown symbols from the chunk selection.
    command.unwrap = function(chunk){
        var txt = new re("([^\\n])\\n(?!(\\n|" + command.prefixes + "))", "g");
        chunk.selection = chunk.selection.replace(txt, "$1 $2");
    };
    
    command.wrap = function(chunk, len){
        command.unwrap(chunk);
        var regex = new re("(.{1," + len + "})( +|$\\n?)", "gm");
        
        chunk.selection = chunk.selection.replace(regex, function(line, marked){
            if (new re("^" + command.prefixes, "").test(line)) {
                return line;
            }
            return marked + "\n";
        });
        
        chunk.selection = chunk.selection.replace(/\s+$/, "");
    };
    
    command.doBold = function(chunk, postProcessing, useDefaultText){
        return command.doBorI(chunk, 2, "strong text");
    };
    
    command.doItalic = function(chunk, postProcessing, useDefaultText){
        return command.doBorI(chunk, 1, "emphasized text");
    };
    
    // chunk: The selected region that will be enclosed with */**
    // nStars: 1 for italics, 2 for bold
    // insertText: If you just click the button without highlighting text, this gets inserted
    command.doBorI = function(chunk, nStars, insertText){
    
        // Get rid of whitespace and fixup newlines.
        chunk.trimWhitespace();
        chunk.selection = chunk.selection.replace(/\n{2,}/g, "\n");
        
        // Look for stars before and after.  Is the chunk already marked up?
        chunk.before.search(/(\**$)/);
        var starsBefore = re.$1;
        
        chunk.after.search(/(^\**)/);
        var starsAfter = re.$1;
        
        var prevStars = Math.min(starsBefore.length, starsAfter.length);
        
        // Remove stars if we have to since the button acts as a toggle.
        if ((prevStars >= nStars) && (prevStars != 2 || nStars != 1)) {
            chunk.before = chunk.before.replace(re("[*]{" + nStars + "}$", ""), "");
            chunk.after = chunk.after.replace(re("^[*]{" + nStars + "}", ""), "");
        }
        else if (!chunk.selection && starsAfter) {
            // It's not really clear why this code is necessary.  It just moves
            // some arbitrary stuff around.
            chunk.after = chunk.after.replace(/^([*_]*)/, "");
            chunk.before = chunk.before.replace(/(\s?)$/, "");
            var whitespace = re.$1;
            chunk.before = chunk.before + starsAfter + whitespace;
        }
        else {
        
            // In most cases, if you don't have any selected text and click the button
            // you'll get a selected, marked up region with the default text inserted.
            if (!chunk.selection && !starsAfter) {
                chunk.selection = insertText;
            }
            
            // Add the true markup.
            var markup = nStars <= 1 ? "*" : "**"; // shouldn't the test be = ?
            chunk.before = chunk.before + markup;
            chunk.after = markup + chunk.after;
        }
        
        return;
    };
    
    command.stripLinkDefs = function(text, defsToAdd){
    
        text = text.replace(/^[ ]{0,3}\[(\d+)\]:[ \t]*\n?[ \t]*<?(\S+?)>?[ \t]*\n?[ \t]*(?:(\n*)["(](.+?)[")][ \t]*)?(?:\n+|$)/gm, 
            function(totalMatch, id, link, newlines, title){    
                defsToAdd[id] = totalMatch.replace(/\s*$/, "");
                if (newlines) {
                    // Strip the title and return that separately.
                    defsToAdd[id] = totalMatch.replace(/["(](.+?)[")]$/, "");
                    return newlines + title;
                }
                return "";
            });
        
        return text;
    };
    
    command.addLinkDef = function(chunk, linkDef){
    
        var refNumber = 0; // The current reference number
        var defsToAdd = {}; //
        // Start with a clean slate by removing all previous link definitions.
        chunk.before = command.stripLinkDefs(chunk.before, defsToAdd);
        chunk.selection = command.stripLinkDefs(chunk.selection, defsToAdd);
        chunk.after = command.stripLinkDefs(chunk.after, defsToAdd);
        
        var defs = "";
        var regex = /(\[(?:\[[^\]]*\]|[^\[\]])*\][ ]?(?:\n[ ]*)?\[)(\d+)(\])/g;
        
        var addDefNumber = function(def){
            refNumber++;
            def = def.replace(/^[ ]{0,3}\[(\d+)\]:/, "  [" + refNumber + "]:");
            defs += "\n" + def;
        };
        
        var getLink = function(wholeMatch, link, id, end){
        
            if (defsToAdd[id]) {
                addDefNumber(defsToAdd[id]);
                return link + refNumber + end;
                
            }
            return wholeMatch;
        };
        
        chunk.before = chunk.before.replace(regex, getLink);
        
        if (linkDef) {
            addDefNumber(linkDef);
        }
        else {
            chunk.selection = chunk.selection.replace(regex, getLink);
        }
        
        var refOut = refNumber;
        
        chunk.after = chunk.after.replace(regex, getLink);
        
        if (chunk.after) {
            chunk.after = chunk.after.replace(/\n*$/, "");
        }
        if (!chunk.after) {
            chunk.selection = chunk.selection.replace(/\n*$/, "");
        }
        
        chunk.after += "\n\n" + defs;
        
        return refOut;
    };
    
    command.doLinkOrImage = function(chunk, postProcessing, isImage){
    
        chunk.trimWhitespace();
        chunk.findTags(/\s*!?\[/, /\][ ]?(?:\n[ ]*)?(\[.*?\])?/);
        
        if (chunk.endTag.length > 1) {
        
            chunk.startTag = chunk.startTag.replace(/!?\[/, "");
            chunk.endTag = "";
            command.addLinkDef(chunk, null);
            
        }
        else {
        
            if (/\n\n/.test(chunk.selection)) {
                command.addLinkDef(chunk, null);
                return;
            }
            
            // The function to be executed when you enter a link and press OK or Cancel.
            // Marks up the link and adds the ref.
            var makeLinkMarkdown = function(link){
            
                if (link !== null) {
                
                    chunk.startTag = chunk.endTag = "";
                    var linkDef = " [999]: " + link;
                    
                    var num = command.addLinkDef(chunk, linkDef);
                    chunk.startTag = isImage ? "![" : "[";
                    chunk.endTag = "][" + num + "]";
                    
                    if (!chunk.selection) {
                        if (isImage) {
                            chunk.selection = "alt text";
                        }
                        else {
                            chunk.selection = "link text";
                        }
                    }
                }
                postProcessing();
            };
            
            if (isImage) {
                util.prompt(wmd_options.imageDialogText, wmd_options.imageDefaultText, makeLinkMarkdown);
            }
            else {
                util.prompt(wmd_options.linkDialogText, wmd_options.linkDefaultText, makeLinkMarkdown);
            }
            return true;
        }
    };

    // Moves the cursor to the next line and continues lists, quotes and code.
    command.doAutoindent = function(chunk, postProcessing, useDefaultText){
        
        chunk.before = chunk.before.replace(/(\n|^)[ ]{0,3}([*+-]|\d+[.])[ \t]*\n$/, "\n\n");
        chunk.before = chunk.before.replace(/(\n|^)[ ]{0,3}>[ \t]*\n$/, "\n\n");
        chunk.before = chunk.before.replace(/(\n|^)[ \t]+\n$/, "\n\n");
        
        useDefaultText = false;
        
        if(/(\n|^)[ ]{0,3}([*+-])[ \t]+.*\n$/.test(chunk.before)){
            if(command.doList){
                command.doList(chunk, postProcessing, false, true);
            }
        }
        if(/(\n|^)[ ]{0,3}(\d+[.])[ \t]+.*\n$/.test(chunk.before)){
            if(command.doList){
                command.doList(chunk, postProcessing, true, true);
            }
        }
        if(/(\n|^)[ ]{0,3}>[ \t]+.*\n$/.test(chunk.before)){
            if(command.doBlockquote){
                command.doBlockquote(chunk, postProcessing, useDefaultText);
            }
        }
        if(/(\n|^)(\t|[ ]{4,}).*\n$/.test(chunk.before)){
            if(command.doCode){
                command.doCode(chunk, postProcessing, useDefaultText);
            }
        }
    };
    
    command.doBlockquote = function(chunk, postProcessing, useDefaultText){
        
        chunk.selection = chunk.selection.replace(/^(\n*)([^\r]+?)(\n*)$/,
            function(totalMatch, newlinesBefore, text, newlinesAfter){
                chunk.before += newlinesBefore;
                chunk.after = newlinesAfter + chunk.after;
                return text;
            });
            
        chunk.before = chunk.before.replace(/(>[ \t]*)$/,
            function(totalMatch, blankLine){
                chunk.selection = blankLine + chunk.selection;
                return "";
            });
        
        var defaultText = useDefaultText ? "Blockquote" : "";
        chunk.selection = chunk.selection.replace(/^(\s|>)+$/ ,"");
        chunk.selection = chunk.selection || defaultText;
        
        if(chunk.before){
            chunk.before = chunk.before.replace(/\n?$/,"\n");
        }
        if(chunk.after){
            chunk.after = chunk.after.replace(/^\n?/,"\n");
        }
        
        chunk.before = chunk.before.replace(/(((\n|^)(\n[ \t]*)*>(.+\n)*.*)+(\n[ \t]*)*$)/,
            function(totalMatch){
                chunk.startTag = totalMatch;
                return "";
            });
            
        chunk.after = chunk.after.replace(/^(((\n|^)(\n[ \t]*)*>(.+\n)*.*)+(\n[ \t]*)*)/,
            function(totalMatch){
                chunk.endTag = totalMatch;
                return "";
            });
        
        var replaceBlanksInTags = function(useBracket){
            
            var replacement = useBracket ? "> " : "";
            
            if(chunk.startTag){
                chunk.startTag = chunk.startTag.replace(/\n((>|\s)*)\n$/,
                    function(totalMatch, markdown){
                        return "\n" + markdown.replace(/^[ ]{0,3}>?[ \t]*$/gm, replacement) + "\n";
                    });
            }
            if(chunk.endTag){
                chunk.endTag = chunk.endTag.replace(/^\n((>|\s)*)\n/,
                    function(totalMatch, markdown){
                        return "\n" + markdown.replace(/^[ ]{0,3}>?[ \t]*$/gm, replacement) + "\n";
                    });
            }
        };
        
        if(/^(?![ ]{0,3}>)/m.test(chunk.selection)){
            command.wrap(chunk, wmd_options.lineLength - 2);
            chunk.selection = chunk.selection.replace(/^/gm, "> ");
            replaceBlanksInTags(true);
            chunk.addBlankLines();
        }
        else{
            chunk.selection = chunk.selection.replace(/^[ ]{0,3}> ?/gm, "");
            command.unwrap(chunk);
            replaceBlanksInTags(false);
            
            if(!/^(\n|^)[ ]{0,3}>/.test(chunk.selection) && chunk.startTag){
                chunk.startTag = chunk.startTag.replace(/\n{0,2}$/, "\n\n");
            }
            
            if(!/(\n|^)[ ]{0,3}>.*$/.test(chunk.selection) && chunk.endTag){
                chunk.endTag=chunk.endTag.replace(/^\n{0,2}/, "\n\n");
            }
        }
        
        if(!/\n/.test(chunk.selection)){
            chunk.selection = chunk.selection.replace(/^(> *)/,
            function(wholeMatch, blanks){
                chunk.startTag += blanks;
                return "";
            });
        }
    };

    command.doCode = function(chunk, postProcessing, useDefaultText){
        
        var hasTextBefore = /\S[ ]*$/.test(chunk.before);
        var hasTextAfter = /^[ ]*\S/.test(chunk.after);
        
        // Use 'four space' markdown if the selection is on its own
        // line or is multiline.
        if((!hasTextAfter && !hasTextBefore) || /\n/.test(chunk.selection)){
            
            chunk.before = chunk.before.replace(/[ ]{4}$/,
                function(totalMatch){
                    chunk.selection = totalMatch + chunk.selection;
                    return "";
                });
                
            var nLinesBefore = 1;
            var nLinesAfter = 1;
            
            
            if(/\n(\t|[ ]{4,}).*\n$/.test(chunk.before) || chunk.after === ""){
                nLinesBefore = 0; 
            }
            if(/^\n(\t|[ ]{4,})/.test(chunk.after)){
                nLinesAfter = 0; // This needs to happen on line 1
            }
            
            chunk.addBlankLines(nLinesBefore, nLinesAfter);
            
            if(!chunk.selection){
                chunk.startTag = "    ";
                chunk.selection = useDefaultText ? "enter code here" : "";
            }
            else {
                if(/^[ ]{0,3}\S/m.test(chunk.selection)){
                    chunk.selection = chunk.selection.replace(/^/gm, "    ");
                }
                else{
                    chunk.selection = chunk.selection.replace(/^[ ]{4}/gm, "");
                }
            }
        }
        else{
            // Use backticks (`) to delimit the code block.
            
            chunk.trimWhitespace();
            chunk.findTags(/`/, /`/);
            
            if(!chunk.startTag && !chunk.endTag){
                chunk.startTag = chunk.endTag="`";
                if(!chunk.selection){
                    chunk.selection = useDefaultText ? "enter code here" : "";
                }
            }
            else if(chunk.endTag && !chunk.startTag){
                chunk.before += chunk.endTag;
                chunk.endTag = "";
            }
            else{
                chunk.startTag = chunk.endTag="";
            }
        }
    };
    
    command.doList = function(chunk, postProcessing, isNumberedList, useDefaultText){
                
        // These are identical except at the very beginning and end.
        // Should probably use the regex extension function to make this clearer.
        var previousItemsRegex = /(\n|^)(([ ]{0,3}([*+-]|\d+[.])[ \t]+.*)(\n.+|\n{2,}([*+-].*|\d+[.])[ \t]+.*|\n{2,}[ \t]+\S.*)*)\n*$/;
        var nextItemsRegex = /^\n*(([ ]{0,3}([*+-]|\d+[.])[ \t]+.*)(\n.+|\n{2,}([*+-].*|\d+[.])[ \t]+.*|\n{2,}[ \t]+\S.*)*)\n*/;
        
        // The default bullet is a dash but others are possible.
        // This has nothing to do with the particular HTML bullet,
        // it's just a markdown bullet.
        var bullet = "-";
        
        // The number in a numbered list.
        var num = 1;
        
        // Get the item prefix - e.g. " 1. " for a numbered list, " - " for a bulleted list.
        var getItemPrefix = function(){
            var prefix;
            if(isNumberedList){
                prefix = " " + num + ". ";
                num++;
            }
            else{
                prefix = " " + bullet + " ";
            }
            return prefix;
        };
        
        // Fixes the prefixes of the other list items.
        var getPrefixedItem = function(itemText){
        
            // The numbering flag is unset when called by autoindent.
            if(isNumberedList === undefined){
                isNumberedList = /^\s*\d/.test(itemText);
            }
            
            // Renumber/bullet the list element.
            itemText = itemText.replace(/^[ ]{0,3}([*+-]|\d+[.])\s/gm,
                function( _ ){
                    return getItemPrefix();
                });
                
            return itemText;
        };
        
        chunk.findTags(/(\n|^)*[ ]{0,3}([*+-]|\d+[.])\s+/, null);
        
        if(chunk.before && !/\n$/.test(chunk.before) && !/^\n/.test(chunk.startTag)){
            chunk.before += chunk.startTag;
            chunk.startTag = "";
        }
        
        if(chunk.startTag){
            
            var hasDigits = /\d+[.]/.test(chunk.startTag);
            chunk.startTag = "";
            chunk.selection = chunk.selection.replace(/\n[ ]{4}/g, "\n");
            command.unwrap(chunk);
            chunk.addBlankLines();
            
            if(hasDigits){
                // Have to renumber the bullet points if this is a numbered list.
                chunk.after = chunk.after.replace(nextItemsRegex, getPrefixedItem);
            }
            if(isNumberedList == hasDigits){
                return;
            }
        }
        
        var nLinesBefore = 1;
        
        chunk.before = chunk.before.replace(previousItemsRegex,
            function(itemText){
                if(/^\s*([*+-])/.test(itemText)){
                    bullet = re.$1;
                }
                nLinesBefore = /[^\n]\n\n[^\n]/.test(itemText) ? 1 : 0;
                return getPrefixedItem(itemText);
            });
            
        if(!chunk.selection){
            chunk.selection = useDefaultText ? "List item" : " ";
        }
        
        var prefix = getItemPrefix();
        
        var nLinesAfter = 1;
        
        chunk.after = chunk.after.replace(nextItemsRegex,
            function(itemText){
                nLinesAfter = /[^\n]\n\n[^\n]/.test(itemText) ? 1 : 0;
                return getPrefixedItem(itemText);
            });
            
        chunk.trimWhitespace(true);
        chunk.addBlankLines(nLinesBefore, nLinesAfter, true);
        chunk.startTag = prefix;
        var spaces = prefix.replace(/./g, " ");
        command.wrap(chunk, wmd_options.lineLength - spaces.length);
        chunk.selection = chunk.selection.replace(/\n/g, "\n" + spaces);
        
    };
    
    command.doHeading = function(chunk, postProcessing, useDefaultText){
        
        // Remove leading/trailing whitespace and reduce internal spaces to single spaces.
        chunk.selection = chunk.selection.replace(/\s+/g, " ");
        chunk.selection = chunk.selection.replace(/(^\s+|\s+$)/g, "");
        
        // If we clicked the button with no selected text, we just
        // make a level 2 hash header around some default text.
        if(!chunk.selection){
            chunk.startTag = "## ";
            chunk.selection = "Heading";
            chunk.endTag = " ##";
            return;
        }
        
        var headerLevel = 0;        // The existing header level of the selected text.
        
        // Remove any existing hash heading markdown and save the header level.
        chunk.findTags(/#+[ ]*/, /[ ]*#+/);
        if(/#+/.test(chunk.startTag)){
            headerLevel = re.lastMatch.length;
        }
        chunk.startTag = chunk.endTag = "";
        
        // Try to get the current header level by looking for - and = in the line
        // below the selection.
        chunk.findTags(null, /\s?(-+|=+)/);
        if(/=+/.test(chunk.endTag)){
            headerLevel = 1;
        }
        if(/-+/.test(chunk.endTag)){
            headerLevel = 2;
        }
        
        // Skip to the next line so we can create the header markdown.
        chunk.startTag = chunk.endTag = "";
        chunk.addBlankLines(1, 1);

        // We make a level 2 header if there is no current header.
        // If there is a header level, we substract one from the header level.
        // If it's already a level 1 header, it's removed.
        var headerLevelToCreate = headerLevel == 0 ? 2 : headerLevel - 1;
        
        if(headerLevelToCreate > 0){
            
            // The button only creates level 1 and 2 underline headers.
            // Why not have it iterate over hash header levels?  Wouldn't that be easier and cleaner?
            var headerChar = headerLevelToCreate >= 2 ? "-" : "=";
            var len = chunk.selection.length;
            if(len > wmd_options.lineLength){
                len = wmd_options.lineLength;
            }
            chunk.endTag = "\n";
            while(len--){
                chunk.endTag += headerChar;
            }
        }
    };    
    
    command.doHorizontalRule = function(chunk, postProcessing, useDefaultText){
        chunk.startTag = "----------\n";
        chunk.selection = "";
        chunk.addBlankLines(2, 1, true);
    }
    // }}}
    
}; // }}}

})();

// For backward compatibility
function setup_wmd(options) {
    return new WMDEditor(options);
}
//
// showdown.js -- A javascript port of Markdown.
//
// Copyright (c) 2007 John Fraser.
//
// Original Markdown Copyright (c) 2004-2005 John Gruber
//   <http://daringfireball.net/projects/markdown/>
//
// The full source distribution is at:
//
//				A A L
//				T C A
//				T K B
//
//   <http://www.attacklab.net/>
//

//
// Wherever possible, Showdown is a straight, line-by-line port
// of the Perl version of Markdown.
//
// This is not a normal parser design; it's basically just a
// series of string substitutions.  It's hard to read and
// maintain this way,  but keeping Showdown close to the original
// design makes it easier to port new features.
//
// More importantly, Showdown behaves like markdown.pl in most
// edge cases.  So web applications can do client-side preview
// in Javascript, and then build identical HTML on the server.
//
// This port needs the new RegExp functionality of ECMA 262,
// 3rd Edition (i.e. Javascript 1.5).  Most modern web browsers
// should do fine.  Even with the new regular expression features,
// We do a lot of work to emulate Perl's regex functionality.
// The tricky changes in this file mostly have the "attacklab:"
// label.  Major or self-explanatory changes don't.
//
// Smart diff tools like Araxis Merge will be able to match up
// this file with markdown.pl in a useful way.  A little tweaking
// helps: in a copy of markdown.pl, replace "#" with "//" and
// replace "$text" with "text".  Be sure to ignore whitespace
// and line endings.
//


//
// Showdown usage:
//
//   var text = "Markdown *rocks*.";
//
//   var converter = new Attacklab.showdown.converter();
//   var html = converter.makeHtml(text);
//
//   alert(html);
//
// Note: move the sample code to the bottom of this
// file before uncommenting it.
//


//
// Attacklab namespace
//
var Attacklab = Attacklab || {}

//
// Showdown namespace
//
Attacklab.showdown = Attacklab.showdown || {}

//
// converter
//
// Wraps all "globals" so that the only thing
// exposed is makeHtml().
//
Attacklab.showdown.converter = function() {

//
// Globals:
//

// Global hashes, used by various utility routines
var g_urls;
var g_titles;
var g_html_blocks;

// Used to track when we're inside an ordered or unordered list
// (see _ProcessListItems() for details):
var g_list_level = 0;


this.makeHtml = function(text) {
//
// Main function. The order in which other subs are called here is
// essential. Link and image substitutions need to happen before
// _EscapeSpecialCharsWithinTagAttributes(), so that any *'s or _'s in the <a>
// and <img> tags get encoded.
//

	// Clear the global hashes. If we don't clear these, you get conflicts
	// from other articles when generating a page which contains more than
	// one article (e.g. an index page that shows the N most recent
	// articles):
	g_urls = new Array();
	g_titles = new Array();
	g_html_blocks = new Array();

	// attacklab: Replace ~ with ~T
	// This lets us use tilde as an escape char to avoid md5 hashes
	// The choice of character is arbitray; anything that isn't
    // magic in Markdown will work.
	text = text.replace(/~/g,"~T");

	// attacklab: Replace $ with ~D
	// RegExp interprets $ as a special character
	// when it's in a replacement string
	text = text.replace(/\$/g,"~D");

	// Standardize line endings
	text = text.replace(/\r\n/g,"\n"); // DOS to Unix
	text = text.replace(/\r/g,"\n"); // Mac to Unix

	// Make sure text begins and ends with a couple of newlines:
	text = "\n\n" + text + "\n\n";

	// Convert all tabs to spaces.
	text = _Detab(text);

	// Strip any lines consisting only of spaces and tabs.
	// This makes subsequent regexen easier to write, because we can
	// match consecutive blank lines with /\n+/ instead of something
	// contorted like /[ \t]*\n+/ .
	text = text.replace(/^[ \t]+$/mg,"");

	// Turn block-level HTML blocks into hash entries
	text = _HashHTMLBlocks(text);

	// Strip link definitions, store in hashes.
	text = _StripLinkDefinitions(text);

	text = _RunBlockGamut(text);

	text = _UnescapeSpecialChars(text);

	// attacklab: Restore dollar signs
	text = text.replace(/~D/g,"$$");

	// attacklab: Restore tildes
	text = text.replace(/~T/g,"~");

        // ** GFM **  Auto-link URLs and emails
        text = text.replace(/https?\:\/\/[^"\s\<\>]*[^.,;'">\:\s\<\>\)\]\!]/g, function(wholeMatch){
            var left = RegExp.leftContext
            var right = RegExp.rightContext
            if (left.match(/<[^>]+$/) && right.match(/^[^>]*>/)) {return wholeMatch}
            return "<a href='" + wholeMatch + "'>" + wholeMatch + "</a>";
        });
        text = text.replace(/[a-z0-9_\-+=.]+@[a-z0-9\-]+(\.[a-z0-9-]+)+/ig, function(wholeMatch){
            return "<a href='mailto:" + wholeMatch + "'>" + wholeMatch + "</a>";
        });


	return text;
}

var _StripLinkDefinitions = function(text) {
//
// Strips link definitions from text, stores the URLs and titles in
// hash references.
//

	// Link defs are in the form: ^[id]: url "optional title"

	/*
		var text = text.replace(/
				^[ ]{0,3}\[(.+)\]:  // id = $1  attacklab: g_tab_width - 1
				  [ \t]*
				  \n?				// maybe *one* newline
				  [ \t]*
				<?(\S+?)>?			// url = $2
				  [ \t]*
				  \n?				// maybe one newline
				  [ \t]*
				(?:
				  (\n*)				// any lines skipped = $3 attacklab: lookbehind removed
				  ["(]
				  (.+?)				// title = $4
				  [")]
				  [ \t]*
				)?					// title is optional
				(?:\n+|$)
			  /gm,
			  function(){...});
	*/
	var text = text.replace(/^[ ]{0,3}\[(.+)\]:[ \t]*\n?[ \t]*<?(\S+?)>?[ \t]*\n?[ \t]*(?:(\n*)["(](.+?)[")][ \t]*)?(?:\n+)/gm,
		function (wholeMatch,m1,m2,m3,m4) {
			m1 = m1.toLowerCase();
			g_urls[m1] = _EncodeAmpsAndAngles(m2);  // Link IDs are case-insensitive
			if (m3) {
				// Oops, found blank lines, so it's not a title.
				// Put back the parenthetical statement we stole.
				return m3+m4;
			} else if (m4) {
				g_titles[m1] = m4.replace(/"/g,"&quot;");
			}
			
			// Completely remove the definition from the text
			return "";
		}
	);

	return text;
}

var _HashHTMLBlocks = function(text) {
	// attacklab: Double up blank lines to reduce lookaround
	text = text.replace(/\n/g,"\n\n");

	// Hashify HTML blocks:
	// We only want to do this for block-level HTML tags, such as headers,
	// lists, and tables. That's because we still want to wrap <p>s around
	// "paragraphs" that are wrapped in non-block-level tags, such as anchors,
	// phrase emphasis, and spans. The list of tags we're looking for is
	// hard-coded:
	var block_tags_a = "p|div|h[1-6]|blockquote|pre|table|dl|ol|ul|script|noscript|form|fieldset|iframe|math|ins|del"
	var block_tags_b = "p|div|h[1-6]|blockquote|pre|table|dl|ol|ul|script|noscript|form|fieldset|iframe|math"

	// First, look for nested blocks, e.g.:
	//   <div>
	//     <div>
	//     tags for inner block must be indented.
	//     </div>
	//   </div>
	//
	// The outermost tags must start at the left margin for this to match, and
	// the inner nested divs must be indented.
	// We need to do this before the next, more liberal match, because the next
	// match will start at the first `<div>` and stop at the first `</div>`.

	// attacklab: This regex can be expensive when it fails.
	/*
		var text = text.replace(/
		(						// save in $1
			^					// start of line  (with /m)
			<($block_tags_a)	// start tag = $2
			\b					// word break
								// attacklab: hack around khtml/pcre bug...
			[^\r]*?\n			// any number of lines, minimally matching
			</\2>				// the matching end tag
			[ \t]*				// trailing spaces/tabs
			(?=\n+)				// followed by a newline
		)						// attacklab: there are sentinel newlines at end of document
		/gm,function(){...}};
	*/
	text = text.replace(/^(<(p|div|h[1-6]|blockquote|pre|table|dl|ol|ul|script|noscript|form|fieldset|iframe|math|ins|del)\b[^\r]*?\n<\/\2>[ \t]*(?=\n+))/gm,hashElement);

	//
	// Now match more liberally, simply from `\n<tag>` to `</tag>\n`
	//

	/*
		var text = text.replace(/
		(						// save in $1
			^					// start of line  (with /m)
			<($block_tags_b)	// start tag = $2
			\b					// word break
								// attacklab: hack around khtml/pcre bug...
			[^\r]*?				// any number of lines, minimally matching
			.*</\2>				// the matching end tag
			[ \t]*				// trailing spaces/tabs
			(?=\n+)				// followed by a newline
		)						// attacklab: there are sentinel newlines at end of document
		/gm,function(){...}};
	*/
	text = text.replace(/^(<(p|div|h[1-6]|blockquote|pre|table|dl|ol|ul|script|noscript|form|fieldset|iframe|math)\b[^\r]*?.*<\/\2>[ \t]*(?=\n+)\n)/gm,hashElement);

	// Special case just for <hr />. It was easier to make a special case than
	// to make the other regex more complicated.  

	/*
		text = text.replace(/
		(						// save in $1
			\n\n				// Starting after a blank line
			[ ]{0,3}
			(<(hr)				// start tag = $2
			\b					// word break
			([^<>])*?			// 
			\/?>)				// the matching end tag
			[ \t]*
			(?=\n{2,})			// followed by a blank line
		)
		/g,hashElement);
	*/
	text = text.replace(/(\n[ ]{0,3}(<(hr)\b([^<>])*?\/?>)[ \t]*(?=\n{2,}))/g,hashElement);

	// Special case for standalone HTML comments:

	/*
		text = text.replace(/
		(						// save in $1
			\n\n				// Starting after a blank line
			[ ]{0,3}			// attacklab: g_tab_width - 1
			<!
			(--[^\r]*?--\s*)+
			>
			[ \t]*
			(?=\n{2,})			// followed by a blank line
		)
		/g,hashElement);
	*/
	text = text.replace(/(\n\n[ ]{0,3}<!(--[^\r]*?--\s*)+>[ \t]*(?=\n{2,}))/g,hashElement);

	// PHP and ASP-style processor instructions (<?...?> and <%...%>)

	/*
		text = text.replace(/
		(?:
			\n\n				// Starting after a blank line
		)
		(						// save in $1
			[ ]{0,3}			// attacklab: g_tab_width - 1
			(?:
				<([?%])			// $2
				[^\r]*?
				\2>
			)
			[ \t]*
			(?=\n{2,})			// followed by a blank line
		)
		/g,hashElement);
	*/
	text = text.replace(/(?:\n\n)([ ]{0,3}(?:<([?%])[^\r]*?\2>)[ \t]*(?=\n{2,}))/g,hashElement);

	// attacklab: Undo double lines (see comment at top of this function)
	text = text.replace(/\n\n/g,"\n");
	return text;
}

var hashElement = function(wholeMatch,m1) {
	var blockText = m1;

	// Undo double lines
	blockText = blockText.replace(/\n\n/g,"\n");
	blockText = blockText.replace(/^\n/,"");
	
	// strip trailing blank lines
	blockText = blockText.replace(/\n+$/g,"");
	
	// Replace the element text with a marker ("~KxK" where x is its key)
	blockText = "\n\n~K" + (g_html_blocks.push(blockText)-1) + "K\n\n";
	
	return blockText;
};

var _RunBlockGamut = function(text) {
//
// These are all the transformations that form block-level
// tags like paragraphs, headers, and list items.
//
	text = _DoHeaders(text);

	// Do Horizontal Rules:
	var key = hashBlock("<hr />");
	text = text.replace(/^[ ]{0,2}([ ]?\*[ ]?){3,}[ \t]*$/gm,key);
	text = text.replace(/^[ ]{0,2}([ ]?\-[ ]?){3,}[ \t]*$/gm,key);
	text = text.replace(/^[ ]{0,2}([ ]?\_[ ]?){3,}[ \t]*$/gm,key);

	text = _DoLists(text);
	text = _DoCodeBlocks(text);
	text = _DoBlockQuotes(text);

	// We already ran _HashHTMLBlocks() before, in Markdown(), but that
	// was to escape raw HTML in the original Markdown source. This time,
	// we're escaping the markup we've just created, so that we don't wrap
	// <p> tags around block-level tags.
	text = _HashHTMLBlocks(text);
	text = _FormParagraphs(text);

	return text;
}


var _RunSpanGamut = function(text) {
//
// These are all the transformations that occur *within* block-level
// tags like paragraphs, headers, and list items.
//

	text = _DoCodeSpans(text);
	text = _EscapeSpecialCharsWithinTagAttributes(text);
	text = _EncodeBackslashEscapes(text);

	// Process anchor and image tags. Images must come first,
	// because ![foo][f] looks like an anchor.
	text = _DoImages(text);
	text = _DoAnchors(text);

	// Make links out of things like `<http://example.com/>`
	// Must come after _DoAnchors(), because you can use < and >
	// delimiters in inline links like [this](<url>).
	text = _DoAutoLinks(text);
	text = _EncodeAmpsAndAngles(text);
	text = _DoItalicsAndBold(text);

	// Do hard breaks:
	text = text.replace(/  +\n/g," <br />\n");

	return text;
}

var _EscapeSpecialCharsWithinTagAttributes = function(text) {
//
// Within tags -- meaning between < and > -- encode [\ ` * _] so they
// don't conflict with their use in Markdown for code, italics and strong.
//

	// Build a regex to find HTML tags and comments.  See Friedl's 
	// "Mastering Regular Expressions", 2nd Ed., pp. 200-201.
	var regex = /(<[a-z\/!$]("[^"]*"|'[^']*'|[^'">])*>|<!(--.*?--\s*)+>)/gi;

	text = text.replace(regex, function(wholeMatch) {
		var tag = wholeMatch.replace(/(.)<\/?code>(?=.)/g,"$1`");
		tag = escapeCharacters(tag,"\\`*_");
		return tag;
	});

	return text;
}

var _DoAnchors = function(text) {
//
// Turn Markdown link shortcuts into XHTML <a> tags.
//
	//
	// First, handle reference-style links: [link text] [id]
	//

	/*
		text = text.replace(/
		(							// wrap whole match in $1
			\[
			(
				(?:
					\[[^\]]*\]		// allow brackets nested one level
					|
					[^\[]			// or anything else
				)*
			)
			\]

			[ ]?					// one optional space
			(?:\n[ ]*)?				// one optional newline followed by spaces

			\[
			(.*?)					// id = $3
			\]
		)()()()()					// pad remaining backreferences
		/g,_DoAnchors_callback);
	*/
	text = text.replace(/(\[((?:\[[^\]]*\]|[^\[\]])*)\][ ]?(?:\n[ ]*)?\[(.*?)\])()()()()/g,writeAnchorTag);

	//
	// Next, inline-style links: [link text](url "optional title")
	//

	/*
		text = text.replace(/
			(						// wrap whole match in $1
				\[
				(
					(?:
						\[[^\]]*\]	// allow brackets nested one level
					|
					[^\[\]]			// or anything else
				)
			)
			\]
			\(						// literal paren
			[ \t]*
			()						// no id, so leave $3 empty
			<?(.*?)>?				// href = $4
			[ \t]*
			(						// $5
				(['"])				// quote char = $6
				(.*?)				// Title = $7
				\6					// matching quote
				[ \t]*				// ignore any spaces/tabs between closing quote and )
			)?						// title is optional
			\)
		)
		/g,writeAnchorTag);
	*/
	text = text.replace(/(\[((?:\[[^\]]*\]|[^\[\]])*)\]\([ \t]*()<?(.*?)>?[ \t]*((['"])(.*?)\6[ \t]*)?\))/g,writeAnchorTag);

	//
	// Last, handle reference-style shortcuts: [link text]
	// These must come last in case you've also got [link test][1]
	// or [link test](/foo)
	//

	/*
		text = text.replace(/
		(		 					// wrap whole match in $1
			\[
			([^\[\]]+)				// link text = $2; can't contain '[' or ']'
			\]
		)()()()()()					// pad rest of backreferences
		/g, writeAnchorTag);
	*/
	text = text.replace(/(\[([^\[\]]+)\])()()()()()/g, writeAnchorTag);

	return text;
}

var writeAnchorTag = function(wholeMatch,m1,m2,m3,m4,m5,m6,m7) {
	if (m7 == undefined) m7 = "";
	var whole_match = m1;
	var link_text   = m2;
	var link_id	 = m3.toLowerCase();
	var url		= m4;
	var title	= m7;
	
	if (url == "") {
		if (link_id == "") {
			// lower-case and turn embedded newlines into spaces
			link_id = link_text.toLowerCase().replace(/ ?\n/g," ");
		}
		url = "#"+link_id;
		
		if (g_urls[link_id] != undefined) {
			url = g_urls[link_id];
			if (g_titles[link_id] != undefined) {
				title = g_titles[link_id];
			}
		}
		else {
			if (whole_match.search(/\(\s*\)$/m)>-1) {
				// Special case for explicit empty url
				url = "";
			} else {
				return whole_match;
			}
		}
	}	
	
	url = escapeCharacters(url,"*_");
	var result = "<a href=\"" + url + "\"";
	
	if (title != "") {
		title = title.replace(/"/g,"&quot;");
		title = escapeCharacters(title,"*_");
		result +=  " title=\"" + title + "\"";
	}
	
	result += ">" + link_text + "</a>";
	
	return result;
}


var _DoImages = function(text) {
//
// Turn Markdown image shortcuts into <img> tags.
//

	//
	// First, handle reference-style labeled images: ![alt text][id]
	//

	/*
		text = text.replace(/
		(						// wrap whole match in $1
			!\[
			(.*?)				// alt text = $2
			\]

			[ ]?				// one optional space
			(?:\n[ ]*)?			// one optional newline followed by spaces

			\[
			(.*?)				// id = $3
			\]
		)()()()()				// pad rest of backreferences
		/g,writeImageTag);
	*/
	text = text.replace(/(!\[(.*?)\][ ]?(?:\n[ ]*)?\[(.*?)\])()()()()/g,writeImageTag);

	//
	// Next, handle inline images:  ![alt text](url "optional title")
	// Don't forget: encode * and _

	/*
		text = text.replace(/
		(						// wrap whole match in $1
			!\[
			(.*?)				// alt text = $2
			\]
			\s?					// One optional whitespace character
			\(					// literal paren
			[ \t]*
			()					// no id, so leave $3 empty
			<?(\S+?)>?			// src url = $4
			[ \t]*
			(					// $5
				(['"])			// quote char = $6
				(.*?)			// title = $7
				\6				// matching quote
				[ \t]*
			)?					// title is optional
		\)
		)
		/g,writeImageTag);
	*/
	text = text.replace(/(!\[(.*?)\]\s?\([ \t]*()<?(\S+?)>?[ \t]*((['"])(.*?)\6[ \t]*)?\))/g,writeImageTag);

	return text;
}

var writeImageTag = function(wholeMatch,m1,m2,m3,m4,m5,m6,m7) {
	var whole_match = m1;
	var alt_text   = m2;
	var link_id	 = m3.toLowerCase();
	var url		= m4;
	var title	= m7;

	if (!title) title = "";
	
	if (url == "") {
		if (link_id == "") {
			// lower-case and turn embedded newlines into spaces
			link_id = alt_text.toLowerCase().replace(/ ?\n/g," ");
		}
		url = "#"+link_id;
		
		if (g_urls[link_id] != undefined) {
			url = g_urls[link_id];
			if (g_titles[link_id] != undefined) {
				title = g_titles[link_id];
			}
		}
		else {
			return whole_match;
		}
	}	
	
	alt_text = alt_text.replace(/"/g,"&quot;");
	url = escapeCharacters(url,"*_");
	var result = "<img src=\"" + url + "\" alt=\"" + alt_text + "\"";

	// attacklab: Markdown.pl adds empty title attributes to images.
	// Replicate this bug.

	//if (title != "") {
		title = title.replace(/"/g,"&quot;");
		title = escapeCharacters(title,"*_");
		result +=  " title=\"" + title + "\"";
	//}
	
	result += " />";
	
	return result;
}


var _DoHeaders = function(text) {

	// Setext-style headers:
	//	Header 1
	//	========
	//  
	//	Header 2
	//	--------
	//
	text = text.replace(/^(.+)[ \t]*\n=+[ \t]*\n+/gm,
		function(wholeMatch,m1){return hashBlock("<h1>" + _RunSpanGamut(m1) + "</h1>");});

	text = text.replace(/^(.+)[ \t]*\n-+[ \t]*\n+/gm,
		function(matchFound,m1){return hashBlock("<h2>" + _RunSpanGamut(m1) + "</h2>");});

	// atx-style headers:
	//  # Header 1
	//  ## Header 2
	//  ## Header 2 with closing hashes ##
	//  ...
	//  ###### Header 6
	//

	/*
		text = text.replace(/
			^(\#{1,6})				// $1 = string of #'s
			[ \t]*
			(.+?)					// $2 = Header text
			[ \t]*
			\#*						// optional closing #'s (not counted)
			\n+
		/gm, function() {...});
	*/

	text = text.replace(/^(\#{1,6})[ \t]*(.+?)[ \t]*\#*\n+/gm,
		function(wholeMatch,m1,m2) {
			var h_level = m1.length;
			return hashBlock("<h" + h_level + ">" + _RunSpanGamut(m2) + "</h" + h_level + ">");
		});

	return text;
}

// This declaration keeps Dojo compressor from outputting garbage:
var _ProcessListItems;

var _DoLists = function(text) {
//
// Form HTML ordered (numbered) and unordered (bulleted) lists.
//

	// attacklab: add sentinel to hack around khtml/safari bug:
	// http://bugs.webkit.org/show_bug.cgi?id=11231
	text += "~0";

	// Re-usable pattern to match any entirel ul or ol list:

	/*
		var whole_list = /
		(									// $1 = whole list
			(								// $2
				[ ]{0,3}					// attacklab: g_tab_width - 1
				([*+-]|\d+[.])				// $3 = first list item marker
				[ \t]+
			)
			[^\r]+?
			(								// $4
				~0							// sentinel for workaround; should be $
			|
				\n{2,}
				(?=\S)
				(?!							// Negative lookahead for another list item marker
					[ \t]*
					(?:[*+-]|\d+[.])[ \t]+
				)
			)
		)/g
	*/
	var whole_list = /^(([ ]{0,3}([*+-]|\d+[.])[ \t]+)[^\r]+?(~0|\n{2,}(?=\S)(?![ \t]*(?:[*+-]|\d+[.])[ \t]+)))/gm;

	if (g_list_level) {
		text = text.replace(whole_list,function(wholeMatch,m1,m2) {
			var list = m1;
			var list_type = (m2.search(/[*+-]/g)>-1) ? "ul" : "ol";

			// Turn double returns into triple returns, so that we can make a
			// paragraph for the last item in a list, if necessary:
			list = list.replace(/\n{2,}/g,"\n\n\n");;
			var result = _ProcessListItems(list);
	
			// Trim any trailing whitespace, to put the closing `</$list_type>`
			// up on the preceding line, to get it past the current stupid
			// HTML block parser. This is a hack to work around the terrible
			// hack that is the HTML block parser.
			result = result.replace(/\s+$/,"");
			result = "<"+list_type+">" + result + "</"+list_type+">\n";
			return result;
		});
	} else {
		whole_list = /(\n\n|^\n?)(([ ]{0,3}([*+-]|\d+[.])[ \t]+)[^\r]+?(~0|\n{2,}(?=\S)(?![ \t]*(?:[*+-]|\d+[.])[ \t]+)))/g;
		text = text.replace(whole_list,function(wholeMatch,m1,m2,m3) {
			var runup = m1;
			var list = m2;

			var list_type = (m3.search(/[*+-]/g)>-1) ? "ul" : "ol";
			// Turn double returns into triple returns, so that we can make a
			// paragraph for the last item in a list, if necessary:
			var list = list.replace(/\n{2,}/g,"\n\n\n");;
			var result = _ProcessListItems(list);
			result = runup + "<"+list_type+">\n" + result + "</"+list_type+">\n";	
			return result;
		});
	}

	// attacklab: strip sentinel
	text = text.replace(/~0/,"");

	return text;
}

_ProcessListItems = function(list_str) {
//
//  Process the contents of a single ordered or unordered list, splitting it
//  into individual list items.
//
	// The $g_list_level global keeps track of when we're inside a list.
	// Each time we enter a list, we increment it; when we leave a list,
	// we decrement. If it's zero, we're not in a list anymore.
	//
	// We do this because when we're not inside a list, we want to treat
	// something like this:
	//
	//    I recommend upgrading to version
	//    8. Oops, now this line is treated
	//    as a sub-list.
	//
	// As a single paragraph, despite the fact that the second line starts
	// with a digit-period-space sequence.
	//
	// Whereas when we're inside a list (or sub-list), that line will be
	// treated as the start of a sub-list. What a kludge, huh? This is
	// an aspect of Markdown's syntax that's hard to parse perfectly
	// without resorting to mind-reading. Perhaps the solution is to
	// change the syntax rules such that sub-lists must start with a
	// starting cardinal number; e.g. "1." or "a.".

	g_list_level++;

	// trim trailing blank lines:
	list_str = list_str.replace(/\n{2,}$/,"\n");

	// attacklab: add sentinel to emulate \z
	list_str += "~0";

	/*
		list_str = list_str.replace(/
			(\n)?							// leading line = $1
			(^[ \t]*)						// leading whitespace = $2
			([*+-]|\d+[.]) [ \t]+			// list marker = $3
			([^\r]+?						// list item text   = $4
			(\n{1,2}))
			(?= \n* (~0 | \2 ([*+-]|\d+[.]) [ \t]+))
		/gm, function(){...});
	*/
	list_str = list_str.replace(/(\n)?(^[ \t]*)([*+-]|\d+[.])[ \t]+([^\r]+?(\n{1,2}))(?=\n*(~0|\2([*+-]|\d+[.])[ \t]+))/gm,
		function(wholeMatch,m1,m2,m3,m4){
			var item = m4;
			var leading_line = m1;
			var leading_space = m2;

			if (leading_line || (item.search(/\n{2,}/)>-1)) {
				item = _RunBlockGamut(_Outdent(item));
			}
			else {
				// Recursion for sub-lists:
				item = _DoLists(_Outdent(item));
				item = item.replace(/\n$/,""); // chomp(item)
				item = _RunSpanGamut(item);
			}

			return  "<li>" + item + "</li>\n";
		}
	);

	// attacklab: strip sentinel
	list_str = list_str.replace(/~0/g,"");

	g_list_level--;
	return list_str;
}


var _DoCodeBlocks = function(text) {
//
//  Process Markdown `<pre><code>` blocks.
//  

	/*
		text = text.replace(text,
			/(?:\n\n|^)
			(								// $1 = the code block -- one or more lines, starting with a space/tab
				(?:
					(?:[ ]{4}|\t)			// Lines must start with a tab or a tab-width of spaces - attacklab: g_tab_width
					.*\n+
				)+
			)
			(\n*[ ]{0,3}[^ \t\n]|(?=~0))	// attacklab: g_tab_width
		/g,function(){...});
	*/

	// attacklab: sentinel workarounds for lack of \A and \Z, safari\khtml bug
	text += "~0";
	
	text = text.replace(/(?:\n\n|^)((?:(?:[ ]{4}|\t).*\n+)+)(\n*[ ]{0,3}[^ \t\n]|(?=~0))/g,
		function(wholeMatch,m1,m2) {
			var codeblock = m1;
			var nextChar = m2;
		
			codeblock = _EncodeCode( _Outdent(codeblock));
			codeblock = _Detab(codeblock);
			codeblock = codeblock.replace(/^\n+/g,""); // trim leading newlines
			codeblock = codeblock.replace(/\n+$/g,""); // trim trailing whitespace

			codeblock = "<pre><code>" + codeblock + "\n</code></pre>";

			return hashBlock(codeblock) + nextChar;
		}
	);

	// attacklab: strip sentinel
	text = text.replace(/~0/,"");

	return text;
}

var hashBlock = function(text) {
	text = text.replace(/(^\n+|\n+$)/g,"");
	return "\n\n~K" + (g_html_blocks.push(text)-1) + "K\n\n";
}


var _DoCodeSpans = function(text) {
//
//   *  Backtick quotes are used for <code></code> spans.
// 
//   *  You can use multiple backticks as the delimiters if you want to
//	 include literal backticks in the code span. So, this input:
//	 
//		 Just type ``foo `bar` baz`` at the prompt.
//	 
//	   Will translate to:
//	 
//		 <p>Just type <code>foo `bar` baz</code> at the prompt.</p>
//	 
//	There's no arbitrary limit to the number of backticks you
//	can use as delimters. If you need three consecutive backticks
//	in your code, use four for delimiters, etc.
//
//  *  You can use spaces to get literal backticks at the edges:
//	 
//		 ... type `` `bar` `` ...
//	 
//	   Turns to:
//	 
//		 ... type <code>`bar`</code> ...
//

	/*
		text = text.replace(/
			(^|[^\\])					// Character before opening ` can't be a backslash
			(`+)						// $2 = Opening run of `
			(							// $3 = The code block
				[^\r]*?
				[^`]					// attacklab: work around lack of lookbehind
			)
			\2							// Matching closer
			(?!`)
		/gm, function(){...});
	*/

	text = text.replace(/(^|[^\\])(`+)([^\r]*?[^`])\2(?!`)/gm,
		function(wholeMatch,m1,m2,m3,m4) {
			var c = m3;
			c = c.replace(/^([ \t]*)/g,"");	// leading whitespace
			c = c.replace(/[ \t]*$/g,"");	// trailing whitespace
			c = _EncodeCode(c);
			return m1+"<code>"+c+"</code>";
		});

	return text;
}


var _EncodeCode = function(text) {
//
// Encode/escape certain characters inside Markdown code runs.
// The point is that in code, these characters are literals,
// and lose their special Markdown meanings.
//
	// Encode all ampersands; HTML entities are not
	// entities within a Markdown code span.
	text = text.replace(/&/g,"&amp;");

	// Do the angle bracket song and dance:
	text = text.replace(/</g,"&lt;");
	text = text.replace(/>/g,"&gt;");

	// Now, escape characters that are magic in Markdown:
	text = escapeCharacters(text,"\*_{}[]\\",false);

// jj the line above breaks this:
//---

//* Item

//   1. Subitem

//            special char: *
//---

	return text;
}


var _DoItalicsAndBold = function(text) {

	// <strong> must go first:
	text = text.replace(/(\*\*|__)(?=\S)([^\r]*?\S[*_]*)\1/g,
		"<strong>$2</strong>");

        text = text.replace(/(\w)_(\w)/g, "$1~E95E$2") // ** GFM **  "~E95E" == escaped "_"

	text = text.replace(/(\*|_)(?=\S)([^\r]*?\S)\1/g,
		"<em>$2</em>");

	return text;
}


var _DoBlockQuotes = function(text) {

	/*
		text = text.replace(/
		(								// Wrap whole match in $1
			(
				^[ \t]*>[ \t]?			// '>' at the start of a line
				.+\n					// rest of the first line
				(.+\n)*					// subsequent consecutive lines
				\n*						// blanks
			)+
		)
		/gm, function(){...});
	*/

	text = text.replace(/((^[ \t]*>[ \t]?.+\n(.+\n)*\n*)+)/gm,
		function(wholeMatch,m1) {
			var bq = m1;

			// attacklab: hack around Konqueror 3.5.4 bug:
			// "----------bug".replace(/^-/g,"") == "bug"

			bq = bq.replace(/^[ \t]*>[ \t]?/gm,"~0");	// trim one level of quoting

			// attacklab: clean up hack
			bq = bq.replace(/~0/g,"");

			bq = bq.replace(/^[ \t]+$/gm,"");		// trim whitespace-only lines
			bq = _RunBlockGamut(bq);				// recurse
			
			bq = bq.replace(/(^|\n)/g,"$1  ");
			// These leading spaces screw with <pre> content, so we need to fix that:
			bq = bq.replace(
					/(\s*<pre>[^\r]+?<\/pre>)/gm,
				function(wholeMatch,m1) {
					var pre = m1;
					// attacklab: hack around Konqueror 3.5.4 bug:
					pre = pre.replace(/^  /mg,"~0");
					pre = pre.replace(/~0/g,"");
					return pre;
				});
			
			return hashBlock("<blockquote>\n" + bq + "\n</blockquote>");
		});
	return text;
}


var _FormParagraphs = function(text) {
//
//  Params:
//    $text - string to process with html <p> tags
//

	// Strip leading and trailing lines:
	text = text.replace(/^\n+/g,"");
	text = text.replace(/\n+$/g,"");

	var grafs = text.split(/\n{2,}/g);
	var grafsOut = new Array();

	//
	// Wrap <p> tags.
	//
	var end = grafs.length;
	for (var i=0; i<end; i++) {
		var str = grafs[i];

		// if this is an HTML marker, copy it
		if (str.search(/~K(\d+)K/g) >= 0) {
			grafsOut.push(str);
		}
		else if (str.search(/\S/) >= 0) {
			str = _RunSpanGamut(str);
                        str = str.replace(/\n/g,"<br />");  // ** GFM **
			str = str.replace(/^([ \t]*)/g,"<p>");
			str += "</p>"
			grafsOut.push(str);
		}

	}

	//
	// Unhashify HTML blocks
	//
	end = grafsOut.length;
	for (var i=0; i<end; i++) {
		// if this is a marker for an html block...
		while (grafsOut[i].search(/~K(\d+)K/) >= 0) {
			var blockText = g_html_blocks[RegExp.$1];
			blockText = blockText.replace(/\$/g,"$$$$"); // Escape any dollar signs
			grafsOut[i] = grafsOut[i].replace(/~K\d+K/,blockText);
		}
	}

	return grafsOut.join("\n\n");
}


var _EncodeAmpsAndAngles = function(text) {
// Smart processing for ampersands and angle brackets that need to be encoded.
	
	// Ampersand-encoding based entirely on Nat Irons's Amputator MT plugin:
	//   http://bumppo.net/projects/amputator/
	text = text.replace(/&(?!#?[xX]?(?:[0-9a-fA-F]+|\w+);)/g,"&amp;");
	
	// Encode naked <'s
	text = text.replace(/<(?![a-z\/?\$!])/gi,"&lt;");
	
	return text;
}


var _EncodeBackslashEscapes = function(text) {
//
//   Parameter:  String.
//   Returns:	The string, with after processing the following backslash
//			   escape sequences.
//

	// attacklab: The polite way to do this is with the new
	// escapeCharacters() function:
	//
	// 	text = escapeCharacters(text,"\\",true);
	// 	text = escapeCharacters(text,"`*_{}[]()>#+-.!",true);
	//
	// ...but we're sidestepping its use of the (slow) RegExp constructor
	// as an optimization for Firefox.  This function gets called a LOT.

	text = text.replace(/\\(\\)/g,escapeCharacters_callback);
	text = text.replace(/\\([`*_{}\[\]()>#+-.!])/g,escapeCharacters_callback);
	return text;
}


var _DoAutoLinks = function(text) {

	text = text.replace(/<((https?|ftp|dict):[^'">\s]+)>/gi,"<a href=\"$1\">$1</a>");

	// Email addresses: <address@domain.foo>

	/*
		text = text.replace(/
			<
			(?:mailto:)?
			(
				[-.\w]+
				\@
				[-a-z0-9]+(\.[-a-z0-9]+)*\.[a-z]+
			)
			>
		/gi, _DoAutoLinks_callback());
	*/
	text = text.replace(/<(?:mailto:)?([-.\w]+\@[-a-z0-9]+(\.[-a-z0-9]+)*\.[a-z]+)>/gi,
		function(wholeMatch,m1) {
			return _EncodeEmailAddress( _UnescapeSpecialChars(m1) );
		}
	);

	return text;
}


var _EncodeEmailAddress = function(addr) {
//
//  Input: an email address, e.g. "foo@example.com"
//
//  Output: the email address as a mailto link, with each character
//	of the address encoded as either a decimal or hex entity, in
//	the hopes of foiling most address harvesting spam bots. E.g.:
//
//	<a href="&#x6D;&#97;&#105;&#108;&#x74;&#111;:&#102;&#111;&#111;&#64;&#101;
//	   x&#x61;&#109;&#x70;&#108;&#x65;&#x2E;&#99;&#111;&#109;">&#102;&#111;&#111;
//	   &#64;&#101;x&#x61;&#109;&#x70;&#108;&#x65;&#x2E;&#99;&#111;&#109;</a>
//
//  Based on a filter by Matthew Wickline, posted to the BBEdit-Talk
//  mailing list: <http://tinyurl.com/yu7ue>
//

	// attacklab: why can't javascript speak hex?
	function char2hex(ch) {
		var hexDigits = '0123456789ABCDEF';
		var dec = ch.charCodeAt(0);
		return(hexDigits.charAt(dec>>4) + hexDigits.charAt(dec&15));
	}

	var encode = [
		function(ch){return "&#"+ch.charCodeAt(0)+";";},
		function(ch){return "&#x"+char2hex(ch)+";";},
		function(ch){return ch;}
	];

	addr = "mailto:" + addr;

	addr = addr.replace(/./g, function(ch) {
		if (ch == "@") {
		   	// this *must* be encoded. I insist.
			ch = encode[Math.floor(Math.random()*2)](ch);
		} else if (ch !=":") {
			// leave ':' alone (to spot mailto: later)
			var r = Math.random();
			// roughly 10% raw, 45% hex, 45% dec
			ch =  (
					r > .9  ?	encode[2](ch)   :
					r > .45 ?	encode[1](ch)   :
								encode[0](ch)
				);
		}
		return ch;
	});

	addr = "<a href=\"" + addr + "\">" + addr + "</a>";
	addr = addr.replace(/">.+:/g,"\">"); // strip the mailto: from the visible part

	return addr;
}


var _UnescapeSpecialChars = function(text) {
//
// Swap back in all the special characters we've hidden.
//
	text = text.replace(/~E(\d+)E/g,
		function(wholeMatch,m1) {
			var charCodeToReplace = parseInt(m1);
			return String.fromCharCode(charCodeToReplace);
		}
	);
	return text;
}


var _Outdent = function(text) {
//
// Remove one level of line-leading tabs or spaces
//

	// attacklab: hack around Konqueror 3.5.4 bug:
	// "----------bug".replace(/^-/g,"") == "bug"

	text = text.replace(/^(\t|[ ]{1,4})/gm,"~0"); // attacklab: g_tab_width

	// attacklab: clean up hack
	text = text.replace(/~0/g,"")

	return text;
}

var _Detab = function(text) {
// attacklab: Detab's completely rewritten for speed.
// In perl we could fix it by anchoring the regexp with \G.
// In javascript we're less fortunate.

	// expand first n-1 tabs
	text = text.replace(/\t(?=\t)/g,"    "); // attacklab: g_tab_width

	// replace the nth with two sentinels
	text = text.replace(/\t/g,"~A~B");

	// use the sentinel to anchor our regex so it doesn't explode
	text = text.replace(/~B(.+?)~A/g,
		function(wholeMatch,m1,m2) {
			var leadingText = m1;
			var numSpaces = 4 - leadingText.length % 4;  // attacklab: g_tab_width

			// there *must* be a better way to do this:
			for (var i=0; i<numSpaces; i++) leadingText+=" ";

			return leadingText;
		}
	);

	// clean up sentinels
	text = text.replace(/~A/g,"    ");  // attacklab: g_tab_width
	text = text.replace(/~B/g,"");

	return text;
}


//
//  attacklab: Utility functions
//


var escapeCharacters = function(text, charsToEscape, afterBackslash) {
	// First we have to escape the escape characters so that
	// we can build a character class out of them
	var regexString = "([" + charsToEscape.replace(/([\[\]\\])/g,"\\$1") + "])";

	if (afterBackslash) {
		regexString = "\\\\" + regexString;
	}

	var regex = new RegExp(regexString,"g");
	text = text.replace(regex,escapeCharacters_callback);

	return text;
}


var escapeCharacters_callback = function(wholeMatch,m1) {
	var charCodeToEscape = m1.charCodeAt(0);
	return "~E"+charCodeToEscape+"E";
}

} // end of Attacklab.showdown.converter


// Version 0.9 used the Showdown namespace instead of Attacklab.showdown
// The old namespace is deprecated, but we'll support it for now:
var Showdown = Attacklab.showdown;

// If anyone's interested, tell the world that this file's been loaded
if (Attacklab.fileLoaded) {
	Attacklab.fileLoaded("showdown.js");
}
