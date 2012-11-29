// node-xml
// An xml parser for node.js
// (C) Rob Righter (@robrighter) 2009 - 2010, Licensed under the MIT-LICENSE
// Contributions from David Joham


(function () {

// CONSTANTS
var whitespace = "\n\r\t ";


//XMLP is a pull-based parser. The calling application passes in a XML string
//to the constructor, then repeatedly calls .next() to parse the next segment.
//.next() returns a flag indicating what type of segment was found, and stores
//data temporarily in couple member variables (name, content, array of
//attributes), which can be accessed by several .get____() methods.
//
//Basically, XMLP is the lowest common denominator parser - an very simple
//API which other wrappers can be built against.


var XMLP = function(strXML) {
    // Normalize line breaks
    strXML = SAXStrings.replace(strXML, null, null, "\r\n", "\n");
    strXML = SAXStrings.replace(strXML, null, null, "\r", "\n");

    this.m_xml = strXML;
    this.m_iP = 0;
    this.m_iState = XMLP._STATE_PROLOG;
    this.m_stack = new Stack();
    this._clearAttributes();
    this.m_pause = false;
    this.m_preInterruptIState = XMLP._STATE_PROLOG;
    this.m_namespaceList = new Array();
    this.m_chunkTransitionContinuation = null;

}


// CONSTANTS    (these must be below the constructor)
XMLP._NONE    = 0;
XMLP._ELM_B   = 1;
XMLP._ELM_E   = 2;
XMLP._ELM_EMP = 3;
XMLP._ATT     = 4;
XMLP._TEXT    = 5;
XMLP._ENTITY  = 6;
XMLP._PI      = 7;
XMLP._CDATA   = 8;
XMLP._COMMENT = 9;
XMLP._DTD     = 10;
XMLP._ERROR   = 11;
XMLP._INTERRUPT = 12;

XMLP._CONT_XML = 0;
XMLP._CONT_ALT = 1;

XMLP._ATT_NAME = 0;
XMLP._ATT_VAL  = 1;

XMLP._STATE_PROLOG = 1;
XMLP._STATE_DOCUMENT = 2;
XMLP._STATE_MISC = 3;

XMLP._errs = new Array();
XMLP._errs[XMLP.ERR_CLOSE_PI       = 0 ] = "PI: missing closing sequence";
XMLP._errs[XMLP.ERR_CLOSE_DTD      = 1 ] = "DTD: missing closing sequence";
XMLP._errs[XMLP.ERR_CLOSE_COMMENT  = 2 ] = "Comment: missing closing sequence";
XMLP._errs[XMLP.ERR_CLOSE_CDATA    = 3 ] = "CDATA: missing closing sequence";
XMLP._errs[XMLP.ERR_CLOSE_ELM      = 4 ] = "Element: missing closing sequence";
XMLP._errs[XMLP.ERR_CLOSE_ENTITY   = 5 ] = "Entity: missing closing sequence";
XMLP._errs[XMLP.ERR_PI_TARGET      = 6 ] = "PI: target is required";
XMLP._errs[XMLP.ERR_ELM_EMPTY      = 7 ] = "Element: cannot be both empty and closing";
XMLP._errs[XMLP.ERR_ELM_NAME       = 8 ] = "Element: name must immediatly follow \"<\"";
XMLP._errs[XMLP.ERR_ELM_LT_NAME    = 9 ] = "Element: \"<\" not allowed in element names";
XMLP._errs[XMLP.ERR_ATT_VALUES     = 10] = "Attribute: values are required and must be in quotes";
XMLP._errs[XMLP.ERR_ATT_LT_NAME    = 11] = "Element: \"<\" not allowed in attribute names";
XMLP._errs[XMLP.ERR_ATT_LT_VALUE   = 12] = "Attribute: \"<\" not allowed in attribute values";
XMLP._errs[XMLP.ERR_ATT_DUP        = 13] = "Attribute: duplicate attributes not allowed";
XMLP._errs[XMLP.ERR_ENTITY_UNKNOWN = 14] = "Entity: unknown entity";
XMLP._errs[XMLP.ERR_INFINITELOOP   = 15] = "Infininte loop";
XMLP._errs[XMLP.ERR_DOC_STRUCTURE  = 16] = "Document: only comments, processing instructions, or whitespace allowed outside of document element";
XMLP._errs[XMLP.ERR_ELM_NESTING    = 17] = "Element: must be nested correctly";



XMLP.prototype.continueParsing = function(strXML) {

    if(this.m_chunkTransitionContinuation){
        strXML = this.m_chunkTransitionContinuation + strXML;
    }
    // Normalize line breaks
    strXML = SAXStrings.replace(strXML, null, null, "\r\n", "\n");
    strXML = SAXStrings.replace(strXML, null, null, "\r", "\n");

    this.m_xml = strXML;
    this.m_iP = 0;
    this.m_iState = XMLP._STATE_DOCUMENT;
    //this.m_stack = new Stack();
    //this._clearAttributes();
    this.m_pause = false;
    this.m_preInterruptIState = XMLP._STATE_PROLOG;
    this.m_chunkTransitionContinuation = null;

}

XMLP.prototype._addAttribute = function(name, value) {
    this.m_atts[this.m_atts.length] = new Array(name, value);
}

XMLP.prototype._checkStructure = function(iEvent) {
	if(XMLP._STATE_PROLOG == this.m_iState) {
		if((XMLP._TEXT == iEvent) || (XMLP._ENTITY == iEvent)) {
            if(SAXStrings.indexOfNonWhitespace(this.getContent(), this.getContentBegin(), this.getContentEnd()) != -1) {
				return this._setErr(XMLP.ERR_DOC_STRUCTURE);
            }
        }

        if((XMLP._ELM_B == iEvent) || (XMLP._ELM_EMP == iEvent)) {
            this.m_iState = XMLP._STATE_DOCUMENT;
            // Don't return - fall through to next state
        }
    }
    if(XMLP._STATE_DOCUMENT == this.m_iState) {
        if((XMLP._ELM_B == iEvent) || (XMLP._ELM_EMP == iEvent)) {
            this.m_stack.push(this.getName());
        }

        if((XMLP._ELM_E == iEvent) || (XMLP._ELM_EMP == iEvent)) {
            var strTop = this.m_stack.pop();
            if((strTop == null) || (strTop != this.getName())) {
                return this._setErr(XMLP.ERR_ELM_NESTING);
            }
        }

        if(this.m_stack.count() == 0) {
            this.m_iState = XMLP._STATE_MISC;
            return iEvent;
        }
    }
    if(XMLP._STATE_MISC == this.m_iState) {
		if((XMLP._ELM_B == iEvent) || (XMLP._ELM_E == iEvent) || (XMLP._ELM_EMP == iEvent) || (XMLP.EVT_DTD == iEvent)) {
			return this._setErr(XMLP.ERR_DOC_STRUCTURE);
        }

        if((XMLP._TEXT == iEvent) || (XMLP._ENTITY == iEvent)) {
			if(SAXStrings.indexOfNonWhitespace(this.getContent(), this.getContentBegin(), this.getContentEnd()) != -1) {
				return this._setErr(XMLP.ERR_DOC_STRUCTURE);
            }
        }
    }

    return iEvent;

}

XMLP.prototype._clearAttributes = function() {
    this.m_atts = new Array();
}

XMLP.prototype._findAttributeIndex = function(name) {
    for(var i = 0; i < this.m_atts.length; i++) {
        if(this.m_atts[i][XMLP._ATT_NAME] == name) {
            return i;
        }
    }
    return -1;

}

XMLP.prototype.getAttributeCount = function() {
    return this.m_atts ? this.m_atts.length : 0;
}

XMLP.prototype.getAttributeName = function(index) {
    return ((index < 0) || (index >= this.m_atts.length)) ? null : this.m_atts[index][XMLP._ATT_NAME];
}

XMLP.prototype.getAttributeValue = function(index) {
    return ((index < 0) || (index >= this.m_atts.length)) ? null : __unescapeString(this.m_atts[index][XMLP._ATT_VAL]);
}

XMLP.prototype.getAttributeValueByName = function(name) {
    return this.getAttributeValue(this._findAttributeIndex(name));
}

XMLP.prototype.getColumnNumber = function() {
    return SAXStrings.getColumnNumber(this.m_xml, this.m_iP);
}

XMLP.prototype.getContent = function() {
    return (this.m_cSrc == XMLP._CONT_XML) ? this.m_xml : this.m_cAlt;
}

XMLP.prototype.getContentBegin = function() {
    return this.m_cB;
}

XMLP.prototype.getContentEnd = function() {
    return this.m_cE;
}

XMLP.prototype.getLineNumber = function() {
    return SAXStrings.getLineNumber(this.m_xml, this.m_iP);
}

XMLP.prototype.getName = function() {
    return this.m_name;
}

XMLP.prototype.pause = function(){
    this.m_pause = true;
}

XMLP.prototype.resume = function(){
    this.m_pause = false;
    this.m_iState = this.m_preInterruptIState;
}

XMLP.prototype.next = function() {
    if(!this.m_pause){
        return this._checkStructure(this._parse());
    }
    else{
        //save off the current event loop state and set the state to interrupt
        this.m_preInterruptIState = this.m_iState;
        return XMLP._INTERRUPT;
    }
}

XMLP.prototype._parse = function() {
    if(this.m_iP == this.m_xml.length) {
        return XMLP._NONE;
    }

    function _indexOf(needle, haystack, start) {
        // This is an improvement over the native indexOf because it stops at the
        // end of the needle and doesn't continue to the end of the haystack looking.
        for(var i = 0; i < needle.length; i++) {
            if(needle.charAt(i) != haystack.charAt(start + i))
                return -1;
        }
        return start;
    }

    var fc = this.m_xml.charAt(this.m_iP);
    if (fc !== '<' && fc !== '&') {
        return this._parseText   (this.m_iP);
    }
    else if(this.m_iP == _indexOf("<?", this.m_xml, this.m_iP)) {
        return this._parsePI     (this.m_iP + 2);
    }
    else if(this.m_iP == _indexOf("<!DOCTYPE", this.m_xml, this.m_iP)) {
        return this._parseDTD    (this.m_iP + 9);
    }
    else if(this.m_iP == _indexOf("<!--", this.m_xml, this.m_iP)) {
        return this._parseComment(this.m_iP + 4);
    }
    else if(this.m_iP == _indexOf("<![CDATA[", this.m_xml, this.m_iP)) {
        return this._parseCDATA  (this.m_iP + 9);
    }
    else if(this.m_iP == _indexOf("<", this.m_xml, this.m_iP)) {
        return this._parseElement(this.m_iP + 1);
    }
    else if(this.m_iP == _indexOf("&", this.m_xml, this.m_iP)) {
        return this._parseEntity (this.m_iP + 1);
    }
    else{
        return this._parseText   (this.m_iP);
    }
}

////////// NAMESPACE SUPPORT //////////////////////////////////////////
XMLP.prototype._parsePrefixAndElementName = function (elementlabel){
    splits = elementlabel.split(':',2);
    return { prefix : ((splits.length === 1) ? '' : splits[0]), name : ((splits.length === 1) ? elementlabel : splits[1]), };
}

XMLP.prototype._parseNamespacesAndAtts = function (atts){
   //translate namespaces into objects with "prefix","uri", "scopetag" Add them to: this.m_namespaceList
   //The function should return a new list of tag attributes with the namespaces filtered
    that = this;
    var newnamespaces = [];
    var filteredatts = [];
    atts.map(function (item){
        if(item[0].slice(0,5) === "xmlns"){
            newnamespaces.push({
                                   prefix : item[0].slice(6),
                                   uri : item[1],
                                   scopetag : that.m_name,
                                });
        }
        else{
            filteredatts.push(item);
        }
        return "not used";
    });
    this.m_namespaceList = this.m_namespaceList.concat(newnamespaces);
    return [ filteredatts, newnamespaces.map(function(item){return [item.prefix,item.uri];}) ];
}

XMLP.prototype._getContextualNamespace = function (prefix){
    if(prefix !== ''){
        for(item in this.m_namespaceList){
            item = this.m_namespaceList[item];
            if(item.prefix === prefix){
                return item.uri;
            }
        }
    }

    //no match was found for the prefix so pop off the first non-prefix namespace
    for(var i = (this.m_namespaceList.length-1); i>= 0; i--){
        var item = this.m_namespaceList[i];
        if(item.prefix === ''){
            return item.uri;
        }
    }

    //still nothing, lets just return an empty string
    return '';
}

XMLP.prototype._removeExpiredNamesapces = function (closingtagname) {
    //remove the expiring namespaces from the list (you can id them by scopetag)
    var keeps = [];
    this.m_namespaceList.map(function (item){
        if(item.scopetag !== closingtagname){
            keeps.push(item);
        }
    });

    this.m_namespaceList = keeps;

}

////////////////////////////////////////////////////////////////////////


XMLP.prototype._parseAttribute = function(iB, iE) {
    var iNB, iNE, iEq, iVB, iVE;
    var cQuote, strN, strV;

	this.m_cAlt = ""; //resets the value so we don't use an old one by accident (see testAttribute7 in the test suite)

	iNB = SAXStrings.indexOfNonWhitespace(this.m_xml, iB, iE);
    if((iNB == -1) ||(iNB >= iE)) {
        return iNB;
    }

    iEq = this.m_xml.indexOf("=", iNB);
    if((iEq == -1) || (iEq > iE)) {
        return this._setErr(XMLP.ERR_ATT_VALUES);
    }

    iNE = SAXStrings.lastIndexOfNonWhitespace(this.m_xml, iNB, iEq);

    iVB = SAXStrings.indexOfNonWhitespace(this.m_xml, iEq + 1, iE);
    if((iVB == -1) ||(iVB > iE)) {
        return this._setErr(XMLP.ERR_ATT_VALUES);
    }

    cQuote = this.m_xml.charAt(iVB);
    if(SAXStrings.QUOTES.indexOf(cQuote) == -1) {
        return this._setErr(XMLP.ERR_ATT_VALUES);
    }

    iVE = this.m_xml.indexOf(cQuote, iVB + 1);
    if((iVE == -1) ||(iVE > iE)) {
        return this._setErr(XMLP.ERR_ATT_VALUES);
    }

    strN = this.m_xml.substring(iNB, iNE + 1);
    strV = this.m_xml.substring(iVB + 1, iVE);

    if(strN.indexOf("<") != -1) {
        return this._setErr(XMLP.ERR_ATT_LT_NAME);
    }

    if(strV.indexOf("<") != -1) {
        return this._setErr(XMLP.ERR_ATT_LT_VALUE);
    }

    strV = SAXStrings.replace(strV, null, null, "\n", " ");
    strV = SAXStrings.replace(strV, null, null, "\t", " ");
	iRet = this._replaceEntities(strV);
    if(iRet == XMLP._ERROR) {
        return iRet;
    }

    strV = this.m_cAlt;

    if(this._findAttributeIndex(strN) == -1) {
        this._addAttribute(strN, strV);
    }
    else {
        return this._setErr(XMLP.ERR_ATT_DUP);
    }

    this.m_iP = iVE + 2;

    return XMLP._ATT;

}

XMLP.prototype._parseCDATA = function(iB) {
    var iE = this.m_xml.indexOf("]]>", iB);
    if (iE == -1) {
        //This item never closes, although it could be a malformed document, we will assume that we are mid-chunck, save the string and reurn as interrupted
        this.m_chunkTransitionContinuation = this.m_xml.slice(iB-9);//the '-<![CDATA[ adds the '<!DOCTYPE' back into the string
        return XMLP._INTERRUPT;
        //return this._setErr(XMLP.ERR_CLOSE_CDATA);
    }

    this._setContent(XMLP._CONT_XML, iB, iE);

    this.m_iP = iE + 3;

    return XMLP._CDATA;

}

XMLP.prototype._parseComment = function(iB) {
    var iE = this.m_xml.indexOf("-" + "->", iB);
    if (iE == -1) {
        //This item never closes, although it could be a malformed document, we will assume that we are mid-chunck, save the string and reurn as interrupted
        this.m_chunkTransitionContinuation = this.m_xml.slice(iB-4);//the '-4' adds the '<!--' back into the string
        return XMLP._INTERRUPT;
        //return this._setErr(XMLP.ERR_CLOSE_COMMENT);
    }

    this._setContent(XMLP._CONT_XML, iB, iE);

    this.m_iP = iE + 3;

    return XMLP._COMMENT;

}

XMLP.prototype._parseDTD = function(iB) {
    // Eat DTD
    var iE, strClose, iInt, iLast;

    iE = this.m_xml.indexOf(">", iB);
    if(iE == -1) {
        //This item never closes, although it could be a malformed document, we will assume that we are mid-chunck, save the string and reurn as interrupted
        this.m_chunkTransitionContinuation = this.m_xml.slice(iB-9);//the '-9' adds the '<!DOCTYPE' back into the string
        return XMLP._INTERRUPT;
        //return this._setErr(XMLP.ERR_CLOSE_DTD);
    }

    iInt = this.m_xml.indexOf("[", iB);
    strClose = ((iInt != -1) && (iInt < iE)) ? "]>" : ">";

    while(true) {
        // DEBUG: Remove
        if(iE == iLast) {
            return this._setErr(XMLP.ERR_INFINITELOOP);
        }

        iLast = iE;
        // DEBUG: Remove End

        iE = this.m_xml.indexOf(strClose, iB);
        if(iE == -1) {
            return this._setErr(XMLP.ERR_CLOSE_DTD);
        }

        // Make sure it is not the end of a CDATA section
        if (this.m_xml.substring(iE - 1, iE + 2) != "]]>") {
            break;
        }
    }

    this.m_iP = iE + strClose.length;

    return XMLP._DTD;

}

XMLP.prototype._parseElement = function(iB) {
    util = require('util');
    var iE, iDE, iNE, iRet;
    var iType, strN, iLast;

    iDE = iE = this.m_xml.indexOf(">", iB);
    if(iE == -1) {
        //This element never closes, although it could be a malformed document, we will assume that we are mid-chunck, save the string and reurn as interrupted
        this.m_chunkTransitionContinuation = this.m_xml.slice(iB-1);//the '-1' adds the '<' back into the string
        return XMLP._INTERRUPT;
        //return this._setErr(XMLP.ERR_CLOSE_ELM);
    }

    if(this.m_xml.charAt(iB) == "/") {
        iType = XMLP._ELM_E;
        iB++;
    } else {
        iType = XMLP._ELM_B;
    }

    if(this.m_xml.charAt(iE - 1) == "/") {
        if(iType == XMLP._ELM_E) {
            return this._setErr(XMLP.ERR_ELM_EMPTY);
        }
        iType = XMLP._ELM_EMP;
        iDE--;
    }

    iDE = SAXStrings.lastIndexOfNonWhitespace(this.m_xml, iB, iDE);

    //djohack
    //hack to allow for elements with single character names to be recognized

    if (iE - iB != 1 ) {
        if(SAXStrings.indexOfNonWhitespace(this.m_xml, iB, iDE) != iB) {
            return this._setErr(XMLP.ERR_ELM_NAME);
        }
    }
    // end hack -- original code below

    /*
    if(SAXStrings.indexOfNonWhitespace(this.m_xml, iB, iDE) != iB)
        return this._setErr(XMLP.ERR_ELM_NAME);
    */
    this._clearAttributes();

    iNE = SAXStrings.indexOfWhitespace(this.m_xml, iB, iDE);
    if(iNE == -1) {
        iNE = iDE + 1;
    }
    else {
        this.m_iP = iNE;
        while(this.m_iP < iDE) {
            // DEBUG: Remove
            if(this.m_iP == iLast) return this._setErr(XMLP.ERR_INFINITELOOP);
            iLast = this.m_iP;
            // DEBUG: Remove End


            iRet = this._parseAttribute(this.m_iP, iDE);
            if(iRet == XMLP._ERROR) return iRet;
        }
    }

    strN = this.m_xml.substring(iB, iNE);

    if(strN.indexOf("<") != -1) {
        return this._setErr(XMLP.ERR_ELM_LT_NAME);
    }

    this.m_name = strN;
    this.m_iP = iE + 1;

    return iType;

}

XMLP.prototype._parseEntity = function(iB) {
    var iE = this.m_xml.indexOf(";", iB);
    if(iE == -1) {
        //This item never closes, although it could be a malformed document, we will assume that we are mid-chunck, save the string and reurn as interrupted
        this.m_chunkTransitionContinuation = this.m_xml.slice(iB-1);//the '-1' adds the '&' back into the string
        return XMLP._INTERRUPT;
        //return this._setErr(XMLP.ERR_CLOSE_ENTITY);
    }

    this.m_iP = iE + 1;

    return this._replaceEntity(this.m_xml, iB, iE);

}

XMLP.prototype._parsePI = function(iB) {
    var iE, iTB, iTE, iCB, iCE;

    iE = this.m_xml.indexOf("?>", iB);
    if(iE   == -1) {
        //This item never closes, although it could be a malformed document, we will assume that we are mid-chunck, save the string and reurn as interrupted
        this.m_chunkTransitionContinuation = this.m_xml.slice(iB-2);//the '-2' adds the '?>' back into the string
        return XMLP._INTERRUPT;
        return this._setErr(XMLP.ERR_CLOSE_PI);
    }

    iTB = SAXStrings.indexOfNonWhitespace(this.m_xml, iB, iE);
    if(iTB == -1) {
        return this._setErr(XMLP.ERR_PI_TARGET);
    }

    iTE = SAXStrings.indexOfWhitespace(this.m_xml, iTB, iE);
    if(iTE  == -1) {
        iTE = iE;
    }

    iCB = SAXStrings.indexOfNonWhitespace(this.m_xml, iTE, iE);
    if(iCB == -1) {
        iCB = iE;
    }

    iCE = SAXStrings.lastIndexOfNonWhitespace(this.m_xml, iCB, iE);
    if(iCE  == -1) {
        iCE = iE - 1;
    }

    this.m_name = this.m_xml.substring(iTB, iTE);
    this._setContent(XMLP._CONT_XML, iCB, iCE + 1);
    this.m_iP = iE + 2;

    return XMLP._PI;

}

XMLP.prototype._parseText = function(iB) {
    var iE, ch;

    for (iE=iB; iE<this.m_xml.length; ++iE) {
        ch = this.m_xml.charAt(iE);
        if (ch === '<' || ch === '&') {
            break;
        }
    }
    
    this._setContent(XMLP._CONT_XML, iB, iE);

    this.m_iP = iE;

    return XMLP._TEXT;

}

XMLP.prototype._replaceEntities = function(strD, iB, iE) {
    if(SAXStrings.isEmpty(strD)) return "";
    iB = iB || 0;
    iE = iE || strD.length;


    var iEB, iEE, strRet = "";

    iEB = strD.indexOf("&", iB);
    iEE = iB;

    while((iEB > 0) && (iEB < iE)) {
        strRet += strD.substring(iEE, iEB);

        iEE = strD.indexOf(";", iEB) + 1;

        if((iEE == 0) || (iEE > iE)) {
            return this._setErr(XMLP.ERR_CLOSE_ENTITY);
        }

        iRet = this._replaceEntity(strD, iEB + 1, iEE - 1);
        if(iRet == XMLP._ERROR) {
            return iRet;
        }

        strRet += this.m_cAlt;

        iEB = strD.indexOf("&", iEE);
    }

    if(iEE != iE) {
        strRet += strD.substring(iEE, iE);
    }

    this._setContent(XMLP._CONT_ALT, strRet);

    return XMLP._ENTITY;

}

XMLP.prototype._replaceEntity = function(strD, iB, iE) {
    if(SAXStrings.isEmpty(strD)) return -1;
    iB = iB || 0;
    iE = iE || strD.length;

    switch(strD.substring(iB, iE)) {
        case "amp":  strEnt = "&";  break;
        case "lt":   strEnt = "<";  break;
        case "gt":   strEnt = ">";  break;
        case "apos": strEnt = "'";  break;
        case "quot": strEnt = "\""; break;
        case "nbsp":strEnt = ''; break;
        case "lt":strEnt = '<'; break;
        case "gt":strEnt = '>'; break;
        case "amp":strEnt = '&'; break;
        case "cent":strEnt = "¢"; break;
        case "pound":strEnt = '£'; break;
        case "yen":strEnt = '¥'; break;
        case "euro":strEnt = '€'; break;
        case "sect":strEnt = '§'; break;
        case "copy":strEnt = '©'; break;
        case "reg":strEnt = '®'; break;
        default:
            if(strD.charAt(iB) == "#") {
                strEnt = String.fromCharCode(parseInt(strD.substring(iB + 1, iE)));
            } else {
                strEnt = ' ';
                //return this._setErr(XMLP.ERR_ENTITY_UNKNOWN);
            }
        break;
    }
    this._setContent(XMLP._CONT_ALT, strEnt);

    return XMLP._ENTITY;
}

XMLP.prototype._setContent = function(iSrc) {
    var args = arguments;

    if(XMLP._CONT_XML == iSrc) {
        this.m_cAlt = null;
        this.m_cB = args[1];
        this.m_cE = args[2];
    } else {
        this.m_cAlt = args[1];
        this.m_cB = 0;
        this.m_cE = args[1].length;
    }
    this.m_cSrc = iSrc;

}

XMLP.prototype._setErr = function(iErr) {
    var strErr = XMLP._errs[iErr];

    this.m_cAlt = strErr;
    this.m_cB = 0;
    this.m_cE = strErr.length;
    this.m_cSrc = XMLP._CONT_ALT;

    return XMLP._ERROR;

}  // end function _setErr


//SaxParser is an object that basically wraps an XMLP instance, and provides an
//event-based interface for parsing. This is the object users interact with when coding
//with XML for <SCRIPT>
var SaxParser = function(eventhandlerfactory) {

    var eventhandler = new function(){

    }

    var thehandler = function() {};
    thehandler.prototype.onStartDocument = function (funct){
      eventhandler.onStartDocument = funct;
    }
    thehandler.prototype.onEndDocument = function (funct){
      eventhandler.onEndDocument = funct;
    }
    thehandler.prototype.onStartElementNS = function (funct){
      eventhandler.onStartElementNS = funct;
    }
    thehandler.prototype.onEndElementNS = function (funct){
      eventhandler.onEndElementNS = funct;
    }
    thehandler.prototype.onCharacters = function(funct) {
      eventhandler.onCharacters = funct;
    }
    thehandler.prototype.onCdata = function(funct) {
      eventhandler.onCdata = funct;
    }
    thehandler.prototype.onComment = function(funct) {
      eventhandler.onComment = funct;
    }
    thehandler.prototype.onWarning = function(funct) {
      eventhandler.onWarning = funct;
    }

    thehandler.prototype.onError = function(funct) {
      eventhandler.onError = funct;
    }


    eventhandlerfactory(new thehandler());
    //eventhandler = eventhandler(eventhandler);
    this.m_hndDoc = eventhandler;
    this.m_hndErr = eventhandler;
    this.m_hndLex = eventhandler;
    this.m_interrupted = false;
}


// CONSTANTS    (these must be below the constructor)
SaxParser.DOC_B = 1;
SaxParser.DOC_E = 2;
SaxParser.ELM_B = 3;
SaxParser.ELM_E = 4;
SaxParser.CHARS = 5;
SaxParser.PI    = 6;
SaxParser.CD_B  = 7;
SaxParser.CD_E  = 8;
SaxParser.CMNT  = 9;
SaxParser.DTD_B = 10;
SaxParser.DTD_E = 11;

SaxParser.prototype.parseFile = function(filename) { //This function will only work in the node.js environment.
    var fs = require('fs');
    var that = this;
    fs.readFile(filename, function (err, data) {
      that.parseString(data);
    });
}


SaxParser.prototype.parseString = function(strD) {
    util = require('util');
    var that = this;
    var startnew = true;
    if(!that.m_parser){
        that.m_parser = new XMLP(strD);
        startnew = false;
    }
    else{
        that.m_parser.continueParsing(strD);
        startnew = true;
    }

    //if(that.m_hndDoc && that.m_hndDoc.setDocumentLocator) {
    //    that.m_hndDoc.setDocumentLocator(that);
    //}

    that.m_bErr = false;

    if(!that.m_bErr && !startnew) {
        that._fireEvent(SaxParser.DOC_B);
    }
    that._parseLoop();
    if(!that.m_bErr && !that.m_interrupted) {
        that._fireEvent(SaxParser.DOC_E);
    }

    that.m_xml = null;
    that.m_iP = 0;
    that.m_interrupted = false;
}

SaxParser.prototype.pause = function() {
    this.m_parser.pause();
}

SaxParser.prototype.resume = function() {
    //reset the state
    this.m_parser.resume();
    this.m_interrupted = false;
    
    //now start up the parse loop
    var that = this;
    setTimeout(function(){
            that._parseLoop();
            if(!that.m_bErr && !that.m_interrupted) {
                that._fireEvent(SaxParser.DOC_E);
            }
    }, 0);
}

SaxParser.prototype.setDocumentHandler = function(hnd) {
    this.m_hndDoc = hnd;
}

SaxParser.prototype.setErrorHandler = function(hnd) {
    this.m_hndErr = hnd;
}

SaxParser.prototype.setLexicalHandler = function(hnd) {
    this.m_hndLex = hnd;
}

SaxParser.prototype.getColumnNumber = function() {
    return this.m_parser.getColumnNumber();
}

SaxParser.prototype.getLineNumber = function() {
    return this.m_parser.getLineNumber();
}

SaxParser.prototype.getMessage = function() {
    return this.m_strErrMsg;
}

SaxParser.prototype.getPublicId = function() {
    return null;
}

SaxParser.prototype.getSystemId = function() {
    return null;
}

SaxParser.prototype.getLength = function() {
    return this.m_parser.getAttributeCount();
}

SaxParser.prototype.getName = function(index) {
    return this.m_parser.getAttributeName(index);
}

SaxParser.prototype.getValue = function(index) {
    return this.m_parser.getAttributeValue(index);
}

SaxParser.prototype.getValueByName = function(name) {
    return this.m_parser.getAttributeValueByName(name);
}

SaxParser.prototype._fireError = function(strMsg) {
    this.m_strErrMsg = strMsg;
    this.m_bErr = true;

    if(this.m_hndErr && this.m_hndErr.onError) {
        this.m_hndErr.onError(this.m_strErrMsg);
    }
}



SaxParser.prototype._fireEvent = function(iEvt) {
    var hnd, func, args = arguments, iLen = args.length - 1;


    if(this.m_bErr) return;

    if(SaxParser.DOC_B == iEvt) {
        func = "onStartDocument";         hnd = this.m_hndDoc;
    }
    else if (SaxParser.DOC_E == iEvt) {
        func = "onEndDocument";           hnd = this.m_hndDoc;
    }
    else if (SaxParser.ELM_B == iEvt) {
        func = "onStartElementNS";          hnd = this.m_hndDoc;
    }
    else if (SaxParser.ELM_E == iEvt) {
        func = "onEndElementNS";            hnd = this.m_hndDoc;
    }
    else if (SaxParser.CHARS == iEvt) {
        func = "onCharacters";            hnd = this.m_hndDoc;
    }
    else if (SaxParser.PI    == iEvt) {
        func = "processingInstruction"; hnd = this.m_hndDoc;
    }
    else if (SaxParser.CD_B  == iEvt) {
        func = "onCdata";            hnd = this.m_hndLex;
    }
    else if (SaxParser.CD_E  == iEvt) {
        func = "onEndCDATA";              hnd = this.m_hndLex;
    }
    else if (SaxParser.CMNT  == iEvt) {
        func = "onComment";               hnd = this.m_hndLex;
    }

    if(hnd && hnd[func]) {
        if(0 == iLen) {
            hnd[func]();
        }
        else if (1 == iLen) {
            hnd[func](args[1]);
        }
        else if (2 == iLen) {
            hnd[func](args[1], args[2]);
        }
        else if (3 == iLen) {
            hnd[func](args[1], args[2], args[3]);
        }
        else if (4 == iLen) {
            hnd[func](args[1], args[2], args[3], args[4]);
        }
        else if (5 == iLen) {
            hnd[func](args[1], args[2], args[3], args[4], args[5]);
        }
        else if (6 == iLen) {
            hnd[func](args[1], args[2], args[3], args[4], args[5], args[6]);
        }
    }

}




SaxParser.prototype._parseLoop = function(parser) {
    var iEvent, parser;

    parser = this.m_parser;
    while(!this.m_bErr) {
        iEvent = parser.next();

        if(iEvent == XMLP._ELM_B) {
            theatts = this.m_parser.m_atts;
            nameobject = parser._parsePrefixAndElementName(parser.getName());
            theattsandnamespace = parser._parseNamespacesAndAtts(theatts);
            var theuri = parser._getContextualNamespace(nameobject.prefix);
            this._fireEvent(SaxParser.ELM_B, nameobject.name, theattsandnamespace[0], (nameobject.prefix === '')? null : nameobject.prefix, (theuri === '')? null : theuri ,theattsandnamespace[1] );
        }
        else if(iEvent == XMLP._ELM_E) {
            nameobject = parser._parsePrefixAndElementName(parser.getName());
            var theuri = parser._getContextualNamespace(nameobject.prefix);
            parser._removeExpiredNamesapces(parser.getName());
            this._fireEvent(SaxParser.ELM_E, nameobject.name, (nameobject.prefix === '')? null : nameobject.prefix, (theuri === '')? null : theuri);
        }
        else if(iEvent == XMLP._ELM_EMP) {
            //this is both a begin and end element
            theatts = this.m_parser.m_atts;
            nameobject = parser._parsePrefixAndElementName(parser.getName());
            theattsandnamespace = parser._parseNamespacesAndAtts(theatts);
            var theuri = parser._getContextualNamespace(nameobject.prefix);
            this._fireEvent(SaxParser.ELM_B, nameobject.name, theattsandnamespace[0], (nameobject.prefix === '')? null : nameobject.prefix, (theuri === '')? null : theuri ,theattsandnamespace[1], true );

            parser._removeExpiredNamesapces(parser.getName());
            this._fireEvent(SaxParser.ELM_E, nameobject.name, (nameobject.prefix === '')? null : nameobject.prefix, (theuri === '')? null : theuri, true);
            //this._fireEvent(SaxParser.ELM_B, parser.getName(), this.m_parser.m_atts.map(function(item){return { name : item[0], value : item[1], };}) );
            //this._fireEvent(SaxParser.ELM_E, parser.getName());
        }
        else if(iEvent == XMLP._TEXT) {
            this._fireEvent(SaxParser.CHARS, parser.getContent().slice(parser.getContentBegin(),parser.getContentEnd()));
        }
        else if(iEvent == XMLP._ENTITY) {
            this._fireEvent(SaxParser.CHARS, parser.getContent(), parser.getContentBegin(), parser.getContentEnd() - parser.getContentBegin());
        }
        else if(iEvent == XMLP._PI) {
            this._fireEvent(SaxParser.PI, parser.getName(), parser.getContent().substring(parser.getContentBegin(), parser.getContentEnd()));
        }
        else if(iEvent == XMLP._CDATA) {
            this._fireEvent(SaxParser.CD_B, parser.getContent().slice(parser.getContentBegin(),parser.getContentEnd()));
            //this._fireEvent(SaxParser.CHARS, parser.getContent(), parser.getContentBegin(), parser.getContentEnd() - parser.getContentBegin());
            //this._fireEvent(SaxParser.CD_E);
        }
        else if(iEvent == XMLP._COMMENT) {
            this._fireEvent(SaxParser.CMNT, parser.getContent().slice(parser.getContentBegin(),parser.getContentEnd()));
        }
        else if(iEvent == XMLP._DTD) {
        }
        else if(iEvent == XMLP._ERROR) {
            this._fireError(parser.getContent());
        }
        else if(iEvent == XMLP._INTERRUPT){
            this.m_interrupted = true;
            return;//just return and wait to be restarted
        }
        else if(iEvent == XMLP._NONE) {
            return;
        }
    }

}

//SAXStrings: a useful object containing string manipulation functions
var SAXStrings = function() {
//This is the constructor of the SAXStrings object
}


// CONSTANTS    (these must be below the constructor)
SAXStrings.WHITESPACE = " \t\n\r";
SAXStrings.QUOTES = "\"'";


SAXStrings.getColumnNumber = function(strD, iP) {
    if(SAXStrings.isEmpty(strD)) {
        return -1;
    }
    iP = iP || strD.length;

    var arrD = strD.substring(0, iP).split("\n");
    var strLine = arrD[arrD.length - 1];
    arrD.length--;
    var iLinePos = arrD.join("\n").length;

    return iP - iLinePos;

}

SAXStrings.getLineNumber = function(strD, iP) {
    if(SAXStrings.isEmpty(strD)) {
        return -1;
    }
    iP = iP || strD.length;

    return strD.substring(0, iP).split("\n").length
}

SAXStrings.indexOfNonWhitespace = function(strD, iB, iE) {
    if(SAXStrings.isEmpty(strD)) {
        return -1;
    }
    iB = iB || 0;
    iE = iE || strD.length;

    for(var i = iB; i < iE; i++){
        if(SAXStrings.WHITESPACE.indexOf(strD.charAt(i)) == -1) {
            return i;
        }
    }
    return -1;
}

SAXStrings.indexOfWhitespace = function(strD, iB, iE) {
    if(SAXStrings.isEmpty(strD)) {
        return -1;
    }
    iB = iB || 0;
    iE = iE || strD.length;

    for(var i = iB; i < iE; i++) {
        if(SAXStrings.WHITESPACE.indexOf(strD.charAt(i)) != -1) {
            return i;
        }
    }
    return -1;
}

SAXStrings.isEmpty = function(strD) {
    return (strD == null) || (strD.length == 0);
}

SAXStrings.lastIndexOfNonWhitespace = function(strD, iB, iE) {
    if(SAXStrings.isEmpty(strD)) {
        return -1;
    }
    iB = iB || 0;
    iE = iE || strD.length;

    for(var i = iE - 1; i >= iB; i--){
        if(SAXStrings.WHITESPACE.indexOf(strD.charAt(i)) == -1){
            return i;
        }
    }
    return -1;
}

SAXStrings.replace = function(strD, iB, iE, strF, strR) {
    if(SAXStrings.isEmpty(strD)) {
        return "";
    }
    iB = iB || 0;
    iE = iE || strD.length;

    return strD.toString().substring(iB, iE).split(strF).join(strR);

}

var Stack = function() {
    this.m_arr = new Array();
}

Stack.prototype.clear = function() {
    this.m_arr = new Array();
}

Stack.prototype.count = function() {
    return this.m_arr.length;
}

Stack.prototype.destroy = function() {
    this.m_arr = null;
}

Stack.prototype.peek = function() {
    if(this.m_arr.length == 0) {
        return null;
    }

    return this.m_arr[this.m_arr.length - 1];

}

Stack.prototype.pop = function() {
    if(this.m_arr.length == 0) {
        return null;
    }

    var o = this.m_arr[this.m_arr.length - 1];
    this.m_arr.length--;
    return o;

}

Stack.prototype.push = function(o) {
    this.m_arr[this.m_arr.length] = o;
}

// CONVENIENCE FUNCTIONS
function isEmpty(str) {
     return (str==null) || (str.length==0);
}


function trim(trimString, leftTrim, rightTrim) {
    if (isEmpty(trimString)) {
        return "";
    }

    // the general focus here is on minimal method calls - hence only one
    // substring is done to complete the trim.

    if (leftTrim == null) {
        leftTrim = true;
    }

    if (rightTrim == null) {
        rightTrim = true;
    }

    var left=0;
    var right=0;
    var i=0;
    var k=0;


    // modified to properly handle strings that are all whitespace
    if (leftTrim == true) {
        while ((i<trimString.length) && (whitespace.indexOf(trimString.charAt(i++))!=-1)) {
            left++;
        }
    }
    if (rightTrim == true) {
        k=trimString.length-1;
        while((k>=left) && (whitespace.indexOf(trimString.charAt(k--))!=-1)) {
            right++;
        }
    }
    return trimString.substring(left, trimString.length - right);
}

function __escapeString(str) {

    var escAmpRegEx = /&/g;
    var escLtRegEx = /</g;
    var escGtRegEx = />/g;
    var quotRegEx = /"/g;
    var aposRegEx = /'/g;

    str = str.replace(escAmpRegEx, "&amp;");
    str = str.replace(escLtRegEx, "&lt;");
    str = str.replace(escGtRegEx, "&gt;");
    str = str.replace(quotRegEx, "&quot;");
    str = str.replace(aposRegEx, "&apos;");

  return str;
}

function __unescapeString(str) {

    var escAmpRegEx = /&amp;/g;
    var escLtRegEx = /&lt;/g;
    var escGtRegEx = /&gt;/g;
    var quotRegEx = /&quot;/g;
    var aposRegEx = /&apos;/g;

    str = str.replace(escAmpRegEx, "&");
    str = str.replace(escLtRegEx, "<");
    str = str.replace(escGtRegEx, ">");
    str = str.replace(quotRegEx, "\"");
    str = str.replace(aposRegEx, "'");

  return str;
}

exports.SaxParser = SaxParser;


})()
