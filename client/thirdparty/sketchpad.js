// Dec 25, 2014 -- fatihacet
// I made some changes to implement readOnly canvas. Here I proposed a PR to
// project owner. https://github.com/trsanders/responsive-sketchpad/pull/5
// If you want to update the library with it's latest master, make sure my PR
// is accepted by project owner.

var jQuery = require('jquery');

(function ($) {
    $.fn.sketchpad = function (options) {
        // Canvas info
        var canvas = this;
        canvas.readOnly = false;
        var ctx = $(this)[0].getContext('2d');

        // Default aspect ratio
        var aspectRatio = 1;

        // For storing strokes
        var strokes = [];

        // Whether or not currently drawing
        var sketching = false;

        // Default Context
        var lineColor = 'black';
        var lineSize = 5;
        var lineCap = 'round';
        var lineJoin = 'round';
        var lineMiterLimit = 10;

        // Array for storing strokes that were undone
        var undo = [];

        // Resize canvas with window
        canvas.parent().resize(function (e) {
            var width = canvas.parent().width();
            var height = width / aspectRatio;

            setSize(width, height);
            redraw();
        });

        // Return the mouse/touch location
        function getCursor(element, event) {
            var cur = {x: 0, y: 0};
            if (event.type.indexOf('touch') !== -1) {
                cur.x = event.originalEvent.touches[0].pageX;
                cur.y = event.originalEvent.touches[0].pageY;
            } else {
                cur.x = event.pageX;
                cur.y = event.pageY;
            }
            return {
                x: (cur.x - $(element).offset().left) / $(element).width(),
                y: (cur.y - $(element).offset().top) / $(element).height()
            }
        }

        // Set the canvas size
        function setSize(w, h) {
            lineSize *= (w / canvas.width());
            canvas.width(w);
            canvas.height(h);

            canvas[0].setAttribute('width', w);
            canvas[0].setAttribute('height', h);
        }

        // On mouse down, create new stroke, push start location
        var startEvent = 'mousedown touchstart ';
        canvas.on(startEvent, function (e) {
            if (canvas.readOnly) {
                return false;
            }

            if (e.type == 'touchstart') {
                e.preventDefault();
            } else {
                e.originalEvent.preventDefault();
            }

            sketching = true;
            undo = []; // Clear undo strokes

            strokes.push({
                stroke: [],
                color: lineColor,
                size: lineSize / $(this).width(),
                cap: lineCap,
                join: lineJoin,
                miterLimit: lineMiterLimit
            });

            var cursor = getCursor(this, e);

            strokes[strokes.length - 1].stroke.push({
                x: cursor.x,
                y: cursor.y
            });

            redraw();
        });

        // On mouse move, record movements
        var moveEvent = 'mousemove touchmove ';
        canvas.on(moveEvent, function (e) {
            if (canvas.readOnly) {
                return false;
            }

            var cursor = getCursor(this, e);

            if (sketching) {
                strokes[strokes.length - 1].stroke.push({
                    x: cursor.x,
                    y: cursor.y
                });
                redraw();
            }
        });

        // On mouse up, end stroke
        var endEvent = 'mouseup mouseleave touchend ';
        canvas.on(endEvent, function (e) {
            sketching = false;
        });

        function redraw() {
            var width = $(canvas).width();
            var height = $(canvas).height();

            ctx.clearRect(0, 0, width, height); // Clear Canvas

            for (var i = 0; i < strokes.length; i++) {
                var stroke = strokes[i].stroke;

                ctx.beginPath();
                for (var j = 0; j < stroke.length - 1; j++) {
                    ctx.moveTo(stroke[j].x * width, stroke[j].y * height);
                    ctx.lineTo(stroke[j + 1].x * width, stroke[j + 1].y * height);
                }
                ctx.closePath();

                ctx.strokeStyle = strokes[i].color;
                ctx.lineWidth = strokes[i].size * width;
                ctx.lineJoin = strokes[i].join;
                ctx.lineCap = strokes[i].cap;
                ctx.miterLimit = strokes[i].miterLimit;

                ctx.stroke()
            }
        }

        function init() {
            if (options.data) {
                aspectRatio = typeof options.data.aspectRatio !== 'undefined' ? options.data.aspectRatio : aspectRatio;
                strokes = typeof options.data.strokes !== 'undefined' ? options.data.strokes : [];
            } else {
                aspectRatio = typeof options.aspectRatio !== 'undefined' ? options.aspectRatio : aspectRatio;
            }

            var canvasColor = typeof options.canvasColor !== 'undefined' ? options.canvasColor : '#fff';
            canvas.css('background-color', canvasColor);

            var locked = typeof options.locked !== 'undefined' ? options.locked : false;
            if (locked) {
                canvas.unbind(startEvent + moveEvent + endEvent);
            } else {
                canvas.css('cursor', 'crosshair');
            }

            // Set canvas size
            var width = canvas.parent().width();
            var height = width / aspectRatio;

            setSize(width, height);
            redraw();
        }

        init();

        this.json = function () {
            return JSON.stringify({
                aspectRatio: aspectRatio,
                strokes: strokes
            });
        };

        this.jsonLoad = function (json) {
            var array = JSON.parse(json);
            aspectRatio = array.aspectRatio;
            strokes = array.strokes;
            redraw()
        };

        this.getImage = function () {
            return '<img src="' + canvas[0].toDataURL("image/png") + '"/>';
        };

        this.getLineColor = function () {
            return lineColor;
        };

        this.setLineColor = function (color) {
            lineColor = color;
        };

        this.getLineSize = function () {
            return lineSize;
        };

        this.setLineSize = function (size) {
            lineSize = size;
        };

        this.undo = function () {
            if (strokes.length > 0) {
                undo.push(strokes.pop());
                redraw();
            }
        };

        this.redo = function () {
            if (undo.length > 0) {
                strokes.push(undo.pop());
                redraw();
            }
        };

        this.clear = function () {
            strokes = [];
            redraw();
        };

        this.setReadOnly = function(state) {
            this.readOnly = state;
            if (state) {
                canvas.css('cursor', 'default');
            }
            else {
                canvas.css('cursor', 'crosshair');
            }
        };

        return this;
    };
}(jQuery));
