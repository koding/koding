exports = module.exports = function () { "use strict"; // if you want
    
    /**
     * Copyright (C) 2011 by Andrea Giammarchi, @WebReflection
     * 
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this software and associated documentation files (the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions:
     * 
     * The above copyright notice and this permission notice shall be included in
     * all copies or substantial portions of the Software.
     * 
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
     * THE SOFTWARE.
     */
    
    var // returns a generic object defined properties
        Object_keys = Object.keys || function (o) {
            var keys = [], key;
            for (key in o) o.hasOwnProperty(key) && keys.push(key);
            return keys;
        },
        // define later, mifiers friendly + self bound
        JSONH
    ;
    return JSONH = {
        
        // transforms [{a:"A"},{a:"B"}] to [1,"a","A","B"]
        pack: function pack(list) {
            for (var
                length = list.length,
                // defined properties (out of one object is enough)
                keys = Object_keys(length ? list[0] : {}),
                klength = keys.length,
                // static length stack of JS values
                result = Array(length * klength),
                i = 0,
                j = 0,
                ki, o;
                i < length; ++i
            ) {
                for (
                    o = list[i], ki = 0;
                    ki < klength;
                    result[j++] = o[keys[ki++]]
                );
            }
            // keys.length, keys, result
            return [klength].concat(keys, result);
        },
        
        // JSONH.unpack after JSON.parse
        parse: function parse(hlist, reviver) {
            return JSONH.unpack(JSON.parse(hlist, reviver));
        },
        
        // JSON.stringify after JSONH.pack
        stringify: function stringify(list, replacer, space) {
            return JSON.stringify(JSONH.pack(list), replacer, space);
        },
        
        // transforms [1,"a","A","B"] to [{a:"A"},{a:"B"}]
        unpack : function unpack(hlist) {
            for (var
                length = hlist.length,
                klength = hlist[0],
                result = Array(((length - klength - 1) / klength) || 0),
                i = 1 + klength,
                j = 0,
                ki, o;
                i < length;
            ) {
                for (
                    result[j++] = (o = {}), ki = 0;
                    ki < klength;
                    o[hlist[++ki]] = hlist[i++]
                );
            }
            return result;
        }
    };
    
}();