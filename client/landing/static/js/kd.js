(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
// Copyright 2011 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
var __extends = this.__extends || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    __.prototype = b.prototype;
    d.prototype = new __();
};
var MutationObserverCtor;
if (typeof WebKitMutationObserver !== 'undefined')
    MutationObserverCtor = WebKitMutationObserver;
else
    MutationObserverCtor = MutationObserver;

if (MutationObserverCtor === undefined) {
    console.error('DOM Mutation Observers are required.');
    console.error('https://developer.mozilla.org/en-US/docs/DOM/MutationObserver');
    throw Error('DOM Mutation Observers are required');
}

var NodeMap = (function () {
    function NodeMap() {
        this.nodes = [];
        this.values = [];
    }
    NodeMap.prototype.isIndex = function (s) {
        return +s === s >>> 0;
    };

    NodeMap.prototype.nodeId = function (node) {
        var id = node[NodeMap.ID_PROP];
        if (!id)
            id = node[NodeMap.ID_PROP] = NodeMap.nextId_++;
        return id;
    };

    NodeMap.prototype.set = function (node, value) {
        var id = this.nodeId(node);
        this.nodes[id] = node;
        this.values[id] = value;
    };

    NodeMap.prototype.get = function (node) {
        var id = this.nodeId(node);
        return this.values[id];
    };

    NodeMap.prototype.has = function (node) {
        return this.nodeId(node) in this.nodes;
    };

    NodeMap.prototype.delete = function (node) {
        var id = this.nodeId(node);
        delete this.nodes[id];
        this.values[id] = undefined;
    };

    NodeMap.prototype.keys = function () {
        var nodes = [];
        for (var id in this.nodes) {
            if (!this.isIndex(id))
                continue;
            nodes.push(this.nodes[id]);
        }

        return nodes;
    };
    NodeMap.ID_PROP = '__mutation_summary_node_map_id__';
    NodeMap.nextId_ = 1;
    return NodeMap;
})();

/**
*  var reachableMatchableProduct = [
*  //  STAYED_OUT,  ENTERED,     STAYED_IN,   EXITED
*    [ STAYED_OUT,  STAYED_OUT,  STAYED_OUT,  STAYED_OUT ], // STAYED_OUT
*    [ STAYED_OUT,  ENTERED,     ENTERED,     STAYED_OUT ], // ENTERED
*    [ STAYED_OUT,  ENTERED,     STAYED_IN,   EXITED     ], // STAYED_IN
*    [ STAYED_OUT,  STAYED_OUT,  EXITED,      EXITED     ]  // EXITED
*  ];
*/
var Movement;
(function (Movement) {
    Movement[Movement["STAYED_OUT"] = 0] = "STAYED_OUT";
    Movement[Movement["ENTERED"] = 1] = "ENTERED";
    Movement[Movement["STAYED_IN"] = 2] = "STAYED_IN";
    Movement[Movement["REPARENTED"] = 3] = "REPARENTED";
    Movement[Movement["REORDERED"] = 4] = "REORDERED";
    Movement[Movement["EXITED"] = 5] = "EXITED";
})(Movement || (Movement = {}));

function enteredOrExited(changeType) {
    return changeType === 1 /* ENTERED */ || changeType === 5 /* EXITED */;
}

var NodeChange = (function () {
    function NodeChange(node, childList, attributes, characterData, oldParentNode, added, attributeOldValues, characterDataOldValue) {
        if (typeof childList === "undefined") { childList = false; }
        if (typeof attributes === "undefined") { attributes = false; }
        if (typeof characterData === "undefined") { characterData = false; }
        if (typeof oldParentNode === "undefined") { oldParentNode = null; }
        if (typeof added === "undefined") { added = false; }
        if (typeof attributeOldValues === "undefined") { attributeOldValues = null; }
        if (typeof characterDataOldValue === "undefined") { characterDataOldValue = null; }
        this.node = node;
        this.childList = childList;
        this.attributes = attributes;
        this.characterData = characterData;
        this.oldParentNode = oldParentNode;
        this.added = added;
        this.attributeOldValues = attributeOldValues;
        this.characterDataOldValue = characterDataOldValue;
        this.isCaseInsensitive = this.node.nodeType === Node.ELEMENT_NODE && this.node instanceof HTMLElement && this.node.ownerDocument instanceof HTMLDocument;
    }
    NodeChange.prototype.getAttributeOldValue = function (name) {
        if (!this.attributeOldValues)
            return undefined;
        if (this.isCaseInsensitive)
            name = name.toLowerCase();
        return this.attributeOldValues[name];
    };

    NodeChange.prototype.getAttributeNamesMutated = function () {
        var names = [];
        if (!this.attributeOldValues)
            return names;
        for (var name in this.attributeOldValues) {
            names.push(name);
        }
        return names;
    };

    NodeChange.prototype.attributeMutated = function (name, oldValue) {
        this.attributes = true;
        this.attributeOldValues = this.attributeOldValues || {};

        if (name in this.attributeOldValues)
            return;

        this.attributeOldValues[name] = oldValue;
    };

    NodeChange.prototype.characterDataMutated = function (oldValue) {
        if (this.characterData)
            return;
        this.characterData = true;
        this.characterDataOldValue = oldValue;
    };

    // Note: is it possible to receive a removal followed by a removal. This
    // can occur if the removed node is added to an non-observed node, that
    // node is added to the observed area, and then the node removed from
    // it.
    NodeChange.prototype.removedFromParent = function (parent) {
        this.childList = true;
        if (this.added || this.oldParentNode)
            this.added = false;
        else
            this.oldParentNode = parent;
    };

    NodeChange.prototype.insertedIntoParent = function () {
        this.childList = true;
        this.added = true;
    };

    // An node's oldParent is
    //   -its present parent, if its parentNode was not changed.
    //   -null if the first thing that happened to it was an add.
    //   -the node it was removed from if the first thing that happened to it
    //      was a remove.
    NodeChange.prototype.getOldParent = function () {
        if (this.childList) {
            if (this.oldParentNode)
                return this.oldParentNode;
            if (this.added)
                return null;
        }

        return this.node.parentNode;
    };
    return NodeChange;
})();

var ChildListChange = (function () {
    function ChildListChange() {
        this.added = new NodeMap();
        this.removed = new NodeMap();
        this.maybeMoved = new NodeMap();
        this.oldPrevious = new NodeMap();
        this.moved = undefined;
    }
    return ChildListChange;
})();

var TreeChanges = (function (_super) {
    __extends(TreeChanges, _super);
    function TreeChanges(rootNode, mutations) {
        _super.call(this);

        this.rootNode = rootNode;
        this.reachableCache = undefined;
        this.wasReachableCache = undefined;
        this.anyParentsChanged = false;
        this.anyAttributesChanged = false;
        this.anyCharacterDataChanged = false;

        for (var m = 0; m < mutations.length; m++) {
            var mutation = mutations[m];
            switch (mutation.type) {
                case 'childList':
                    this.anyParentsChanged = true;
                    for (var i = 0; i < mutation.removedNodes.length; i++) {
                        var node = mutation.removedNodes[i];
                        this.getChange(node).removedFromParent(mutation.target);
                    }
                    for (var i = 0; i < mutation.addedNodes.length; i++) {
                        var node = mutation.addedNodes[i];
                        this.getChange(node).insertedIntoParent();
                    }
                    break;

                case 'attributes':
                    this.anyAttributesChanged = true;
                    var change = this.getChange(mutation.target);
                    change.attributeMutated(mutation.attributeName, mutation.oldValue);
                    break;

                case 'characterData':
                    this.anyCharacterDataChanged = true;
                    var change = this.getChange(mutation.target);
                    change.characterDataMutated(mutation.oldValue);
                    break;
            }
        }
    }
    TreeChanges.prototype.getChange = function (node) {
        var change = this.get(node);
        if (!change) {
            change = new NodeChange(node);
            this.set(node, change);
        }
        return change;
    };

    TreeChanges.prototype.getOldParent = function (node) {
        var change = this.get(node);
        return change ? change.getOldParent() : node.parentNode;
    };

    TreeChanges.prototype.getIsReachable = function (node) {
        if (node === this.rootNode)
            return true;
        if (!node)
            return false;

        this.reachableCache = this.reachableCache || new NodeMap();
        var isReachable = this.reachableCache.get(node);
        if (isReachable === undefined) {
            isReachable = this.getIsReachable(node.parentNode);
            this.reachableCache.set(node, isReachable);
        }
        return isReachable;
    };

    // A node wasReachable if its oldParent wasReachable.
    TreeChanges.prototype.getWasReachable = function (node) {
        if (node === this.rootNode)
            return true;
        if (!node)
            return false;

        this.wasReachableCache = this.wasReachableCache || new NodeMap();
        var wasReachable = this.wasReachableCache.get(node);
        if (wasReachable === undefined) {
            wasReachable = this.getWasReachable(this.getOldParent(node));
            this.wasReachableCache.set(node, wasReachable);
        }
        return wasReachable;
    };

    TreeChanges.prototype.reachabilityChange = function (node) {
        if (this.getIsReachable(node)) {
            return this.getWasReachable(node) ? 2 /* STAYED_IN */ : 1 /* ENTERED */;
        }

        return this.getWasReachable(node) ? 5 /* EXITED */ : 0 /* STAYED_OUT */;
    };
    return TreeChanges;
})(NodeMap);

var MutationProjection = (function () {
    // TOOD(any)
    function MutationProjection(rootNode, mutations, selectors, calcReordered, calcOldPreviousSibling) {
        this.rootNode = rootNode;
        this.mutations = mutations;
        this.selectors = selectors;
        this.calcReordered = calcReordered;
        this.calcOldPreviousSibling = calcOldPreviousSibling;
        this.treeChanges = new TreeChanges(rootNode, mutations);
        this.entered = [];
        this.exited = [];
        this.stayedIn = new NodeMap();
        this.visited = new NodeMap();
        this.childListChangeMap = undefined;
        this.characterDataOnly = undefined;
        this.matchCache = undefined;

        this.processMutations();
    }
    MutationProjection.prototype.processMutations = function () {
        if (!this.treeChanges.anyParentsChanged && !this.treeChanges.anyAttributesChanged)
            return;

        var changedNodes = this.treeChanges.keys();
        for (var i = 0; i < changedNodes.length; i++) {
            this.visitNode(changedNodes[i], undefined);
        }
    };

    MutationProjection.prototype.visitNode = function (node, parentReachable) {
        if (this.visited.has(node))
            return;

        this.visited.set(node, true);

        var change = this.treeChanges.get(node);
        var reachable = parentReachable;

        // node inherits its parent's reachability change unless
        // its parentNode was mutated.
        if ((change && change.childList) || reachable == undefined)
            reachable = this.treeChanges.reachabilityChange(node);

        if (reachable === 0 /* STAYED_OUT */)
            return;

        // Cache match results for sub-patterns.
        this.matchabilityChange(node);

        if (reachable === 1 /* ENTERED */) {
            this.entered.push(node);
        } else if (reachable === 5 /* EXITED */) {
            this.exited.push(node);
            this.ensureHasOldPreviousSiblingIfNeeded(node);
        } else if (reachable === 2 /* STAYED_IN */) {
            var movement = 2 /* STAYED_IN */;

            if (change && change.childList) {
                if (change.oldParentNode !== node.parentNode) {
                    movement = 3 /* REPARENTED */;
                    this.ensureHasOldPreviousSiblingIfNeeded(node);
                } else if (this.calcReordered && this.wasReordered(node)) {
                    movement = 4 /* REORDERED */;
                }
            }

            this.stayedIn.set(node, movement);
        }

        if (reachable === 2 /* STAYED_IN */)
            return;

        for (var child = node.firstChild; child; child = child.nextSibling) {
            this.visitNode(child, reachable);
        }
    };

    MutationProjection.prototype.ensureHasOldPreviousSiblingIfNeeded = function (node) {
        if (!this.calcOldPreviousSibling)
            return;

        this.processChildlistChanges();

        var parentNode = node.parentNode;
        var nodeChange = this.treeChanges.get(node);
        if (nodeChange && nodeChange.oldParentNode)
            parentNode = nodeChange.oldParentNode;

        var change = this.childListChangeMap.get(parentNode);
        if (!change) {
            change = new ChildListChange();
            this.childListChangeMap.set(parentNode, change);
        }

        if (!change.oldPrevious.has(node)) {
            change.oldPrevious.set(node, node.previousSibling);
        }
    };

    MutationProjection.prototype.getChanged = function (summary, selectors, characterDataOnly) {
        this.selectors = selectors;
        this.characterDataOnly = characterDataOnly;

        for (var i = 0; i < this.entered.length; i++) {
            var node = this.entered[i];
            var matchable = this.matchabilityChange(node);
            if (matchable === 1 /* ENTERED */ || matchable === 2 /* STAYED_IN */)
                summary.added.push(node);
        }

        var stayedInNodes = this.stayedIn.keys();
        for (var i = 0; i < stayedInNodes.length; i++) {
            var node = stayedInNodes[i];
            var matchable = this.matchabilityChange(node);

            if (matchable === 1 /* ENTERED */) {
                summary.added.push(node);
            } else if (matchable === 5 /* EXITED */) {
                summary.removed.push(node);
            } else if (matchable === 2 /* STAYED_IN */ && (summary.reparented || summary.reordered)) {
                var movement = this.stayedIn.get(node);
                if (summary.reparented && movement === 3 /* REPARENTED */)
                    summary.reparented.push(node);
                else if (summary.reordered && movement === 4 /* REORDERED */)
                    summary.reordered.push(node);
            }
        }

        for (var i = 0; i < this.exited.length; i++) {
            var node = this.exited[i];
            var matchable = this.matchabilityChange(node);
            if (matchable === 5 /* EXITED */ || matchable === 2 /* STAYED_IN */)
                summary.removed.push(node);
        }
    };

    MutationProjection.prototype.getOldParentNode = function (node) {
        var change = this.treeChanges.get(node);
        if (change && change.childList)
            return change.oldParentNode ? change.oldParentNode : null;

        var reachabilityChange = this.treeChanges.reachabilityChange(node);
        if (reachabilityChange === 0 /* STAYED_OUT */ || reachabilityChange === 1 /* ENTERED */)
            throw Error('getOldParentNode requested on invalid node.');

        return node.parentNode;
    };

    MutationProjection.prototype.getOldPreviousSibling = function (node) {
        var parentNode = node.parentNode;
        var nodeChange = this.treeChanges.get(node);
        if (nodeChange && nodeChange.oldParentNode)
            parentNode = nodeChange.oldParentNode;

        var change = this.childListChangeMap.get(parentNode);
        if (!change)
            throw Error('getOldPreviousSibling requested on invalid node.');

        return change.oldPrevious.get(node);
    };

    MutationProjection.prototype.getOldAttribute = function (element, attrName) {
        var change = this.treeChanges.get(element);
        if (!change || !change.attributes)
            throw Error('getOldAttribute requested on invalid node.');

        var value = change.getAttributeOldValue(attrName);
        if (value === undefined)
            throw Error('getOldAttribute requested for unchanged attribute name.');

        return value;
    };

    MutationProjection.prototype.attributeChangedNodes = function (includeAttributes) {
        if (!this.treeChanges.anyAttributesChanged)
            return {};

        var attributeFilter;
        var caseInsensitiveFilter;
        if (includeAttributes) {
            attributeFilter = {};
            caseInsensitiveFilter = {};
            for (var i = 0; i < includeAttributes.length; i++) {
                var attrName = includeAttributes[i];
                attributeFilter[attrName] = true;
                caseInsensitiveFilter[attrName.toLowerCase()] = attrName;
            }
        }

        var result = {};
        var nodes = this.treeChanges.keys();

        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i];

            var change = this.treeChanges.get(node);
            if (!change.attributes)
                continue;

            if (2 /* STAYED_IN */ !== this.treeChanges.reachabilityChange(node) || 2 /* STAYED_IN */ !== this.matchabilityChange(node)) {
                continue;
            }

            var element = node;
            var changedAttrNames = change.getAttributeNamesMutated();
            for (var j = 0; j < changedAttrNames.length; j++) {
                var attrName = changedAttrNames[j];

                if (attributeFilter && !attributeFilter[attrName] && !(change.isCaseInsensitive && caseInsensitiveFilter[attrName])) {
                    continue;
                }

                var oldValue = change.getAttributeOldValue(attrName);
                if (oldValue === element.getAttribute(attrName))
                    continue;

                if (caseInsensitiveFilter && change.isCaseInsensitive)
                    attrName = caseInsensitiveFilter[attrName];

                result[attrName] = result[attrName] || [];
                result[attrName].push(element);
            }
        }

        return result;
    };

    MutationProjection.prototype.getOldCharacterData = function (node) {
        var change = this.treeChanges.get(node);
        if (!change || !change.characterData)
            throw Error('getOldCharacterData requested on invalid node.');

        return change.characterDataOldValue;
    };

    MutationProjection.prototype.getCharacterDataChanged = function () {
        if (!this.treeChanges.anyCharacterDataChanged)
            return [];

        var nodes = this.treeChanges.keys();
        var result = [];
        for (var i = 0; i < nodes.length; i++) {
            var target = nodes[i];
            if (2 /* STAYED_IN */ !== this.treeChanges.reachabilityChange(target))
                continue;

            var change = this.treeChanges.get(target);
            if (!change.characterData || target.textContent == change.characterDataOldValue)
                continue;

            result.push(target);
        }

        return result;
    };

    MutationProjection.prototype.computeMatchabilityChange = function (selector, el) {
        if (!this.matchCache)
            this.matchCache = [];
        if (!this.matchCache[selector.uid])
            this.matchCache[selector.uid] = new NodeMap();

        var cache = this.matchCache[selector.uid];
        var result = cache.get(el);
        if (result === undefined) {
            result = selector.matchabilityChange(el, this.treeChanges.get(el));
            cache.set(el, result);
        }
        return result;
    };

    MutationProjection.prototype.matchabilityChange = function (node) {
        var _this = this;
        // TODO(rafaelw): Include PI, CDATA?
        // Only include text nodes.
        if (this.characterDataOnly) {
            switch (node.nodeType) {
                case Node.COMMENT_NODE:
                case Node.TEXT_NODE:
                    return 2 /* STAYED_IN */;
                default:
                    return 0 /* STAYED_OUT */;
            }
        }

        // No element filter. Include all nodes.
        if (!this.selectors)
            return 2 /* STAYED_IN */;

        // Element filter. Exclude non-elements.
        if (node.nodeType !== Node.ELEMENT_NODE)
            return 0 /* STAYED_OUT */;

        var el = node;

        var matchChanges = this.selectors.map(function (selector) {
            return _this.computeMatchabilityChange(selector, el);
        });

        var accum = 0 /* STAYED_OUT */;
        var i = 0;

        while (accum !== 2 /* STAYED_IN */ && i < matchChanges.length) {
            switch (matchChanges[i]) {
                case 2 /* STAYED_IN */:
                    accum = 2 /* STAYED_IN */;
                    break;
                case 1 /* ENTERED */:
                    if (accum === 5 /* EXITED */)
                        accum = 2 /* STAYED_IN */;
                    else
                        accum = 1 /* ENTERED */;
                    break;
                case 5 /* EXITED */:
                    if (accum === 1 /* ENTERED */)
                        accum = 2 /* STAYED_IN */;
                    else
                        accum = 5 /* EXITED */;
                    break;
            }

            i++;
        }

        return accum;
    };

    MutationProjection.prototype.getChildlistChange = function (el) {
        var change = this.childListChangeMap.get(el);
        if (!change) {
            change = new ChildListChange();
            this.childListChangeMap.set(el, change);
        }

        return change;
    };

    MutationProjection.prototype.processChildlistChanges = function () {
        if (this.childListChangeMap)
            return;

        this.childListChangeMap = new NodeMap();

        for (var i = 0; i < this.mutations.length; i++) {
            var mutation = this.mutations[i];
            if (mutation.type != 'childList')
                continue;

            if (this.treeChanges.reachabilityChange(mutation.target) !== 2 /* STAYED_IN */ && !this.calcOldPreviousSibling)
                continue;

            var change = this.getChildlistChange(mutation.target);

            var oldPrevious = mutation.previousSibling;

            function recordOldPrevious(node, previous) {
                if (!node || change.oldPrevious.has(node) || change.added.has(node) || change.maybeMoved.has(node))
                    return;

                if (previous && (change.added.has(previous) || change.maybeMoved.has(previous)))
                    return;

                change.oldPrevious.set(node, previous);
            }

            for (var j = 0; j < mutation.removedNodes.length; j++) {
                var node = mutation.removedNodes[j];
                recordOldPrevious(node, oldPrevious);

                if (change.added.has(node)) {
                    change.added.delete(node);
                } else {
                    change.removed.set(node, true);
                    change.maybeMoved.delete(node);
                }

                oldPrevious = node;
            }

            recordOldPrevious(mutation.nextSibling, oldPrevious);

            for (var j = 0; j < mutation.addedNodes.length; j++) {
                var node = mutation.addedNodes[j];
                if (change.removed.has(node)) {
                    change.removed.delete(node);
                    change.maybeMoved.set(node, true);
                } else {
                    change.added.set(node, true);
                }
            }
        }
    };

    MutationProjection.prototype.wasReordered = function (node) {
        if (!this.treeChanges.anyParentsChanged)
            return false;

        this.processChildlistChanges();

        var parentNode = node.parentNode;
        var nodeChange = this.treeChanges.get(node);
        if (nodeChange && nodeChange.oldParentNode)
            parentNode = nodeChange.oldParentNode;

        var change = this.childListChangeMap.get(parentNode);
        if (!change)
            return false;

        if (change.moved)
            return change.moved.get(node);

        change.moved = new NodeMap();
        var pendingMoveDecision = new NodeMap();

        function isMoved(node) {
            if (!node)
                return false;
            if (!change.maybeMoved.has(node))
                return false;

            var didMove = change.moved.get(node);
            if (didMove !== undefined)
                return didMove;

            if (pendingMoveDecision.has(node)) {
                didMove = true;
            } else {
                pendingMoveDecision.set(node, true);
                didMove = getPrevious(node) !== getOldPrevious(node);
            }

            if (pendingMoveDecision.has(node)) {
                pendingMoveDecision.delete(node);
                change.moved.set(node, didMove);
            } else {
                didMove = change.moved.get(node);
            }

            return didMove;
        }

        var oldPreviousCache = new NodeMap();
        function getOldPrevious(node) {
            var oldPrevious = oldPreviousCache.get(node);
            if (oldPrevious !== undefined)
                return oldPrevious;

            oldPrevious = change.oldPrevious.get(node);
            while (oldPrevious && (change.removed.has(oldPrevious) || isMoved(oldPrevious))) {
                oldPrevious = getOldPrevious(oldPrevious);
            }

            if (oldPrevious === undefined)
                oldPrevious = node.previousSibling;
            oldPreviousCache.set(node, oldPrevious);

            return oldPrevious;
        }

        var previousCache = new NodeMap();
        function getPrevious(node) {
            if (previousCache.has(node))
                return previousCache.get(node);

            var previous = node.previousSibling;
            while (previous && (change.added.has(previous) || isMoved(previous)))
                previous = previous.previousSibling;

            previousCache.set(node, previous);
            return previous;
        }

        change.maybeMoved.keys().forEach(isMoved);
        return change.moved.get(node);
    };
    return MutationProjection;
})();

var Summary = (function () {
    function Summary(projection, query) {
        var _this = this;
        this.projection = projection;
        this.added = [];
        this.removed = [];
        this.reparented = query.all || query.element ? [] : undefined;
        this.reordered = query.all ? [] : undefined;

        projection.getChanged(this, query.elementFilter, query.characterData);

        if (query.all || query.attribute || query.attributeList) {
            var filter = query.attribute ? [query.attribute] : query.attributeList;
            var attributeChanged = projection.attributeChangedNodes(filter);

            if (query.attribute) {
                this.valueChanged = attributeChanged[query.attribute] || [];
            } else {
                this.attributeChanged = attributeChanged;
                if (query.attributeList) {
                    query.attributeList.forEach(function (attrName) {
                        if (!_this.attributeChanged.hasOwnProperty(attrName))
                            _this.attributeChanged[attrName] = [];
                    });
                }
            }
        }

        if (query.all || query.characterData) {
            var characterDataChanged = projection.getCharacterDataChanged();

            if (query.characterData)
                this.valueChanged = characterDataChanged;
            else
                this.characterDataChanged = characterDataChanged;
        }

        if (this.reordered)
            this.getOldPreviousSibling = projection.getOldPreviousSibling.bind(projection);
    }
    Summary.prototype.getOldParentNode = function (node) {
        return this.projection.getOldParentNode(node);
    };

    Summary.prototype.getOldAttribute = function (node, name) {
        return this.projection.getOldAttribute(node, name);
    };

    Summary.prototype.getOldCharacterData = function (node) {
        return this.projection.getOldCharacterData(node);
    };

    Summary.prototype.getOldPreviousSibling = function (node) {
        return this.projection.getOldPreviousSibling(node);
    };
    return Summary;
})();

// TODO(rafaelw): Allow ':' and '.' as valid name characters.
var validNameInitialChar = /[a-zA-Z_]+/;
var validNameNonInitialChar = /[a-zA-Z0-9_\-]+/;

// TODO(rafaelw): Consider allowing backslash in the attrValue.
// TODO(rafaelw): There's got a to be way to represent this state machine
// more compactly???
function escapeQuotes(value) {
    return '"' + value.replace(/"/, '\\\"') + '"';
}

var Qualifier = (function () {
    function Qualifier() {
    }
    Qualifier.prototype.matches = function (oldValue) {
        if (oldValue === null)
            return false;

        if (this.attrValue === undefined)
            return true;

        if (!this.contains)
            return this.attrValue == oldValue;

        var tokens = oldValue.split(' ');
        for (var i = 0; i < tokens.length; i++) {
            if (this.attrValue === tokens[i])
                return true;
        }

        return false;
    };

    Qualifier.prototype.toString = function () {
        if (this.attrName === 'class' && this.contains)
            return '.' + this.attrValue;

        if (this.attrName === 'id' && !this.contains)
            return '#' + this.attrValue;

        if (this.contains)
            return '[' + this.attrName + '~=' + escapeQuotes(this.attrValue) + ']';

        if ('attrValue' in this)
            return '[' + this.attrName + '=' + escapeQuotes(this.attrValue) + ']';

        return '[' + this.attrName + ']';
    };
    return Qualifier;
})();

var Selector = (function () {
    function Selector() {
        this.uid = Selector.nextUid++;
        this.qualifiers = [];
    }
    Object.defineProperty(Selector.prototype, "caseInsensitiveTagName", {
        get: function () {
            return this.tagName.toUpperCase();
        },
        enumerable: true,
        configurable: true
    });

    Object.defineProperty(Selector.prototype, "selectorString", {
        get: function () {
            return this.tagName + this.qualifiers.join('');
        },
        enumerable: true,
        configurable: true
    });

    Selector.prototype.isMatching = function (el) {
        return el[Selector.matchesSelector](this.selectorString);
    };

    Selector.prototype.wasMatching = function (el, change, isMatching) {
        if (!change || !change.attributes)
            return isMatching;

        var tagName = change.isCaseInsensitive ? this.caseInsensitiveTagName : this.tagName;
        if (tagName !== '*' && tagName !== el.tagName)
            return false;

        var attributeOldValues = [];
        var anyChanged = false;
        for (var i = 0; i < this.qualifiers.length; i++) {
            var qualifier = this.qualifiers[i];
            var oldValue = change.getAttributeOldValue(qualifier.attrName);
            attributeOldValues.push(oldValue);
            anyChanged = anyChanged || (oldValue !== undefined);
        }

        if (!anyChanged)
            return isMatching;

        for (var i = 0; i < this.qualifiers.length; i++) {
            var qualifier = this.qualifiers[i];
            var oldValue = attributeOldValues[i];
            if (oldValue === undefined)
                oldValue = el.getAttribute(qualifier.attrName);
            if (!qualifier.matches(oldValue))
                return false;
        }

        return true;
    };

    Selector.prototype.matchabilityChange = function (el, change) {
        var isMatching = this.isMatching(el);
        if (isMatching)
            return this.wasMatching(el, change, isMatching) ? 2 /* STAYED_IN */ : 1 /* ENTERED */;
        else
            return this.wasMatching(el, change, isMatching) ? 5 /* EXITED */ : 0 /* STAYED_OUT */;
    };

    Selector.parseSelectors = function (input) {
        var selectors = [];
        var currentSelector;
        var currentQualifier;

        function newSelector() {
            if (currentSelector) {
                if (currentQualifier) {
                    currentSelector.qualifiers.push(currentQualifier);
                    currentQualifier = undefined;
                }

                selectors.push(currentSelector);
            }
            currentSelector = new Selector();
        }

        function newQualifier() {
            if (currentQualifier)
                currentSelector.qualifiers.push(currentQualifier);

            currentQualifier = new Qualifier();
        }

        var WHITESPACE = /\s/;
        var valueQuoteChar;
        var SYNTAX_ERROR = 'Invalid or unsupported selector syntax.';

        var SELECTOR = 1;
        var TAG_NAME = 2;
        var QUALIFIER = 3;
        var QUALIFIER_NAME_FIRST_CHAR = 4;
        var QUALIFIER_NAME = 5;
        var ATTR_NAME_FIRST_CHAR = 6;
        var ATTR_NAME = 7;
        var EQUIV_OR_ATTR_QUAL_END = 8;
        var EQUAL = 9;
        var ATTR_QUAL_END = 10;
        var VALUE_FIRST_CHAR = 11;
        var VALUE = 12;
        var QUOTED_VALUE = 13;
        var SELECTOR_SEPARATOR = 14;

        var state = SELECTOR;
        var i = 0;
        while (i < input.length) {
            var c = input[i++];

            switch (state) {
                case SELECTOR:
                    if (c.match(validNameInitialChar)) {
                        newSelector();
                        currentSelector.tagName = c;
                        state = TAG_NAME;
                        break;
                    }

                    if (c == '*') {
                        newSelector();
                        currentSelector.tagName = '*';
                        state = QUALIFIER;
                        break;
                    }

                    if (c == '.') {
                        newSelector();
                        newQualifier();
                        currentSelector.tagName = '*';
                        currentQualifier.attrName = 'class';
                        currentQualifier.contains = true;
                        state = QUALIFIER_NAME_FIRST_CHAR;
                        break;
                    }
                    if (c == '#') {
                        newSelector();
                        newQualifier();
                        currentSelector.tagName = '*';
                        currentQualifier.attrName = 'id';
                        state = QUALIFIER_NAME_FIRST_CHAR;
                        break;
                    }
                    if (c == '[') {
                        newSelector();
                        newQualifier();
                        currentSelector.tagName = '*';
                        currentQualifier.attrName = '';
                        state = ATTR_NAME_FIRST_CHAR;
                        break;
                    }

                    if (c.match(WHITESPACE))
                        break;

                    throw Error(SYNTAX_ERROR);

                case TAG_NAME:
                    if (c.match(validNameNonInitialChar)) {
                        currentSelector.tagName += c;
                        break;
                    }

                    if (c == '.') {
                        newQualifier();
                        currentQualifier.attrName = 'class';
                        currentQualifier.contains = true;
                        state = QUALIFIER_NAME_FIRST_CHAR;
                        break;
                    }
                    if (c == '#') {
                        newQualifier();
                        currentQualifier.attrName = 'id';
                        state = QUALIFIER_NAME_FIRST_CHAR;
                        break;
                    }
                    if (c == '[') {
                        newQualifier();
                        currentQualifier.attrName = '';
                        state = ATTR_NAME_FIRST_CHAR;
                        break;
                    }

                    if (c.match(WHITESPACE)) {
                        state = SELECTOR_SEPARATOR;
                        break;
                    }

                    if (c == ',') {
                        state = SELECTOR;
                        break;
                    }

                    throw Error(SYNTAX_ERROR);

                case QUALIFIER:
                    if (c == '.') {
                        newQualifier();
                        currentQualifier.attrName = 'class';
                        currentQualifier.contains = true;
                        state = QUALIFIER_NAME_FIRST_CHAR;
                        break;
                    }
                    if (c == '#') {
                        newQualifier();
                        currentQualifier.attrName = 'id';
                        state = QUALIFIER_NAME_FIRST_CHAR;
                        break;
                    }
                    if (c == '[') {
                        newQualifier();
                        currentQualifier.attrName = '';
                        state = ATTR_NAME_FIRST_CHAR;
                        break;
                    }

                    if (c.match(WHITESPACE)) {
                        state = SELECTOR_SEPARATOR;
                        break;
                    }

                    if (c == ',') {
                        state = SELECTOR;
                        break;
                    }

                    throw Error(SYNTAX_ERROR);

                case QUALIFIER_NAME_FIRST_CHAR:
                    if (c.match(validNameInitialChar)) {
                        currentQualifier.attrValue = c;
                        state = QUALIFIER_NAME;
                        break;
                    }

                    throw Error(SYNTAX_ERROR);

                case QUALIFIER_NAME:
                    if (c.match(validNameNonInitialChar)) {
                        currentQualifier.attrValue += c;
                        break;
                    }

                    if (c == '.') {
                        newQualifier();
                        currentQualifier.attrName = 'class';
                        currentQualifier.contains = true;
                        state = QUALIFIER_NAME_FIRST_CHAR;
                        break;
                    }
                    if (c == '#') {
                        newQualifier();
                        currentQualifier.attrName = 'id';
                        state = QUALIFIER_NAME_FIRST_CHAR;
                        break;
                    }
                    if (c == '[') {
                        newQualifier();
                        state = ATTR_NAME_FIRST_CHAR;
                        break;
                    }

                    if (c.match(WHITESPACE)) {
                        state = SELECTOR_SEPARATOR;
                        break;
                    }
                    if (c == ',') {
                        state = SELECTOR;
                        break;
                    }

                    throw Error(SYNTAX_ERROR);

                case ATTR_NAME_FIRST_CHAR:
                    if (c.match(validNameInitialChar)) {
                        currentQualifier.attrName = c;
                        state = ATTR_NAME;
                        break;
                    }

                    if (c.match(WHITESPACE))
                        break;

                    throw Error(SYNTAX_ERROR);

                case ATTR_NAME:
                    if (c.match(validNameNonInitialChar)) {
                        currentQualifier.attrName += c;
                        break;
                    }

                    if (c.match(WHITESPACE)) {
                        state = EQUIV_OR_ATTR_QUAL_END;
                        break;
                    }

                    if (c == '~') {
                        currentQualifier.contains = true;
                        state = EQUAL;
                        break;
                    }

                    if (c == '=') {
                        currentQualifier.attrValue = '';
                        state = VALUE_FIRST_CHAR;
                        break;
                    }

                    if (c == ']') {
                        state = QUALIFIER;
                        break;
                    }

                    throw Error(SYNTAX_ERROR);

                case EQUIV_OR_ATTR_QUAL_END:
                    if (c == '~') {
                        currentQualifier.contains = true;
                        state = EQUAL;
                        break;
                    }

                    if (c == '=') {
                        currentQualifier.attrValue = '';
                        state = VALUE_FIRST_CHAR;
                        break;
                    }

                    if (c == ']') {
                        state = QUALIFIER;
                        break;
                    }

                    if (c.match(WHITESPACE))
                        break;

                    throw Error(SYNTAX_ERROR);

                case EQUAL:
                    if (c == '=') {
                        currentQualifier.attrValue = '';
                        state = VALUE_FIRST_CHAR;
                        break;
                    }

                    throw Error(SYNTAX_ERROR);

                case ATTR_QUAL_END:
                    if (c == ']') {
                        state = QUALIFIER;
                        break;
                    }

                    if (c.match(WHITESPACE))
                        break;

                    throw Error(SYNTAX_ERROR);

                case VALUE_FIRST_CHAR:
                    if (c.match(WHITESPACE))
                        break;

                    if (c == '"' || c == "'") {
                        valueQuoteChar = c;
                        state = QUOTED_VALUE;
                        break;
                    }

                    currentQualifier.attrValue += c;
                    state = VALUE;
                    break;

                case VALUE:
                    if (c.match(WHITESPACE)) {
                        state = ATTR_QUAL_END;
                        break;
                    }
                    if (c == ']') {
                        state = QUALIFIER;
                        break;
                    }
                    if (c == "'" || c == '"')
                        throw Error(SYNTAX_ERROR);

                    currentQualifier.attrValue += c;
                    break;

                case QUOTED_VALUE:
                    if (c == valueQuoteChar) {
                        state = ATTR_QUAL_END;
                        break;
                    }

                    currentQualifier.attrValue += c;
                    break;

                case SELECTOR_SEPARATOR:
                    if (c.match(WHITESPACE))
                        break;

                    if (c == ',') {
                        state = SELECTOR;
                        break;
                    }

                    throw Error(SYNTAX_ERROR);
            }
        }

        switch (state) {
            case SELECTOR:
            case TAG_NAME:
            case QUALIFIER:
            case QUALIFIER_NAME:
            case SELECTOR_SEPARATOR:
                // Valid end states.
                newSelector();
                break;
            default:
                throw Error(SYNTAX_ERROR);
        }

        if (!selectors.length)
            throw Error(SYNTAX_ERROR);

        return selectors;
    };
    Selector.nextUid = 1;
    Selector.matchesSelector = (function () {
        var element = document.createElement('div');
        if (typeof element['webkitMatchesSelector'] === 'function')
            return 'webkitMatchesSelector';
        if (typeof element['mozMatchesSelector'] === 'function')
            return 'mozMatchesSelector';
        if (typeof element['msMatchesSelector'] === 'function')
            return 'msMatchesSelector';

        return 'matchesSelector';
    })();
    return Selector;
})();

var attributeFilterPattern = /^([a-zA-Z:_]+[a-zA-Z0-9_\-:\.]*)$/;

function validateAttribute(attribute) {
    if (typeof attribute != 'string')
        throw Error('Invalid request opion. attribute must be a non-zero length string.');

    attribute = attribute.trim();

    if (!attribute)
        throw Error('Invalid request opion. attribute must be a non-zero length string.');

    if (!attribute.match(attributeFilterPattern))
        throw Error('Invalid request option. invalid attribute name: ' + attribute);

    return attribute;
}

function validateElementAttributes(attribs) {
    if (!attribs.trim().length)
        throw Error('Invalid request option: elementAttributes must contain at least one attribute.');

    var lowerAttributes = {};
    var attributes = {};

    var tokens = attribs.split(/\s+/);
    for (var i = 0; i < tokens.length; i++) {
        var name = tokens[i];
        if (!name)
            continue;

        var name = validateAttribute(name);
        var nameLower = name.toLowerCase();
        if (lowerAttributes[nameLower])
            throw Error('Invalid request option: observing multiple case variations of the same attribute is not supported.');

        attributes[name] = true;
        lowerAttributes[nameLower] = true;
    }

    return Object.keys(attributes);
}

function elementFilterAttributes(selectors) {
    var attributes = {};

    selectors.forEach(function (selector) {
        selector.qualifiers.forEach(function (qualifier) {
            attributes[qualifier.attrName] = true;
        });
    });

    return Object.keys(attributes);
}

var MutationSummary = (function () {
    function MutationSummary(opts) {
        var _this = this;
        this.connected = false;
        this.options = MutationSummary.validateOptions(opts);
        this.observerOptions = MutationSummary.createObserverOptions(this.options.queries);
        this.root = this.options.rootNode;
        this.callback = this.options.callback;

        this.elementFilter = Array.prototype.concat.apply([], this.options.queries.map(function (query) {
            return query.elementFilter ? query.elementFilter : [];
        }));
        if (!this.elementFilter.length)
            this.elementFilter = undefined;

        this.calcReordered = this.options.queries.some(function (query) {
            return query.all;
        });

        this.queryValidators = []; // TODO(rafaelw): Shouldn't always define this.
        if (MutationSummary.createQueryValidator) {
            this.queryValidators = this.options.queries.map(function (query) {
                return MutationSummary.createQueryValidator(_this.root, query);
            });
        }

        this.observer = new MutationObserverCtor(function (mutations) {
            _this.observerCallback(mutations);
        });

        this.reconnect();
    }
    MutationSummary.createObserverOptions = function (queries) {
        var observerOptions = {
            childList: true,
            subtree: true
        };

        var attributeFilter;
        function observeAttributes(attributes) {
            if (observerOptions.attributes && !attributeFilter)
                return;

            observerOptions.attributes = true;
            observerOptions.attributeOldValue = true;

            if (!attributes) {
                // observe all.
                attributeFilter = undefined;
                return;
            }

            // add to observed.
            attributeFilter = attributeFilter || {};
            attributes.forEach(function (attribute) {
                attributeFilter[attribute] = true;
                attributeFilter[attribute.toLowerCase()] = true;
            });
        }

        queries.forEach(function (query) {
            if (query.characterData) {
                observerOptions.characterData = true;
                observerOptions.characterDataOldValue = true;
                return;
            }

            if (query.all) {
                observeAttributes();
                observerOptions.characterData = true;
                observerOptions.characterDataOldValue = true;
                return;
            }

            if (query.attribute) {
                observeAttributes([query.attribute.trim()]);
                return;
            }

            var attributes = elementFilterAttributes(query.elementFilter).concat(query.attributeList || []);
            if (attributes.length)
                observeAttributes(attributes);
        });

        if (attributeFilter)
            observerOptions.attributeFilter = Object.keys(attributeFilter);

        return observerOptions;
    };

    MutationSummary.validateOptions = function (options) {
        for (var prop in options) {
            if (!(prop in MutationSummary.optionKeys))
                throw Error('Invalid option: ' + prop);
        }

        if (typeof options.callback !== 'function')
            throw Error('Invalid options: callback is required and must be a function');

        if (!options.queries || !options.queries.length)
            throw Error('Invalid options: queries must contain at least one query request object.');

        var opts = {
            callback: options.callback,
            rootNode: options.rootNode || document,
            observeOwnChanges: !!options.observeOwnChanges,
            oldPreviousSibling: !!options.oldPreviousSibling,
            queries: []
        };

        for (var i = 0; i < options.queries.length; i++) {
            var request = options.queries[i];

            // all
            if (request.all) {
                if (Object.keys(request).length > 1)
                    throw Error('Invalid request option. all has no options.');

                opts.queries.push({ all: true });
                continue;
            }

            // attribute
            if ('attribute' in request) {
                var query = {
                    attribute: validateAttribute(request.attribute)
                };

                query.elementFilter = Selector.parseSelectors('*[' + query.attribute + ']');

                if (Object.keys(request).length > 1)
                    throw Error('Invalid request option. attribute has no options.');

                opts.queries.push(query);
                continue;
            }

            // element
            if ('element' in request) {
                var requestOptionCount = Object.keys(request).length;
                var query = {
                    element: request.element,
                    elementFilter: Selector.parseSelectors(request.element)
                };

                if (request.hasOwnProperty('elementAttributes')) {
                    query.attributeList = validateElementAttributes(request.elementAttributes);
                    requestOptionCount--;
                }

                if (requestOptionCount > 1)
                    throw Error('Invalid request option. element only allows elementAttributes option.');

                opts.queries.push(query);
                continue;
            }

            // characterData
            if (request.characterData) {
                if (Object.keys(request).length > 1)
                    throw Error('Invalid request option. characterData has no options.');

                opts.queries.push({ characterData: true });
                continue;
            }

            throw Error('Invalid request option. Unknown query request.');
        }

        return opts;
    };

    MutationSummary.prototype.createSummaries = function (mutations) {
        if (!mutations || !mutations.length)
            return [];

        var projection = new MutationProjection(this.root, mutations, this.elementFilter, this.calcReordered, this.options.oldPreviousSibling);

        var summaries = [];
        for (var i = 0; i < this.options.queries.length; i++) {
            summaries.push(new Summary(projection, this.options.queries[i]));
        }

        return summaries;
    };

    MutationSummary.prototype.checkpointQueryValidators = function () {
        this.queryValidators.forEach(function (validator) {
            if (validator)
                validator.recordPreviousState();
        });
    };

    MutationSummary.prototype.runQueryValidators = function (summaries) {
        this.queryValidators.forEach(function (validator, index) {
            if (validator)
                validator.validate(summaries[index]);
        });
    };

    MutationSummary.prototype.changesToReport = function (summaries) {
        return summaries.some(function (summary) {
            var summaryProps = [
                'added', 'removed', 'reordered', 'reparented',
                'valueChanged', 'characterDataChanged'];
            if (summaryProps.some(function (prop) {
                return summary[prop] && summary[prop].length;
            }))
                return true;

            if (summary.attributeChanged) {
                var attrNames = Object.keys(summary.attributeChanged);
                var attrsChanged = attrNames.some(function (attrName) {
                    return !!summary.attributeChanged[attrName].length;
                });
                if (attrsChanged)
                    return true;
            }
            return false;
        });
    };

    MutationSummary.prototype.observerCallback = function (mutations) {
        if (!this.options.observeOwnChanges)
            this.observer.disconnect();

        var summaries = this.createSummaries(mutations);
        this.runQueryValidators(summaries);

        if (this.options.observeOwnChanges)
            this.checkpointQueryValidators();

        if (this.changesToReport(summaries))
            this.callback(summaries);

        // disconnect() may have been called during the callback.
        if (!this.options.observeOwnChanges && this.connected) {
            this.checkpointQueryValidators();
            this.observer.observe(this.root, this.observerOptions);
        }
    };

    MutationSummary.prototype.reconnect = function () {
        if (this.connected)
            throw Error('Already connected');

        this.observer.observe(this.root, this.observerOptions);
        this.connected = true;
        this.checkpointQueryValidators();
    };

    MutationSummary.prototype.takeSummaries = function () {
        if (!this.connected)
            throw Error('Not connected');

        var summaries = this.createSummaries(this.observer.takeRecords());
        return this.changesToReport(summaries) ? summaries : undefined;
    };

    MutationSummary.prototype.disconnect = function () {
        var summaries = this.takeSummaries();
        this.observer.disconnect();
        this.connected = false;
        return summaries;
    };
    MutationSummary.NodeMap = NodeMap;
    MutationSummary.parseElementFilter = Selector.parseSelectors;

    MutationSummary.optionKeys = {
        'callback': true,
        'queries': true,
        'rootNode': true,
        'oldPreviousSibling': true,
        'observeOwnChanges': true
    };
    return MutationSummary;
})();

module.exports = MutationSummary

},{}],2:[function(require,module,exports){
/*! Copyright (c) 2013 Brandon Aaron (http://brandon.aaron.sh)
 * Licensed under the MIT License (LICENSE.txt).
 *
 * Version: 3.1.12
 *
 * Requires: jQuery 1.2.2+
 */

(function (factory) {
    if ( typeof define === 'function' && define.amd ) {
        // AMD. Register as an anonymous module.
        define(['jquery'], factory);
    } else if (typeof exports === 'object') {
        // Node/CommonJS style for Browserify
        module.exports = factory;
    } else {
        // Browser globals
        factory(jQuery);
    }
}(function ($) {

    var toFix  = ['wheel', 'mousewheel', 'DOMMouseScroll', 'MozMousePixelScroll'],
        toBind = ( 'onwheel' in document || document.documentMode >= 9 ) ?
                    ['wheel'] : ['mousewheel', 'DomMouseScroll', 'MozMousePixelScroll'],
        slice  = Array.prototype.slice,
        nullLowestDeltaTimeout, lowestDelta;

    if ( $.event.fixHooks ) {
        for ( var i = toFix.length; i; ) {
            $.event.fixHooks[ toFix[--i] ] = $.event.mouseHooks;
        }
    }

    var special = $.event.special.mousewheel = {
        version: '3.1.12',

        setup: function() {
            if ( this.addEventListener ) {
                for ( var i = toBind.length; i; ) {
                    this.addEventListener( toBind[--i], handler, false );
                }
            } else {
                this.onmousewheel = handler;
            }
            // Store the line height and page height for this particular element
            $.data(this, 'mousewheel-line-height', special.getLineHeight(this));
            $.data(this, 'mousewheel-page-height', special.getPageHeight(this));
        },

        teardown: function() {
            if ( this.removeEventListener ) {
                for ( var i = toBind.length; i; ) {
                    this.removeEventListener( toBind[--i], handler, false );
                }
            } else {
                this.onmousewheel = null;
            }
            // Clean up the data we added to the element
            $.removeData(this, 'mousewheel-line-height');
            $.removeData(this, 'mousewheel-page-height');
        },

        getLineHeight: function(elem) {
            var $elem = $(elem),
                $parent = $elem['offsetParent' in $.fn ? 'offsetParent' : 'parent']();
            if (!$parent.length) {
                $parent = $('body');
            }
            return parseInt($parent.css('fontSize'), 10) || parseInt($elem.css('fontSize'), 10) || 16;
        },

        getPageHeight: function(elem) {
            return $(elem).height();
        },

        settings: {
            adjustOldDeltas: true, // see shouldAdjustOldDeltas() below
            normalizeOffset: true  // calls getBoundingClientRect for each event
        }
    };

    $.fn.extend({
        mousewheel: function(fn) {
            return fn ? this.bind('mousewheel', fn) : this.trigger('mousewheel');
        },

        unmousewheel: function(fn) {
            return this.unbind('mousewheel', fn);
        }
    });


    function handler(event) {
        var orgEvent   = event || window.event,
            args       = slice.call(arguments, 1),
            delta      = 0,
            deltaX     = 0,
            deltaY     = 0,
            absDelta   = 0,
            offsetX    = 0,
            offsetY    = 0;
        event = $.event.fix(orgEvent);
        event.type = 'mousewheel';

        // Old school scrollwheel delta
        if ( 'detail'      in orgEvent ) { deltaY = orgEvent.detail * -1;      }
        if ( 'wheelDelta'  in orgEvent ) { deltaY = orgEvent.wheelDelta;       }
        if ( 'wheelDeltaY' in orgEvent ) { deltaY = orgEvent.wheelDeltaY;      }
        if ( 'wheelDeltaX' in orgEvent ) { deltaX = orgEvent.wheelDeltaX * -1; }

        // Firefox < 17 horizontal scrolling related to DOMMouseScroll event
        if ( 'axis' in orgEvent && orgEvent.axis === orgEvent.HORIZONTAL_AXIS ) {
            deltaX = deltaY * -1;
            deltaY = 0;
        }

        // Set delta to be deltaY or deltaX if deltaY is 0 for backwards compatabilitiy
        delta = deltaY === 0 ? deltaX : deltaY;

        // New school wheel delta (wheel event)
        if ( 'deltaY' in orgEvent ) {
            deltaY = orgEvent.deltaY * -1;
            delta  = deltaY;
        }
        if ( 'deltaX' in orgEvent ) {
            deltaX = orgEvent.deltaX;
            if ( deltaY === 0 ) { delta  = deltaX * -1; }
        }

        // No change actually happened, no reason to go any further
        if ( deltaY === 0 && deltaX === 0 ) { return; }

        // Need to convert lines and pages to pixels if we aren't already in pixels
        // There are three delta modes:
        //   * deltaMode 0 is by pixels, nothing to do
        //   * deltaMode 1 is by lines
        //   * deltaMode 2 is by pages
        if ( orgEvent.deltaMode === 1 ) {
            var lineHeight = $.data(this, 'mousewheel-line-height');
            delta  *= lineHeight;
            deltaY *= lineHeight;
            deltaX *= lineHeight;
        } else if ( orgEvent.deltaMode === 2 ) {
            var pageHeight = $.data(this, 'mousewheel-page-height');
            delta  *= pageHeight;
            deltaY *= pageHeight;
            deltaX *= pageHeight;
        }

        // Store lowest absolute delta to normalize the delta values
        absDelta = Math.max( Math.abs(deltaY), Math.abs(deltaX) );

        if ( !lowestDelta || absDelta < lowestDelta ) {
            lowestDelta = absDelta;

            // Adjust older deltas if necessary
            if ( shouldAdjustOldDeltas(orgEvent, absDelta) ) {
                lowestDelta /= 40;
            }
        }

        // Adjust older deltas if necessary
        if ( shouldAdjustOldDeltas(orgEvent, absDelta) ) {
            // Divide all the things by 40!
            delta  /= 40;
            deltaX /= 40;
            deltaY /= 40;
        }

        // Get a whole, normalized value for the deltas
        delta  = Math[ delta  >= 1 ? 'floor' : 'ceil' ](delta  / lowestDelta);
        deltaX = Math[ deltaX >= 1 ? 'floor' : 'ceil' ](deltaX / lowestDelta);
        deltaY = Math[ deltaY >= 1 ? 'floor' : 'ceil' ](deltaY / lowestDelta);

        // Normalise offsetX and offsetY properties
        if ( special.settings.normalizeOffset && this.getBoundingClientRect ) {
            var boundingRect = this.getBoundingClientRect();
            offsetX = event.clientX - boundingRect.left;
            offsetY = event.clientY - boundingRect.top;
        }

        // Add information to the event object
        event.deltaX = deltaX;
        event.deltaY = deltaY;
        event.deltaFactor = lowestDelta;
        event.offsetX = offsetX;
        event.offsetY = offsetY;
        // Go ahead and set deltaMode to 0 since we converted to pixels
        // Although this is a little odd since we overwrite the deltaX/Y
        // properties with normalized deltas.
        event.deltaMode = 0;

        // Add event and delta to the front of the arguments
        args.unshift(event, delta, deltaX, deltaY);

        // Clearout lowestDelta after sometime to better
        // handle multiple device types that give different
        // a different lowestDelta
        // Ex: trackpad = 3 and mouse wheel = 120
        if (nullLowestDeltaTimeout) { clearTimeout(nullLowestDeltaTimeout); }
        nullLowestDeltaTimeout = setTimeout(nullLowestDelta, 200);

        return ($.event.dispatch || $.event.handle).apply(this, args);
    }

    function nullLowestDelta() {
        lowestDelta = null;
    }

    function shouldAdjustOldDeltas(orgEvent, absDelta) {
        // If this is an older event and the delta is divisable by 120,
        // then we are assuming that the browser is treating this as an
        // older mouse wheel event and that we should divide the deltas
        // by 40 to try and get a more usable deltaFactor.
        // Side note, this actually impacts the reported scroll distance
        // in older browsers and can cause scrolling to be slower than native.
        // Turn this off by setting $.event.special.mousewheel.settings.adjustOldDeltas to false.
        return special.settings.adjustOldDeltas && orgEvent.type === 'mousewheel' && absDelta % 120 === 0;
    }

}));

},{}],3:[function(require,module,exports){
var KDAutoComplete, KDInputView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDInputView = require('./../inputs/inputview.coffee');

module.exports = KDAutoComplete = (function(_super) {
  __extends(KDAutoComplete, _super);

  function KDAutoComplete() {
    return KDAutoComplete.__super__.constructor.apply(this, arguments);
  }

  KDAutoComplete.prototype.mouseDown = function() {
    return this.focus();
  };

  KDAutoComplete.prototype.setDomElement = function() {
    return this.domElement = $("<div class='kdautocompletewrapper clearfix'><input type='text' placeholder='" + (this.getOptions().placeholder) + "' class='kdinput text'/></div>");
  };

  KDAutoComplete.prototype.setDomId = function() {
    this.$input().attr("id", this.getDomId());
    this.$input().attr("name", this.getName());
    return this.$input().data("data-id", this.getId());
  };

  KDAutoComplete.prototype.setDefaultValue = function(value) {
    this.inputDefaultValue = value;
    return this.setValue(value);
  };

  KDAutoComplete.prototype.$input = function() {
    return this.$("input").eq(0);
  };

  KDAutoComplete.prototype.getValue = function() {
    return this.$input().val();
  };

  KDAutoComplete.prototype.setValue = function(value) {
    return this.$input().val(value);
  };

  KDAutoComplete.prototype.bindEvents = function() {
    return KDAutoComplete.__super__.bindEvents.call(this, this.$input());
  };

  KDAutoComplete.prototype.blur = function(pubInst, event) {
    this.unsetClass("focus");
    return true;
  };

  KDAutoComplete.prototype.focus = function(pubInst, event) {
    this.setClass("focus");
    return KDAutoComplete.__super__.focus.apply(this, arguments);
  };

  KDAutoComplete.prototype.keyDown = function(event) {
    (KD.getSingleton("windowController")).setKeyView(this);
    return true;
  };

  KDAutoComplete.prototype.getLeftOffset = function() {
    return this.$input().prev().width();
  };

  KDAutoComplete.prototype.destroyDropdown = function() {
    if (this.dropdown != null) {
      this.dropdown.destroy();
    }
    this.dropdownPrefix = "";
    return this.dropdown = null;
  };

  KDAutoComplete.prototype.setPlaceHolder = function(value) {
    return this.$input()[0].setAttribute("placeholder", value);
  };

  KDAutoComplete.prototype.setFocus = function() {
    KDAutoComplete.__super__.setFocus.apply(this, arguments);
    return this.$input().trigger("focus");
  };

  KDAutoComplete.prototype.setBlur = function() {
    KDAutoComplete.__super__.setBlur.apply(this, arguments);
    return this.$input().trigger("blur");
  };

  return KDAutoComplete;

})(KDInputView);


},{"./../inputs/inputview.coffee":46}],4:[function(require,module,exports){
var KDAutoComplete, KDAutoCompleteController, KDAutoCompleteFetchingItem, KDAutoCompleteListView, KDLabelView, KDListViewController, KDNotificationView, KDViewController,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

KDViewController = require('./../../core/viewcontroller.coffee');

KDListViewController = require('./../list/listviewcontroller.coffee');

KDLabelView = require('./../inputs/labelview.coffee');

KDNotificationView = require('./../notifications/notificationview.coffee');

KDAutoComplete = require('./autocomplete.coffee');

KDAutoCompleteListView = require('./autocompletelist.coffee');

KDAutoCompleteFetchingItem = require('./autocompletefetchingitem.coffee');

module.exports = KDAutoCompleteController = (function(_super) {
  __extends(KDAutoCompleteController, _super);

  function KDAutoCompleteController(options, data) {
    var mainView;
    if (options == null) {
      options = {};
    }
    options = $.extend({
      view: mainView = options.view || new KDAutoComplete({
        name: options.name,
        placeholder: options.placeholder || "",
        label: options.label || new KDLabelView({
          title: options.name
        })
      }),
      itemClass: KDAutoCompleteListItemView,
      selectedItemClass: KDAutoCompletedItem,
      nothingFoundItemClass: KDAutoCompleteNothingFoundItem,
      fetchingItemClass: KDAutoCompleteFetchingItem,
      listWrapperCssClass: '',
      minSuggestionLength: 2,
      selectedItemsLimit: null,
      itemDataPath: '',
      separator: ',',
      wrapper: 'parent',
      submitValuesAsText: false,
      defaultValue: []
    }, options);
    KDAutoCompleteController.__super__.constructor.call(this, options, data);
    mainView.on('focus', this.bound("updateDropdownContents"));
    this.lastPrefix = null;
    this.selectedItemData = [];
    this.hiddenInputs = {};
    this.selectedItemCounter = 0;
    this.readyToShowDropDown = true;
  }

  KDAutoCompleteController.prototype.reset = function() {
    var item, subViews, _i, _len, _results;
    subViews = this.itemWrapper.getSubViews().slice();
    _results = [];
    for (_i = 0, _len = subViews.length; _i < _len; _i++) {
      item = subViews[_i];
      _results.push(this.removeFromSubmitQueue(item));
    }
    return _results;
  };

  KDAutoCompleteController.prototype.loadView = function(mainView) {
    this.createDropDown();
    this.getAutoCompletedItemParent();
    this.setDefaultValue();
    mainView.on('keyup', this.utils.debounce(300, this.bound("keyUpOnInputView")));
    return mainView.on('keydown', (function(_this) {
      return function(event) {
        return _this.keyDownOnInputView(event);
      };
    })(this));
  };

  KDAutoCompleteController.prototype.setDefaultValue = function(defaultItems) {
    var defaultValue, item, itemDataPath, _i, _len, _ref, _results;
    _ref = this.getOptions(), defaultValue = _ref.defaultValue, itemDataPath = _ref.itemDataPath;
    defaultItems || (defaultItems = defaultValue);
    _results = [];
    for (_i = 0, _len = defaultItems.length; _i < _len; _i++) {
      item = defaultItems[_i];
      _results.push(this.addItemToSubmitQueue(this.getView(), item));
    }
    return _results;
  };

  KDAutoCompleteController.prototype.keyDownOnInputView = function(event) {
    var autoCompleteView;
    autoCompleteView = this.getView();
    switch (event.which) {
      case 13:
      case 9:
        if (autoCompleteView.getValue() !== "" && event.shiftKey !== true) {
          this.submitAutoComplete(autoCompleteView.getValue());
          event.stopPropagation();
          event.preventDefault();
          this.readyToShowDropDown = false;
          return false;
        } else {
          return true;
        }
        break;
      case 27:
        this.hideDropdown();
        break;
      case 38:
        if (this.dropdown.getView().$().is(":visible")) {
          this.dropdown.getListView().goUp();
          event.stopPropagation();
          event.preventDefault();
          return false;
        } else {

        }
        break;
      case 40:
        if (this.dropdown.getView().$().is(":visible")) {
          this.dropdown.getListView().goDown();
          event.stopPropagation();
          event.preventDefault();
          return false;
        }
        break;
      default:
        this.readyToShowDropDown = true;
    }
    return false;
  };

  KDAutoCompleteController.prototype.getPrefix = function() {
    var items, prefix, separator;
    separator = this.getOptions().separator;
    items = this.getView().getValue().split(separator);
    prefix = items[items.length - 1];
    return prefix;
  };

  KDAutoCompleteController.prototype.createDropDown = function(data) {
    var dropdownListView, dropdownWrapper, windowController;
    if (data == null) {
      data = [];
    }
    this.dropdownPrefix = "";
    this.dropdownListView = dropdownListView = new KDAutoCompleteListView({
      itemClass: this.getOptions().itemClass
    }, {
      items: data
    });
    dropdownListView.on('ItemsDeselected', (function(_this) {
      return function() {
        var view;
        view = _this.getView();
        return view.$input().trigger('focus');
      };
    })(this));
    dropdownListView.on('KDAutoCompleteSubmit', this.bound("submitAutoComplete"));
    windowController = KD.getSingleton('windowController');
    this.dropdown = new KDListViewController({
      view: dropdownListView
    });
    dropdownWrapper = this.dropdown.getView();
    dropdownWrapper.on('ReceivedClickElsewhere', (function(_this) {
      return function() {
        return _this.hideDropdown();
      };
    })(this));
    dropdownWrapper.setClass("kdautocomplete hidden " + (this.getOptions().listWrapperCssClass));
    return dropdownWrapper.appendToDomBody();
  };

  KDAutoCompleteController.prototype.hideDropdown = function() {
    var dropdownWrapper;
    dropdownWrapper = this.dropdown.getView();
    return dropdownWrapper.$().fadeOut(75);
  };

  KDAutoCompleteController.prototype.showDropdown = function() {
    var dropdownWrapper, input, offset, windowController;
    if (!this.readyToShowDropDown) {
      return;
    }
    windowController = KD.getSingleton('windowController');
    dropdownWrapper = this.dropdown.getView();
    dropdownWrapper.unsetClass("hidden");
    input = this.getView();
    offset = input.$().offset();
    offset.top += input.getHeight();
    dropdownWrapper.$().css(offset);
    dropdownWrapper.$().fadeIn(75);
    return windowController.addLayer(dropdownWrapper);
  };

  KDAutoCompleteController.prototype.refreshDropDown = function(data) {
    var allowNewSuggestions, exactMatches, exactPattern, inexactMatches, itemDataPath, listView, minSuggestionLength, _ref;
    if (data == null) {
      data = [];
    }
    listView = this.dropdown.getListView();
    this.dropdown.removeAllItems();
    listView.userInput = this.dropdownPrefix;
    exactPattern = RegExp('^' + this.dropdownPrefix.replace(/[^\s\w]/, '') + '$', 'i');
    exactMatches = [];
    inexactMatches = [];
    _ref = this.getOptions(), itemDataPath = _ref.itemDataPath, allowNewSuggestions = _ref.allowNewSuggestions, minSuggestionLength = _ref.minSuggestionLength;
    data.forEach((function(_this) {
      return function(datum) {
        var match;
        if (!_this.isItemAlreadySelected(datum)) {
          match = JsPath.getAt(datum, itemDataPath);
          if (exactPattern.test(match)) {
            return exactMatches.push(datum);
          } else {
            return inexactMatches.push(datum);
          }
        }
      };
    })(this));
    if ((this.dropdownPrefix.length >= minSuggestionLength) && allowNewSuggestions && !exactMatches.length) {
      this.dropdown.getListView().addItemView(this.getNoItemFoundView());
    }
    data = exactMatches.concat(inexactMatches);
    this.dropdown.instantiateListItems(data);
    return this.dropdown.getListView().goDown();
  };

  KDAutoCompleteController.prototype.submitAutoComplete = function(item, data) {
    var activeItem, inputView;
    inputView = this.getView();
    if (this.getOptions().selectedItemsLimit === null || this.getOptions().selectedItemsLimit > this.selectedItemCounter) {
      activeItem = this.dropdown.getListView().getActiveItem();
      if (activeItem.item) {
        this.appendAutoCompletedItem();
      }
      this.addItemToSubmitQueue(activeItem.item);
      this.emit('ItemListChanged', this.selectedItemCounter);
    } else {
      inputView.setValue('');
      KD.getSingleton("windowController").setKeyView(null);
      new KDNotificationView({
        type: "mini",
        title: "You can add up to " + (this.getOptions().selectedItemsLimit) + " items!",
        duration: 4000
      });
    }
    return this.hideDropdown();
  };

  KDAutoCompleteController.prototype.getAutoCompletedItemParent = function() {
    var outputWrapper;
    outputWrapper = this.getOptions().outputWrapper;
    if (outputWrapper instanceof KDView) {
      return this.itemWrapper = outputWrapper;
    } else {
      return this.itemWrapper = this.getView();
    }
  };

  KDAutoCompleteController.prototype.isItemAlreadySelected = function(data) {
    var alreadySelected, customCompare, isCaseSensitive, itemDataPath, selected, selectedData, suggested, _i, _len, _ref, _ref1;
    _ref = this.getOptions(), itemDataPath = _ref.itemDataPath, customCompare = _ref.customCompare, isCaseSensitive = _ref.isCaseSensitive;
    suggested = JsPath.getAt(data, itemDataPath);
    _ref1 = this.getSelectedItemData();
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      selectedData = _ref1[_i];
      if (customCompare != null) {
        alreadySelected = customCompare(data, selectedData);
        if (alreadySelected) {
          return true;
        }
      } else {
        selected = JsPath.getAt(selectedData, itemDataPath);
        if (!isCaseSensitive) {
          suggested = suggested.toLowerCase();
          selected = selected.toLowerCase();
        }
        if (suggested === selected) {
          return true;
        }
      }
    }
    return false;
  };

  KDAutoCompleteController.prototype.addHiddenInputItem = function(name, value) {
    return this.itemWrapper.addSubView(this.hiddenInputs[name] = new KDInputView({
      type: "hidden",
      name: name,
      defaultValue: value
    }));
  };

  KDAutoCompleteController.prototype.removeHiddenInputItem = function(name) {
    return delete this.hiddenInputs[name];
  };

  KDAutoCompleteController.prototype.addSelectedItem = function(name, data) {
    var itemView, selectedItemClass;
    selectedItemClass = this.getOptions().selectedItemClass;
    this.itemWrapper.addSubView(itemView = new selectedItemClass({
      cssClass: "kdautocompletedlistitem",
      delegate: this,
      name: name
    }, data));
    return itemView.setPartial("<span class='close-icon'></span>");
  };

  KDAutoCompleteController.prototype.getSelectedItemData = function() {
    return this.selectedItemData;
  };

  KDAutoCompleteController.prototype.addSelectedItemData = function(data) {
    return this.getSelectedItemData().push(data);
  };

  KDAutoCompleteController.prototype.removeSelectedItemData = function(data) {
    var i, selectedData, selectedItemData, _i, _len;
    selectedItemData = this.getSelectedItemData();
    for (i = _i = 0, _len = selectedItemData.length; _i < _len; i = ++_i) {
      selectedData = selectedItemData[i];
      if (selectedData === data) {
        selectedItemData.splice(i, 1);
        return;
      }
    }
  };

  KDAutoCompleteController.prototype.getCollectionPath = function() {
    var collectionName, leaf, name, path, _i, _ref;
    name = this.getOptions().name;
    if (!name) {
      throw new Error('No name!');
    }
    _ref = name.split('.'), path = 2 <= _ref.length ? __slice.call(_ref, 0, _i = _ref.length - 1) : (_i = 0, []), leaf = _ref[_i++];
    collectionName = Inflector.pluralize(leaf);
    path.push(collectionName);
    return path.join('.');
  };

  KDAutoCompleteController.prototype.addSuggestion = function(title) {
    return this.emit('AutocompleteSuggestionWasAdded', title);
  };

  KDAutoCompleteController.prototype.addItemToSubmitQueue = function(item, data) {
    var collection, form, itemDataPath, itemName, itemValue, name, path, submitValuesAsText, _ref;
    data || (data = item != null ? item.getData() : void 0);
    if (!(data || (item != null ? item.getOptions().userInput : void 0))) {
      return;
    }
    _ref = this.getOptions(), name = _ref.name, itemDataPath = _ref.itemDataPath, form = _ref.form, submitValuesAsText = _ref.submitValuesAsText;
    if (data) {
      itemValue = submitValuesAsText ? JsPath.getAt(data, itemDataPath) : data;
    } else {
      itemValue = item.getOptions().userInput;
      data = JsPath(itemDataPath, itemValue);
    }
    if (this.isItemAlreadySelected(data)) {
      return false;
    }
    path = this.getCollectionPath();
    itemName = "" + name + "-" + (this.selectedItemCounter++);
    if (form) {
      collection = form.getCustomData(path) || [];
      collection.push(submitValuesAsText ? itemValue : (typeof itemValue.getId === "function" ? itemValue.getId() : void 0) ? {
        constructorName: itemValue.constructor.name,
        id: itemValue.getId(),
        title: itemValue.title
      } : {
        $suggest: itemValue
      });
      form.addCustomData(path, collection);
      if (item.getOptions().userInput === !"") {
        this.selectedItemCounter++;
      }
    } else {
      this.addHiddenInputItem(path, itemValue);
    }
    this.addSelectedItemData(data);
    this.addSelectedItem(itemName, data);
    return this.getView().setValue(this.dropdownPrefix = "");
  };

  KDAutoCompleteController.prototype.removeFromSubmitQueue = function(item, data) {
    var collection, form, itemDataPath, path, _ref;
    _ref = this.getOptions(), itemDataPath = _ref.itemDataPath, form = _ref.form;
    data || (data = item.getData());
    path = this.getCollectionPath();
    if (form) {
      collection = JsPath.getAt(form.getCustomData(), path);
      collection = collection.filter(function(sibling) {
        var id;
        id = typeof data.getId === "function" ? data.getId() : void 0;
        if (id == null) {
          return sibling.$suggest !== data.title;
        } else {
          return sibling.id !== id;
        }
      });
      JsPath.setAt(form.getCustomData(), path, collection);
    } else {
      this.removeHiddenInputItem(path);
    }
    this.removeSelectedItemData(data);
    this.selectedItemCounter--;
    item.destroy();
    return this.emit('ItemListChanged', this.selectedItemCounter);
  };

  KDAutoCompleteController.prototype.appendAutoCompletedItem = function() {
    this.getView().setValue("");
    return this.getView().$input().trigger("focus");
  };

  KDAutoCompleteController.prototype.updateDropdownContents = function() {
    var inputView;
    inputView = this.getView();
    if (inputView.getValue() === "") {
      this.hideDropdown();
    }
    if (inputView.getValue() !== "" && this.dropdownPrefix !== inputView.getValue() && this.dropdown.getView().$().not(":visible")) {
      this.dropdownPrefix = inputView.getValue();
      return this.fetch((function(_this) {
        return function(data) {
          _this.refreshDropDown(data);
          return _this.showDropdown();
        };
      })(this));
    }
  };

  KDAutoCompleteController.prototype.keyUpOnInputView = function(event) {
    var _ref;
    if ((_ref = event.keyCode) === 9 || _ref === 38 || _ref === 40) {
      return;
    }
    this.updateDropdownContents();
    return false;
  };

  KDAutoCompleteController.prototype.fetch = function(callback) {
    var args, source;
    args = {};
    if (this.getOptions().fetchInputName) {
      args[this.getOptions().fetchInputName] = this.getView().getValue();
    } else {
      args = {
        inputValue: this.getView().getValue()
      };
    }
    this.dropdownPrefix = this.getView().getValue();
    source = this.getOptions().dataSource;
    return source(args, callback);
  };

  KDAutoCompleteController.prototype.showFetching = function() {
    var fetchingItemClass, view, _ref;
    fetchingItemClass = this.getOptions().fetchingItemClass;
    if (!(((_ref = this.dropdown.getListView().items) != null ? _ref[0] : void 0) instanceof KDAutoCompleteFetchingItem)) {
      view = new fetchingItemClass;
      if (this.dropdown.getListView().items.length) {
        return this.dropdown.getListView().addItemView(view, 0);
      } else {
        return this.dropdown.getListView().addItemView(view);
      }
    }
  };

  KDAutoCompleteController.prototype.getNoItemFoundView = function(suggestion) {
    var nothingFoundItemClass, view;
    nothingFoundItemClass = this.getOptions().nothingFoundItemClass;
    return view = new nothingFoundItemClass({
      delegate: this.dropdown.getListView(),
      userInput: suggestion || this.getView().getValue()
    });
  };

  KDAutoCompleteController.prototype.showNoDataFound = function() {
    var noItemFoundView;
    noItemFoundView = this.getNoItemFoundView();
    this.dropdown.removeAllItems();
    this.dropdown.getListView().addItemView(noItemFoundView);
    return this.showDropdown();
  };

  KDAutoCompleteController.prototype.destroy = function() {
    this.dropdown.getView().destroy();
    return KDAutoCompleteController.__super__.destroy.apply(this, arguments);
  };

  return KDAutoCompleteController;

})(KDViewController);


},{"./../../core/viewcontroller.coffee":109,"./../inputs/labelview.coffee":47,"./../list/listviewcontroller.coffee":55,"./../notifications/notificationview.coffee":61,"./autocomplete.coffee":3,"./autocompletefetchingitem.coffee":6,"./autocompletelist.coffee":7}],5:[function(require,module,exports){
var KDAutoCompletedItem, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDAutoCompletedItem = (function(_super) {
  __extends(KDAutoCompletedItem, _super);

  function KDAutoCompletedItem(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass = this.utils.curry("kdautocompletedlistitem", options.cssClass);
    KDAutoCompletedItem.__super__.constructor.apply(this, arguments);
  }

  KDAutoCompletedItem.prototype.click = function(event) {
    if ($(event.target).is('span.close-icon')) {
      this.getDelegate().removeFromSubmitQueue(this);
    }
    return this.getDelegate().getView().$input().trigger("focus");
  };

  KDAutoCompletedItem.prototype.viewAppended = function() {
    return this.setPartial(this.partial());
  };

  KDAutoCompletedItem.prototype.partial = function(data) {
    return this.getDelegate().getOptions().itemClass.prototype.partial(this.getData());
  };

  return KDAutoCompletedItem;

})(KDView);


},{"./../../core/view.coffee":108}],6:[function(require,module,exports){
var KDAutoCompleteFetchingItem, KDAutocompleteUnselecteableItem,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDAutocompleteUnselecteableItem = require('./autocompleteunselecteableitem.coffee');

module.exports = KDAutoCompleteFetchingItem = (function(_super) {
  __extends(KDAutoCompleteFetchingItem, _super);

  function KDAutoCompleteFetchingItem(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass = this.utils.curry("kdautocompletelistitem fetching", options.cssClass);
    KDAutoCompleteFetchingItem.__super__.constructor.apply(this, arguments);
  }

  KDAutoCompleteFetchingItem.prototype.partial = function() {
    return "Fetching in process...";
  };

  return KDAutoCompleteFetchingItem;

})(KDAutocompleteUnselecteableItem);


},{"./autocompleteunselecteableitem.coffee":10}],7:[function(require,module,exports){
var KDAutoCompleteListView, KDListView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDListView = require('./../list/listview.coffee');

module.exports = KDAutoCompleteListView = (function(_super) {
  __extends(KDAutoCompleteListView, _super);

  function KDAutoCompleteListView(options, data) {
    KDAutoCompleteListView.__super__.constructor.call(this, options, data);
    this.setClass("kdautocompletelist");
  }

  KDAutoCompleteListView.prototype.goDown = function() {
    var activeItem, nextItem, _ref;
    activeItem = this.getActiveItem();
    if (activeItem.index != null) {
      nextItem = this.items[activeItem.index + 1];
      if (nextItem != null) {
        return nextItem.makeItemActive();
      }
    } else {
      return (_ref = this.items[0]) != null ? _ref.makeItemActive() : void 0;
    }
  };

  KDAutoCompleteListView.prototype.goUp = function() {
    var activeItem;
    activeItem = this.getActiveItem();
    if (activeItem.index != null) {
      if (this.items[activeItem.index - 1] != null) {
        return this.items[activeItem.index - 1].makeItemActive();
      } else {
        return this.emit('ItemsDeselected');
      }
    } else {
      return this.items[0].makeItemActive();
    }
  };

  KDAutoCompleteListView.prototype.getActiveItem = function() {
    var active, i, item, _i, _len, _ref;
    active = {
      index: null,
      item: null
    };
    _ref = this.items;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      item = _ref[i];
      if (item.active) {
        active.item = item;
        active.index = i;
        break;
      }
    }
    return active;
  };

  return KDAutoCompleteListView;

})(KDListView);


},{"./../list/listview.coffee":54}],8:[function(require,module,exports){
var KDAutoCompleteListItemView, KDListItemView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDListItemView = require('./../list/listitemview.coffee');

module.exports = KDAutoCompleteListItemView = (function(_super) {
  __extends(KDAutoCompleteListItemView, _super);

  function KDAutoCompleteListItemView(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass = KD.utils.curry("kdautocompletelistitem", options.cssClass);
    options.bind = "mouseenter mouseleave";
    KDAutoCompleteListItemView.__super__.constructor.call(this, options, data);
    this.active = false;
  }

  KDAutoCompleteListItemView.prototype.viewAppended = function() {
    return this.updatePartial(this.partial(this.data));
  };

  KDAutoCompleteListItemView.prototype.mouseEnter = function() {
    return this.makeItemActive();
  };

  KDAutoCompleteListItemView.prototype.mouseLeave = function() {
    return this.makeItemInactive();
  };

  KDAutoCompleteListItemView.prototype.makeItemActive = function() {
    var item, _i, _len, _ref;
    _ref = this.getDelegate().items;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      item.makeItemInactive();
    }
    this.active = true;
    return this.setClass("active");
  };

  KDAutoCompleteListItemView.prototype.makeItemInactive = function() {
    this.active = false;
    return this.unsetClass("active");
  };

  KDAutoCompleteListItemView.prototype.click = function() {
    var list;
    list = this.getDelegate();
    list.emit('KDAutoCompleteSubmit', this, this.data);
    return false;
  };

  KDAutoCompleteListItemView.prototype.partial = function() {
    return "<div class='autocomplete-item clearfix'>Default item</div>";
  };

  return KDAutoCompleteListItemView;

})(KDListItemView);


},{"./../list/listitemview.coffee":53}],9:[function(require,module,exports){
var KDAutoCompleteNothingFoundItem, KDAutocompleteUnselecteableItem,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDAutocompleteUnselecteableItem = require('./autocompleteunselecteableitem.coffee');

module.exports = KDAutoCompleteNothingFoundItem = (function(_super) {
  __extends(KDAutoCompleteNothingFoundItem, _super);

  function KDAutoCompleteNothingFoundItem(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass = this.utils.curry("kdautocompletelistitem no-result", options.cssClass);
    KDAutoCompleteNothingFoundItem.__super__.constructor.apply(this, arguments);
  }

  KDAutoCompleteNothingFoundItem.prototype.partial = function(data) {
    return "Nothing found";
  };

  return KDAutoCompleteNothingFoundItem;

})(KDAutocompleteUnselecteableItem);


},{"./autocompleteunselecteableitem.coffee":10}],10:[function(require,module,exports){
var KDAutocompleteUnselecteableItem, KDListItemView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDListItemView = require('./../list/listitemview.coffee');

module.exports = KDAutocompleteUnselecteableItem = (function(_super) {
  __extends(KDAutocompleteUnselecteableItem, _super);

  function KDAutocompleteUnselecteableItem() {
    return KDAutocompleteUnselecteableItem.__super__.constructor.apply(this, arguments);
  }

  KDAutocompleteUnselecteableItem.prototype.click = function() {
    return false;
  };

  KDAutocompleteUnselecteableItem.prototype.keyUp = function() {
    return false;
  };

  KDAutocompleteUnselecteableItem.prototype.keyDown = function() {
    return false;
  };

  KDAutocompleteUnselecteableItem.prototype.makeItemActive = function() {};

  KDAutocompleteUnselecteableItem.prototype.destroy = function() {
    return KDAutocompleteUnselecteableItem.__super__.destroy.call(this, false);
  };

  return KDAutocompleteUnselecteableItem;

})(KDListItemView);


},{"./../list/listitemview.coffee":53}],11:[function(require,module,exports){
var KDListView, MultipleInputListView, MultipleListItemView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDListView = require('./../list/listview.coffee');

MultipleListItemView = require('./multiplelistitemview.coffee');

module.exports = MultipleInputListView = (function(_super) {
  __extends(MultipleInputListView, _super);

  function MultipleInputListView() {
    return MultipleInputListView.__super__.constructor.apply(this, arguments);
  }

  MultipleInputListView.prototype.setDomElement = function() {
    return this.domElement = $("<p class='search-tags clearfix'></p>");
  };

  MultipleInputListView.prototype.addItems = function(items) {
    var item, newItem, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = items.length; _i < _len; _i++) {
      item = items[_i];
      newItem = new MultipleListItemView({
        delegate: this
      }, item);
      _results.push(this.addItemView(newItem));
    }
    return _results;
  };

  MultipleInputListView.prototype.removeListItem = function(instance) {
    MultipleInputListView.__super__.removeListItem.call(this, instance);
    return this.getDelegate().inputRemoveValue(instance.getData());
  };

  return MultipleInputListView;

})(KDListView);


},{"./../list/listview.coffee":54,"./multiplelistitemview.coffee":13}],12:[function(require,module,exports){
var KDInputView, KDMultipleInputView, KDSimpleAutocomplete, MultipleInputListView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

KDSimpleAutocomplete = require('./simpleautocomplete.coffee');

MultipleInputListView = require('./multipleinputlistview.coffee');

KDInputView = require('./../inputs/inputview.coffee');

module.exports = KDMultipleInputView = (function(_super) {
  __extends(KDMultipleInputView, _super);

  function KDMultipleInputView(options) {
    this._values = [];
    options = $.extend({
      icon: 'noicon',
      title: ''
    }, options);
    KDMultipleInputView.__super__.constructor.call(this, options);
  }

  KDMultipleInputView.prototype.focus = function(pubInst, event) {
    return (KD.getSingleton("windowController")).setKeyView(this);
  };

  KDMultipleInputView.prototype.viewAppended = function() {
    this.list = new MultipleInputListView({
      delegate: this
    });
    return this.addSubView(this.list);
  };

  KDMultipleInputView.prototype.$input = function() {
    return this.$().find("input.main").eq(0);
  };

  KDMultipleInputView.prototype.getValues = function() {
    return this._values;
  };

  KDMultipleInputView.prototype.addItemToSubmitQueue = function() {
    KDMultipleInputView.__super__.addItemToSubmitQueue.apply(this, arguments);
    return this.inputAddCurrentValue();
  };

  KDMultipleInputView.prototype.keyUp = function(event) {
    if (event.keyCode === 13) {
      this.inputAddCurrentValue();
    }
    return KDMultipleInputView.__super__.keyUp.apply(this, arguments);
  };

  KDMultipleInputView.prototype.inputRemoveValue = function(value) {
    var index;
    index = this._values.indexOf(value);
    if (index > -1) {
      this._values.splice(index, 1);
    }
    return this._inputChanged();
  };

  KDMultipleInputView.prototype.clear = function() {
    this._values = [];
    this.removeAllItems();
    return this._inputChanged();
  };

  KDMultipleInputView.prototype.inputAddCurrentValue = function() {
    var value;
    value = this.$input().val();
    value = $.trim(value);
    if (__indexOf.call(this._values, value) >= 0 || value === '') {
      return;
    }
    this._values.push(value);
    this.$input().val('');
    this.list.addItems([value]);
    return this._inputChanged();
  };

  KDMultipleInputView.prototype._inputChanged = function() {
    var index, input, inputName, newInput, value, _i, _j, _len, _len1, _ref, _ref1;
    if (!this._hiddenInputs) {
      this._hiddenInputs = [];
    }
    _ref = this._hiddenInputs;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      input = _ref[_i];
      input.destroy();
    }
    inputName = this.getOptions().name;
    _ref1 = this._values;
    for (index = _j = 0, _len1 = _ref1.length; _j < _len1; index = ++_j) {
      value = _ref1[index];
      newInput = new KDInputView({
        type: 'hidden',
        name: inputName + ("[" + index + "]"),
        defaultValue: value
      });
      this._hiddenInputs.push(newInput);
      this.addSubView(newInput);
    }
    return this.emit('MultipleInputChanged', {
      values: this.getValue()
    });
  };

  KDMultipleInputView.prototype.click = function(event) {
    if ($(event.target).hasClass('addNewItem')) {
      return this.inputAddCurrentValue();
    }
  };

  KDMultipleInputView.prototype.setDomId = function() {
    this.$input().attr("id", this.getDomId());
    return this.$input().data("data-id", this.getId());
  };

  KDMultipleInputView.prototype.setDomElement = function() {
    return this.domElement = $("<div class='filter kdview'> <h2>" + (this.getOptions().title) + "</h2> <div class='clearfix'> <span class='" + (this.getOptions().icon) + "'></span> <input type='text' class='main'> <a href='#' class='addNewItem'>+</a> </div> </div>");
  };

  return KDMultipleInputView;

})(KDSimpleAutocomplete);


},{"./../inputs/inputview.coffee":46,"./multipleinputlistview.coffee":11,"./simpleautocomplete.coffee":16}],13:[function(require,module,exports){
var KDListItemView, MultipleListItemView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDListItemView = require('./../list/listitemview.coffee');

module.exports = MultipleListItemView = (function(_super) {
  __extends(MultipleListItemView, _super);

  function MultipleListItemView() {
    return MultipleListItemView.__super__.constructor.apply(this, arguments);
  }

  MultipleListItemView.prototype.click = function(event) {
    if ($(event.target).hasClass('removeIcon')) {
      return this.getDelegate().removeListItem(this);
    }
  };

  MultipleListItemView.prototype.setDomElement = function() {
    return this.domElement = $('<span />');
  };

  MultipleListItemView.prototype.partial = function() {
    return "" + (this.getData()) + " <cite class='removeIcon'>x</cite>";
  };

  return MultipleListItemView;

})(KDListItemView);


},{"./../list/listitemview.coffee":53}],14:[function(require,module,exports){
var KDMultipleInputView, NoAutocompleteInputView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDMultipleInputView = require('./multipleinputview.coffee');

module.exports = NoAutocompleteInputView = (function(_super) {
  __extends(NoAutocompleteInputView, _super);

  function NoAutocompleteInputView() {
    return NoAutocompleteInputView.__super__.constructor.apply(this, arguments);
  }

  NoAutocompleteInputView.prototype.keyUp = function(event) {
    if (event.keyCode === 13) {
      return this.inputAddCurrentValue();
    }
  };

  NoAutocompleteInputView.prototype.setDomElement = function(cssClass) {
    var placeholder;
    placeholder = this.getOptions().placeholder;
    return this.domElement = $("<div class='" + cssClass + "'><input type='text' class='main' placeholder='" + (placeholder || '') + "' /></div>");
  };

  NoAutocompleteInputView.prototype.addItemToSubmitQueue = function(item) {
    return false;
  };

  return NoAutocompleteInputView;

})(KDMultipleInputView);


},{"./multipleinputview.coffee":12}],15:[function(require,module,exports){
var KDView, NoAutocompleteMultipleListView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = NoAutocompleteMultipleListView = (function(_super) {
  __extends(NoAutocompleteMultipleListView, _super);

  function NoAutocompleteMultipleListView(options, data) {
    var defaults;
    if (options == null) {
      options = {};
    }
    defaults = {
      cssClass: 'common-view input-with-extras'
    };
    options = $.extend(defaults, options);
    NoAutocompleteMultipleListView.__super__.constructor.call(this, options, data);
  }

  NoAutocompleteMultipleListView.prototype.viewAppended = function() {
    var button, defaults, icon, input, options, _ref;
    _ref = this.options, icon = _ref.icon, input = _ref.input, button = _ref.button;
    if (icon) {
      this.setClass("with-icon");
      options = {
        tagName: "span",
        cssClass: "icon " + icon
      };
      this.addSubView(this.icon = new KDCustomHTMLView(options));
    }
    if (input) {
      this.addSubView(this.input = new KDNoAutocompleteInputView(input));
    }
    if (button) {
      defaults = {
        callback: (function(_this) {
          return function(event) {
            event.preventDefault();
            event.stopPropagation();
            return _this.input.inputAddCurrentValue();
          };
        })(this)
      };
      button = $.extend(defaults, button);
      return this.addSubView(this.button = new KDButtonView(button));
    }
  };

  return NoAutocompleteMultipleListView;

})(KDView);


},{"./../../core/view.coffee":108}],16:[function(require,module,exports){
var KDAutoComplete, KDSimpleAutocomplete,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDAutoComplete = require('./autocomplete.coffee');

module.exports = KDSimpleAutocomplete = (function(_super) {
  __extends(KDSimpleAutocomplete, _super);

  function KDSimpleAutocomplete() {
    return KDSimpleAutocomplete.__super__.constructor.apply(this, arguments);
  }

  KDSimpleAutocomplete.prototype.addItemToSubmitQueue = function(item) {
    var itemValue;
    itemValue = JsPath.getAt(item.getData(), this.getOptions().itemDataPath);
    return this.setValue(itemValue);
  };

  KDSimpleAutocomplete.prototype.keyUp = function(event) {
    if (event.keyCode === 13) {
      return;
    }
    return KDSimpleAutocomplete.__super__.keyUp.apply(this, arguments);
  };

  KDSimpleAutocomplete.prototype.showNoDataFound = function() {
    this.dropdown.removeAllItems();
    return this.hideDropdown();
  };

  return KDSimpleAutocomplete;

})(KDAutoComplete);


},{"./autocomplete.coffee":3}],17:[function(require,module,exports){
var KDButtonBar, KDButtonView, KDFormView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

KDButtonView = require('./buttonview');

KDFormView = require('../forms/formview.coffee');

module.exports = KDButtonBar = (function(_super) {
  __extends(KDButtonBar, _super);

  function KDButtonBar(options, data) {
    var button, buttonOptions, buttons, _i, _len, _ref;
    if (options == null) {
      options = {};
    }
    options.cssClass = KD.utils.curry("formline button-field clearfix", options.cssClass);
    KDButtonBar.__super__.constructor.call(this, options, data);
    this.buttons = {};
    buttons = options.buttons;
    _ref = KDFormView.sanitizeFormOptions(buttons);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      buttonOptions = _ref[_i];
      button = this.createButton(buttonOptions);
      this.addSubView(button);
      this.buttons[buttonOptions.key] = button;
    }
  }

  KDButtonBar.prototype._itemClass = KDButtonView;

  KDButtonBar.prototype.createButton = function(options) {
    var button, o;
    options || (options = {});
    options.itemClass || (options.itemClass = this._itemClass);
    o = $.extend({}, options);
    delete o.itemClass;
    return button = new options.itemClass(o);
  };

  return KDButtonBar;

})(KDView);


},{"../forms/formview.coffee":34,"./../../core/view.coffee":108,"./buttonview":20}],18:[function(require,module,exports){
var KDButtonGroupView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDButtonGroupView = (function(_super) {
  __extends(KDButtonGroupView, _super);

  function KDButtonGroupView(options, data) {
    var cssClass;
    if (options == null) {
      options = {};
    }
    cssClass = options.cssClass;
    cssClass = cssClass ? " " + cssClass : "";
    options.cssClass = "kdbuttongroup" + cssClass;
    options.buttons || (options.buttons = {});
    KDButtonGroupView.__super__.constructor.call(this, options, data);
    this.buttons = {};
    this.createButtons(options.buttons);
  }

  KDButtonGroupView.prototype.createButtons = function(allButtonOptions) {
    var buttonClass, buttonOptions, buttonTitle, _results;
    _results = [];
    for (buttonTitle in allButtonOptions) {
      if (!__hasProp.call(allButtonOptions, buttonTitle)) continue;
      buttonOptions = allButtonOptions[buttonTitle];
      buttonClass = buttonOptions.buttonClass || KDButtonView;
      buttonOptions.title = buttonTitle;
      buttonOptions.style = "";
      this.addSubView(this.buttons[buttonTitle] = new buttonClass(buttonOptions));
      _results.push(this.buttons[buttonTitle].on("click", (function(_this) {
        return function(event) {
          return _this.buttonReceivedClick(_this.buttons[buttonTitle], event);
        };
      })(this)));
    }
    return _results;
  };

  KDButtonGroupView.prototype.buttonReceivedClick = function(button, event) {
    var otherButton, title, _ref;
    _ref = this.buttons;
    for (title in _ref) {
      if (!__hasProp.call(_ref, title)) continue;
      otherButton = _ref[title];
      otherButton.unsetClass("toggle");
    }
    return button.setClass("toggle");
  };

  return KDButtonGroupView;

})(KDView);


},{"./../../core/view.coffee":108}],19:[function(require,module,exports){
var JButtonMenu, KDContextMenu,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDContextMenu = require('./../contextmenu/contextmenu.coffee');

module.exports = JButtonMenu = (function(_super) {
  __extends(JButtonMenu, _super);

  function JButtonMenu(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass = this.utils.curry("kdbuttonmenu", options.cssClass);
    options.listViewClass || (options.listViewClass = JContextMenuTreeView);
    JButtonMenu.__super__.constructor.call(this, options, data);
  }

  JButtonMenu.prototype.viewAppended = function() {
    JButtonMenu.__super__.viewAppended.apply(this, arguments);
    this.setPartial("<div class='chevron-ghost-wrapper'><span class='chevron-ghost'></span></div>");
    return this.positionContextMenu();
  };

  JButtonMenu.prototype.positionContextMenu = KD.utils.debounce(10, function() {
    var button, buttonHeight, buttonWidth, ghostCss, mainHeight, mainScroll, menuHeight, menuWidth, top;
    button = this.getDelegate();
    mainHeight = $(window).height();
    mainScroll = $(window).scrollTop();
    buttonHeight = button.getHeight();
    buttonWidth = button.getWidth();
    top = button.getY() + buttonHeight;
    menuHeight = this.getHeight();
    menuWidth = this.getWidth();
    ghostCss = top + menuHeight > mainHeight + mainScroll ? (top = button.getY() - menuHeight, this.setClass("top-menu"), {
      top: "100%",
      height: buttonHeight
    }) : {
      top: -(buttonHeight + 1),
      height: buttonHeight
    };
    this.$(".chevron-ghost-wrapper").css(ghostCss);
    return this.$().css({
      top: top,
      left: button.getX() + buttonWidth - menuWidth
    });
  });

  return JButtonMenu;

})(KDContextMenu);


},{"./../contextmenu/contextmenu.coffee":23}],20:[function(require,module,exports){
var KDButtonView, KDLoaderView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

KDLoaderView = require('./../loader/loaderview.coffee');


/**
 * KDButtonView implements a `<button>` DOM element, with the ability to subscribe
 * to click events.
 *
 * ## Usage
 *
 * ```coffee
 * view = new KDButtonView
 *   title: 'Click me!'
 *   cssClass: 'cupid-green'
 *   callback: ->
 *     alert 'I got clicked!'
 *
 * appView.addSubView view
 * ```
 *
 * This example will render a green button, with the text `"Click me!"`. When the
 * button is pressed by the user, an alert will pop up with the message `"I got
 * clicked!"`
 *
 * While this example is fine for an immediate action, what if we wanted our
 * button to load a project? For that, we tell the button to use a
 * [KDLoaderView](./kdloaderview.md). Lets see how this looks.
 *
 * ```coffee
 * view = new KDButtonView
 *   title: 'Take a long time.'
 *   cssClass: 'clean-red'
 *   loader: {}
 *   callback: ->
 *     longTimeDone = =>
 *       @hideLoader()
 *     setTimeout longTimeDone, 2000
 *
 * appView.addSubView view
 * ```
 *
 * In this example, a couple things are different. First, we define a loader
 * object. This is an object full of options that are passed to a
 * [KDLoaderView](./kdloaderview.md) instance. You'll note that we don't actually
 * define any options, but the empty object will cause a loader to be used with
 * the default options.
 *
 * Secondly, in our callback we turn the loader off with the
 * [hideLoader](#hideloader) method, after a `setTimeout` of 2000.
 *
 * The end result of these changes is that when our button is clicked, it starts
 * the loader *(with the options we define)*. When we want to turn it off, we call
 * the `@hideLoader()` method. Easy!
 *
 * ## Styling
 *
 * While not complete, the following list contains some useful built-in
 * css classes to style your button with.
 *
 * - **small-gray**: A small, gray button.
 * - **small-blue**: A small, blue button.
 * - **clean-gray**: A clean gray button, the default button style.
 * - **clean-red**: A clean red button.
 * - **cupid-green**: A green button.
 * - **transparent**: And no surprise, a transparent button.
 */

module.exports = KDButtonView = (function(_super) {
  __extends(KDButtonView, _super);


  /**
   * Options supports the following keys:
   * - **options.title**: The title of the button.
   * - **options.callback**: The function to be called when the button is pressed.
   * - **options.loader**: The options to use for a loader on this button. If
   *   false, this button will not use a loader by default. See
   *   KDLoaderView for the supported options.
   *
   * @param {Object} options
   * @param {Object} data
   */

  function KDButtonView(options, data) {
    if (options == null) {
      options = {};
    }
    options.callback || (options.callback = noop);
    options.title || (options.title = "");
    options.type || (options.type = "button");
    options.cssClass || (options.cssClass = options.style || (options.style = "clean-gray"));
    if (options.icon == null) {
      options.icon = false;
    }
    if (options.iconOnly == null) {
      options.iconOnly = false;
    }
    options.iconClass || (options.iconClass = "");
    if (options.disabled == null) {
      options.disabled = false;
    }
    options.hint || (options.hint = null);
    if (options.loader == null) {
      options.loader = false;
    }
    KDButtonView.__super__.constructor.call(this, options, data);
    this.setClass(options.style);
    this.setCallback(options.callback);
    this.setTitle(options.title);
    if (options.iconClass) {
      this.setIconClass(options.iconClass);
    }
    if (options.icon || options.iconOnly) {
      this.showIcon();
    }
    if (options.iconOnly) {
      this.setIconOnly(options.iconOnly);
    }
    if (options.disabled) {
      this.disable();
    }
    if (options.focus) {
      this.once("viewAppended", this.bound("setFocus"));
    }
    if (options.loader) {
      this.once("viewAppended", this.bound("setLoader"));
    }
  }

  KDButtonView.prototype.setFocus = function() {
    return this.$().trigger('focus');
  };

  KDButtonView.prototype.setDomElement = function(cssClass) {
    var el, klass, lazyDomId, tagName, _i, _len, _ref, _ref1;
    _ref = this.getOptions(), lazyDomId = _ref.lazyDomId, tagName = _ref.tagName;
    if (lazyDomId) {
      el = document.getElementById(lazyDomId);
      _ref1 = ("kdview " + cssClass).split(' ');
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        klass = _ref1[_i];
        if (klass.length) {
          el.classList.add(klass);
        }
      }
    }
    if (el == null) {
      if (lazyDomId) {
        warn("No lazy DOM Element found with given id " + lazyDomId + ".");
      }
      el = "<button type='" + (this.getOptions().type) + "' class='kdbutton " + cssClass + "' id='" + (this.getId()) + "'>\n  <span class='icon hidden'></span>\n  <span class='button-title'>Title</span>\n</button>";
    }
    return this.domElement = $(el);
  };

  KDButtonView.prototype.setTitle = function(title) {
    this.buttonTitle = title;
    return this.$('.button-title').html(title);
  };

  KDButtonView.prototype.getTitle = function() {
    return this.buttonTitle;
  };

  KDButtonView.prototype.setCallback = function(callback) {
    return this.buttonCallback = callback;
  };

  KDButtonView.prototype.getCallback = function() {
    return this.buttonCallback;
  };

  KDButtonView.prototype.showIcon = function() {
    this.setClass("with-icon");
    return this.$('span.icon').removeClass('hidden');
  };

  KDButtonView.prototype.hideIcon = function() {
    this.unsetClass("with-icon");
    return this.$('span.icon').addClass('hidden');
  };

  KDButtonView.prototype.setIconClass = function(iconClass) {
    this.$('.icon').attr('class', 'icon');
    return this.$('.icon').addClass(iconClass);
  };

  KDButtonView.prototype.setIconOnly = function() {
    var $icon;
    this.unsetClass("with-icon");
    this.$().addClass('icon-only');
    $icon = this.$('span.icon');
    return this.$().html($icon);
  };

  KDButtonView.prototype.setLoader = function() {
    var loader, loaderSize, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;
    this.setClass("w-loader");
    loader = this.getOptions().loader;
    loaderSize = this.getHeight() / 2;
    this.loader = new KDLoaderView({
      size: {
        width: (_ref = loader.diameter) != null ? _ref : loaderSize
      },
      loaderOptions: {
        color: loader.color || "#ffffff",
        shape: loader.shape || "spiral",
        diameter: (_ref1 = loader.diameter) != null ? _ref1 : loaderSize,
        density: (_ref2 = loader.density) != null ? _ref2 : 30,
        range: (_ref3 = loader.range) != null ? _ref3 : 0.4,
        speed: (_ref4 = loader.speed) != null ? _ref4 : 1.5,
        FPS: (_ref5 = loader.FPS) != null ? _ref5 : 24
      }
    });
    this.addSubView(this.loader, null, true);
    this.loader.$().css({
      position: "absolute",
      left: loader.left || "50%",
      top: loader.top || "50%",
      marginTop: -(loader.diameter / 2),
      marginLeft: -(loader.diameter / 2)
    });
    return this.loader.hide();
  };


  /**
   * Show the KDLoaderView on this button, if any. Note that the loader is
   * shown by default when the button is clicked.
   */

  KDButtonView.prototype.showLoader = function() {
    var icon, iconOnly, _ref;
    if (!this.loader) {
      return warn('KDButtonView::showLoader is called where no loader is set');
    }
    _ref = this.getOptions(), icon = _ref.icon, iconOnly = _ref.iconOnly;
    this.setClass("loading");
    this.loader.show();
    if (icon && !iconOnly) {
      return this.hideIcon();
    }
  };


  /**
   * Hide the KDLoaderView on this button, if any.
   */

  KDButtonView.prototype.hideLoader = function() {
    var icon, iconOnly, _ref;
    if (!this.loader) {
      return warn('KDButtonView::hideLoader is called where no loader is set');
    }
    _ref = this.getOptions(), icon = _ref.icon, iconOnly = _ref.iconOnly;
    this.unsetClass("loading");
    this.loader.hide();
    if (icon && !iconOnly) {
      return this.showIcon();
    }
  };

  KDButtonView.prototype.disable = function() {
    return this.$().attr("disabled", true);
  };

  KDButtonView.prototype.enable = function() {
    return this.$().attr("disabled", false);
  };

  KDButtonView.prototype.focus = function() {
    return this.$().trigger("focus");
  };

  KDButtonView.prototype.blur = function() {
    return this.$().trigger("blur");
  };

  KDButtonView.prototype.click = function(event) {
    var _ref;
    if ((_ref = this.loader) != null ? _ref.active : void 0) {
      return this.utils.stopDOMEvent();
    }
    if (this.loader && !this.loader.active) {
      this.showLoader();
    }
    if (this.getOption('type') === "button") {
      this.utils.stopDOMEvent();
    }
    this.getCallback().call(this, event);
    return false;
  };

  KDButtonView.prototype.triggerClick = function() {
    return this.doOnSubmit();
  };

  return KDButtonView;

})(KDView);


},{"./../../core/view.coffee":108,"./../loader/loaderview.coffee":56}],21:[function(require,module,exports){
var KDButtonView, KDButtonViewWithMenu,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDButtonView = require('./buttonview.coffee');

module.exports = KDButtonViewWithMenu = (function(_super) {
  __extends(KDButtonViewWithMenu, _super);

  function KDButtonViewWithMenu() {
    return KDButtonViewWithMenu.__super__.constructor.apply(this, arguments);
  }

  KDButtonViewWithMenu.prototype.setDomElement = function(cssClass) {
    if (cssClass == null) {
      cssClass = '';
    }
    this.domElement = $("<div class='kdbuttonwithmenu-wrapper " + cssClass + "'>\n  <button class='kdbutton " + cssClass + " with-icon with-menu' id='" + (this.getId()) + "'>\n    <span class='icon hidden'></span>\n  </button>\n  <span class='chevron-separator'></span>\n  <span class='chevron'></span>\n</div>");
    this.$button = this.$('button').first();
    return this.domElement;
  };

  KDButtonViewWithMenu.prototype.setIconOnly = function() {
    var $icons;
    this.$().addClass('icon-only').removeClass('with-icon');
    $icons = this.$('span.icon,span.chevron');
    return this.$().html($icons);
  };

  KDButtonViewWithMenu.prototype.click = function(event) {
    if ($(event.target).is(".chevron")) {
      this.contextMenu(event);
      return false;
    }
    return this.getCallback().call(this, event);
  };

  KDButtonViewWithMenu.prototype.contextMenu = function(event) {
    this.createContextMenu(event);
    return false;
  };

  KDButtonViewWithMenu.prototype.createContextMenu = function(event) {
    var menuArrayToObj, menuObject, menuObjectProperty, menuObjectValue, o;
    o = this.getOptions();
    this.buttonMenu = new (o.buttonMenuClass || JButtonMenu)({
      cssClass: o.style,
      ghost: this.$('.chevron').clone(),
      event: event,
      delegate: this,
      treeItemClass: o.treeItemClass,
      itemChildClass: o.itemChildClass,
      itemChildOptions: o.itemChildOptions
    }, (function() {
      var _i, _len, _ref;
      if ("function" === typeof o.menu) {
        return o.menu();
      } else {
        if (o.menu instanceof Array) {
          menuArrayToObj = {};
          _ref = o.menu;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            menuObject = _ref[_i];
            for (menuObjectProperty in menuObject) {
              if (!__hasProp.call(menuObject, menuObjectProperty)) continue;
              menuObjectValue = menuObject[menuObjectProperty];
              if ((menuObjectProperty != null) && (menuObjectValue != null)) {
                menuArrayToObj[menuObjectProperty] = menuObjectValue;
              }
            }
          }
          return menuArrayToObj;
        } else {
          return o.menu;
        }
      }
    })());
    return this.buttonMenu.on("ContextMenuItemReceivedClick", (function(_this) {
      return function() {
        return _this.buttonMenu.destroy();
      };
    })(this));
  };

  KDButtonViewWithMenu.prototype.setTitle = function(title) {
    return this.$button.append(title);
  };

  KDButtonViewWithMenu.prototype.setButtonStyle = function(newStyle) {
    var style, styles, _i, _len;
    styles = this.constructor.styles;
    for (_i = 0, _len = styles.length; _i < _len; _i++) {
      style = styles[_i];
      this.$().removeClass(style);
      this.$button.removeClass(style);
    }
    this.$button.addClass(newStyle);
    return this.$().addClass(newStyle);
  };

  KDButtonViewWithMenu.prototype.setIconOnly = function() {
    var $icon;
    this.$button.addClass('icon-only').removeClass('with-icon');
    $icon = this.$('span.icon');
    return this.$button.html($icon);
  };

  KDButtonViewWithMenu.prototype.disable = function() {
    return this.$button.attr("disabled", true);
  };

  KDButtonViewWithMenu.prototype.enable = function() {
    return this.$button.attr("disabled", false);
  };

  return KDButtonViewWithMenu;

})(KDButtonView);


},{"./buttonview.coffee":20}],22:[function(require,module,exports){
var KDButtonView, KDToggleButton,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDButtonView = require('./buttonview.coffee');

module.exports = KDToggleButton = (function(_super) {
  __extends(KDToggleButton, _super);

  function KDToggleButton(options, data) {
    if (options == null) {
      options = {};
    }
    options = $.extend({
      dataPath: null,
      defaultState: null,
      states: []
    }, options);
    KDToggleButton.__super__.constructor.call(this, options, data);
    this.setState(options.defaultState);
  }

  KDToggleButton.prototype.getStateIndex = function(name) {
    var index, state, states, _i, _len;
    states = this.getOptions().states;
    if (!name) {
      return 0;
    } else {
      for (index = _i = 0, _len = states.length; _i < _len; index = ++_i) {
        state = states[index];
        if (name === state.title) {
          return index;
        }
      }
    }
  };

  KDToggleButton.prototype.decorateState = function(name) {
    this.setTitle(this.state.title);
    if (this.state.iconClass != null) {
      this.setIconClass(this.state.iconClass);
    }
    if ((this.state.cssClass != null) || (this.lastUsedCssClass != null)) {
      if (this.lastUsedCssClass != null) {
        this.unsetClass(this.lastUsedCssClass);
      }
      this.setClass(this.state.cssClass);
      return this.lastUsedCssClass = this.state.cssClass;
    } else {
      return delete this.lastUsedCssClass;
    }
  };

  KDToggleButton.prototype.getState = function() {
    return this.state;
  };

  KDToggleButton.prototype.setState = function(name) {
    var index, states;
    states = this.getOptions().states;
    this.stateIndex = index = this.getStateIndex(name);
    this.state = states[index];
    this.decorateState(name);
    return this.setCallback(states[index].callback.bind(this, this.toggleState.bind(this)));
  };

  KDToggleButton.prototype.toggleState = function(err) {
    var nextState, states;
    states = this.getOptions().states;
    nextState = states[this.stateIndex + 1] || states[0];
    if (!err) {
      this.setState(nextState.title);
    } else {
      if (err.name !== 'AccessDenied') {
        warn(err.message || ("There was an error, couldn't switch to " + nextState.title + " state!"));
      }
    }
    return typeof this.hideLoader === "function" ? this.hideLoader() : void 0;
  };

  return KDToggleButton;

})(KDButtonView);


},{"./buttonview.coffee":20}],23:[function(require,module,exports){
var JContextMenuTreeViewController, KDContextMenu, KDCustomHTMLView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

KDCustomHTMLView = require('./../../core/customhtmlview.coffee');

JContextMenuTreeViewController = require('./contextmenutreeviewcontroller.coffee');

module.exports = KDContextMenu = (function(_super) {
  __extends(KDContextMenu, _super);

  function KDContextMenu(options, data) {
    var o, _base, _base1, _ref;
    if (options == null) {
      options = {};
    }
    options.cssClass = this.utils.curry("kdcontextmenu", options.cssClass);
    options.menuMaxWidth || (options.menuMaxWidth = "auto");
    options.menuMinWidth || (options.menuMinWidth = "auto");
    options.menuWidth || (options.menuWidth = 172);
    options.offset || (options.offset = {});
    (_base = options.offset).left || (_base.left = 0);
    (_base1 = options.offset).top || (_base1.top = 0);
    if (options.arrow == null) {
      options.arrow = false;
    }
    if (options.sticky == null) {
      options.sticky = false;
    }
    KDContextMenu.__super__.constructor.call(this, options, data);
    this.topMargin = 0;
    this.leftMargin = 0;
    o = this.getOptions();
    this.sticky = o.sticky;
    KD.getSingleton("windowController").addLayer(this);
    this.on('ReceivedClickElsewhere', (function(_this) {
      return function() {
        if (!_this.sticky) {
          return _this.destroy();
        }
      };
    })(this));
    if (data) {
      this.treeController = new JContextMenuTreeViewController({
        type: o.type,
        view: o.view,
        delegate: this,
        treeItemClass: o.treeItemClass,
        listViewClass: o.listViewClass,
        itemChildClass: o.itemChildClass,
        itemChildOptions: o.itemChildOptions,
        addListsCollapsed: o.addListsCollapsed,
        putDepthInfo: o.putDepthInfo,
        lazyLoad: (_ref = o.lazyLoad) != null ? _ref : false
      }, data);
      this.addSubView(this.treeController.getView());
      this.treeController.getView().on('ReceivedClickElsewhere', (function(_this) {
        return function() {
          if (!_this.sticky) {
            return _this.destroy();
          }
        };
      })(this));
      this.treeController.on("NodeExpanded", this.bound("positionSubMenu"));
    }
    if (options.arrow) {
      this.on("viewAppended", this.bound("addArrow"));
    }
    this.appendToDomBody();
  }

  KDContextMenu.prototype.changeStickyState = function(state) {
    return this.sticky = state;
  };

  KDContextMenu.prototype.childAppended = function() {
    KDContextMenu.__super__.childAppended.apply(this, arguments);
    this.positionContextMenu();
    if (this.getOption("deferPositioning")) {
      return KD.utils.defer((function(_this) {
        return function() {
          return _this.positionContextMenu();
        };
      })(this));
    } else {
      return this.positionContextMenu();
    }
  };

  KDContextMenu.prototype.addArrow = function() {
    var o, rule, _ref;
    o = this.getOptions().arrow;
    o.placement || (o.placement = "top");
    if (o.margin == null) {
      o.margin = 0;
    }
    if ((_ref = o.placement) === 'top' || _ref === 'bottom') {
      o.margin += this.leftMargin;
    } else {
      o.margin += this.topMargin;
    }
    this.arrow = new KDCustomHTMLView({
      tagName: "span",
      cssClass: "arrow " + o.placement
    });
    this.arrow.$().css((function() {
      switch (o.placement) {
        case "top":
          rule = {};
          if (o.margin > 0) {
            rule.left = o.margin;
          } else {
            rule.right = -o.margin;
          }
          return rule;
        case "bottom":
          rule = {};
          if (o.margin > 0) {
            rule.left = o.margin;
          } else {
            rule.right = -o.margin;
          }
          return rule;
        case "right":
          rule = {};
          if (o.margin > 0) {
            rule.top = o.margin;
          } else {
            rule.bottom = -o.margin;
          }
          return rule;
        case "left":
          rule = {};
          if (o.margin > 0) {
            rule.top = o.margin;
          } else {
            rule.bottom = -o.margin;
          }
          return rule;
        default:
          return {};
      }
    })());
    return this.addSubView(this.arrow);
  };

  KDContextMenu.prototype.positionContextMenu = KD.utils.debounce(10, function() {
    var event, expectedLeft, expectedTop, left, mainHeight, mainView, mainWidth, menuHeight, menuMaxWidth, menuMinWidth, menuWidth, options, style, top;
    options = this.getOptions();
    event = options.event || {};
    mainView = KD.getSingleton('mainView');
    mainHeight = mainView.getHeight();
    mainWidth = mainView.getWidth();
    menuWidth = options.menuWidth, menuHeight = options.menuHeight, menuMaxWidth = options.menuMaxWidth, menuMinWidth = options.menuMinWidth;
    if (menuHeight == null) {
      menuHeight = this.getHeight();
    }
    if (menuWidth == null) {
      menuWidth = this.getWidth();
    }
    top = (options.y || event.pageY || 0) + options.offset.top;
    left = (options.x || event.pageX || 0) + options.offset.left;
    expectedTop = top;
    expectedLeft = left;
    if (top + menuHeight > mainHeight) {
      top = mainHeight - menuHeight + options.offset.top;
    }
    if (left + menuWidth > mainWidth) {
      left = mainWidth - menuWidth + options.offset.left;
    }
    this.topMargin = expectedTop - top;
    this.leftMargin = expectedLeft - left;
    style = {
      width: "" + menuWidth + "px",
      top: top,
      left: left
    };
    if (menuMaxWidth) {
      style.maxWidth = "" + menuMaxWidth + "px";
    }
    if (menuMinWidth) {
      style.minWidth = "" + menuMinWidth + "px";
    }
    return this.getDomElement().css(style);
  });

  KDContextMenu.prototype.positionSubMenu = function(nodeView) {
    var children, expandView, fullViewHeight, fullViewWidth, id, _ref;
    _ref = nodeView.getData(), children = _ref.children, id = _ref.id;
    if (children) {
      expandView = this.treeController.listControllers[id].getView();
      fullViewHeight = expandView.getY() + expandView.getHeight();
      if (fullViewHeight > window.innerHeight) {
        expandView.$().css("bottom", 0);
      }
      fullViewWidth = expandView.getX() + expandView.getWidth();
      if (fullViewWidth > window.innerWidth) {
        expandView.$().css("left", -expandView.getWidth());
        return expandView.setClass("left-aligned");
      }
    }
  };

  return KDContextMenu;

})(KDView);


},{"./../../core/customhtmlview.coffee":97,"./../../core/view.coffee":108,"./contextmenutreeviewcontroller.coffee":26}],24:[function(require,module,exports){
var JContextMenuItem, JTreeItemView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

JTreeItemView = require('./../tree/treeitemview.coffee');

module.exports = JContextMenuItem = (function(_super) {
  __extends(JContextMenuItem, _super);

  function JContextMenuItem(options, data) {
    if (options == null) {
      options = {};
    }
    if (data == null) {
      data = {};
    }
    options.type = "contextitem";
    options.cssClass || (options.cssClass = "default");
    JContextMenuItem.__super__.constructor.call(this, options, data);
    this.unsetClass("jtreeitem");
    if (data) {
      if (data.type === "divider" || data.type === "separator") {
        this.setClass("separator");
      }
      if (data.cssClass) {
        this.setClass(data.cssClass);
      }
      if (data.type === "customView") {
        this.addCustomView(data);
      }
      if (data.disabled) {
        this.setClass("disabled");
      }
    }
  }

  JContextMenuItem.prototype.viewAppended = function() {
    if (!this.customView) {
      return JContextMenuItem.__super__.viewAppended.call(this);
    }
  };

  JContextMenuItem.prototype.mouseDown = function() {
    return true;
  };

  JContextMenuItem.prototype.addCustomView = function(data) {
    this.setClass("custom-view");
    this.unsetClass("default");
    this.customView = data.view || new KDView;
    delete data.view;
    return this.addSubView(this.customView);
  };

  return JContextMenuItem;

})(JTreeItemView);


},{"./../../core/view.coffee":108,"./../tree/treeitemview.coffee":86}],25:[function(require,module,exports){
var JContextMenuTreeView, JTreeView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

JTreeView = require('./../tree/treeview.coffee');

module.exports = JContextMenuTreeView = (function(_super) {
  __extends(JContextMenuTreeView, _super);

  function JContextMenuTreeView(options, data) {
    if (options == null) {
      options = {};
    }
    if (data == null) {
      data = {};
    }
    options.type || (options.type = "contextmenu");
    if (options.animated == null) {
      options.animated = false;
    }
    options.cssClass || (options.cssClass = "default");
    JContextMenuTreeView.__super__.constructor.call(this, options, data);
    this.unsetClass("jtreeview");
  }

  return JContextMenuTreeView;

})(JTreeView);


},{"./../tree/treeview.coffee":87}],26:[function(require,module,exports){
var JContextMenuItem, JContextMenuTreeView, JContextMenuTreeViewController, JTreeViewController, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

JTreeViewController = require('./../tree/treeviewcontroller.coffee');

JContextMenuItem = require('./contextmenuitem.coffee');

JContextMenuTreeView = require('./contextmenutreeview.coffee');

module.exports = JContextMenuTreeViewController = (function(_super) {

  /*
  STATIC CONTEXT
   */
  var convertToArray, getUId, uId;

  __extends(JContextMenuTreeViewController, _super);

  uId = 0;

  getUId = function() {
    return ++uId;
  };

  convertToArray = JContextMenuTreeViewController.convertToArray = function(items, pId) {
    var childrenArr, divider, id, newItem, options, results, title;
    if (pId == null) {
      pId = null;
    }
    results = [];
    for (title in items) {
      if (!__hasProp.call(items, title)) continue;
      options = items[title];
      id = null;
      if ((title.indexOf("customView")) === 0) {
        newItem = {
          type: 'customView',
          parentId: pId,
          view: options
        };
        results.push(newItem);
        continue;
      }
      if (options.children) {
        id = getUId();
        options.title = title;
        options.id = id;
        options.parentId = pId;
        results.push(options);
        childrenArr = convertToArray(options.children, id);
        results = results.concat(childrenArr);
        if (options.separator) {
          divider = {
            type: 'separator',
            parentId: pId
          };
          results.push(divider);
        }
        continue;
      }
      options.title = title;
      options.parentId = pId;
      results.push(options);
      if (options.separator) {
        divider = {
          type: 'separator',
          parentId: pId
        };
        results.push(divider);
      }
    }
    return results;
  };


  /*
  INSTANCE LEVEL
   */

  function JContextMenuTreeViewController(options, data) {
    var o;
    if (options == null) {
      options = {};
    }
    o = options;
    o.view || (o.view = new KDView({
      cssClass: "context-list-wrapper"
    }));
    o.type || (o.type = "contextmenu");
    o.treeItemClass || (o.treeItemClass = JContextMenuItem);
    o.listViewClass || (o.listViewClass = JContextMenuTreeView);
    if (o.addListsCollapsed == null) {
      o.addListsCollapsed = true;
    }
    if (o.putDepthInfo == null) {
      o.putDepthInfo = true;
    }
    JContextMenuTreeViewController.__super__.constructor.call(this, o, data);
    this.expandedNodes = [];
  }

  JContextMenuTreeViewController.prototype.loadView = function() {
    JContextMenuTreeViewController.__super__.loadView.apply(this, arguments);
    if (!this.getOptions().lazyLoad) {
      return this.selectFirstNode();
    }
  };

  JContextMenuTreeViewController.prototype.initTree = function(nodes) {
    if (!nodes.length) {
      this.setData(nodes = convertToArray(nodes));
    }
    return JContextMenuTreeViewController.__super__.initTree.call(this, nodes);
  };


  /*
  Helpers
   */

  JContextMenuTreeViewController.prototype.repairIds = function(nodeData) {
    if (nodeData.type === "divider") {
      nodeData.type = "separator";
    }
    return JContextMenuTreeViewController.__super__.repairIds.apply(this, arguments);
  };


  /*
  EXPAND / COLLAPSE
   */

  JContextMenuTreeViewController.prototype.expand = function(nodeView) {
    JContextMenuTreeViewController.__super__.expand.apply(this, arguments);
    this.emit("NodeExpanded", nodeView);
    if (nodeView.expanded) {
      return this.expandedNodes.push(nodeView);
    }
  };


  /*
  NODE SELECTION
   */

  JContextMenuTreeViewController.prototype.organizeSelectedNodes = function(listController, nodes, event) {
    var depth1, nodeView;
    if (event == null) {
      event = {};
    }
    nodeView = nodes[0];
    if (this.expandedNodes.length) {
      depth1 = nodeView.getData().depth;
      this.expandedNodes.forEach((function(_this) {
        return function(expandedNode) {
          var depth2;
          depth2 = expandedNode.getData().depth;
          if (depth1 <= depth2) {
            return _this.collapse(expandedNode);
          }
        };
      })(this));
    }
    return JContextMenuTreeViewController.__super__.organizeSelectedNodes.apply(this, arguments);
  };


  /*
  re-HANDLING MOUSE EVENTS
   */

  JContextMenuTreeViewController.prototype.dblClick = function(nodeView, event) {};

  JContextMenuTreeViewController.prototype.mouseEnter = function(nodeView, event) {
    var nodeData;
    if (this.mouseEnterTimeOut) {
      clearTimeout(this.mouseEnterTimeOut);
    }
    nodeData = nodeView.getData();
    if (nodeData.type !== "separator") {
      this.selectNode(nodeView, event);
      return this.mouseEnterTimeOut = setTimeout((function(_this) {
        return function() {
          return _this.expand(nodeView);
        };
      })(this), 150);
    }
  };

  JContextMenuTreeViewController.prototype.click = function(nodeView, event) {
    var contextMenu, nodeData;
    nodeData = nodeView.getData();
    if (nodeData.type === "separator" || nodeData.disabled) {
      return;
    }
    this.toggle(nodeView);
    contextMenu = this.getDelegate();
    if (nodeData.callback && "function" === typeof nodeData.callback) {
      nodeData.callback.call(contextMenu, nodeView, event);
    }
    contextMenu.emit("ContextMenuItemReceivedClick", nodeView);
    event.stopPropagation();
    return false;
  };


  /*
  re-HANDLING KEY EVENTS
   */

  JContextMenuTreeViewController.prototype.performDownKey = function(nodeView, event) {
    var nextNode, nodeData;
    nextNode = JContextMenuTreeViewController.__super__.performDownKey.call(this, nodeView, event);
    if (nextNode) {
      nodeData = nextNode.getData();
      if (nodeData.type === "separator") {
        return this.performDownKey(nextNode, event);
      }
    }
  };

  JContextMenuTreeViewController.prototype.performUpKey = function(nodeView, event) {
    var nextNode, nodeData;
    nextNode = JContextMenuTreeViewController.__super__.performUpKey.call(this, nodeView, event);
    if (nextNode) {
      nodeData = nextNode.getData();
      if (nodeData.type === "separator") {
        this.performUpKey(nextNode, event);
      }
    }
    return nextNode;
  };

  JContextMenuTreeViewController.prototype.performRightKey = function(nodeView, event) {
    JContextMenuTreeViewController.__super__.performRightKey.apply(this, arguments);
    return this.performDownKey(nodeView, event);
  };

  JContextMenuTreeViewController.prototype.performLeftKey = function(nodeView, event) {
    var parentNode;
    parentNode = JContextMenuTreeViewController.__super__.performLeftKey.call(this, nodeView, event);
    if (parentNode) {
      this.collapse(parentNode);
    }
    return parentNode;
    return nextNode;
  };

  JContextMenuTreeViewController.prototype.performEscapeKey = function(nodeView, event) {
    KD.getSingleton("windowController").revertKeyView();
    return this.getDelegate().destroy();
  };

  JContextMenuTreeViewController.prototype.performEnterKey = function(nodeView, event) {
    var contextMenu;
    KD.getSingleton("windowController").revertKeyView();
    contextMenu = this.getDelegate();
    contextMenu.emit("ContextMenuItemReceivedClick", nodeView);
    contextMenu.destroy();
    event.stopPropagation();
    event.preventDefault();
    return false;
  };

  return JContextMenuTreeViewController;

})(JTreeViewController);


},{"./../../core/view.coffee":108,"./../tree/treeviewcontroller.coffee":88,"./contextmenuitem.coffee":24,"./contextmenutreeview.coffee":25}],27:[function(require,module,exports){
var KDCounterDigitView, KDCustomHTMLView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDCustomHTMLView = require('./../../core/customhtmlview.coffee');

module.exports = KDCounterDigitView = (function(_super) {
  __extends(KDCounterDigitView, _super);

  function KDCounterDigitView(options, data) {
    if (options == null) {
      options = {};
    }
    if (data == null) {
      data = {};
    }
    options.tagName = "ul";
    if (options.initialValue == null) {
      options.initialValue = 0;
    }
    KDCounterDigitView.__super__.constructor.call(this, options, data);
    this.currentValue = options.initialValue;
    this.createDigit();
  }

  KDCounterDigitView.prototype.createDigit = function() {
    this.addSubView(this.digit = new KDCustomHTMLView({
      tagName: "li",
      cssClass: "real",
      partial: "<span class=\"top\">" + (this.getOption('initialValue')) + "</span>\n<span class=\"bottom\">" + (this.getOption('initialValue')) + "</span>"
    }));
    this.addSubView(this.fakeDigit = new KDCustomHTMLView({
      tagName: "li",
      cssClass: "fake",
      partial: "<span class=\"top\">" + (this.getOption('initialValue')) + "</span>\n<span class=\"bottom\">" + (this.getOption('initialValue')) + "</span>"
    }));
    return this.setValue(this.getOption("initialValue"));
  };

  KDCounterDigitView.prototype.setValue = function(value) {
    if (value === this.currentValue) {
      return;
    }
    this.currentValue = value;
    this.digit.updatePartial("<span class=\"top\">" + value + "</span>\n<span class=\"bottom\">" + value + "</span>");
    this.setClass("animate");
    return KD.utils.wait(500, (function(_this) {
      return function() {
        _this.fakeDigit.updatePartial("<span class=\"top\">" + value + "</span>\n<span class=\"bottom\">" + value + "</span>");
        return _this.unsetClass("animate");
      };
    })(this));
  };

  return KDCounterDigitView;

})(KDCustomHTMLView);


},{"./../../core/customhtmlview.coffee":97}],28:[function(require,module,exports){
var KDCounterDigitView, KDCounterView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

KDCounterDigitView = require('./counterdigitview.coffee');

module.exports = KDCounterView = (function(_super) {
  __extends(KDCounterView, _super);

  function KDCounterView(options, data) {
    if (options == null) {
      options = {};
    }
    if (data == null) {
      data = {};
    }
    if (options.style == null) {
      options.style = "dark";
    }
    if (options.from == null) {
      options.from = 5000;
    }
    if (options.to == null) {
      options.to = 10000;
    }
    if (options.interval == null) {
      options.interval = 1000;
    }
    if (options.step == null) {
      options.step = 1;
    }
    if (options.autoStart == null) {
      options.autoStart = true;
    }
    options.direction = options.from < options.to ? "up" : "down";
    if (options.digits == null) {
      options.digits = options.direction === "up" ? options.to.toString().length : options.from.toString().length;
    }
    options.cssClass = KD.utils.curry("" + options.style + " " + options.direction + " kd-counter", options.cssClass);
    KDCounterView.__super__.constructor.call(this, options, data);
    this.digitsList = [];
    this.currentValue = options.from;
    this.createCounter();
    if (options.autoStart) {
      this.start();
    }
  }

  KDCounterView.prototype.createCounter = function() {
    var digits, from, i, _i, _ref, _results;
    _ref = this.getOptions(), from = _ref.from, digits = _ref.digits;
    _results = [];
    for (i = _i = 0; 0 <= digits ? _i < digits : _i > digits; i = 0 <= digits ? ++_i : --_i) {
      _results.push(this.digitsList.push(this.addSubView(new KDCounterDigitView({
        initialValue: from.toString()[i]
      }))));
    }
    return _results;
  };

  KDCounterView.prototype.setValue = function(value) {
    var i, _i, _ref, _results;
    if (value === this.currentValue) {
      return;
    }
    this.currentValue = value;
    value = value.toString();
    _results = [];
    for (i = _i = 0, _ref = value.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      _results.push(this.digitsList[i].setValue(value[i]));
    }
    return _results;
  };

  KDCounterView.prototype.start = function() {
    var timer;
    timer = this.getOption("interval");
    return this.counterInterval = KD.utils.repeat(timer, (function(_this) {
      return function() {
        var newValue;
        if (_this.getOption("direction") === "up") {
          newValue = _this.currentValue + _this.getOption("step");
        } else {
          newValue = _this.currentValue - _this.getOption("step");
        }
        _this.setValue(newValue);
        return _this.currentValue = newValue;
      };
    })(this));
  };

  return KDCounterView;

})(KDView);


},{"./../../core/view.coffee":108,"./counterdigitview.coffee":27}],29:[function(require,module,exports){
var KDDiaContainer, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDDiaContainer = (function(_super) {
  __extends(KDDiaContainer, _super);

  function KDDiaContainer(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass = KD.utils.curry('kddia-container', options.cssClass);
    if (options.draggable) {
      if ('object' !== typeof options.draggable) {
        options.draggable = {};
      }
    }
    if (options.itemClass == null) {
      options.itemClass = KDDiaObject;
    }
    KDDiaContainer.__super__.constructor.call(this, options, data);
    this.scale = 1;
    this.dias = {};
  }

  KDDiaContainer.prototype.mouseDown = function() {
    var dia, key;
    KDDiaContainer.__super__.mouseDown.apply(this, arguments);
    return this.emit("HighlightDia", (function() {
      var _ref, _results;
      _ref = this.dias;
      _results = [];
      for (key in _ref) {
        dia = _ref[key];
        _results.push(dia);
      }
      return _results;
    }).call(this));
  };

  KDDiaContainer.prototype.addDia = function(diaObj, pos) {
    if (pos == null) {
      pos = {};
    }
    this.addSubView(diaObj);
    diaObj.on("DiaObjectClicked", (function(_this) {
      return function() {
        return _this.emit("HighlightDia", diaObj);
      };
    })(this));
    diaObj.on("RemoveMyConnections", (function(_this) {
      return function() {
        return delete _this.dias[diaObj.getId()];
      };
    })(this));
    this.dias[diaObj.getId()] = diaObj;
    this.emit("NewDiaObjectAdded", this, diaObj);
    if (pos.x != null) {
      diaObj.setX(pos.x);
    }
    if (pos.y != null) {
      diaObj.setY(pos.y);
    }
    return diaObj;
  };

  KDDiaContainer.prototype.addItem = function(data, options) {
    var itemClass;
    if (options == null) {
      options = {};
    }
    itemClass = this.getOption('itemClass');
    return this.addDia(new itemClass(options, data));
  };

  KDDiaContainer.prototype.removeAllItems = function() {
    var dia, _key, _ref, _results;
    _ref = this.dias;
    _results = [];
    for (_key in _ref) {
      dia = _ref[_key];
      _results.push(typeof dia.destroy === "function" ? dia.destroy() : void 0);
    }
    return _results;
  };

  KDDiaContainer.prototype.setScale = function(scale) {
    var css, prop, props, _i, _len;
    if (scale == null) {
      scale = 1;
    }
    if (scale === this.scale) {
      return;
    }
    props = ['webkitTransform', 'MozTransform', 'transform'];
    css = {};
    for (_i = 0, _len = props.length; _i < _len; _i++) {
      prop = props[_i];
      css[prop] = "scale(" + scale + ")";
    }
    this.setStyle(css);
    return this.scale = scale;
  };

  return KDDiaContainer;

})(KDView);


},{"./../../core/view.coffee":108}],30:[function(require,module,exports){
var KDDiaJoint, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

KDView = require('./../../core/view.coffee');

module.exports = KDDiaJoint = (function(_super) {
  var types;

  __extends(KDDiaJoint, _super);

  types = ['left', 'right', 'top', 'bottom'];

  function KDDiaJoint(options, data) {
    var _ref;
    if (options == null) {
      options = {};
    }
    options.type || (options.type = 'left');
    if (_ref = options.type, __indexOf.call(types, _ref) < 0) {
      warn("Unknown joint type '" + options.type + "', falling back to 'left'");
      options.type = 'left';
    }
    if (options["static"] == null) {
      options["static"] = false;
    }
    if (options.size == null) {
      options.size = 10;
    }
    options.cssClass = KD.utils.curry("kddia-joint " + options.type, options.cssClass);
    KDDiaJoint.__super__.constructor.call(this, options, data);
    this.connections = {};
    this.type = this.getOption('type');
    this.size = this.getOption('size');
  }

  KDDiaJoint.prototype.viewAppended = function() {
    KDDiaJoint.__super__.viewAppended.apply(this, arguments);
    return this.domElement.attr("dia-id", this.getDiaId());
  };

  KDDiaJoint.prototype.getDiaId = function() {
    return "dia-" + (this.parent.getId()) + "-joint-" + this.type;
  };

  KDDiaJoint.prototype.getPos = function() {
    return this.parent.getJointPos(this);
  };

  KDDiaJoint.prototype.click = function(e) {
    if (this.inDeleteMode()) {
      this.emit('DeleteRequested', this.parent, this.type);
    }
    return this.utils.stopDOMEvent(e);
  };

  KDDiaJoint.prototype.mouseDown = function(e) {
    if (this.inDeleteMode()) {
      return;
    }
    this.utils.stopDOMEvent(e);
    this.parent.emit("JointRequestsLine", this);
    return false;
  };

  KDDiaJoint.prototype.inDeleteMode = function() {
    return this.hasClass('deleteMode');
  };

  KDDiaJoint.prototype.showDeleteButton = function() {
    if (!this.isStatic()) {
      return this.setClass('deleteMode');
    }
  };

  KDDiaJoint.prototype.hideDeleteButton = function() {
    return this.unsetClass('deleteMode');
  };

  KDDiaJoint.prototype.isStatic = function() {
    return this.getOption('static');
  };

  return KDDiaJoint;

})(KDView);


},{"./../../core/view.coffee":108}],31:[function(require,module,exports){
var KDDiaObject, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

KDView = require('./../../core/view.coffee');

module.exports = KDDiaObject = (function(_super) {
  __extends(KDDiaObject, _super);

  function KDDiaObject(options, data) {
    var _base, _base1, _base2;
    options.cssClass = KD.utils.curry('kddia-object', options.cssClass);
    if (options.draggable == null) {
      if ('object' !== typeof options.draggable) {
        options.draggable = {};
      }
      (_base = options.draggable).containment || (_base.containment = {});
      (_base1 = options.draggable.containment).view || (_base1.view = 'parent');
      if ((_base2 = options.draggable.containment).padding == null) {
        _base2.padding = {
          top: 1,
          right: 1,
          bottom: 1,
          left: 1
        };
      }
    }
    options.bind = KD.utils.curry('mouseleave', options.bind);
    if (options.joints == null) {
      options.joints = ['left', 'right'];
    }
    if (options.jointItemClass == null) {
      options.jointItemClass = KDDiaJoint;
    }
    options.allowedConnections || (options.allowedConnections = {});
    options.staticJoints || (options.staticJoints = []);
    KDDiaObject.__super__.constructor.call(this, options, data);
    this.joints = {};
    this.allowedConnections = this.getOption('allowedConnections');
    this.domElement.attr("dia-id", "dia-" + (this.getId()));
    this.wc = KD.getSingleton('windowController');
    this.on("KDObjectWillBeDestroyed", (function(_this) {
      return function() {
        return _this.emit('RemoveMyConnections');
      };
    })(this));
    this.once('viewAppended', (function(_this) {
      return function() {
        var joint, _i, _len, _ref;
        _ref = _this.getOption('joints');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          joint = _ref[_i];
          _this.addJoint(joint);
        }
        return _this.parent.on('UnhighlightDias', function() {
          var key, _ref1, _results;
          _this.unsetClass('highlight');
          _ref1 = _this.joints;
          _results = [];
          for (key in _ref1) {
            joint = _ref1[key];
            _results.push(joint.hideDeleteButton());
          }
          return _results;
        });
      };
    })(this));
  }

  KDDiaObject.prototype.mouseDown = function(e) {
    this.emit("DiaObjectClicked");
    this._mouseDown = true;
    this.wc.once('ReceivedMouseUpElsewhere', (function(_this) {
      return function() {
        return _this._mouseDown = false;
      };
    })(this));
    if (!this.getOption('draggable')) {
      return this.utils.stopDOMEvent(e);
    }
  };

  KDDiaObject.prototype.mouseLeave = function(e) {
    var bounds, joint;
    if (!this._mouseDown) {
      return;
    }
    bounds = this.getBounds();
    joint = null;
    bounds.w = bounds.w * this.parent.scale;
    bounds.h = bounds.h * this.parent.scale;
    if (e.pageX >= bounds.x + bounds.w) {
      joint = this.joints['right'];
    }
    if (e.pageX <= bounds.x) {
      joint = this.joints['left'];
    }
    if (e.pageY >= bounds.y + bounds.h) {
      joint = this.joints['bottom'];
    }
    if (e.pageY <= bounds.y) {
      joint = this.joints['top'];
    }
    if (joint) {
      return this.emit("JointRequestsLine", joint);
    }
  };

  KDDiaObject.prototype.addJoint = function(type) {
    var joint, jointItemClass, staticJoints, _base, _ref;
    if (this.joints[type] != null) {
      warn("KDDiaObject: Tried to add same joint! Destroying old one. ");
      if (typeof (_base = this.joints[type]).destroy === "function") {
        _base.destroy();
      }
    }
    _ref = this.getOptions(), jointItemClass = _ref.jointItemClass, staticJoints = _ref.staticJoints;
    this.addSubView(joint = new jointItemClass({
      type: type,
      "static": __indexOf.call(staticJoints, type) >= 0
    }));
    return this.joints[type] = joint;
  };

  KDDiaObject.prototype.getJointPos = function(joint) {
    var dx, dy, j, jx, jy, p, s, x, y, _ref, _ref1, _ref2, _ref3, _ref4;
    if (typeof joint === "string") {
      joint = this.joints[joint];
    }
    if (!joint) {
      return {
        x: 0,
        y: 0
      };
    }
    _ref = [this.parent.getElement(), this.getElement(), joint.getElement()], p = _ref[0], s = _ref[1], j = _ref[2];
    _ref1 = [p.offsetLeft + s.offsetLeft, p.offsetTop + s.offsetTop], x = _ref1[0], y = _ref1[1];
    _ref2 = [j.offsetLeft, j.offsetTop], jx = _ref2[0], jy = _ref2[1];
    _ref4 = (_ref3 = joint.type) === 'left' || _ref3 === 'right' ? [10, 4] : [4, 10], dx = _ref4[0], dy = _ref4[1];
    return {
      x: x + jx + dx,
      y: y + jy + dy
    };
  };

  KDDiaObject.prototype.getDiaId = function() {
    return this.domElement.attr("dia-id");
  };

  return KDDiaObject;

})(KDView);


},{"./../../core/view.coffee":108}],32:[function(require,module,exports){
var KDCustomHTMLView, KDDiaScene, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

KDView = require('./../../core/view.coffee');

KDCustomHTMLView = require('./../../core/customhtmlview.coffee');

module.exports = KDDiaScene = (function(_super) {
  __extends(KDDiaScene, _super);

  function KDDiaScene(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass = KD.utils.curry("kddia-scene", options.cssClass);
    options.bind = KD.utils.curry("mousemove", options.bind);
    options.lineCap || (options.lineCap = "round");
    if (options.lineWidth == null) {
      options.lineWidth = 2;
    }
    options.lineColor || (options.lineColor = "#ccc");
    options.lineColorActive || (options.lineColorActive = "orange");
    if (options.lineDashes == null) {
      options.lineDashes = [];
    }
    options.fakeLineColor || (options.fakeLineColor = "green");
    if (options.fakeLineDashes == null) {
      options.fakeLineDashes = [];
    }
    if (options.curveDistance == null) {
      options.curveDistance = 50;
    }
    KDDiaScene.__super__.constructor.apply(this, arguments);
    this.containers = [];
    this.connections = [];
    this.activeDias = [];
    this.activeJoints = [];
    this.fakeConnections = [];
  }

  KDDiaScene.prototype.diaAdded = function(container, diaObj) {
    diaObj.on("JointRequestsLine", this.bound("handleLineRequest"));
    diaObj.on("DragInAction", (function(_this) {
      return function() {
        return _this.highlightLines(diaObj);
      };
    })(this));
    return diaObj.on("RemoveMyConnections", (function(_this) {
      return function() {
        return _this.disconnectAllConnections(diaObj);
      };
    })(this));
  };

  KDDiaScene.prototype.addContainer = function(container, pos) {
    var padding, _ref, _ref1, _ref2, _ref3;
    if (pos == null) {
      pos = {};
    }
    this.addSubView(container);
    container.on("NewDiaObjectAdded", this.bound("diaAdded"));
    container.on("DragInAction", this.bound("updateScene"));
    container.on("UpdateScene", this.bound("updateScene"));
    container.on("HighlightDia", this.bound("highlightLines"));
    this.containers.push(container);
    padding = (_ref = container.getOption('draggable')) != null ? (_ref1 = _ref.containment) != null ? _ref1.padding : void 0 : void 0;
    if (padding) {
      pos.x = Math.max(padding, (_ref2 = pos.x) != null ? _ref2 : 0);
      pos.y = Math.max(padding, (_ref3 = pos.y) != null ? _ref3 : 0);
    }
    if (pos.x != null) {
      container.setX(pos.x);
    }
    if (pos.y != null) {
      container.setY(pos.y);
    }
    return this.createCanvas();
  };

  KDDiaScene.prototype.drawFakeLine = function(options) {
    var ex, ey, lineDashes, sx, sy;
    if (options == null) {
      options = {};
    }
    sx = options.sx, sy = options.sy, ex = options.ex, ey = options.ey;
    this.cleanup(this.fakeCanvas);
    this.fakeContext.beginPath();
    this.fakeContext.moveTo(sx, sy);
    this.fakeContext.lineTo(ex, ey);
    this.fakeContext.lineCap = this.getOption("lineCap");
    this.fakeContext.lineWidth = this.getOption("lineWidth");
    this.fakeContext.strokeStyle = this._trackJoint.parent.getOption('colorTag') || this.getOption("fakeLineColor");
    lineDashes = this.getOption("fakeLineDashes");
    if (lineDashes.length > 0) {
      this.fakeContext.setLineDash(lineDashes);
    }
    return this.fakeContext.stroke();
  };

  KDDiaScene.prototype.click = function(e) {
    if (e.target !== e.currentTarget) {
      return;
    }
    return this.highlightLines();
  };

  KDDiaScene.prototype.mouseMove = function(e) {
    var ex, ey, x, y, _ref;
    if (!this._trackJoint) {
      return;
    }
    _ref = this._trackJoint.getPos(), x = _ref.x, y = _ref.y;
    ex = x + (e.clientX - this._trackJoint.getX());
    ey = y + (e.clientY - this._trackJoint.getY());
    return this.drawFakeLine({
      sx: x,
      sy: y,
      ex: ex,
      ey: ey
    });
  };

  KDDiaScene.prototype.mouseUp = function(e) {
    var source, sourceId, target, targetId;
    if (!this._trackJoint) {
      return;
    }
    targetId = $(e.target).closest(".kddia-object").attr("dia-id");
    sourceId = this._trackJoint.getDiaId();
    delete this._trackJoint;
    this.cleanup(this.fakeCanvas);
    if (!targetId) {
      return;
    }
    source = this.getDia(sourceId);
    target = this.getDia(targetId);
    if (!target.joint) {
      target.joint = this.guessJoint(target, source);
    }
    if (target.joint) {
      return this.connect(source, target);
    }
  };

  KDDiaScene.prototype.guessJoint = function(target, source) {
    if (source.joint === "right" && (target.dia.joints.left != null)) {
      return "left";
    }
    if (source.joint === "left" && (target.dia.joints.right != null)) {
      return "right";
    }
  };

  KDDiaScene.prototype.getDia = function(id) {
    var container, dia, joint, objId, parts, _i, _len, _ref, _ref1;
    parts = (id.match(/dia\-((.*)\-joint\-(.*)|(.*))/)).filter(function(m) {
      return !!m;
    });
    if (!parts) {
      return null;
    }
    _ref = parts.slice(-2), objId = _ref[0], joint = _ref[1];
    if (objId === joint) {
      joint = null;
    }
    _ref1 = this.containers;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      container = _ref1[_i];
      if (dia = container.dias[objId]) {
        break;
      }
    }
    return {
      dia: dia,
      joint: joint,
      container: container
    };
  };

  KDDiaScene.prototype.highlightLines = function(dia, update) {
    var connection, container, joint, source, target, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _results;
    if (dia == null) {
      dia = [];
    }
    if (update == null) {
      update = true;
    }
    if (!Array.isArray(dia)) {
      dia = [dia];
    }
    this.activeDias = dia;
    _ref = this.activeJoints;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      joint = _ref[_i];
      joint.off('DeleteRequested');
    }
    _ref1 = this.containers;
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      container = _ref1[_j];
      container.emit('UnhighlightDias');
    }
    this.activeJoints = [];
    if (update) {
      this.updateScene();
    }
    if (this.activeDias.length !== 1) {
      return;
    }
    dia = dia.first;
    _ref2 = this.connections;
    _results = [];
    for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
      connection = _ref2[_k];
      source = connection.source, target = connection.target;
      if ((source.dia === dia) || (target.dia === dia)) {
        _results.push([source, target].forEach((function(_this) {
          return function(conn) {
            conn.dia.setClass('highlight');
            if (conn.dia !== dia) {
              joint = conn.dia.joints[conn.joint];
              if (__indexOf.call(_this.activeJoints, joint) < 0) {
                joint.showDeleteButton();
                joint.on('DeleteRequested', _this.bound('disconnect'));
                return _this.activeJoints.push(joint);
              }
            }
          };
        })(this)));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  KDDiaScene.prototype.handleLineRequest = function(joint) {
    return this._trackJoint = joint;
  };

  KDDiaScene.prototype.findTargetConnection = function(dia, joint) {
    var activeDia, conn, isEqual, _i, _len, _ref;
    isEqual = (function(_this) {
      return function(connection) {
        return (dia === connection.dia) && (joint === connection.joint);
      };
    })(this);
    activeDia = this.activeDias.first;
    _ref = this.connections;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      conn = _ref[_i];
      if (((isEqual(conn.source)) || (isEqual(conn.target))) && ((conn.source.dia === activeDia) || (conn.target.dia === activeDia))) {
        return conn;
      }
    }
  };

  KDDiaScene.prototype.disconnect = function(dia, joint) {
    var c, connectionsToDelete;
    if (this.activeDias.length !== 1) {
      return;
    }
    connectionsToDelete = this.findTargetConnection(dia, joint);
    this.connections = (function() {
      var _i, _len, _ref, _results;
      _ref = this.connections;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        c = _ref[_i];
        if (c !== connectionsToDelete) {
          _results.push(c);
        }
      }
      return _results;
    }).call(this);
    return this.highlightLines(this.activeDias);
  };

  KDDiaScene.prototype.disconnectAllConnections = function(dia) {
    var connection, newConnections, source, target, _i, _len, _ref, _ref1;
    newConnections = [];
    _ref = this.connections;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      connection = _ref[_i];
      source = connection.source, target = connection.target;
      if ((_ref1 = dia.getDiaId()) !== source.dia.getDiaId() && _ref1 !== target.dia.getDiaId()) {
        newConnections.push(connection);
      }
    }
    this.connections = newConnections;
    return this.highlightLines();
  };

  KDDiaScene.prototype.allowedToConnect = function(source, target) {
    var allowList, i, restrictions, _i, _ref, _ref1, _ref2, _ref3;
    if (!(source && target)) {
      return false;
    }
    if (((_ref = source.dia) != null ? _ref.id : void 0) === ((_ref1 = target.dia) != null ? _ref1.id : void 0)) {
      return false;
    }
    for (i = _i = 0; _i <= 1; i = ++_i) {
      if ((source.dia.allowedConnections != null) && Object.keys(source.dia.allowedConnections).length > 0) {
        allowList = source.dia.allowedConnections;
        restrictions = allowList[target.dia.constructor.name];
        if (!restrictions) {
          return false;
        }
        if (_ref2 = source.joint, __indexOf.call(restrictions, _ref2) >= 0) {
          return false;
        }
      }
      _ref3 = [target, source], source = _ref3[0], target = _ref3[1];
    }
    return true;
  };

  KDDiaScene.prototype.connect = function(source, target, update) {
    if (update == null) {
      update = true;
    }
    if (!this.allowedToConnect(source, target)) {
      return;
    }
    this.emit("ConnectionCreated", source, target);
    this.connections.push({
      source: source,
      target: target
    });
    return this.highlightLines(target.dia, update);
  };

  KDDiaScene.prototype.resetScene = function() {
    this.fakeConnections = [];
    return this.updateScene();
  };

  KDDiaScene.prototype.updateScene = function() {
    var connection, _i, _j, _len, _len1, _ref, _ref1, _results;
    this.cleanup(this.realCanvas);
    _ref = this.connections;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      connection = _ref[_i];
      this.drawConnectionLine(connection);
    }
    _ref1 = this.fakeConnections;
    _results = [];
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      connection = _ref1[_j];
      _results.push(this.drawConnectionLine(connection));
    }
    return _results;
  };

  KDDiaScene.prototype.drawConnectionLine = function(_arg) {
    var activeColor, activeDia, cd, lineColor, lineDashes, options, sJoint, source, sx, sy, tJoint, target, tx, ty, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6;
    source = _arg.source, target = _arg.target, options = _arg.options;
    if (!(source || target)) {
      return;
    }
    options || (options = {});
    activeColor = this.getOption('lineColorActive');
    lineDashes = this.getOption('lineDashes');
    lineColor = this.getOption('lineColor');
    this.realContext.beginPath();
    activeDia = (_ref = source.dia, __indexOf.call(this.activeDias, _ref) >= 0) ? source : (_ref1 = target.dia, __indexOf.call(this.activeDias, _ref1) >= 0) ? target : void 0;
    if (activeDia) {
      lineColor = options.lineColor || (activeDia.dia.getOption('colorTag')) || activeColor;
      lineDashes = options.lineDashes || (activeDia.dia.getOption('lineDashes')) || lineDashes;
    }
    sJoint = source.dia.getJointPos(source.joint);
    tJoint = target.dia.getJointPos(target.joint);
    this.realContext.strokeStyle = lineColor;
    if (lineDashes.length > 0) {
      this.realContext.setLineDash(lineDashes);
    }
    this.realContext.moveTo(sJoint.x, sJoint.y);
    cd = this.getOption('curveDistance');
    _ref2 = [0, 0, 0, 0], sx = _ref2[0], sy = _ref2[1], tx = _ref2[2], ty = _ref2[3];
    if ((_ref3 = source.joint) === "top" || _ref3 === "bottom") {
      sy = source.joint === "top" ? -cd : cd;
    } else if ((_ref4 = source.joint) === "left" || _ref4 === "right") {
      sx = source.joint === "left" ? -cd : cd;
    }
    if ((_ref5 = target.joint) === "top" || _ref5 === "bottom") {
      ty = target.joint === "top" ? -cd : cd;
    } else if ((_ref6 = target.joint) === "left" || _ref6 === "right") {
      tx = target.joint === "left" ? -cd : cd;
    }
    this.realContext.bezierCurveTo(sJoint.x + sx, sJoint.y + sy, tJoint.x + tx, tJoint.y + ty, tJoint.x, tJoint.y);
    this.realContext.lineWidth = this.getOption('lineWidth');
    return this.realContext.stroke();
  };

  KDDiaScene.prototype.addFakeConnection = function(connection) {
    this.drawConnectionLine(connection);
    return this.fakeConnections.push(connection);
  };

  KDDiaScene.prototype.createCanvas = function() {
    var _ref, _ref1;
    if ((_ref = this.realCanvas) != null) {
      _ref.destroy();
    }
    if ((_ref1 = this.fakeCanvas) != null) {
      _ref1.destroy();
    }
    this.addSubView(this.realCanvas = new KDCustomHTMLView({
      tagName: "canvas",
      attributes: this.getSceneSize()
    }));
    this.realContext = this.realCanvas.getElement().getContext("2d");
    if (this.realContext.setLineDash == null) {
      this.realContext.setLineDash = noop;
    }
    this.addSubView(this.fakeCanvas = new KDCustomHTMLView({
      tagName: "canvas",
      cssClass: "fakeCanvas",
      attributes: this.getSceneSize()
    }));
    return this.fakeContext = this.fakeCanvas.getElement().getContext("2d");
  };

  KDDiaScene.prototype.setScale = function(scale) {
    var container, _i, _len, _ref;
    if (scale == null) {
      scale = 1;
    }
    _ref = this.containers;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      container = _ref[_i];
      container.setScale(scale);
    }
    return this.updateScene();
  };

  KDDiaScene.prototype.cleanup = function(canvas) {
    return canvas.setAttributes(this.getSceneSize());
  };

  KDDiaScene.prototype.parentDidResize = function() {
    KDDiaScene.__super__.parentDidResize.apply(this, arguments);
    return _.throttle((function(_this) {
      return function() {
        return _this.updateScene();
      };
    })(this))();
  };

  KDDiaScene.prototype.getSceneSize = function() {
    return {
      width: this.getWidth(),
      height: this.getHeight()
    };
  };

  KDDiaScene.prototype.dumpScene = function() {
    return log(this.containers, this.connections);
  };

  KDDiaScene.prototype.reset = function(update) {
    if (update == null) {
      update = true;
    }
    this.connections = [];
    this.fakeConnections = [];
    if (update) {
      return this.updateScene();
    }
  };

  return KDDiaScene;

})(KDView);


},{"./../../core/customhtmlview.coffee":97,"./../../core/view.coffee":108}],33:[function(require,module,exports){
var KDButtonView, KDDialogView, KDOverlayView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

KDOverlayView = require('./../overlay/overlayview.coffee');

KDButtonView = require('./../buttons/buttonview.coffee');

module.exports = KDDialogView = (function(_super) {
  __extends(KDDialogView, _super);

  function KDDialogView(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass = KD.utils.curry('kddialogview', options.cssClass);
    if (options.offset == null) {
      options.offset = true;
    }
    options.container || (options.container = null);
    options.buttons || (options.buttons = {
      Cancel: {
        style: 'clean-red',
        callback: this.bound('hide')
      }
    });
    KDDialogView.__super__.constructor.call(this, options, data);
    this.bindTransitionEnd();
    this.setButtons();
  }

  KDDialogView.prototype.show = function() {
    return KD.utils.defer((function(_this) {
      return function() {
        var container, _ref;
        if ((_ref = _this.overlay) != null) {
          _ref.destroy();
        }
        container = _this.getOptions().container;
        _this.overlay = new KDOverlayView({
          click: _this.bound('hide'),
          container: container
        });
        return _this.setClass('in');
      };
    })(this));
  };

  KDDialogView.prototype.hide = function() {
    this.once('transitionend', (function(_this) {
      return function() {
        _this.overlay.destroy();
        return _this.destroy();
      };
    })(this));
    return this.unsetClass('in');
  };

  KDDialogView.prototype.setButtons = function() {
    var buttonOptions, buttonTitle, buttons, _results;
    buttons = this.getOptions().buttons;
    this.buttons = {};
    this.buttonHolder = new KDView({
      cssClass: "kddialog-buttons clearfix"
    });
    this.addSubView(this.buttonHolder);
    _results = [];
    for (buttonTitle in buttons) {
      if (!__hasProp.call(buttons, buttonTitle)) continue;
      buttonOptions = buttons[buttonTitle];
      _results.push(this.createButton(buttonTitle, buttonOptions));
    }
    return _results;
  };

  KDDialogView.prototype.createButton = function(title, buttonOptions) {
    var button;
    this.buttonHolder.addSubView(button = new KDButtonView({
      title: title,
      loader: buttonOptions.loader,
      style: buttonOptions.style,
      callback: buttonOptions.callback
    }));
    return this.buttons[title] = button;
  };

  return KDDialogView;

})(KDView);


},{"./../../core/view.coffee":108,"./../buttons/buttonview.coffee":20,"./../overlay/overlayview.coffee":62}],34:[function(require,module,exports){
var KDFormView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

KDView = require('./../../core/view.coffee');

module.exports = KDFormView = (function(_super) {
  __extends(KDFormView, _super);

  KDFormView.findChildInputs = function(parent) {
    var inputs, subViews;
    inputs = [];
    subViews = parent.getSubViews();
    if (subViews.length > 0) {
      subViews.forEach(function(subView) {
        if (subView instanceof KDInputView) {
          inputs.push(subView);
        }
        return inputs = inputs.concat(KDFormView.findChildInputs(subView));
      });
    }
    return inputs;
  };

  KDFormView.sanitizeFormOptions = function(options) {
    var key, option, _results;
    _results = [];
    for (key in options) {
      option = options[key];
      if (option.title == null) {
        option.title = key;
      }
      option.key = key;
      _results.push(option);
    }
    return _results;
  };


  /*
  INSTANCE LEVEL
   */

  function KDFormView(options, data) {
    if (options == null) {
      options = {};
    }
    options.tagName = "form";
    options.cssClass = KD.utils.curry("kdformview", options.cssClass);
    options.callback || (options.callback = noop);
    options.customData || (options.customData = {});
    options.bind || (options.bind = "submit");
    KDFormView.__super__.constructor.call(this, options, data);
    this.unsetClass("kdview");
    this.valid = null;
    this.setCallback(options.callback);
    this.customData = {};
  }

  KDFormView.prototype.childAppended = function(child) {
    if (typeof child.associateForm === "function") {
      child.associateForm(this);
    }
    if (child instanceof KDInputView) {
      this.emit('inputWasAdded', child);
    }
    return KDFormView.__super__.childAppended.apply(this, arguments);
  };

  KDFormView.prototype.getCustomData = function(path) {
    if (path) {
      return JsPath.getAt(this.customData, path);
    } else {
      return this.customData;
    }
  };

  KDFormView.prototype.addCustomData = function(path, value) {
    var key, _results;
    if ('string' === typeof path) {
      return JsPath.setAt(this.customData, path, value);
    } else {
      _results = [];
      for (key in path) {
        if (!__hasProp.call(path, key)) continue;
        value = path[key];
        _results.push(JsPath.setAt(this.customData, key, value));
      }
      return _results;
    }
  };

  KDFormView.prototype.removeCustomData = function(path) {
    var isArrayElement, last, pathUntil, _i;
    if ('string' === typeof path) {
      path = path.split('.');
    }
    pathUntil = 2 <= path.length ? __slice.call(path, 0, _i = path.length - 1) : (_i = 0, []), last = path[_i++];
    isArrayElement = !isNaN(+last);
    if (isArrayElement) {
      return JsPath.spliceAt(this.customData, pathUntil, last);
    } else {
      return JsPath.deleteAt(this.customData, path);
    }
  };

  KDFormView.prototype.serializeFormData = function(data) {
    var inputData, _i, _len, _ref;
    if (data == null) {
      data = {};
    }
    _ref = this.getDomElement().serializeArray();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      inputData = _ref[_i];
      data[inputData.name] = inputData.value;
    }
    return data;
  };

  KDFormView.prototype.getData = function() {
    var formData;
    formData = $.extend({}, this.getCustomData());
    this.serializeFormData(formData);
    return formData;
  };

  KDFormView.prototype.getFormData = function() {
    var formData, inputs;
    inputs = KDFormView.findChildInputs(this);
    formData = this.getCustomData() || {};
    inputs.forEach(function(input) {
      if (input.getName()) {
        return formData[input.getName()] = input.getValue();
      }
    });
    return formData;
  };

  KDFormView.prototype.focusFirstElement = function() {
    return KDFormView.findChildInputs(this)[0].$().trigger("focus");
  };

  KDFormView.prototype.setCallback = function(callback) {
    return this.formCallback = callback;
  };

  KDFormView.prototype.getCallback = function() {
    return this.formCallback;
  };

  KDFormView.prototype.reset = function() {
    return this.getElement().reset();
  };

  KDFormView.prototype.submit = function(event) {
    var form, formData, inputs, toBeValidatedInputs, validInputs, validationCount;
    if (event) {
      event.stopPropagation();
      event.preventDefault();
    }
    form = this;
    inputs = KDFormView.findChildInputs(form);
    validationCount = 0;
    toBeValidatedInputs = [];
    validInputs = [];
    formData = this.getCustomData() || {};
    this.once("FormValidationFinished", function(isValid) {
      var _ref;
      if (isValid == null) {
        isValid = true;
      }
      form.valid = isValid;
      if (isValid) {
        if ((_ref = form.getCallback()) != null) {
          _ref.call(form, formData, event);
        }
        return form.emit("FormValidationPassed");
      } else {
        return form.emit("FormValidationFailed");
      }
    });
    inputs.forEach(function(input) {
      var inputOptions, name, value;
      inputOptions = input.getOptions();
      if (inputOptions.validate || inputOptions.required) {
        return toBeValidatedInputs.push(input);
      } else {
        name = input.getName();
        value = input.getValue();
        if (name) {
          return formData[name] = value;
        }
      }
    });
    toBeValidatedInputs.forEach(function(inputToBeValidated) {
      (function() {
        return inputToBeValidated.once("ValidationResult", function(result) {
          var input, valid, _i, _len;
          validationCount++;
          if (result) {
            validInputs.push(inputToBeValidated);
          }
          if (toBeValidatedInputs.length === validationCount) {
            if (validInputs.length === toBeValidatedInputs.length) {
              for (_i = 0, _len = validInputs.length; _i < _len; _i++) {
                input = validInputs[_i];
                formData[input.getName()] = input.getValue();
              }
            } else {
              valid = false;
            }
            return form.emit("FormValidationFinished", valid);
          }
        });
      })();
      return inputToBeValidated.validate(null, event);
    });
    if (toBeValidatedInputs.length === 0) {
      return form.emit("FormValidationFinished");
    }
  };

  return KDFormView;

})(KDView);


},{"./../../core/view.coffee":108}],35:[function(require,module,exports){
var KDButtonBar, KDCustomHTMLView, KDFormView, KDFormViewWithFields, KDLabelView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

KDCustomHTMLView = require('./../../core/customhtmlview.coffee');

KDFormView = require('./formview.coffee');

KDButtonBar = require('./../buttons/buttonbar.coffee');

KDLabelView = require('./../inputs/labelview.coffee');

module.exports = KDFormViewWithFields = (function(_super) {
  __extends(KDFormViewWithFields, _super);

  function KDFormViewWithFields() {
    var buttons, fields, _ref;
    KDFormViewWithFields.__super__.constructor.apply(this, arguments);
    this.setClass("with-fields");
    this.inputs = {};
    this.fields = {};
    _ref = this.getOptions(), fields = _ref.fields, buttons = _ref.buttons;
    if (fields) {
      this.createFields(KDFormView.sanitizeFormOptions(fields));
    }
    if (buttons) {
      this.createButtons(buttons);
      this.buttons = this.buttonField.buttons;
    }
  }

  KDFormViewWithFields.prototype.createFields = function(fields) {
    var fieldData, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = fields.length; _i < _len; _i++) {
      fieldData = fields[_i];
      _results.push(this.addSubView(this.createField(fieldData)));
    }
    return _results;
  };

  KDFormViewWithFields.prototype.createButtons = function(buttons) {
    return this.addSubView(this.buttonField = new KDButtonBar({
      buttons: buttons
    }));
  };

  KDFormViewWithFields.prototype.createField = function(fieldData, field, isNextElement) {
    var hint, input, inputWrapper, itemClass, key, label, next, title, _ref, _ref1;
    if (isNextElement == null) {
      isNextElement = false;
    }
    itemClass = fieldData.itemClass, title = fieldData.title;
    itemClass || (itemClass = KDInputView);
    fieldData.cssClass || (fieldData.cssClass = "");
    fieldData.name || (fieldData.name = title);
    field || (field = new KDView({
      cssClass: "formline " + (KD.utils.slugify(fieldData.name)) + " " + fieldData.cssClass
    }));
    if (fieldData.label) {
      field.addSubView(label = fieldData.label = this.createLabel(fieldData));
    }
    if (!isNextElement) {
      field.addSubView(inputWrapper = new KDCustomHTMLView({
        cssClass: "input-wrapper"
      }));
      inputWrapper.addSubView(input = this.createInput(itemClass, fieldData));
    } else {
      field.addSubView(input = this.createInput(itemClass, fieldData));
    }
    if (fieldData.hint) {
      inputWrapper.addSubView(hint = new KDCustomHTMLView({
        partial: fieldData.hint,
        tagName: "cite",
        cssClass: "hint"
      }));
    }
    this.fields[title] = field;
    if (fieldData.nextElement) {
      _ref = fieldData.nextElement;
      for (key in _ref) {
        next = _ref[key];
        next.title || (next.title = key);
        this.createField(next, inputWrapper || field, true);
      }
    }
    if (fieldData.nextElementFlat) {
      _ref1 = fieldData.nextElementFlat;
      for (key in _ref1) {
        if (!__hasProp.call(_ref1, key)) continue;
        next = _ref1[key];
        next.title || (next.title = key);
        this.createField(next, field);
      }
    }
    return field;
  };

  KDFormViewWithFields.prototype.createLabel = function(data) {
    return new KDLabelView({
      title: data.label,
      cssClass: this.utils.slugify(data.label)
    });
  };

  KDFormViewWithFields.prototype.createInput = function(itemClass, options) {
    var data, input;
    data = options.data;
    if (data) {
      delete options.data;
    }
    this.inputs[options.title] = input = new itemClass(options, data);
    return input;
  };

  return KDFormViewWithFields;

})(KDFormView);


},{"./../../core/customhtmlview.coffee":97,"./../../core/view.coffee":108,"./../buttons/buttonbar.coffee":17,"./../inputs/labelview.coffee":47,"./formview.coffee":34}],36:[function(require,module,exports){
var KDHeaderView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');


/**
 * # KDHeaderView
 *
 * KDHeaderView is a basic KDView to implement the
 * `<h1>`/`<h2>`/`<h3>`/etc DOM elements.
 *
 * ## Usage
 *
 * ```coffee
 * header = new KDHeaderView
 *   title: 'Header title!'
 *   type: 'big'
 *
 * appView.addSubView header
 * ```
 */

module.exports = KDHeaderView = (function(_super) {
  __extends(KDHeaderView, _super);


  /**
   * Options supports the following keys:
   * - **options.title**: The contents for your header view.
   * - **options.type**: The level of your `H` element, represented in three
   *  options: `"big"`, `"medium"`, `"small"` which translates to `"h1"`,
   *  `"h2"`, ` "h3"` respectively.
   *
   * @param {Object} options
   * @param {Object} data
   */

  function KDHeaderView(options, data) {
    var _ref;
    options = options != null ? options : {};
    options.type = (_ref = options.type) != null ? _ref : "default";
    KDHeaderView.__super__.constructor.call(this, options, data);
    if (options.title != null) {
      if (this.lazy) {
        this.updateTitle(options.title);
      } else {
        this.setTitle(options.title);
      }
    }
  }


  /**
   * Set the title of this heaer element.
   *
   * @param {String} title The title you want to set your header to
   */

  KDHeaderView.prototype.setTitle = function(title) {
    return this.getDomElement().append("<span>" + title + "</span>");
  };


  /**
   * Update the title for this header option. This can be used after you have
   * already set the title, to change it to another title.
   *
   * @param {String} title The title you want to update your header to
   */

  KDHeaderView.prototype.updateTitle = function(title) {
    return this.$().find('span').html(title);
  };

  KDHeaderView.prototype.setDomElement = function(cssClass) {
    var type;
    if (cssClass == null) {
      cssClass = "";
    }
    type = this.getOptions().type;
    this.setOption("tagName", (function() {
      switch (type) {
        case "big":
          return "h1";
        case "medium":
          return "h2";
        case "small":
          return "h3";
        default:
          return "h4";
      }
    })());
    return KDHeaderView.__super__.setDomElement.call(this, this.utils.curry("kdheaderview", cssClass));
  };

  return KDHeaderView;

})(KDView);


},{"./../../core/view.coffee":108}],37:[function(require,module,exports){
var KDButtonView, KDCustomHTMLView, KDView, KDWebcamView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

KDCustomHTMLView = require('./../../core/customhtmlview.coffee');

KDButtonView = require('./../buttons/buttonview.coffee');

module.exports = KDWebcamView = (function(_super) {
  __extends(KDWebcamView, _super);

  function KDWebcamView(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass || (options.cssClass = "kdwebcamview");
    if (options.screenFlash == null) {
      options.screenFlash = true;
    }
    if (options.hideControls == null) {
      options.hideControls = false;
    }
    options.snapTitle || (options.snapTitle = "Snap Photo");
    options.resnapTitle || (options.resnapTitle = "Resnap");
    options.saveTitle || (options.saveTitle = "Save");
    if (options.countdown == null) {
      options.countdown = 3;
    }
    KDWebcamView.__super__.constructor.call(this, options, data);
    this.attachEvents();
    this.video = new KDCustomHTMLView({
      tagName: "video",
      attributes: {
        autoplay: true
      }
    });
    this.picture = new KDCustomHTMLView({
      tagName: "canvas"
    });
    this.button = options.hideControls ? new KDView({
      cssClass: "hidden"
    }) : new KDButtonView({
      title: options.snapTitle,
      cssClass: "snap-button hidden",
      callback: this.bound('countDown')
    });
    this.retake = options.hideControls ? new KDView({
      cssClass: "hidden"
    }) : new KDButtonView({
      title: options.resnapTitle,
      cssClass: "snap-button retake hidden",
      callback: (function(_this) {
        return function() {
          return _this.resetView();
        };
      })(this)
    });
    this.save = options.hideControls ? new KDView({
      cssClass: "hidden"
    }) : new KDButtonView({
      title: options.saveTitle,
      cssClass: "snap-button save hidden",
      callback: (function(_this) {
        return function() {
          _this.resetView();
          _this.video.setClass("invisible");
          _this.button.hide();
          return _this.emit("save");
        };
      })(this)
    });
  }

  KDWebcamView.prototype.attachEvents = function() {
    var snapTitle;
    snapTitle = this.getOptions().snapTitle;
    this.on("KDObjectWillBeDestroyed", (function(_this) {
      return function() {
        return _this.unsetVideoStream();
      };
    })(this));
    this.on("viewAppended", (function(_this) {
      return function() {
        _this.context = _this.picture.getElement().getContext("2d");
        return _this.getUserMedia();
      };
    })(this));
    this.on("error", function(error) {
      return this.emit("forbidden");
    });
    this.on("snap", (function(_this) {
      return function() {
        return _this.video.setClass("invisible");
      };
    })(this));
    return this.on("countDownEnd", (function(_this) {
      return function() {
        _this.button.hide();
        _this.retake.show();
        _this.save.show();
        _this.takePicture();
        return _this.button.setTitle(snapTitle);
      };
    })(this));
  };

  KDWebcamView.prototype.resetView = function() {
    this.button.show();
    this.retake.hide();
    this.save.hide();
    return this.reset();
  };

  KDWebcamView.prototype.reset = function() {
    return this.video.unsetClass("invisible");
  };

  KDWebcamView.prototype.countDown = function() {
    var count, countdown, counter, timer;
    countdown = this.getOptions().countdown;
    if (countdown > 0) {
      counter = (function(_this) {
        return function() {
          _this.button.setTitle(countdown);
          return countdown--;
        };
      })(this);
      count = this.utils.repeat(1000, counter);
      counter();
      return timer = this.utils.wait((countdown + 1) * 1000, (function(_this) {
        return function() {
          _this.utils.killRepeat(count);
          _this.utils.killWait(timer);
          return _this.emit("countDownEnd");
        };
      })(this));
    } else {
      return this.emit("countDownEnd");
    }
  };

  KDWebcamView.prototype.autoResize = function() {
    var size, video;
    video = this.video.getElement();
    size = {
      width: video.clientWidth,
      height: video.clientHeight
    };
    this.picture.setAttributes(size);
    return this.setSize(size);
  };

  KDWebcamView.prototype.unsetVideoStream = function() {
    var video, _ref;
    video = this.video.getElement();
    video.pause();
    KDWebcamView.setVideoStreamVendor(video, "");
    return (_ref = this.localMediaStream) != null ? _ref.stop() : void 0;
  };

  KDWebcamView.prototype.setVideoStream = function(stream) {
    var video;
    video = this.video.getElement();
    KDWebcamView.setVideoStreamVendor(video, stream);
    video.play();
    return video.addEventListener("playing", (function(_this) {
      return function() {
        _this.show();
        _this.button.show();
        _this.autoResize();
        return _this.emit("allowed");
      };
    })(this));
  };

  KDWebcamView.setVideoStreamVendor = function(video, stream) {
    if (video.mozSrcObject !== void 0) {
      return video.mozSrcObject = stream;
    } else {
      return video.src = stream;
    }
  };

  KDWebcamView.getUserMediaVendor = function() {
    return navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia;
  };

  KDWebcamView.getURLVendor = function() {
    return window.URL || window.webkitURL || window.mozURL;
  };

  KDWebcamView.prototype.getUserMedia = function() {
    var _onError;
    _onError = (function(_this) {
      return function(error) {
        return _this.emit("error", error);
      };
    })(this);
    navigator.getUserMedia = KDWebcamView.getUserMediaVendor();
    window.URL = KDWebcamView.getURLVendor();
    if (navigator.getUserMedia) {
      return navigator.getUserMedia({
        video: true
      }, (function(_this) {
        return function(stream) {
          _this.localMediaStream = stream;
          return _this.setVideoStream((window.URL && window.URL.createObjectURL(stream)) || stream);
        };
      })(this), _onError);
    } else {
      return _onError({
        notSupported: true
      });
    }
  };

  KDWebcamView.prototype.flash = function() {
    var flash;
    flash = new KDView({
      cssClass: "kdwebcamview-flash"
    });
    flash.appendToDomBody();
    return KD.utils.defer(function() {
      flash.setClass("flashed");
      return KD.utils.wait(500, function() {
        return flash.destroy();
      });
    });
  };

  KDWebcamView.prototype.takePicture = function() {
    var picture, screenFlash, video;
    video = this.video.getElement();
    picture = this.picture.getElement();
    screenFlash = this.getOptions().screenFlash;
    if (screenFlash) {
      this.flash();
    }
    this.autoResize();
    this.context.drawImage(video, 0, 0, video.clientWidth, video.clientHeight);
    return this.emit("snap", picture.toDataURL(), picture);
  };

  KDWebcamView.prototype.viewAppended = function() {
    var view, _i, _len, _ref, _results;
    KDWebcamView.__super__.viewAppended.call(this);
    _ref = [this.button, this.save, this.retake, this.video, this.picture];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      view = _ref[_i];
      _results.push(this.addSubView(view));
    }
    return _results;
  };

  return KDWebcamView;

})(KDView);


},{"./../../core/customhtmlview.coffee":97,"./../../core/view.coffee":108,"./../buttons/buttonview.coffee":20}],38:[function(require,module,exports){
var KDCheckBox, KDInputView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDInputView = require('./inputview.coffee');

module.exports = KDCheckBox = (function(_super) {
  __extends(KDCheckBox, _super);

  function KDCheckBox(options, data) {
    var _base;
    if (options == null) {
      options = {};
    }
    options.type || (options.type = "checkbox");
    if (options.attributes == null) {
      options.attributes = {};
    }
    if ((_base = options.attributes).checked == null) {
      _base.checked = options.defaultValue || false;
    }
    KDCheckBox.__super__.constructor.call(this, options, data);
  }

  return KDCheckBox;

})(KDInputView);


},{"./inputview.coffee":46}],39:[function(require,module,exports){
var KDContentEditableView, KDNotificationView, KDView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

KDNotificationView = require('./../notifications/notificationview.coffee');

module.exports = KDContentEditableView = (function(_super) {
  __extends(KDContentEditableView, _super);

  function KDContentEditableView(options, data) {
    var _ref;
    if (options == null) {
      options = {};
    }
    this.keyDown = __bind(this.keyDown, this);
    this.input = __bind(this.input, this);
    this.click = __bind(this.click, this);
    options.cssClass = KD.utils.curry("kdcontenteditableview", options.cssClass);
    options.bind = KD.utils.curry("click input keydown paste drop", options.bind);
    options.type || (options.type = "text");
    if (options.multiline == null) {
      options.multiline = false;
    }
    options.placeholder || (options.placeholder = "");
    if (options.tabNavigation == null) {
      options.tabNavigation = false;
    }
    KDContentEditableView.__super__.constructor.call(this, options, data);
    if ((_ref = this.getDelegate()) != null) {
      _ref.on("EditingModeToggled", (function(_this) {
        return function(state) {
          return _this.setEditingMode(state);
        };
      })(this));
    }
    this.validationNotifications = {};
  }

  KDContentEditableView.prototype.viewAppended = function() {
    this.setEditingMode(false);
    return KDContentEditableView.__super__.viewAppended.apply(this, arguments);
  };

  KDContentEditableView.prototype.getEditableElement = function() {
    if (!this.editableElement) {
      if (this.getData()) {
        this.editableElement = this.getElement().children[0];
      } else {
        this.editableElement = document.createElement("div");
        this.getDomElement().append(this.editableElement);
      }
    }
    return this.editableElement;
  };

  KDContentEditableView.prototype.getEditableDomElement = function() {
    if (!this.editableDomElement) {
      this.editableDomElement = $(this.getEditableElement());
    }
    return this.editableDomElement;
  };

  KDContentEditableView.prototype.setEditingMode = function(state) {
    this.editingMode = state;
    this.getEditableElement().setAttribute("contenteditable", state);
    if (this.getValue() === "") {
      if (this.editingMode && this.getOptions().placeholder) {
        return this.setPlaceholder();
      } else {
        return this.unsetPlaceholder();
      }
    }
  };

  KDContentEditableView.prototype.getValue = function(forceType) {
    var element, placeholder, type, value, _ref;
    _ref = this.getOptions(), type = _ref.type, placeholder = _ref.placeholder;
    element = this.getEditableElement();
    if (forceType) {
      type = forceType;
    }
    switch (type) {
      case "text":
        value = element.textContent;
        break;
      case "html":
        value = element.innerHTML;
    }
    if (value === Encoder.htmlDecode(placeholder)) {
      return "";
    } else {
      return value.trim();
    }
  };

  KDContentEditableView.prototype.setContent = function(content) {
    var element, type;
    type = this.getOptions().type;
    element = this.getEditableElement();
    if (content) {
      switch (type) {
        case "text":
          return element.textContent = content;
        case "html":
          return element.innerHTML = content;
      }
    } else if (this.editingMode && content === "") {
      return this.setPlaceholder();
    }
  };

  KDContentEditableView.prototype.focus = function() {
    var windowController, _base;
    if (this.getValue().length === 0) {
      this.unsetPlaceholder();
    }
    this.getEditableDomElement().trigger("focus");
    windowController = KD.getSingleton("windowController");
    windowController.addLayer(this);
    if (!this.focused) {
      this.once("ReceivedClickElsewhere", this.bound('blur'));
    }
    this.focused = true;
    return typeof (_base = this.getOptions()).focus === "function" ? _base.focus() : void 0;
  };

  KDContentEditableView.prototype.blur = function() {
    this.focused = false;
    if (this.getValue("text").length === 0) {
      this.setPlaceholder();
    } else {
      if (this.getOptions().type !== "html") {
        this.setContent(this.getValue());
      }
    }
    return this.emit('BlurHappened');
  };

  KDContentEditableView.prototype.click = function() {
    if (this.editingMode && !this.focused) {
      return this.focus();
    }
  };

  KDContentEditableView.prototype.input = function(event) {
    return this.emit("ValueChanged", event);
  };

  KDContentEditableView.prototype.keyDown = function(event) {
    var maxLength, multiline, tabNavigation, validate, value, _ref, _ref1, _ref2;
    _ref = this.getOptions(), tabNavigation = _ref.tabNavigation, multiline = _ref.multiline, validate = _ref.validate;
    switch (event.which) {
      case 9:
        if (tabNavigation) {
          this.utils.stopDOMEvent(event);
        }
        break;
      case 13:
        this.utils.stopDOMEvent(event);
    }
    switch (event.which) {
      case 9:
        if (!tabNavigation) {
          break;
        }
        this.blur();
        if (event.shiftKey) {
          this.emit("PreviousTabStop");
        } else {
          this.emit("NextTabStop");
        }
        break;
      case 13:
        if (this.getOptions().multiline) {
          this.appendNewline();
        } else {
          this.emit("EnterPressed");
        }
    }
    value = this.getValue();
    maxLength = ((_ref1 = this.getOptions().validate) != null ? (_ref2 = _ref1.rules) != null ? _ref2.maxLength : void 0 : void 0) || 0;
    if (event.which === 13 || (maxLength > 0 && value.length === maxLength)) {
      return event.preventDefault();
    } else if (value.length === 0) {
      this.unsetPlaceholder();
      if (event.target !== this.getEditableElement()) {
        return this.focus();
      }
    }
  };

  KDContentEditableView.prototype.paste = function(event) {
    var text;
    event.preventDefault();
    text = event.originalEvent.clipboardData.getData("text/plain");
    return document.execCommand("insertText", false, text);
  };

  KDContentEditableView.prototype.drop = function(event) {
    var clientX, clientY, commonAncestorContainer, endOffset, startOffset, text, _ref, _ref1;
    event.preventDefault();
    text = event.originalEvent.dataTransfer.getData("text/plain");
    _ref = event.originalEvent, clientX = _ref.clientX, clientY = _ref.clientY;
    if (this.getValue() === "") {
      startOffset = 0;
      this.unsetPlaceholder();
    }
    _ref1 = document.caretRangeFromPoint(clientX, clientY), commonAncestorContainer = _ref1.commonAncestorContainer, startOffset = _ref1.startOffset, endOffset = _ref1.endOffset;
    return this.utils.replaceRange(commonAncestorContainer, text, startOffset);
  };

  KDContentEditableView.prototype.setPlaceholder = function() {
    var placeholder;
    this.setClass("placeholder");
    placeholder = this.getOptions().placeholder;
    if (placeholder) {
      return this.setContent(placeholder);
    }
  };

  KDContentEditableView.prototype.unsetPlaceholder = function() {
    var content, defaultValue, element, value;
    this.unsetClass("placeholder");
    content = "";
    defaultValue = this.getOptions().defaultValue;
    value = this.getValue();
    if (this.editingMode) {
      content = value || "";
    } else {
      content = value || defaultValue || "";
    }
    element = this.getEditableDomElement();
    element.text("");
    return element.append(document.createTextNode(content));
  };

  KDContentEditableView.prototype.validate = function(event) {
    var message, name, rule, valid, validator, _ref, _ref1;
    valid = true;
    _ref1 = ((_ref = this.getOptions().validate) != null ? _ref.rules : void 0) || {};
    for (name in _ref1) {
      if (!__hasProp.call(_ref1, name)) continue;
      rule = _ref1[name];
      validator = KDInputValidator["rule" + (name.capitalize())];
      if (validator && (message = validator(this, event))) {
        valid = false;
        this.notify(message, {
          title: message,
          type: "mini",
          cssClass: "error",
          duration: 2500
        });
        break;
      }
    }
    return valid;
  };

  KDContentEditableView.prototype.notify = function(message, options) {
    var notice;
    this.validationNotifications[message] = notice = new KDNotificationView(options);
    return notice.on("KDObjectWillBeDestroyed", (function(_this) {
      return function() {
        message = notice.getOptions().title;
        return delete _this.validationNotifications[message];
      };
    })(this));
  };

  KDContentEditableView.prototype.appendNewline = function() {
    var count, i, newline, range, selection, _i;
    selection = window.getSelection();
    count = selection.baseNode.length === selection.focusOffset ? 1 : 0;
    range = selection.getRangeAt(0);
    for (i = _i = 0; 0 <= count ? _i <= count : _i >= count; i = 0 <= count ? ++_i : --_i) {
      range.insertNode(newline = document.createElement("br"));
    }
    return this.utils.selectEnd(newline);
  };

  KDContentEditableView.prototype.viewAppended = function() {
    KDContentEditableView.__super__.viewAppended.apply(this, arguments);
    if (!this.editingMode && this.getValue().length === 0) {
      return this.unsetPlaceholder();
    }
  };

  return KDContentEditableView;

})(KDView);


},{"./../../core/view.coffee":108,"./../notifications/notificationview.coffee":61}],40:[function(require,module,exports){
var KDDelimitedInputView, KDInputView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDInputView = require('./inputview.coffee');

module.exports = KDDelimitedInputView = (function(_super) {
  __extends(KDDelimitedInputView, _super);

  function KDDelimitedInputView(options, data) {
    var defaultValue;
    if (options == null) {
      options = {};
    }
    if (options.delimiter == null) {
      options.delimiter = ',';
    }
    if (options.usePadding == null) {
      options.usePadding = true;
    }
    defaultValue = options.defaultValue;
    if ((defaultValue != null ? defaultValue.join : void 0) != null) {
      options.defaultValue = this.join(defaultValue, options);
    }
    KDDelimitedInputView.__super__.constructor.call(this, options, data);
  }

  KDDelimitedInputView.prototype.change = function() {
    return this.setValue(this.getValue());
  };

  KDDelimitedInputView.prototype.getPadding = function(options) {
    if (options == null) {
      options = this.getOptions();
    }
    if (options.usePadding) {
      return ' ';
    } else {
      return '';
    }
  };

  KDDelimitedInputView.prototype.split = function(value, options) {
    if (options == null) {
      options = this.getOptions();
    }
    return this.utils.splitTrim(value, options.delimiter);
  };

  KDDelimitedInputView.prototype.join = function(value, options) {
    if (options == null) {
      options = this.getOptions();
    }
    return value.join("" + options.delimiter + (this.getPadding(options)));
  };

  KDDelimitedInputView.prototype.getValue = function() {
    return this.split(KDDelimitedInputView.__super__.getValue.apply(this, arguments));
  };

  KDDelimitedInputView.prototype.setValue = function(value) {
    return KDDelimitedInputView.__super__.setValue.call(this, value.join != null ? this.join(value) : value);
  };

  return KDDelimitedInputView;

})(KDInputView);


},{"./inputview.coffee":46}],41:[function(require,module,exports){

/*
todo:

  - on enter should validation fire by default??? Sinan - 6/6/2012
 */
var KDHitEnterInputView, KDInputView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDInputView = require('./inputview.coffee');

module.exports = KDHitEnterInputView = (function(_super) {
  __extends(KDHitEnterInputView, _super);

  function KDHitEnterInputView(options, data) {
    var _ref;
    if (options == null) {
      options = {};
    }
    options.type || (options.type = "textarea");
    options.button || (options.button = null);
    if (options.showButton == null) {
      options.showButton = false;
    }
    options.label || (options.label = null);
    options.placeholder || (options.placeholder = "");
    options.callback || (options.callback = null);
    options.togglerPartials || (options.togglerPartials = ["quick update disabled", "quick update enabled"]);
    KDHitEnterInputView.__super__.constructor.call(this, options, data);
    this.setClass("hitenterview");
    this.button = (_ref = this.getOptions().button) != null ? _ref : null;
    this.enableEnterKey();
    if (options.label != null) {
      this.setToggler();
    }
    if (this.getOptions().showButton) {
      this.disableEnterKey();
    }
    this.on("ValidationPassed", (function(_this) {
      return function() {
        var _ref1;
        _this.blur();
        return (_ref1 = _this.getOptions().callback) != null ? _ref1.call(_this, _this.getValue()) : void 0;
      };
    })(this));
  }

  KDHitEnterInputView.prototype.enableEnterKey = function() {
    this.setClass("active");
    if (this.button) {
      this.hideButton();
    }
    if (this.inputEnterToggler != null) {
      this.inputEnterToggler.$().html(this.getOptions().togglerPartials[1]);
    }
    return this.enterKeyEnabled = true;
  };

  KDHitEnterInputView.prototype.disableEnterKey = function() {
    this.unsetClass("active");
    if (this.button) {
      this.showButton();
    }
    if (this.inputEnterToggler != null) {
      this.inputEnterToggler.$().html(this.getOptions().togglerPartials[0]);
    }
    return this.enterKeyEnabled = false;
  };

  KDHitEnterInputView.prototype.setToggler = function() {
    var o;
    o = this.getOptions();
    this.inputEnterToggler = new KDCustomHTMLView({
      tagName: "a",
      cssClass: "hitenterview-toggle",
      partial: o.showButton ? o.togglerPartials[0] : o.togglerPartials[1],
      click: this.bound("toggleEnterKey")
    });
    return this.inputLabel.addSubView(this.inputEnterToggler);
  };

  KDHitEnterInputView.prototype.hideButton = function() {
    return this.button.hide();
  };

  KDHitEnterInputView.prototype.showButton = function() {
    return this.button.show();
  };

  KDHitEnterInputView.prototype.toggleEnterKey = function() {
    if (this.enterKeyEnabled) {
      return this.disableEnterKey();
    } else {
      return this.enableEnterKey();
    }
  };

  KDHitEnterInputView.prototype.keyDown = function(event) {
    if (event.which === 13 && (event.altKey || event.shiftKey) !== true && this.enterKeyEnabled) {
      event.preventDefault();
      this.emit("EnterPerformed");
      this.validate();
      return false;
    } else if (event.which === 27) {
      return this.emit("EscapePerformed");
    }
  };

  return KDHitEnterInputView;

})(KDInputView);


},{"./inputview.coffee":46}],42:[function(require,module,exports){
var KDInputCheckboxGroup, KDInputRadioGroup,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDInputRadioGroup = require('./inputradiogroup.coffee');

module.exports = KDInputCheckboxGroup = (function(_super) {
  __extends(KDInputCheckboxGroup, _super);

  function KDInputCheckboxGroup(options, data) {
    if (options == null) {
      options = {};
    }
    options.checkboxes || (options.checkboxes = []);
    options.radios || (options.radios = options.checkboxes);
    options.type || (options.type = 'checkbox');
    KDInputCheckboxGroup.__super__.constructor.call(this, options, data);
  }

  KDInputCheckboxGroup.prototype.click = function(event) {
    if (event.target.tagName !== 'LABEL') {
      return this.setValue(this.getValue());
    }
  };

  KDInputCheckboxGroup.prototype.getValue = function() {
    var el, values, _i, _len, _ref;
    values = [];
    _ref = this.getDomElement().find('input:checked');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      el = _ref[_i];
      values.push($(el).val());
    }
    return values;
  };

  KDInputCheckboxGroup.prototype.setValue = function(value) {
    var v, _i, _len, _results;
    this.$('input').prop('checked', false);
    this.$('.kd-radio-holder').removeClass('active');
    if (value instanceof Array) {
      _results = [];
      for (_i = 0, _len = value.length; _i < _len; _i++) {
        v = value[_i];
        _results.push(this._setValue(v));
      }
      return _results;
    } else {
      return this._setValue(value);
    }
  };

  KDInputCheckboxGroup.prototype._setValue = function(value) {
    this.$("input[value='" + value + "']").prop('checked', true);
    if (value) {
      return this.$(".kd-radio-holder.role-" + value).addClass('active');
    }
  };

  return KDInputCheckboxGroup;

})(KDInputRadioGroup);


},{"./inputradiogroup.coffee":43}],43:[function(require,module,exports){
var KDInputRadioGroup, KDInputView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDInputView = require('./inputview.coffee');

module.exports = KDInputRadioGroup = (function(_super) {
  __extends(KDInputRadioGroup, _super);

  function KDInputRadioGroup(options) {
    options.type || (options.type = 'radio');
    if (options.hideRadios == null) {
      options.hideRadios = false;
    }
    if (options.showIcons == null) {
      options.showIcons = false;
    }
    options.cssClassPrefix || (options.cssClassPrefix = '');
    KDInputRadioGroup.__super__.constructor.call(this, options);
    this._currentValue = this.getOption('defaultValue');
  }

  KDInputRadioGroup.prototype.setDomElement = function() {
    var disabledClass, div, i, label, options, radio, radioOptions, _i, _len, _ref;
    options = this.getOptions();
    this.domElement = $("<fieldset class='" + (this.utils.curry('radiogroup kdinput', options.cssClass)) + "'></fieldset>");
    _ref = options.radios;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      radioOptions = _ref[i];
      if (radioOptions.visible == null) {
        radioOptions.visible = true;
      }
      radioOptions.callback || (radioOptions.callback = function() {});
      disabledClass = radioOptions.disabled ? 'disabled ' : '';
      div = $("<div/>", {
        "class": "kd-" + (this.getType()) + "-holder " + disabledClass + options.cssClassPrefix + (this.utils.slugify(radioOptions.value))
      });
      radio = $("<input/>", {
        type: this.getType(),
        name: options.name,
        value: radioOptions.value,
        "class": "no-kdinput" + (options.hideRadios ? ' hidden' : ''),
        id: "" + (this.getId()) + "_" + (this.getType()) + "_" + i,
        change: radioOptions.callback
      });
      if (radioOptions.disabled) {
        radio[0].setAttribute('disabled', 'disabled');
      }
      label = $("<label/>", {
        "for": "" + (this.getId()) + "_" + (this.getType()) + "_" + i,
        html: radioOptions.title,
        "class": options.cssClassPrefix + this.utils.slugify(radioOptions.value)
      });
      div.append(radio);
      if (options.showIcons) {
        div.append($("<span/>", {
          "class": "icon"
        }));
      }
      div.append(label);
      this.domElement.append(div);
      if (!radioOptions.visible) {
        div.hide();
      }
    }
    return this.domElement;
  };

  KDInputRadioGroup.prototype.click = function(event) {
    var input;
    input = $(event.target).closest(".kd-" + (this.getType()) + "-holder").find('input');
    if (input.length < 1) {
      return;
    }
    if (input[0].getAttribute('disabled') === 'disabled') {
      return false;
    }
    return this.setValue(input[0].getAttribute("value"));
  };

  KDInputRadioGroup.prototype.setDefaultValue = function(value) {
    this.inputDefaultValue = value;
    return this.setValue(value, true);
  };

  KDInputRadioGroup.prototype.getValue = function() {
    return this.$('input[checked=checked]').val();
  };

  KDInputRadioGroup.prototype.setValue = function(value, isDefault) {
    var inputElement;
    if (isDefault == null) {
      isDefault = false;
    }
    this.$("input").attr("checked", false);
    inputElement = this.$("input[value='" + value + "']");
    inputElement.attr("checked", "checked");
    inputElement.prop("checked", true);
    if ((value != null) && value !== this._currentValue && !isDefault) {
      this.emit("change", value);
    }
    this._currentValue = value;
    this.$(".kd-radio-holder").removeClass('active');
    if ((value != null) && value !== "") {
      return this.$(".kd-radio-holder." + value).addClass('active');
    }
  };

  KDInputRadioGroup.prototype.getInputElements = function() {
    return this.getDomElement().find('input');
  };

  return KDInputRadioGroup;

})(KDInputView);


},{"./inputview.coffee":46}],44:[function(require,module,exports){
var KDInputSwitch, KDInputView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDInputView = require('./inputview.coffee');

module.exports = KDInputSwitch = (function(_super) {
  __extends(KDInputSwitch, _super);

  function KDInputSwitch(options) {
    if (options == null) {
      options = {};
    }
    options.type = "switch";
    KDInputSwitch.__super__.constructor.call(this, options);
    this.setPartial("<input class='checkbox hidden no-kdinput' type='checkbox' name='" + (this.getName()) + "'/>");
  }

  KDInputSwitch.prototype.setDomElement = function() {
    return this.domElement = $("<span class='kdinput kdinputswitch off'></span>");
  };

  KDInputSwitch.prototype.setDefaultValue = function(value) {
    switch (value) {
      case true:
      case "on":
      case "true":
      case "yes":
      case 1:
        return this._setDefaultValue(true);
      default:
        return this._setDefaultValue(false);
    }
  };

  KDInputSwitch.prototype.getDefaultValue = function() {
    return this.inputDefaultValue;
  };

  KDInputSwitch.prototype.getValue = function() {
    return this.getDomElement().find("input").eq(0).is(":checked");
  };

  KDInputSwitch.prototype.setValue = function(value) {
    switch (value) {
      case true:
        return this.switchAnimateOn();
      case false:
        return this.switchAnimateOff();
    }
  };

  KDInputSwitch.prototype._setDefaultValue = function(val) {
    return setTimeout((function(_this) {
      return function() {
        val = !!val;
        if (val) {
          _this.inputDefaultValue = true;
          _this.getDomElement().find("input").eq(0).attr("checked", true);
          return _this.getDomElement().removeClass("off").addClass("on");
        } else {
          _this.inputDefaultValue = false;
          _this.getDomElement().find("input").eq(0).attr("checked", false);
          return _this.getDomElement().removeClass("on").addClass("off");
        }
      };
    })(this), 0);
  };

  KDInputSwitch.prototype.switchAnimateOff = function() {
    var counter, timer;
    if (!this.getValue()) {
      return;
    }
    counter = 0;
    return timer = setInterval((function(_this) {
      return function() {
        _this.getDomElement().css("background-position", "left -" + (counter * 20) + "px");
        if (counter === 6) {
          clearInterval(timer);
          _this.getDomElement().find("input").eq(0).attr("checked", false);
          _this.getDomElement().removeClass("on").addClass("off");
          _this.switchStateChanged();
        }
        return counter++;
      };
    })(this), 20);
  };

  KDInputSwitch.prototype.switchAnimateOn = function() {
    var counter, timer;
    if (this.getValue()) {
      return;
    }
    counter = 6;
    return timer = setInterval((function(_this) {
      return function() {
        _this.getDomElement().css("background-position", "left -" + (counter * 20) + "px");
        if (counter === 0) {
          clearInterval(timer);
          _this.getDomElement().find("input").eq(0).attr("checked", true);
          _this.getDomElement().removeClass("off").addClass("on");
          _this.switchStateChanged();
        }
        return counter--;
      };
    })(this), 20);
  };

  KDInputSwitch.prototype.switchStateChanged = function() {
    if (this.getCallback() != null) {
      return this.getCallback().call(this, this.getValue());
    }
  };

  KDInputSwitch.prototype.mouseDown = function() {
    switch (this.getValue()) {
      case true:
        this.setValue(false);
        break;
      case false:
        this.setValue(true);
    }
    return false;
  };

  return KDInputSwitch;

})(KDInputView);


},{"./inputview.coffee":46}],45:[function(require,module,exports){
var KDInputValidator;

module.exports = KDInputValidator = (function() {
  function KDInputValidator() {}

  KDInputValidator.ruleRequired = function(input, event) {
    var doesValidate, ruleSet, value, _ref;
    if ((event != null ? event.which : void 0) === 9) {
      return;
    }
    value = $.trim(input.getValue());
    ruleSet = input.getOptions().validate;
    doesValidate = value.length > 0;
    if (doesValidate) {
      return null;
    } else {
      return ((_ref = ruleSet.messages) != null ? _ref.required : void 0) || "Field is required";
    }
  };

  KDInputValidator.ruleEmail = function(input, event) {
    var doesValidate, ruleSet, value, _ref;
    if ((event != null ? event.which : void 0) === 9) {
      return;
    }
    value = $.trim(input.getValue());
    ruleSet = input.getOptions().validate;
    doesValidate = /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i.test(value);
    if (doesValidate) {
      return null;
    } else {
      return ((_ref = ruleSet.messages) != null ? _ref.email : void 0) || "Please enter a valid email address";
    }
  };

  KDInputValidator.ruleMinLength = function(input, event) {
    var doesValidate, minLength, ruleSet, value, _ref;
    if ((event != null ? event.which : void 0) === 9) {
      return;
    }
    value = $.trim(input.getValue());
    ruleSet = input.getOptions().validate;
    minLength = ruleSet.rules.minLength;
    doesValidate = value.length >= minLength;
    if (doesValidate) {
      return null;
    } else {
      return ((_ref = ruleSet.messages) != null ? _ref.minLength : void 0) || ("Please enter a value that has " + minLength + " characters or more");
    }
  };

  KDInputValidator.ruleMaxLength = function(input, event) {
    var doesValidate, maxLength, ruleSet, value, _ref;
    if ((event != null ? event.which : void 0) === 9) {
      return;
    }
    value = $.trim(input.getValue());
    ruleSet = input.getOptions().validate;
    maxLength = ruleSet.rules.maxLength;
    doesValidate = value.length <= maxLength;
    if (doesValidate) {
      return null;
    } else {
      return ((_ref = ruleSet.messages) != null ? _ref.maxLength : void 0) || ("Please enter a value that has " + maxLength + " characters or less");
    }
  };

  KDInputValidator.ruleRangeLength = function(input, event) {
    var doesValidate, rangeLength, ruleSet, value, _ref;
    if ((event != null ? event.which : void 0) === 9) {
      return;
    }
    value = $.trim(input.getValue());
    ruleSet = input.getOptions().validate;
    rangeLength = ruleSet.rules.rangeLength;
    doesValidate = value.length <= rangeLength[1] && value.length >= rangeLength[0];
    if (doesValidate) {
      return null;
    } else {
      return ((_ref = ruleSet.messages) != null ? _ref.rangeLength : void 0) || ("Please enter a value that has more than " + rangeLength[0] + " and less than " + rangeLength[1] + " characters");
    }
  };

  KDInputValidator.ruleMatch = function(input, event) {
    var doesValidate, matchView, matchViewVal, ruleSet, value, _ref;
    if ((event != null ? event.which : void 0) === 9) {
      return;
    }
    value = $.trim(input.getValue());
    ruleSet = input.getOptions().validate;
    matchView = ruleSet.rules.match;
    matchViewVal = $.trim(matchView.getValue());
    doesValidate = value === matchViewVal;
    if (doesValidate) {
      return null;
    } else {
      return ((_ref = ruleSet.messages) != null ? _ref.match : void 0) || "Values do not match";
    }
  };

  KDInputValidator.ruleCreditCard = function(input, event) {

    /*
    Visa:             start with a 4. New cards have 16 digits. Old cards have 13.
    MasterCard:       start with the numbers 51 through 55. All have 16 digits.
    American Express: start with 34 or 37 and have 15 digits.
    Diners Club:      start with 300 through 305, 36 or 38. All have 14 digits. There are Diners Club cards that begin with 5 and have 16 digits. These are a joint venture between Diners Club and MasterCard, and should be processed like a MasterCard.
    Discover:         start with 6011 or 65. All have 16 digits.
    JCB:              start with 2131 or 1800 have 15 digits. JCB cards beginning with 35 have 16 digits.
     */
    var doesValidate, ruleSet, type, value, _ref;
    if ((event != null ? event.which : void 0) === 9) {
      return;
    }
    value = $.trim(input.getValue().replace(/-|\s/g, ""));
    ruleSet = input.getOptions().validate;
    doesValidate = /(^4[0-9]{12}(?:[0-9]{3})?$)|(^5[1-5][0-9]{14}$)|(^3[47][0-9]{13}$)|(^3(?:0[0-5]|[68][0-9])[0-9]{11}$)|(^6(?:011|5[0-9]{2})[0-9]{12}$)|(^(?:2131|1800|35\d{3})\d{11}$)/.test(value);
    if (doesValidate) {
      type = /^4[0-9]{12}(?:[0-9]{3})?$/.test(value) ? "Visa" : /^5[1-5][0-9]{14}$/.test(value) ? "MasterCard" : /^3[47][0-9]{13}$/.test(value) ? "Amex" : /^3(?:0[0-5]|[68][0-9])[0-9]{11}$/.test(value) ? "Diners" : /^6(?:011|5[0-9]{2})[0-9]{12}$/.test(value) ? "Discover" : /^(?:2131|1800|35\d{3})\d{11}$/.test(value) ? "JCB" : false;
      input.emit("CreditCardTypeIdentified", type);
      return null;
    } else {
      return ((_ref = ruleSet.messages) != null ? _ref.creditCard : void 0) || "Please enter a valid credit card number";
    }
  };

  KDInputValidator.ruleJSON = function(input, event) {
    var doesValidate, err, ruleSet, value, _ref;
    if ((event != null ? event.which : void 0) === 9) {
      return;
    }
    value = $.trim(input.getValue());
    ruleSet = input.getOptions().validate;
    doesValidate = true;
    try {
      if (value) {
        JSON.parse(value);
      }
    } catch (_error) {
      err = _error;
      error(err, doesValidate);
      doesValidate = false;
    }
    if (doesValidate) {
      return null;
    } else {
      return ((_ref = ruleSet.messages) != null ? _ref.JSON : void 0) || "a valid JSON is required";
    }
  };

  KDInputValidator.ruleRegExp = function(input, event) {
    var doesValidate, regExp, ruleSet, value, _ref;
    if ((event != null ? event.which : void 0) === 9) {
      return;
    }
    value = $.trim(input.getValue());
    ruleSet = input.getOptions().validate;
    regExp = ruleSet.rules.regExp;
    doesValidate = regExp.test(value);
    if (doesValidate) {
      return null;
    } else {
      return ((_ref = ruleSet.messages) != null ? _ref.regExp : void 0) || "Validation failed";
    }
  };

  KDInputValidator.ruleUri = function(input, event) {
    var doesValidate, regExp, ruleSet, value, _ref;
    if ((event != null ? event.which : void 0) === 9) {
      return;
    }
    regExp = /^([a-z0-9+.-]+):(?:\/\/(?:((?:[a-z0-9-._~!$&'()*+,;=:]|%[0-9A-F]{2})*)@)?((?:[a-z0-9-._~!$&'()*+,;=]|%[0-9A-F]{2})*)(?::(\d*))?(\/(?:[a-z0-9-._~!$&'()*+,;=:@\/]|%[0-9A-F]{2})*)?|(\/?(?:[a-z0-9-._~!$&'()*+,;=:@]|%[0-9A-F]{2})+(?:[a-z0-9-._~!$&'()*+,;=:@\/]|%[0-9A-F]{2})*)?)(?:\?((?:[a-z0-9-._~!$&'()*+,;=:\/?@]|%[0-9A-F]{2})*))?(?:)?$/i;
    value = $.trim(input.getValue());
    ruleSet = input.getOptions().validate;
    doesValidate = regExp.test(value);
    if (doesValidate) {
      return null;
    } else {
      return ((_ref = ruleSet.messages) != null ? _ref.uri : void 0) || "Not a valid URI";
    }
  };

  return KDInputValidator;

})();


/*
Credits
  email check regex:
  by Scott Gonzalez: http://projects.scottsplayground.com/email_address_validation/
 */


},{}],46:[function(require,module,exports){
var KDInputValidator, KDInputView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

KDView = require('./../../core/view.coffee');

KDInputValidator = require('./inputvalidator.coffee');


/**
 * The base input field view. Similar to the classic `<input type="foo">`
 * element, but with additional options such as validation.
 *
 * ## Usage
 *
 * ```coffee
 * view = new KDInputView
 *   placeholder: 'Type something here for an inspiring message!'
 *
 * view.on 'keyup', (e) ->
 *   if e.keyCode is 13 #13==Enter
 *     new KDNotificationView
 *       content: "You said #{e.target.value}!"
 *
 * appView.addSubView view
 * ```
 *
 * Create a simple text input view, with a placeholder. When the `keyup`
 * event is fired, we check what the key is. If the keyCode is `13`
 * *(An Enter key)*, we create a notification with the value of the field.
 */

module.exports = KDInputView = (function(_super) {
  __extends(KDInputView, _super);


  /**
   * Options supports the following keys.
   * - **options.type**: The type of this input. All html input types are
   *   supported. It should be noted that `"textarea"` and `"select"` do not
   *   create `<input>` elements, but rather they create `<textarea>` and
   *   `<select>` respectively.
   *
   *   Supports the options `"text"`, `"password"`, `"hidden"`, `"checkbox"`,
   *   `"range"`, `"textarea"`, and `"select"`.
   * - **options.name**: The `name="foo"` attribute of this `<input>` element.
   * - **options.label**: The label instance for this input field.
   * - **options.defaultValue**: The default value for this instance.
   * - **options.placeholder**: The HTML5 placeholder for this input.
   * - **options.disabled**: Whether or not this input is disabled. Defaults to
   *   `false`
   * - **options.selectOptions**: If this input is of the type `"select"`, this
   *   list populates the select options. Defaults to `null`
   * - **options.validate**: An object containing validation options, which are
   *   passed to the KDInputValidator for this input. Note that the validator is
   *   created internally, you do not need to create it. Defaults to `null`
   * - **options.autogrow**: If the input type can grow, such as a `textarea`,
   *   this will cause the input to grow to the content size, rather than scroll.
   *   Defaults to `false`
   * - **options.bind**: A string of event names, separated by a space. Defaults
   *   to `" blur change focus"`
   * - **options.forceCase**: Force either uppercase, or lowercase for this field
   *   type. If `null`, case is not enforced. Supports the options: `"uppercase"`,
   *   `"lowercase"`, `null`
   *
   * @param {Object} options
   * @param {Object} data
   */

  function KDInputView(o, data) {
    var options;
    if (o == null) {
      o = {};
    }
    o.type || (o.type = "text");
    o.name || (o.name = "");
    o.label || (o.label = null);
    o.cssClass || (o.cssClass = "");
    o.callback || (o.callback = null);
    if (o.defaultValue == null) {
      o.defaultValue = "";
    }
    o.placeholder || (o.placeholder = "");
    if (o.disabled == null) {
      o.disabled = false;
    }
    o.selectOptions || (o.selectOptions = null);
    o.validate || (o.validate = null);
    if (o.decorateValidation == null) {
      o.decorateValidation = true;
    }
    o.hint || (o.hint = null);
    if (o.autogrow == null) {
      o.autogrow = false;
    }
    if (o.enableTabKey == null) {
      o.enableTabKey = false;
    }
    o.bind || (o.bind = "");
    o.forceCase || (o.forceCase = null);
    o.bind += " blur change focus";
    this.setType(o.type);
    KDInputView.__super__.constructor.call(this, o, data);
    options = this.getOptions();
    this.validationNotifications = {};
    this.valid = true;
    this.inputCallback = null;
    this.setName(options.name);
    this.setLabel();
    this.setCallback();
    this.setDefaultValue(options.defaultValue);
    this.setPlaceHolder(options.placeholder);
    if (options.disabled) {
      this.makeDisabled();
    }
    if ((options.selectOptions != null) && 'function' !== typeof options.selectOptions) {
      this.setSelectOptions(options.selectOptions);
    }
    if (options.autogrow) {
      this.setAutoGrow();
    }
    if (options.enableTabKey) {
      this.enableTabKey();
    }
    if (options.forceCase) {
      this.setCase(options.forceCase);
    }
    if (options.required) {
      (function(v) {
        if (v.rules == null) {
          v.rules = {};
        }
        if (v.messages == null) {
          v.messages = {};
        }
        v.rules.required = true;
        return v.messages.required = options.required;
      })(options.validate != null ? options.validate : options.validate = {});
    }
    if (options.validate) {
      this.setValidation(options.validate);
    }
    this.bindValidationEvents();
    if (options.type === "select" && options.selectOptions) {
      this.on("viewAppended", (function(_this) {
        return function() {
          var kallback;
          o = _this.getOptions();
          if ('function' === typeof o.selectOptions) {
            kallback = _this.bound("setSelectOptions");
            return o.selectOptions.call(_this, kallback);
          } else if (!o.selectOptions.length) {
            if (!o.defaultValue) {
              return _this.setValue(o.selectOptions[Object.keys(o.selectOptions)[0]][0].value);
            }
          } else {
            if (!o.defaultValue) {
              return _this.setValue(o.selectOptions[0].value);
            }
          }
        };
      })(this));
    }
    if (o.autogrow) {
      this.once("focus", (function(_this) {
        return function() {
          if (!_this.initialHeight) {
            return _this.initialHeight = _this.$().height();
          }
        };
      })(this));
    }
  }

  KDInputView.prototype.setDomElement = function(cssClass) {
    var name;
    if (cssClass == null) {
      cssClass = "";
    }
    name = "name='" + this.options.name + "'";
    return this.domElement = (function() {
      switch (this.getType()) {
        case "text":
          return $("<input " + name + " type='text' class='kdinput text " + cssClass + "'/>");
        case "password":
          return $("<input " + name + " type='password' class='kdinput text " + cssClass + "'/>");
        case "hidden":
          return $("<input " + name + " type='hidden' class='kdinput hidden " + cssClass + "'/>");
        case "checkbox":
          return $("<input " + name + " type='checkbox' class='kdinput checkbox " + cssClass + "'/>");
        case "textarea":
          return $("<textarea " + name + " class='kdinput text " + cssClass + "'></textarea>");
        case "select":
          return $("<select " + name + " class='kdinput select " + cssClass + "'/>");
        case "range":
          return $("<input " + name + " type='range' class='kdinput range " + cssClass + "'/>");
        default:
          return $("<input " + name + " type='" + (this.getType()) + "' class='kdinput " + (this.getType()) + " " + cssClass + "'/>");
      }
    }).call(this);
  };

  KDInputView.prototype.bindValidationEvents = function() {
    this.on("ValidationError", this.bound("giveValidationFeedback"));
    this.on("ValidationPassed", this.bound("giveValidationFeedback"));
    return this.on("focus", this.bound("clearValidationFeedback"));
  };

  KDInputView.prototype.setLabel = function(label) {
    if (label == null) {
      label = this.getOptions().label;
    }
    if (!label) {
      return;
    }
    this.inputLabel = label;
    this.inputLabel.$()[0].setAttribute("for", this.getName());
    return this.inputLabel.$().bind("click", (function(_this) {
      return function() {
        _this.$().trigger("focus");
        return _this.$().trigger("click");
      };
    })(this));
  };

  KDInputView.prototype.getLabel = function() {
    return this.inputLabel;
  };

  KDInputView.prototype.setCallback = function() {
    return this.inputCallback = this.getOptions().callback;
  };

  KDInputView.prototype.getCallback = function() {
    return this.inputCallback;
  };

  KDInputView.prototype.setType = function(inputType) {
    this.inputType = inputType != null ? inputType : "text";
  };

  KDInputView.prototype.getType = function() {
    return this.inputType;
  };

  KDInputView.prototype.setName = function(inputName) {
    this.inputName = inputName;
  };

  KDInputView.prototype.getName = function() {
    return this.inputName;
  };

  KDInputView.prototype.setFocus = function() {
    (KD.getSingleton("windowController")).setKeyView(this);
    return this.$().trigger("focus");
  };

  KDInputView.prototype.setBlur = function() {
    (KD.getSingleton("windowController")).setKeyView(null);
    return this.$().trigger("blur");
  };

  KDInputView.prototype.setSelectOptions = function(options) {
    var $optGroup, optGroup, option, subOptions, _i, _j, _len, _len1;
    if (!options.length) {
      for (optGroup in options) {
        if (!__hasProp.call(options, optGroup)) continue;
        subOptions = options[optGroup];
        $optGroup = $("<optgroup label='" + optGroup + "'/>");
        this.$().append($optGroup);
        for (_i = 0, _len = subOptions.length; _i < _len; _i++) {
          option = subOptions[_i];
          $optGroup.append("<option value='" + option.value + "'>" + option.title + "</option>");
        }
      }
    } else if (options.length) {
      for (_j = 0, _len1 = options.length; _j < _len1; _j++) {
        option = options[_j];
        this.$().append("<option value='" + option.value + "'>" + option.title + "</option>");
      }
    } else {
      warn("no valid options specified for the input:", this);
    }
    return this.$().val(this.getDefaultValue());
  };

  KDInputView.prototype.setDefaultValue = function(value) {
    if ((value == null) && value !== '') {
      return;
    }
    KDInputView.prototype.setValue.call(this, value);
    return this.inputDefaultValue = value;
  };

  KDInputView.prototype.getDefaultValue = function() {
    return this.inputDefaultValue;
  };

  KDInputView.prototype.setPlaceHolder = function(value) {
    if (this.$().is("input") || this.$().is("textarea")) {
      this.$().attr("placeholder", value);
      return this.options.placeholder = value;
    }
  };


  /**
   * Disable this input field.
   */

  KDInputView.prototype.makeDisabled = function() {
    return this.getDomElement().attr("disabled", "disabled");
  };


  /**
   * Enable this input field.
   */

  KDInputView.prototype.makeEnabled = function() {
    return this.getDomElement().removeAttr("disabled");
  };


  /**
   * Get the value of this input field.
   */

  KDInputView.prototype.getValue = function() {
    var forceCase, value;
    if (this.getOption("type") === "checkbox") {
      value = this.$().is(':checked');
    } else {
      value = this.getDomElement().val();
      forceCase = this.getOptions().forceCase;
      if (forceCase) {
        value = forceCase.toLowerCase() === 'uppercase' ? value.toUpperCase() : value.toLowerCase();
      }
    }
    return value;
  };


  /**
   * Set the value of this input field.
   */

  KDInputView.prototype.setValue = function(value) {
    var $el, el, _ref;
    $el = this.$();
    el = $el[0];
    if ((_ref = this.getOption("type")) === "checkbox" || _ref === "radio") {
      if (value) {
        return el.setAttribute("checked", "checked");
      } else {
        return el.removeAttribute("checked");
      }
    } else {
      return $el.val(value);
    }
  };

  KDInputView.prototype.setCase = function(forceCase) {
    var cb;
    cb = (function(_this) {
      return function() {
        var $el, el, end, start, val;
        $el = _this.getDomElement();
        el = $el[0];
        val = _this.getValue();
        if (val === $el.val()) {
          return;
        }
        start = el.selectionStart;
        end = el.selectionEnd;
        _this.setValue(val);
        if (el.setSelectionRange) {
          return el.setSelectionRange(start, end);
        }
      };
    })(this);
    this.on("keyup", cb);
    return this.on("blur", cb);
  };

  KDInputView.prototype.unsetValidation = function() {
    return this.setValidation({});
  };

  KDInputView.prototype.setValidation = function(ruleSet) {
    var oldCallback, oldCallbacks, oldEventName, _i, _len, _ref;
    this.valid = false;
    this.currentRuleset = ruleSet;
    this.validationCallbacks || (this.validationCallbacks = {});
    this.createRuleChain(ruleSet);
    _ref = this.validationCallbacks;
    for (oldEventName in _ref) {
      if (!__hasProp.call(_ref, oldEventName)) continue;
      oldCallbacks = _ref[oldEventName];
      for (_i = 0, _len = oldCallbacks.length; _i < _len; _i++) {
        oldCallback = oldCallbacks[_i];
        this.off(oldEventName, oldCallback);
      }
    }
    return this.ruleChain.forEach((function(_this) {
      return function(rule) {
        var cb, eventName, _base;
        eventName = ruleSet.events ? ruleSet.events[rule] ? ruleSet.events[rule] : ruleSet.event ? ruleSet.event : void 0 : ruleSet.event ? ruleSet.event : void 0;
        if (eventName) {
          (_base = _this.validationCallbacks)[eventName] || (_base[eventName] = []);
          _this.validationCallbacks[eventName].push(cb = function(event) {
            if (__indexOf.call(_this.ruleChain, rule) >= 0) {
              return _this.validate(rule, event);
            }
          });
          return _this.on(eventName, cb);
        }
      };
    })(this));
  };

  KDInputView.prototype.validate = function(rule, event) {
    var allClear, errMsg, result, ruleSet, rulesToBeValidated, _ref;
    if (event == null) {
      event = {};
    }
    this.ruleChain || (this.ruleChain = []);
    this.validationResults || (this.validationResults = {});
    rulesToBeValidated = rule ? [rule] : this.ruleChain;
    ruleSet = this.currentRuleset || this.getOptions().validate;
    if (this.ruleChain.length > 0) {
      rulesToBeValidated.forEach((function(_this) {
        return function(rule) {
          var result;
          if (KDInputValidator["rule" + (rule.capitalize())] != null) {
            result = KDInputValidator["rule" + (rule.capitalize())](_this, event);
            return _this.setValidationResult(rule, result);
          } else if ("function" === typeof ruleSet.rules[rule]) {
            return ruleSet.rules[rule](_this, event);
          }
        };
      })(this));
    } else {
      this.valid = true;
    }
    allClear = true;
    _ref = this.validationResults;
    for (result in _ref) {
      if (!__hasProp.call(_ref, result)) continue;
      errMsg = _ref[result];
      if (errMsg) {
        allClear = false;
      }
    }
    this.valid = allClear ? true : false;
    if (this.valid) {
      this.emit("ValidationPassed");
    }
    this.emit("ValidationResult", this.valid);
    return this.valid;
  };

  KDInputView.prototype.createRuleChain = function(ruleSet) {
    var rule, rules, value, _i, _len, _ref, _results;
    rules = ruleSet.rules;
    this.validationResults || (this.validationResults = {});
    this.ruleChain = typeof rules === "object" ? (function() {
      var _results;
      _results = [];
      for (rule in rules) {
        if (!__hasProp.call(rules, rule)) continue;
        value = rules[rule];
        _results.push(rule);
      }
      return _results;
    })() : [rules];
    _ref = this.ruleChain;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      rule = _ref[_i];
      _results.push(this.validationResults[rule] = null);
    }
    return _results;
  };

  KDInputView.prototype.setValidationResult = function(rule, err, showNotification) {
    if (showNotification == null) {
      showNotification = true;
    }
    if (err) {
      this.validationResults[rule] = err;
      if (this.getOptions().validate.notifications && showNotification) {
        this.showValidationError(err);
      }
      this.emit("ValidationError", err);
      return this.valid = false;
    } else {
      this.validationResults[rule] = null;
      return this.valid = !_.values(this.validationResults).map(function(result) {
        return Boolean(result);
      }).indexOf(true) > -1;
    }
  };

  KDInputView.prototype.showValidationError = function(message) {
    var container, notice, notifications, str, _ref, _ref1;
    if ((_ref = this.validationNotifications[message]) != null) {
      _ref.destroy();
    }
    _ref1 = this.getOption('validate'), container = _ref1.container, notifications = _ref1.notifications;
    if ((notifications != null ? notifications.type : void 0) === 'tooltip') {
      if (this.tooltip) {
        str = "- " + message + "<br>" + (this.tooltip.getOption('title'));
      }
      this.unsetTooltip();
      notifications = {
        cssClass: notifications.cssClass || 'input-validation',
        delegate: notifications.delegate || this,
        title: notifications.title || str || message,
        placement: notifications.placement || 'right',
        direction: notifications.direction || 'left',
        forcePosition: true
      };
      this.validationNotifications[message] = notice = this.setTooltip(notifications);
      notice.show();
    } else if (notifications) {
      this.validationNotifications[message] = notice = new KDNotificationView({
        container: container,
        title: message,
        type: 'growl',
        cssClass: 'mini',
        duration: 2500
      });
    }
    return notice.on("KDObjectWillBeDestroyed", (function(_this) {
      return function() {
        message = notice.getOptions().title;
        return delete _this.validationNotifications[message];
      };
    })(this));
  };

  KDInputView.prototype.clearValidationFeedback = function() {
    this.unsetClass("validation-error validation-passed");
    return this.emit("ValidationFeedbackCleared");
  };

  KDInputView.prototype.giveValidationFeedback = function(err) {
    if (!this.getOption("decorateValidation")) {
      return;
    }
    if (err) {
      return this.setClass("validation-error");
    } else {
      this.setClass("validation-passed");
      return this.unsetClass("validation-error");
    }
  };

  KDInputView.prototype.setCaretPosition = function(pos) {
    return this.selectRange(pos, pos);
  };

  KDInputView.prototype.getCaretPosition = function() {
    var el, r, rc, re;
    el = this.$()[0];
    if (el.selectionStart) {
      return el.selectionStart;
    } else if (document.selection) {
      el.focus();
      r = document.selection.createRange();
      if (!r) {
        return 0;
      }
      re = el.createTextRange();
      rc = re.duplicate();
      re.moveToBookmark(r.getBookmark());
      rc.setEndPoint('EndToStart', re);
      return rc.text.length;
    }
    return 0;
  };

  KDInputView.prototype.selectAll = function() {
    return this.getDomElement().select();
  };

  KDInputView.prototype.selectRange = function(selectionStart, selectionEnd) {
    var input, range;
    input = this.$()[0];
    if (input.setSelectionRange) {
      input.focus();
      return input.setSelectionRange(selectionStart, selectionEnd);
    } else if (input.createTextRange) {
      range = input.createTextRange();
      range.collapse(true);
      range.moveEnd('character', selectionEnd);
      range.moveStart('character', selectionStart);
      return range.select();
    }
  };

  KDInputView.prototype.setAutoGrow = function() {
    var $input;
    $input = this.$();
    $input.css("overflow", "hidden");
    this.setClass("autogrow");
    this._clone = $("<div/>", {
      "class": "invisible"
    });
    this.on("focus", (function(_this) {
      return function() {
        _this._clone.appendTo('body');
        return _this._clone.css({
          height: "auto",
          zIndex: 100000,
          width: $input.css('width'),
          boxSizing: $input.css('box-sizing'),
          borderTop: $input.css('border-top'),
          borderRight: $input.css('border-right'),
          borderBottom: $input.css('border-bottom'),
          borderLeft: $input.css('border-left'),
          minHeight: $input.css('minHeight'),
          maxHeight: $input.css('maxHeight'),
          paddingTop: $input.css('padding-top'),
          paddingRight: $input.css('padding-right'),
          paddingBottom: $input.css('padding-bottom'),
          paddingLeft: $input.css('padding-left'),
          wordBreak: $input.css('wordBreak'),
          fontSize: $input.css('fontSize'),
          fontWeight: $input.css('fontWeight'),
          lineHeight: $input.css('lineHeight'),
          whiteSpace: "pre-line"
        });
      };
    })(this));
    this.on("blur", (function(_this) {
      return function() {
        _this._clone.detach();
        return _this.$()[0].style.height = "none";
      };
    })(this));
    return this.on("keyup", (function(_this) {
      return function(event) {
        return _this.resize();
      };
    })(this));
  };

  KDInputView.prototype.resize = function() {
    var border, height, padding;
    if (!this._clone) {
      return;
    }
    if (!document.body.contains(this._clone[0])) {
      this._clone.appendTo('body');
    }
    this._clone.html(Encoder.XSSEncode(this.getValue()));
    this._clone.append(document.createElement("br"));
    height = this._clone.height();
    if (this.$().css("boxSizing") === "border-box") {
      padding = parseInt(this._clone.css("paddingTop"), 10) + parseInt(this._clone.css("paddingBottom"), 10);
      border = parseInt(this._clone.css("borderTopWidth"), 10) + parseInt(this._clone.css("borderBottomWidth"), 10);
      height = height + border + padding;
    }
    return this.setHeight(this.initialHeight ? Math.max(this.initialHeight, height) : height);
  };

  KDInputView.prototype.enableTabKey = function() {
    return this.inputTabKeyEnabled = true;
  };

  KDInputView.prototype.disableTabKey = function() {
    return this.inputTabKeyEnabled = false;
  };

  KDInputView.prototype.change = function() {};

  KDInputView.prototype.keyUp = function() {
    return true;
  };

  KDInputView.prototype.keyDown = function(event) {
    if (this.inputTabKeyEnabled) {
      this.checkTabKey(event);
    }
    return true;
  };

  KDInputView.prototype.focus = function() {
    this.setKeyView();
    return true;
  };

  KDInputView.prototype.blur = function() {
    KD.getSingleton("windowController").revertKeyView(this);
    return true;
  };

  KDInputView.prototype.mouseDown = function() {
    this.setFocus();
    return false;
  };

  KDInputView.prototype.checkTabKey = function(event) {
    var post, pre, se, sel, ss, t, tab, tabLength;
    tab = "  ";
    tabLength = tab.length;
    t = event.target;
    ss = t.selectionStart;
    se = t.selectionEnd;
    if (event.which === 9) {
      event.preventDefault();
      if (ss !== se && t.value.slice(ss, se).indexOf("n") !== -1) {
        pre = t.value.slice(0, ss);
        sel = t.value.slice(ss, se).replace(/n/g, "n" + tab);
        post = t.value.slice(se, t.value.length);
        t.value = pre.concat(tab).concat(sel).concat(post);
        t.selectionStart = ss + tab.length;
        return t.selectionEnd = se + tab.length;
      } else {
        t.value = t.value.slice(0, ss).concat(tab).concat(t.value.slice(ss, t.value.length));
        if (ss === se) {
          return t.selectionStart = t.selectionEnd = ss + tab.length;
        } else {
          t.selectionStart = ss + tab.length;
          return t.selectionEnd = se + tab.length;
        }
      }
    } else if (event.which === 8 && t.value.slice(ss - tabLength, ss) === tab) {
      event.preventDefault();
      t.value = t.value.slice(0, ss - tabLength).concat(t.value.slice(ss, t.value.length));
      return t.selectionStart = t.selectionEnd = ss - tab.length;
    } else if (event.which === 46 && t.value.slice(se, se + tabLength) === tab) {
      event.preventDefault();
      t.value = t.value.slice(0, ss).concat(t.value.slice(ss + tabLength, t.value.length));
      return t.selectionStart = t.selectionEnd = ss;
    } else if (event.which === 37 && t.value.slice(ss - tabLength, ss) === tab) {
      event.preventDefault();
      return t.selectionStart = t.selectionEnd = ss - tabLength;
    } else if (event.which === 39 && t.value.slice(ss, ss + tabLength) === tab) {
      event.preventDefault();
      return t.selectionStart = t.selectionEnd = ss + tabLength;
    }
  };

  return KDInputView;

})(KDView);


},{"./../../core/view.coffee":108,"./inputvalidator.coffee":45}],47:[function(require,module,exports){
var KDLabelView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDLabelView = (function(_super) {
  __extends(KDLabelView, _super);

  function KDLabelView(options) {
    if ((options != null ? options.title : void 0) != null) {
      this.setTitle(options.title);
    }
    KDLabelView.__super__.constructor.call(this, options);
  }

  KDLabelView.prototype.setDomElement = function(cssClass) {
    return this.domElement = $("<label class='kdlabel " + cssClass + "'>" + (this.getTitle()) + "</label>");
  };

  KDLabelView.prototype.setTitle = function(title) {
    return this.labelTitle = title || '';
  };

  KDLabelView.prototype.updateTitle = function(title) {
    this.setTitle(title);
    return this.$().html(title);
  };

  KDLabelView.prototype.getTitle = function() {
    return this.labelTitle;
  };

  return KDLabelView;

})(KDView);


},{"./../../core/view.coffee":108}],48:[function(require,module,exports){
var KDInputView, KDMultipleChoice,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

KDInputView = require('./inputview.coffee');

module.exports = KDMultipleChoice = (function(_super) {
  var setCurrent;

  __extends(KDMultipleChoice, _super);

  function KDMultipleChoice(options, data) {
    if (options == null) {
      options = {};
    }
    if (options.disabled == null) {
      options.disabled = false;
    }
    options.size || (options.size = "small");
    options.labels || (options.labels = ["ON", "OFF"]);
    options.titles || (options.titles = options.labels);
    if (options.multiple == null) {
      options.multiple = false;
    }
    options.defaultValue || (options.defaultValue = options.multiple ? options.labels[0] : void 0);
    if (!options.multiple && Array.isArray(options.defaultValue)) {
      options.defaultValue = options.defaultValue[0];
    }
    KDMultipleChoice.__super__.constructor.call(this, options, data);
    this.setClass(options.size);
    this.setPartial("<input class='hidden no-kdinput' name='" + (this.getName()) + "'/>");
    this.oldValue = null;
    if (options.multiple) {
      this.currentValue = [];
    }
    this.setDisabled(options.disabled);
  }

  KDMultipleChoice.prototype.setDomElement = function(cssClass) {
    var activeClass, clsName, defaultValue, i, label, labelItems, labels, name, titles, _i, _len, _ref;
    _ref = this.getOptions(), titles = _ref.titles, labels = _ref.labels, name = _ref.name, defaultValue = _ref.defaultValue;
    this.inputName = name;
    labelItems = "";
    for (i = _i = 0, _len = labels.length; _i < _len; i = ++_i) {
      label = labels[i];
      activeClass = label === defaultValue ? ' active' : '';
      clsName = "multiple-choice-" + label + activeClass;
      labelItems += "<a href='#' name='" + label + "' class='" + clsName + "' title='" + (titles[i] || 'Select ' + label) + "'>" + label + "</a>";
    }
    return this.domElement = $("<div class='kdinput on-off multiple-choice " + cssClass + "'>\n  " + labelItems + "\n</div> ");
  };

  KDMultipleChoice.prototype.getDefaultValue = function() {
    return this.getOptions().defaultValue;
  };

  KDMultipleChoice.prototype.getValue = function() {
    return this.currentValue;
  };

  setCurrent = function(view, label) {
    if (__indexOf.call(view.currentValue, label) >= 0) {
      view.$("a[name$='" + label + "']").removeClass('active');
      return view.currentValue.splice(view.currentValue.indexOf(label), 1);
    } else {
      view.$("a[name$='" + label + "']").addClass('active');
      return view.currentValue.push(label);
    }
  };

  KDMultipleChoice.prototype.setDisabled = function(disable) {
    if (disable == null) {
      disable = true;
    }
    return this._disabled = disable;
  };

  KDMultipleChoice.prototype.setValue = function(label, wCallback) {
    var multiple, obj, val, _ref;
    if (wCallback == null) {
      wCallback = true;
    }
    multiple = this.getOptions().multiple;
    if (multiple) {
      this.oldValue = (_ref = [
        (function() {
          var _i, _len, _ref1, _results;
          _ref1 = this.currentValue;
          _results = [];
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            obj = _ref1[_i];
            _results.push(obj);
          }
          return _results;
        }).call(this)
      ]) != null ? _ref.first : void 0;
      if (Array.isArray(label)) {
        [
          (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = label.length; _i < _len; _i++) {
              val = label[_i];
              _results.push(setCurrent(this, val));
            }
            return _results;
          }).call(this)
        ];
      } else {
        setCurrent(this, label);
      }
      if (wCallback) {
        return this.switchStateChanged();
      }
    } else {
      this.$("a").removeClass('active');
      this.$("a[name='" + label + "']").addClass('active');
      this.oldValue = this.currentValue;
      this.currentValue = label;
      if (this.currentValue !== this.oldValue && wCallback) {
        return this.switchStateChanged();
      }
    }
  };

  KDMultipleChoice.prototype.switchStateChanged = function() {
    if (this._disabled) {
      return;
    }
    if (this.getCallback() != null) {
      return this.getCallback().call(this, this.getValue());
    }
  };

  KDMultipleChoice.prototype.fallBackToOldState = function() {
    var multiple;
    multiple = this.getOptions().multiple;
    if (multiple) {
      this.currentValue = [];
      this.$("a").removeClass('active');
    }
    return this.setValue(this.oldValue, false);
  };

  KDMultipleChoice.prototype.mouseDown = function(event) {
    if (this._disabled) {
      return;
    }
    if ($(event.target).is('a')) {
      return this.setValue(event.target.name);
    }
  };

  return KDMultipleChoice;

})(KDInputView);


},{"./inputview.coffee":46}],49:[function(require,module,exports){
var KDInputView, KDOnOffSwitch,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDInputView = require('./inputview.coffee');

module.exports = KDOnOffSwitch = (function(_super) {
  __extends(KDOnOffSwitch, _super);

  function KDOnOffSwitch(options, data) {
    if (options == null) {
      options = {};
    }
    options.type = "switch";
    options.title || (options.title = "");
    options.size || (options.size = "small");
    options.labels || (options.labels = ["ON", "OFF"]);
    if (options.defaultValue == null) {
      options.defaultValue = false;
    }
    KDOnOffSwitch.__super__.constructor.call(this, options, data);
    this.setClass(options.size);
    this.setPartial("<input class='checkbox hidden no-kdinput' type='checkbox' name='" + (this.getName()) + "'/>");
    this.setDefaultValue(options.defaultValue);
  }

  KDOnOffSwitch.prototype.setDomElement = function(cssClass) {
    var labels, name, title, _ref;
    _ref = this.getOptions(), title = _ref.title, labels = _ref.labels, name = _ref.name;
    if (title !== '') {
      title = "<span>" + title + "</span>";
    }
    this.inputName = name;
    return this.domElement = $("<div class='kdinput on-off off " + cssClass + "'>\n  " + title + "\n  <a href='#' class='on' title='turn on'>" + labels[0] + "</a><a href='#' class='off' title='turn off'>" + labels[1] + "</a>\n</div> ");
  };

  KDOnOffSwitch.prototype.getValue = function() {
    return this.$("input").attr("checked") === "checked";
  };

  KDOnOffSwitch.prototype.setValue = function(value, wCallback) {
    if (wCallback == null) {
      wCallback = true;
    }
    switch (value) {
      case true:
        return this.setOn(wCallback);
      case false:
        return this.setOff(wCallback);
    }
  };

  KDOnOffSwitch.prototype.setDefaultValue = function(value) {
    switch (value) {
      case true:
      case "on":
      case "true":
      case "yes":
      case 1:
        return this.setValue(true, false);
      default:
        return this.setValue(false, false);
    }
  };

  KDOnOffSwitch.prototype.setOff = function(wCallback) {
    if (wCallback == null) {
      wCallback = true;
    }
    if (!this.getValue() && wCallback) {
      return;
    }
    this.$("input").attr("checked", false);
    this.$('a.on').removeClass('active');
    this.$('a.off').addClass('active');
    if (wCallback) {
      return this.switchStateChanged();
    }
  };

  KDOnOffSwitch.prototype.setOn = function(wCallback) {
    if (wCallback == null) {
      wCallback = true;
    }
    if (this.getValue() && wCallback) {
      return;
    }
    this.$("input").attr("checked", true);
    this.$('a.off').removeClass('active');
    this.$('a.on').addClass('active');
    if (wCallback) {
      return this.switchStateChanged();
    }
  };

  KDOnOffSwitch.prototype.switchStateChanged = function() {
    this.emit('SwitchStateChanged', this.getValue());
    if (this.getCallback() != null) {
      return this.getCallback().call(this, this.getValue());
    }
  };

  KDOnOffSwitch.prototype.click = KD.utils.stopDOMEvent;

  KDOnOffSwitch.prototype.mouseDown = function(event) {
    if ($(event.target).is('a.on')) {
      return this.setValue(true);
    } else if ($(event.target).is('a.off')) {
      return this.setValue(false);
    }
  };

  return KDOnOffSwitch;

})(KDInputView);


},{"./inputview.coffee":46}],50:[function(require,module,exports){
var KDInputView, KDSelectBox,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDInputView = require('./inputview.coffee');

module.exports = KDSelectBox = (function(_super) {
  __extends(KDSelectBox, _super);

  function KDSelectBox(options) {
    if (options == null) {
      options = {};
    }
    options.type = "select";
    KDSelectBox.__super__.constructor.call(this, options);
  }

  KDSelectBox.prototype.setDomElement = function(cssClass) {
    var name;
    this.inputName = this.getOption("name");
    name = "name='" + this.options.name + "'";
    this.domElement = $("<div class='kdselectbox " + cssClass + "'>\n  <select " + name + "></select>\n  <span class='title'></span>\n  <span class='arrows'></span>\n</div>\"");
    this._$select = this.$("select").eq(0);
    this._$title = this.$("span.title").eq(0);
    return this.domElement;
  };

  KDSelectBox.prototype.bindEvents = function() {
    this._$select.bind("blur change focus", (function(_this) {
      return function(event) {
        var _base;
        if (event.type === "change") {
          if (typeof (_base = _this.getCallback()) === "function") {
            _base(_this.getValue());
          }
        }
        _this.emit(event.type, event, _this.getValue());
        return _this.handleEvent(event);
      };
    })(this));
    return KDSelectBox.__super__.bindEvents.apply(this, arguments);
  };

  KDSelectBox.prototype.setDefaultValue = function(value) {
    if (value !== "") {
      this.getDomElement().val(value);
    }
    this._$select.val(value);
    this._$title.text(this._$select.find("option[value=\"" + value + "\"]").text());
    return this.inputDefaultValue = value;
  };

  KDSelectBox.prototype.getDefaultValue = function() {
    return this.inputDefaultValue;
  };

  KDSelectBox.prototype.getValue = function() {
    return this._$select.val();
  };

  KDSelectBox.prototype.setValue = function(value) {
    this._$select.val(value);
    return this.change();
  };

  KDSelectBox.prototype.makeDisabled = function() {
    this.setClass("disabled");
    return this._$select.attr("disabled", "disabled");
  };

  KDSelectBox.prototype.makeEnabled = function() {
    this.unsetClass("disabled");
    return this._$select.removeAttr("disabled");
  };

  KDSelectBox.prototype.setSelectOptions = function(options) {
    var $optGroup, firstOption, optGroup, option, subOptions, value, _i, _j, _len, _len1;
    firstOption = null;
    if (!options.length) {
      for (optGroup in options) {
        if (!__hasProp.call(options, optGroup)) continue;
        subOptions = options[optGroup];
        $optGroup = $("<optgroup label='" + optGroup + "'/>");
        this._$select.append($optGroup);
        for (_i = 0, _len = subOptions.length; _i < _len; _i++) {
          option = subOptions[_i];
          firstOption || (firstOption = option);
          $optGroup.append("<option value='" + option.value + "'>" + option.title + "</option>");
        }
      }
    } else if (options.length) {
      for (_j = 0, _len1 = options.length; _j < _len1; _j++) {
        option = options[_j];
        this._$select.append("<option value='" + option.value + "'>" + option.title + "</option>");
        firstOption || (firstOption = option);
      }
    } else {
      warn("no valid options specified for the input:", this);
    }
    value = this.getDefaultValue() || (firstOption != null ? firstOption.value : void 0) || "";
    this._$select.val(value + "");
    return this._$title.text(this._$select.find("option[value=\"" + value + "\"]").text());
  };

  KDSelectBox.prototype.removeSelectOptions = function() {
    this._$select.find("optgroup").remove();
    return this._$select.find("option").remove();
  };

  KDSelectBox.prototype.change = function() {
    return this._$title.text(this._$select.find("option[value=\"" + (this.getValue()) + "\"]").text());
  };

  KDSelectBox.prototype.focus = function() {
    return this.setClass('focus');
  };

  KDSelectBox.prototype.blur = function() {
    return this.unsetClass('focus');
  };

  return KDSelectBox;

})(KDInputView);


},{"./inputview.coffee":46}],51:[function(require,module,exports){
var KDContentEditableView, KDContextMenu, KDTokenizedInput,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDContentEditableView = require('./contenteditableview.coffee');

KDContextMenu = require('./../contextmenu/contextmenu.coffee');

module.exports = KDTokenizedInput = (function(_super) {
  __extends(KDTokenizedInput, _super);

  function KDTokenizedInput(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass = KD.utils.curry("kdtokenizedinputview", options.cssClass);
    options.bind = KD.utils.curry("keyup", options.bind);
    options.rules || (options.rules = {});
    options.layer || (options.layer = {});
    KDTokenizedInput.__super__.constructor.call(this, options, data);
    this.tokenViews = {};
  }

  KDTokenizedInput.prototype.getValue = function(options) {
    var node, nodeValue, value, _i, _len, _ref, _ref1;
    if (options == null) {
      options = {};
    }
    value = "";
    _ref = this.getEditableElement().childNodes;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      node = _ref[_i];
      if (((_ref1 = node.tagName) != null ? _ref1.toLowerCase() : void 0) === "div") {
        value += "\n";
      }
      nodeValue = this.getValueOfNode(node);
      if (nodeValue !== "\n") {
        value += nodeValue;
      }
    }
    if (value === Encoder.htmlDecode(this.getOptions().placeholder)) {
      return "";
    } else {
      return value;
    }
  };

  KDTokenizedInput.prototype.getValueOfNode = function(node) {
    var value;
    value = "";
    switch (node.nodeType) {
      case Node.TEXT_NODE:
        if (node.textContent !== "") {
          value += node.textContent;
        }
        break;
      case Node.ELEMENT_NODE:
        value += this.getValueOfElement(node);
    }
    return value;
  };

  KDTokenizedInput.prototype.getValueOfElement = function(element) {
    var child, key, tagName, value, _i, _len, _ref, _ref1;
    key = (_ref = element.dataset) != null ? _ref.key : void 0;
    if (key) {
      value = this.getValueOfTokenElement(key);
    }
    if (value) {
      return value;
    }
    tagName = element.tagName.toLowerCase();
    switch (tagName) {
      case "br":
        return "\n";
      default:
        value = "";
        _ref1 = element.childNodes;
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          child = _ref1[_i];
          value += this.getValueOfNode(child);
        }
        return value || "";
    }
  };

  KDTokenizedInput.prototype.getValueOfTokenElement = function(key) {
    var view;
    view = this.getTokenView(key);
    if (key && view) {
      return view.encodeValue();
    }
  };

  KDTokenizedInput.prototype.getTokens = function() {
    return this.findTokensInElement(this.getEditableElement());
  };

  KDTokenizedInput.prototype.findTokensInElement = function(element) {
    var child, data, key, tokens, type, view, _i, _len, _ref, _ref1;
    tokens = [];
    _ref = element.childNodes;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      child = _ref[_i];
      switch (child.nodeType) {
        case Node.ELEMENT_NODE:
          if (key = (_ref1 = child.dataset) != null ? _ref1.key : void 0) {
            view = this.getTokenView(key);
            type = view.getOptions().type;
            data = view.getData();
            tokens.push({
              type: type,
              data: data
            });
          } else {
            tokens = tokens.concat(this.findTokensInElement(child));
          }
      }
    }
    return tokens;
  };

  KDTokenizedInput.prototype.getTokenView = function(key) {
    return this.tokenViews[key];
  };

  KDTokenizedInput.prototype.matchPrefix = function() {
    var char, name, node, range, rule, start, _ref, _ref1, _results;
    if (this.tokenInput) {
      return;
    }
    if (!(range = this.utils.getSelectionRange())) {
      return;
    }
    node = range.commonAncestorContainer;
    if (((_ref = node.children) != null ? _ref.length : void 0) === 1) {
      return node.textContent === node.children[0].textContent;
    }
    start = range.startOffset - 1;
    char = node.textContent[start];
    _ref1 = this.getOptions().rules;
    _results = [];
    for (name in _ref1) {
      rule = _ref1[name];
      if (char === rule.prefix) {
        this.activeRule = rule;
        this.tokenInput = document.createElement("span");
        this.tokenInput.textContent = rule.prefix;
        this.utils.replaceRange(node, this.tokenInput, start, start + rule.prefix.length);
        _results.push(this.utils.selectText(this.tokenInput, rule.prefix.length));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  KDTokenizedInput.prototype.matchToken = function() {
    var dataSource, token;
    if (!this.tokenInput.parentNode) {
      return this.cancel();
    }
    this.sanitizeInput();
    token = this.tokenInput.textContent.substring(this.activeRule.prefix.length);
    if (token.trim()) {
      dataSource = this.activeRule.dataSource;
      return dataSource(token, this.bound("showMenu"));
    } else if (token.length !== 0) {
      return this.cancel();
    }
  };

  KDTokenizedInput.prototype.sanitizeInput = function() {};

  KDTokenizedInput.prototype.showMenu = function(options, data) {
    var pos, _ref;
    if ((_ref = this.menu) != null) {
      _ref.destroy();
    }
    this.blur();
    if (!(this.tokenInput && data.length)) {
      return;
    }
    pos = this.tokenInput.getBoundingClientRect();
    options.x = pos.left;
    options.y = pos.top + parseInt(window.getComputedStyle(this.tokenInput).lineHeight, 10);
    this.menu = new KDContextMenu(options, data);
    return this.menu.on("ContextMenuItemReceivedClick", this.bound("menuItemClicked"));
  };

  KDTokenizedInput.prototype.hideMenu = function() {
    var _ref;
    if ((_ref = this.menu) != null) {
      _ref.destroy();
    }
    this.menu = null;
    this.activeRule = null;
    return this.tokenInput = null;
  };

  KDTokenizedInput.prototype.menuItemClicked = function(item, tokenViewClass) {
    this.addToken(item.data, tokenViewClass);
    return this.hideMenu();
  };

  KDTokenizedInput.prototype.addToken = function(item, tokenViewClass) {
    var pistachio, prefix, tokenElement, tokenKey, tokenView, type, _ref;
    if (tokenViewClass == null) {
      tokenViewClass = this.getOptions().tokenViewClass;
    }
    _ref = this.activeRule, type = _ref.type, prefix = _ref.prefix, pistachio = _ref.pistachio;
    tokenView = new tokenViewClass({
      type: type,
      prefix: prefix,
      pistachio: pistachio
    }, item);
    tokenElement = tokenView.getElement();
    tokenKey = "" + (tokenView.getId()) + "-" + (tokenView.getKey());
    this.tokenViews[tokenKey] = tokenView;
    tokenView.setAttributes({
      "data-key": tokenKey
    });
    this.tokenInput.parentElement.insertBefore(tokenElement, this.tokenInput);
    tokenView.emit("viewAppended");
    this.tokenInput.nextSibling.textContent = "\u00a0";
    this.utils.selectText(this.tokenInput.nextSibling, 1);
    this.tokenInput.remove();
    return this.emit("TokenAdded", type, item);
  };

  KDTokenizedInput.prototype.keyDown = function(event) {
    switch (event.which) {
      case 9:
      case 13:
      case 27:
      case 38:
      case 40:
        if (this.menu) {
          this.menu.treeController.keyEventHappened(event);
          this.utils.stopDOMEvent(event);
        }
        break;
      default:
        KDTokenizedInput.__super__.keyDown.call(this, event);
    }
    switch (event.which) {
      case 27:
        if (this.tokenInput) {
          return this.cancel();
        }
    }
  };

  KDTokenizedInput.prototype.keyUp = function(event) {
    KDTokenizedInput.__super__.keyUp.apply(this, arguments);
    switch (event.which) {
      case 9:
      case 13:
      case 27:
      case 38:
      case 40:
        break;
      default:
        if (event.altKey || event.ctrlKey || event.metaKey) {
          return;
        }
        if (this.activeRule) {
          return this.matchToken();
        } else {
          return this.matchPrefix();
        }
    }
  };

  KDTokenizedInput.prototype.cancel = function() {
    var text;
    if (this.tokenInput.parentNode) {
      text = document.createTextNode(this.tokenInput.textContent);
      this.tokenInput.parentElement.insertBefore(text, this.tokenInput);
      this.tokenInput.nextSibling.remove();
      this.tokenInput.remove();
      this.utils.selectEnd(text);
    }
    return this.hideMenu();
  };

  KDTokenizedInput.prototype.reset = function() {
    var id, view, _ref, _results;
    this.setPlaceholder();
    this.blur();
    _ref = this.tokenViews;
    _results = [];
    for (id in _ref) {
      if (!__hasProp.call(_ref, id)) continue;
      view = _ref[id];
      view.destroy();
      _results.push(delete this.tokenViews[id]);
    }
    return _results;
  };

  KDTokenizedInput.prototype.viewAppended = function() {
    KDTokenizedInput.__super__.viewAppended.apply(this, arguments);
    return this.setEditingMode(true);
  };

  return KDTokenizedInput;

})(KDContentEditableView);


},{"./../contextmenu/contextmenu.coffee":23,"./contenteditableview.coffee":39}],52:[function(require,module,exports){
var KDInputView, KDWmdInput,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDInputView = require('./inputview.coffee');

module.exports = KDWmdInput = (function(_super) {
  __extends(KDWmdInput, _super);

  function KDWmdInput(options, data) {
    var _ref;
    options = options != null ? options : {};
    options.type = "textarea";
    options.preview = (_ref = options.preview) != null ? _ref : false;
    KDWmdInput.__super__.constructor.call(this, options, data);
    this.setClass("monospace");
  }

  KDWmdInput.prototype.setWMD = function() {
    var preview;
    preview = this.getOptions().preview;
    this.getDomElement().wmd({
      preview: preview
    });
    if (preview) {
      return this.getDomElement().after("<h3 class='wmd-preview-title'>Preview:</h3>");
    }
  };

  return KDWmdInput;

})(KDInputView);


},{"./inputview.coffee":46}],53:[function(require,module,exports){
var KDListItemView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDListItemView = (function(_super) {
  __extends(KDListItemView, _super);

  function KDListItemView(options, data) {
    var _ref, _ref1;
    if (options == null) {
      options = {};
    }
    options.type = (_ref = options.type) != null ? _ref : "default";
    options.cssClass = "kdlistitemview kdlistitemview-" + options.type + " " + ((_ref1 = options.cssClass) != null ? _ref1 : '');
    options.bind || (options.bind = "mouseenter mouseleave");
    options.childClass || (options.childClass = null);
    options.childOptions || (options.childOptions = {});
    if (options.selectable == null) {
      options.selectable = true;
    }
    KDListItemView.__super__.constructor.call(this, options, data);
    this.content = {};
  }

  KDListItemView.prototype.viewAppended = function() {
    var childClass, childOptions, _ref;
    _ref = this.getOptions(), childClass = _ref.childClass, childOptions = _ref.childOptions;
    if (childClass) {
      return this.addSubView(this.child = new childClass(childOptions, this.getData()));
    } else {
      return this.setPartial(this.partial(this.data));
    }
  };

  KDListItemView.prototype.partial = function() {
    return "<div class='kdlistitemview-default-content'> <p>This is a default partial of <b>KDListItemView</b>, you need to override this partial to have your custom content here.</p> </div>";
  };

  KDListItemView.prototype.dim = function() {
    return this.setClass("dimmed");
  };

  KDListItemView.prototype.undim = function() {
    return this.unsetClass("dimmed");
  };

  KDListItemView.prototype.highlight = function() {
    this.undim();
    return this.setClass("selected");
  };

  KDListItemView.prototype.removeHighlight = function() {
    this.undim();
    return this.unsetClass("selected");
  };

  KDListItemView.prototype.getItemDataId = function() {
    var _base;
    return (typeof (_base = this.getData()).getId === "function" ? _base.getId() : void 0) || this.getData().id || this.getData()._id;
  };

  return KDListItemView;

})(KDView);


},{"./../../core/view.coffee":108}],54:[function(require,module,exports){
var KDListView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDListView = (function(_super) {
  __extends(KDListView, _super);

  function KDListView(options, data) {
    if (options == null) {
      options = {};
    }
    options.type || (options.type = "default");
    if (options.lastToFirst == null) {
      options.lastToFirst = false;
    }
    options.cssClass = options.cssClass != null ? "kdlistview kdlistview-" + options.type + " " + options.cssClass : "kdlistview kdlistview-" + options.type;
    if (!this.items) {
      this.items = [];
    }
    KDListView.__super__.constructor.call(this, options, data);
  }

  KDListView.prototype.empty = function() {
    var i, item, _i, _len, _ref;
    _ref = this.items;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      item = _ref[i];
      if (item != null) {
        item.destroy();
      }
    }
    return this.items = [];
  };

  KDListView.prototype.keyDown = function(event) {
    event.stopPropagation();
    event.preventDefault();
    return this.emit("KeyDownOnList", event);
  };

  KDListView.prototype.addItem = function(itemData, index, animation) {
    var itemChildClass, itemChildOptions, itemInstance, itemOptions, _ref, _ref1;
    _ref = this.getOptions(), itemChildClass = _ref.itemChildClass, itemChildOptions = _ref.itemChildOptions;
    if ((index != null) && typeof index !== 'number') {
      itemOptions = index;
      index = null;
    } else {
      itemOptions = this.getOptions().itemOptions;
    }
    itemOptions = (typeof this.customizeItemOptions === "function" ? this.customizeItemOptions(itemOptions, itemData) : void 0) || itemOptions || {};
    itemOptions.delegate || (itemOptions.delegate = this);
    itemOptions.childClass || (itemOptions.childClass = itemChildClass);
    itemOptions.childOptions || (itemOptions.childOptions = itemChildOptions);
    itemInstance = new ((_ref1 = this.getOptions().itemClass) != null ? _ref1 : KDListItemView)(itemOptions, itemData);
    this.addItemView(itemInstance, index, animation);
    return itemInstance;
  };

  KDListView.prototype.removeItem = function(itemInstance, itemData, index) {
    var i, item, _i, _len, _ref;
    if (index != null) {
      this.emit('ItemIsBeingDestroyed', {
        view: this.items[index],
        index: index
      });
      item = this.items.splice(index, 1);
      item[0].destroy();
    } else {
      _ref = this.items;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        item = _ref[i];
        if (itemInstance === item || itemData === item.getData()) {
          this.emit('ItemIsBeingDestroyed', {
            view: item,
            index: i
          });
          this.items.splice(i, 1);
          item.destroy();
          return;
        }
      }
    }
  };

  KDListView.prototype.removeItemByData = function(itemData) {
    return this.removeItem(null, itemData);
  };

  KDListView.prototype.removeItemByIndex = function(index) {
    return this.removeItem(null, null, index);
  };

  KDListView.prototype.destroy = function(animated, animationType, duration) {
    var item, _i, _len, _ref;
    if (animated == null) {
      animated = false;
    }
    if (animationType == null) {
      animationType = "slideUp";
    }
    if (duration == null) {
      duration = 100;
    }
    _ref = this.items;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      item.destroy();
    }
    return KDListView.__super__.destroy.call(this);
  };

  KDListView.prototype.addItemView = function(itemInstance, index, animation) {
    var actualIndex;
    this.emit('ItemWasAdded', itemInstance, index);
    if (index != null) {
      actualIndex = this.getOptions().lastToFirst ? this.items.length - index - 1 : index;
      this.items.splice(actualIndex, 0, itemInstance);
      this.appendItemAtIndex(itemInstance, index, animation);
    } else {
      this.items[this.getOptions().lastToFirst ? 'unshift' : 'push'](itemInstance);
      this.appendItem(itemInstance, animation);
    }
    return itemInstance;
  };

  KDListView.prototype.appendItem = function(itemInstance, animation) {
    var scroll;
    itemInstance.setParent(this);
    scroll = this.doIHaveToScroll();
    if (animation != null) {
      itemInstance.$().hide();
      this.$()[this.getOptions().lastToFirst ? 'prepend' : 'append'](itemInstance.$());
      itemInstance.$()[animation.type](animation.duration, (function(_this) {
        return function() {
          return itemInstance.emit('introEffectCompleted');
        };
      })(this));
    } else {
      this.$()[this.getOptions().lastToFirst ? 'prepend' : 'append'](itemInstance.$());
    }
    if (scroll) {
      this.scrollDown();
    }
    if (this.parentIsInDom) {
      itemInstance.emit('viewAppended');
    }
    return null;
  };

  KDListView.prototype.appendItemAtIndex = function(itemInstance, index, animation) {
    var actualIndex;
    itemInstance.setParent(this);
    actualIndex = this.getOptions().lastToFirst ? this.items.length - index - 1 : index;
    if (animation != null) {
      itemInstance.$().hide();
      if (index === 0) {
        this.$()[this.getOptions().lastToFirst ? 'append' : 'prepend'](itemInstance.$());
      }
      if (index > 0) {
        this.items[actualIndex - 1].$()[this.getOptions().lastToFirst ? 'before' : 'after'](itemInstance.$());
      }
      itemInstance.$()[animation.type](animation.duration, (function(_this) {
        return function() {
          return itemInstance.emit('introEffectCompleted');
        };
      })(this));
    } else {
      if (index === 0) {
        this.$()[this.getOptions().lastToFirst ? 'append' : 'prepend'](itemInstance.$());
      }
      if (index > 0) {
        this.items[actualIndex - 1].$()[this.getOptions().lastToFirst ? 'before' : 'after'](itemInstance.$());
      }
    }
    if (this.parentIsInDom) {
      itemInstance.emit('viewAppended');
    }
    return null;
  };

  KDListView.prototype.getItemIndex = function(targetItem) {
    var index, item, _i, _len, _ref;
    _ref = this.items;
    for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
      item = _ref[index];
      if (item === targetItem) {
        return index;
      }
    }
    return -1;
  };

  KDListView.prototype.moveItemToIndex = function(item, newIndex) {
    var currentIndex, diff, targetItem;
    currentIndex = this.getItemIndex(item);
    if (currentIndex < 0) {
      warn("Item doesn't exists", item);
      return this.items;
    }
    newIndex = Math.max(0, Math.min(this.items.length - 1, newIndex));
    if (newIndex >= this.items.length - 1) {
      targetItem = this.items.last;
      targetItem.$().after(item.$());
    } else {
      diff = newIndex > currentIndex ? 1 : 0;
      targetItem = this.items[newIndex + diff];
      targetItem.$().before(item.$());
    }
    this.items.splice(currentIndex, 1);
    this.items.splice(newIndex, 0, item);
    return this.items;
  };

  KDListView.prototype.scrollDown = function() {
    clearTimeout(this._scrollDownTimeout);
    return this._scrollDownTimeout = setTimeout((function(_this) {
      return function() {
        var scrollView, slidingHeight, slidingView;
        scrollView = _this.$().closest(".kdscrollview");
        slidingView = scrollView.find('> .kdview');
        slidingHeight = slidingView.height();
        return scrollView.animate({
          scrollTop: slidingHeight
        }, {
          duration: 200,
          queue: false
        });
      };
    })(this), 50);
  };

  KDListView.prototype.doIHaveToScroll = function() {
    var scrollView;
    scrollView = this.$().closest(".kdscrollview");
    if (this.getOptions().autoScroll) {
      if (scrollView.length && scrollView[0].scrollHeight <= scrollView.height()) {
        return true;
      } else {
        return this.isScrollAtBottom();
      }
    } else {
      return false;
    }
  };

  KDListView.prototype.isScrollAtBottom = function() {
    var scrollTop, scrollView, scrollViewheight, slidingHeight, slidingView;
    scrollView = this.$().closest(".kdscrollview");
    slidingView = scrollView.find('> .kdview');
    scrollTop = scrollView.scrollTop();
    slidingHeight = slidingView.height();
    scrollViewheight = scrollView.height();
    if (slidingHeight - scrollViewheight === scrollTop) {
      return true;
    } else {
      return false;
    }
  };

  return KDListView;

})(KDView);


},{"./../../core/view.coffee":108}],55:[function(require,module,exports){
var KDListView, KDListViewController, KDLoaderView, KDScrollView, KDView, KDViewController,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

KDView = require('./../../core/view.coffee');

KDViewController = require('./../../core/viewcontroller.coffee');

KDScrollView = require('./../scrollview/scrollview.coffee');

KDListView = require('./../list/listview.coffee');

KDLoaderView = require('./../loader/loaderview.coffee');

module.exports = KDListViewController = (function(_super) {
  __extends(KDListViewController, _super);

  function KDListViewController(options, data) {
    var listView, noItemFoundWidget, viewOptions;
    if (options == null) {
      options = {};
    }
    if (options.wrapper == null) {
      options.wrapper = true;
    }
    if (options.scrollView == null) {
      options.scrollView = true;
    }
    if (options.keyNav == null) {
      options.keyNav = false;
    }
    if (options.multipleSelection == null) {
      options.multipleSelection = false;
    }
    if (options.selection == null) {
      options.selection = false;
    }
    if (options.ownScrollBars == null) {
      options.ownScrollBars = false;
    }
    if (options.startWithLazyLoader == null) {
      options.startWithLazyLoader = false;
    }
    options.itemChildClass || (options.itemChildClass = null);
    options.itemChildOptions || (options.itemChildOptions = {});
    options.noItemFoundWidget || (options.noItemFoundWidget = null);
    options.noMoreItemFoundWidget || (options.noMoreItemFoundWidget = null);
    if (!this.itemsOrdered) {
      this.itemsOrdered = [];
    }
    this.itemsIndexed = {};
    this.selectedItems = [];
    this.lazyLoader = null;
    if (options.view) {
      this.setListView(listView = options.view);
    } else {
      viewOptions = options.viewOptions || {};
      viewOptions.lastToFirst || (viewOptions.lastToFirst = options.lastToFirst);
      viewOptions.itemClass || (viewOptions.itemClass = options.itemClass);
      viewOptions.itemOptions || (viewOptions.itemOptions = options.itemOptions);
      viewOptions.itemChildClass || (viewOptions.itemChildClass = options.itemChildClass);
      viewOptions.itemChildOptions || (viewOptions.itemChildOptions = options.itemChildOptions);
      this.setListView(listView = new KDListView(viewOptions));
    }
    if (options.scrollView) {
      this.scrollView = new KDScrollView({
        lazyLoadThreshold: options.lazyLoadThreshold,
        ownScrollBars: options.ownScrollBars
      });
    }
    options.view = options.wrapper ? new KDView({
      cssClass: "listview-wrapper"
    }) : listView;
    KDListViewController.__super__.constructor.call(this, options, data);
    noItemFoundWidget = this.getOptions().noItemFoundWidget;
    listView.on('ItemWasAdded', (function(_this) {
      return function(view, index) {
        _this.registerItem(view, index);
        if (noItemFoundWidget) {
          return _this.hideNoItemWidget();
        }
      };
    })(this));
    listView.on('ItemIsBeingDestroyed', (function(_this) {
      return function(itemInfo) {
        _this.unregisterItem(itemInfo);
        if (noItemFoundWidget) {
          return _this.showNoItemWidget();
        }
      };
    })(this));
    if (options.keyNav) {
      listView.on('KeyDownOnList', (function(_this) {
        return function(event) {
          return _this.keyDownPerformed(listView, event);
        };
      })(this));
    }
  }

  KDListViewController.prototype.loadView = function(mainView) {
    var options, _ref;
    options = this.getOptions();
    if (options.scrollView) {
      mainView.addSubView(this.scrollView);
      this.scrollView.addSubView(this.getListView());
      if (options.startWithLazyLoader) {
        this.showLazyLoader(false);
      }
      this.scrollView.on('LazyLoadThresholdReached', this.bound("showLazyLoader"));
    }
    if (options.noItemFoundWidget) {
      this.putNoItemView();
    }
    this.instantiateListItems(((_ref = this.getData()) != null ? _ref.items : void 0) || []);
    return KD.getSingleton("windowController").on("ReceivedMouseUpElsewhere", (function(_this) {
      return function(event) {
        return _this.mouseUpHappened(event);
      };
    })(this));
  };

  KDListViewController.prototype.instantiateListItems = function(items) {
    var itemData, newItems;
    newItems = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        itemData = items[_i];
        _results.push(this.getListView().addItem(itemData));
      }
      return _results;
    }).call(this);
    this.emit("AllItemsAddedToList");
    return newItems;
  };


  /*
  HELPERS
   */

  KDListViewController.prototype.itemForId = function(id) {
    return this.itemsIndexed[id];
  };

  KDListViewController.prototype.getItemsOrdered = function() {
    return this.itemsOrdered;
  };

  KDListViewController.prototype.getItemCount = function() {
    return this.itemsOrdered.length;
  };

  KDListViewController.prototype.setListView = function(listView) {
    return this.listView = listView;
  };

  KDListViewController.prototype.getListView = function() {
    return this.listView;
  };

  KDListViewController.prototype.forEachItemByIndex = function(ids, callback) {
    var _ref;
    if (!callback) {
      _ref = [ids, callback], callback = _ref[0], ids = _ref[1];
    }
    if (!Array.isArray(ids)) {
      ids = [ids];
    }
    return ids.forEach((function(_this) {
      return function(id) {
        var item;
        item = _this.itemsIndexed[id];
        if (item != null) {
          return callback(item);
        }
      };
    })(this));
  };

  KDListViewController.prototype.putNoItemView = function() {
    var noItemFoundWidget;
    noItemFoundWidget = this.getOptions().noItemFoundWidget;
    return this.getListView().addSubView(this.noItemView = noItemFoundWidget);
  };

  KDListViewController.prototype.showNoItemWidget = function() {
    var _ref;
    if (this.itemsOrdered.length === 0) {
      return (_ref = this.noItemView) != null ? _ref.show() : void 0;
    }
  };

  KDListViewController.prototype.hideNoItemWidget = function() {
    var _ref;
    return (_ref = this.noItemView) != null ? _ref.hide() : void 0;
  };

  KDListViewController.prototype.showNoMoreItemWidget = function() {
    var noMoreItemFoundWidget;
    noMoreItemFoundWidget = this.getOptions().noMoreItemFoundWidget;
    if (noMoreItemFoundWidget) {
      return this.scrollView.addSubView(noMoreItemFoundWidget);
    }
  };


  /*
  ITEM OPERATIONS
   */

  KDListViewController.prototype.addItem = function(itemData, index, animation) {
    return this.getListView().addItem(itemData, index, animation);
  };

  KDListViewController.prototype.removeItem = function(itemInstance, itemData, index) {
    return this.getListView().removeItem(itemInstance, itemData, index);
  };

  KDListViewController.prototype.registerItem = function(view, index) {
    var actualIndex, options;
    options = this.getOptions();
    if (index != null) {
      actualIndex = this.getOptions().lastToFirst ? this.getListView().items.length - index - 1 : index;
      this.itemsOrdered.splice(actualIndex, 0, view);
    } else {
      this.itemsOrdered[this.getOptions().lastToFirst ? 'unshift' : 'push'](view);
    }
    if (view.getData() != null) {
      this.itemsIndexed[view.getItemDataId()] = view;
    }
    if (options.selection) {
      view.on('click', (function(_this) {
        return function(event) {
          return _this.selectItem(view, event);
        };
      })(this));
    }
    if (options.keyNav || options.multipleSelection) {
      view.on("mousedown", (function(_this) {
        return function(event) {
          return _this.mouseDownHappenedOnItem(view, event);
        };
      })(this));
      return view.on("mouseenter", (function(_this) {
        return function(event) {
          return _this.mouseEnterHappenedOnItem(view, event);
        };
      })(this));
    }
  };

  KDListViewController.prototype.unregisterItem = function(itemInfo) {
    var actualIndex, index, view;
    this.emit("UnregisteringItem", itemInfo);
    index = itemInfo.index, view = itemInfo.view;
    actualIndex = this.getOptions().lastToFirst ? this.getListView().items.length - index - 1 : index;
    this.itemsOrdered.splice(actualIndex, 1);
    if (view.getData() != null) {
      return delete this.itemsIndexed[view.getItemDataId()];
    }
  };

  KDListViewController.prototype.replaceAllItems = function(items) {
    this.removeAllItems();
    return this.instantiateListItems(items);
  };

  KDListViewController.prototype.removeAllItems = function() {
    var itemsOrdered, listView;
    itemsOrdered = this.itemsOrdered;
    this.itemsOrdered.length = 0;
    this.itemsIndexed = {};
    listView = this.getListView();
    if (listView.items.length) {
      listView.empty();
    }
    return itemsOrdered;
  };

  KDListViewController.prototype.moveItemToIndex = function(item, newIndex) {
    newIndex = Math.max(0, Math.min(this.itemsOrdered.length - 1, newIndex));
    return this.itemsOrdered = this.getListView().moveItemToIndex(item, newIndex).slice();
  };


  /*
  HANDLING MOUSE EVENTS
   */

  KDListViewController.prototype.mouseDownHappenedOnItem = function(item, event) {
    if (this.getOptions().keyNav) {
      KD.getSingleton("windowController").setKeyView(this.getListView());
    }
    this.lastEvent = event;
    if (__indexOf.call(this.selectedItems, item) < 0) {
      this.mouseDown = true;
      this.mouseDownTempItem = item;
      return this.mouseDownTimer = setTimeout((function(_this) {
        return function() {
          _this.mouseDown = false;
          _this.mouseDownTempItem = null;
          return _this.selectItem(item, event);
        };
      })(this), 300);
    } else {
      this.mouseDown = false;
      return this.mouseDownTempItem = null;
    }
  };

  KDListViewController.prototype.mouseUpHappened = function(event) {
    clearTimeout(this.mouseDownTimer);
    this.mouseDown = false;
    return this.mouseDownTempItem = null;
  };

  KDListViewController.prototype.mouseEnterHappenedOnItem = function(item, event) {
    clearTimeout(this.mouseDownTimer);
    if (this.mouseDown) {
      if (!(event.metaKey || event.ctrlKey || event.shiftKey)) {
        this.deselectAllItems();
      }
      return this.selectItemsByRange(this.mouseDownTempItem, item);
    } else {
      return this.emit("MouseEnterHappenedOnItem", item);
    }
  };


  /*
  HANDLING KEY EVENTS
   */

  KDListViewController.prototype.keyDownPerformed = function(mainView, event) {
    switch (event.which) {
      case 40:
      case 38:
        this.selectItemBelowOrAbove(event);
        return this.emit("KeyDownOnListHandled", this.selectedItems);
    }
  };


  /*
  ITEM SELECTION
   */

  KDListViewController.prototype.selectItem = function(item, event) {
    var ctrlKey, metaKey, multipleSelection, selectable, shiftKey;
    if (event == null) {
      event = {};
    }
    if (item == null) {
      return;
    }
    this.lastEvent = event;
    selectable = item.getOptions().selectable;
    multipleSelection = this.getOptions().multipleSelection;
    metaKey = event.metaKey, ctrlKey = event.ctrlKey, shiftKey = event.shiftKey;
    if (!multipleSelection) {
      this.deselectAllItems();
    }
    if (selectable && !(metaKey || ctrlKey || shiftKey)) {
      this.deselectAllItems();
    }
    if (event.shiftKey && this.selectedItems.length > 0) {
      this.selectItemsByRange(this.selectedItems[0], item);
    } else {
      if (__indexOf.call(this.selectedItems, item) < 0) {
        this.selectSingleItem(item);
      } else {
        this.deselectSingleItem(item);
      }
    }
    return this.selectedItems;
  };

  KDListViewController.prototype.selectItemBelowOrAbove = function(event) {
    var addend, direction, lastSelectedIndex, selectedIndex;
    direction = event.which === 40 ? "down" : "up";
    addend = event.which === 40 ? 1 : -1;
    selectedIndex = this.itemsOrdered.indexOf(this.selectedItems[0]);
    lastSelectedIndex = this.itemsOrdered.indexOf(this.selectedItems[this.selectedItems.length - 1]);
    if (this.itemsOrdered[selectedIndex + addend]) {
      if (!(event.metaKey || event.ctrlKey || event.shiftKey)) {
        return this.selectItem(this.itemsOrdered[selectedIndex + addend]);
      } else {
        if (this.selectedItems.indexOf(this.itemsOrdered[lastSelectedIndex + addend]) !== -1) {
          if (this.itemsOrdered[lastSelectedIndex]) {
            return this.deselectSingleItem(this.itemsOrdered[lastSelectedIndex]);
          }
        } else {
          if (this.itemsOrdered[lastSelectedIndex + addend]) {
            return this.selectSingleItem(this.itemsOrdered[lastSelectedIndex + addend]);
          }
        }
      }
    }
  };

  KDListViewController.prototype.selectNextItem = function(item, event) {
    var selectedIndex;
    if (!item) {
      item = this.selectedItems[0];
    }
    selectedIndex = this.itemsOrdered.indexOf(item);
    return this.selectItem(this.itemsOrdered[selectedIndex + 1]);
  };

  KDListViewController.prototype.selectPrevItem = function(item, event) {
    var selectedIndex;
    if (!item) {
      item = this.selectedItems[0];
    }
    selectedIndex = this.itemsOrdered.indexOf(item);
    return this.selectItem(this.itemsOrdered[selectedIndex + -1]);
  };

  KDListViewController.prototype.deselectAllItems = function() {
    var deselectedItems, selectedItem, _i, _len, _ref, _results;
    _ref = this.selectedItems;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      selectedItem = _ref[_i];
      selectedItem.removeHighlight();
      deselectedItems = this.selectedItems.concat([]);
      this.selectedItems = [];
      this.getListView().unsetClass("last-item-selected");
      _results.push(this.itemDeselectionPerformed(deselectedItems));
    }
    return _results;
  };

  KDListViewController.prototype.deselectSingleItem = function(item) {
    item.removeHighlight();
    this.selectedItems.splice(this.selectedItems.indexOf(item), 1);
    if (item === this.itemsOrdered[this.itemsOrdered.length - 1]) {
      this.getListView().unsetClass("last-item-selected");
    }
    return this.itemDeselectionPerformed([item]);
  };

  KDListViewController.prototype.selectSingleItem = function(item) {
    if (item.getOption("selectable") && !(__indexOf.call(this.selectedItems, item) >= 0)) {
      item.highlight();
      this.selectedItems.push(item);
      if (item === this.itemsOrdered[this.itemsOrdered.length - 1]) {
        this.getListView().setClass("last-item-selected");
      }
      return this.itemSelectionPerformed();
    }
  };

  KDListViewController.prototype.selectAllItems = function() {
    var item, _i, _len, _ref, _results;
    _ref = this.itemsOrdered;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      _results.push(this.selectSingleItem(item));
    }
    return _results;
  };

  KDListViewController.prototype.selectItemsByRange = function(item1, item2) {
    var indicesToBeSliced, item, itemsToBeSelected, _i, _len;
    indicesToBeSliced = [this.itemsOrdered.indexOf(item1), this.itemsOrdered.indexOf(item2)];
    indicesToBeSliced.sort(function(a, b) {
      return a - b;
    });
    itemsToBeSelected = this.itemsOrdered.slice(indicesToBeSliced[0], indicesToBeSliced[1] + 1);
    for (_i = 0, _len = itemsToBeSelected.length; _i < _len; _i++) {
      item = itemsToBeSelected[_i];
      this.selectSingleItem(item);
    }
    return this.itemSelectionPerformed();
  };

  KDListViewController.prototype.itemSelectionPerformed = function() {
    return this.emit("ItemSelectionPerformed", this, {
      event: this.lastEvent,
      items: this.selectedItems
    });
  };

  KDListViewController.prototype.itemDeselectionPerformed = function(deselectedItems) {
    return this.emit("ItemDeselectionPerformed", this, {
      event: this.lastEvent,
      items: deselectedItems
    });
  };


  /*
  LAZY LOADER
   */

  KDListViewController.prototype.showLazyLoader = function(emitWhenReached) {
    var itemClass, lazyLoaderOptions, spinnerOptions, wrapper;
    if (emitWhenReached == null) {
      emitWhenReached = true;
    }
    if (this.noItemView && this.getOptions().noItemFoundWidget) {
      this.hideNoItemWidget();
    }
    if (!this.lazyLoader) {
      lazyLoaderOptions = this.getOptions().lazyLoaderOptions;
      lazyLoaderOptions || (lazyLoaderOptions = {});
      lazyLoaderOptions.itemClass || (lazyLoaderOptions.itemClass = KDCustomHTMLView);
      if (lazyLoaderOptions.partial == null) {
        lazyLoaderOptions.partial = '';
      }
      lazyLoaderOptions.cssClass = KD.utils.curry('lazy-loader', lazyLoaderOptions.cssClass);
      lazyLoaderOptions.spinnerOptions || (lazyLoaderOptions.spinnerOptions = {
        size: {
          width: 32
        }
      });
      itemClass = lazyLoaderOptions.itemClass, spinnerOptions = lazyLoaderOptions.spinnerOptions;
      delete lazyLoaderOptions.itemClass;
      wrapper = this.scrollView || this.getView();
      wrapper.addSubView(this.lazyLoader = new itemClass(lazyLoaderOptions));
      this.lazyLoader.addSubView(this.lazyLoader.spinner = new KDLoaderView(spinnerOptions));
      this.lazyLoader.spinner.show();
      if (emitWhenReached) {
        this.emit('LazyLoadThresholdReached');
      }
      return KD.utils.defer((function(_this) {
        return function() {
          var _ref;
          return (_ref = _this.scrollView) != null ? _ref.stopScrolling = true : void 0;
        };
      })(this));
    }
  };

  KDListViewController.prototype.hideLazyLoader = function() {
    KD.utils.wait(300, (function(_this) {
      return function() {
        var _ref;
        return (_ref = _this.scrollView) != null ? _ref.stopScrolling = false : void 0;
      };
    })(this));
    if (this.noItemView && this.getOptions().noItemFoundWidget) {
      this.showNoItemWidget();
    }
    if (this.lazyLoader) {
      this.lazyLoader.spinner.hide();
      this.lazyLoader.destroy();
      return this.lazyLoader = null;
    }
  };

  return KDListViewController;

})(KDViewController);


},{"./../../core/view.coffee":108,"./../../core/viewcontroller.coffee":109,"./../list/listview.coffee":54,"./../loader/loaderview.coffee":56,"./../scrollview/scrollview.coffee":69}],56:[function(require,module,exports){
var KDLoaderView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDLoaderView = (function(_super) {
  __extends(KDLoaderView, _super);

  function KDLoaderView(options, data) {
    var o;
    o = options || {};
    o.loaderOptions || (o.loaderOptions = {});
    o.size || (o.size = {});
    options = {
      tagName: o.tagName || "span",
      bind: o.bind || "mouseenter mouseleave",
      showLoader: o.showLoader || false,
      size: {
        width: o.size.width || 24,
        height: o.size.height || 24
      },
      loaderOptions: {
        color: o.loaderOptions.color || "#000000",
        shape: o.loaderOptions.shape || "rect",
        diameter: o.loaderOptions.diameter || 20,
        density: o.loaderOptions.density || 12,
        range: o.loaderOptions.range || 1,
        speed: o.loaderOptions.speed || 1,
        FPS: o.loaderOptions.FPS || 24
      }
    };
    options.loaderOptions.diameter = options.size.height = options.size.width;
    options.cssClass = o.cssClass ? "" + o.cssClass + " kdloader" : "kdloader";
    KDLoaderView.__super__.constructor.call(this, options, data);
  }

  KDLoaderView.prototype.viewAppended = function() {
    var loaderOptions, option, showLoader, value, _ref;
    this.canvas = new CanvasLoader(this.getElement(), {
      id: "cl_" + this.id
    });
    _ref = this.getOptions(), loaderOptions = _ref.loaderOptions, showLoader = _ref.showLoader;
    for (option in loaderOptions) {
      if (!__hasProp.call(loaderOptions, option)) continue;
      value = loaderOptions[option];
      this.canvas["set" + (option.capitalize())](value);
    }
    if (showLoader) {
      return this.show();
    }
  };

  KDLoaderView.prototype.show = function() {
    KDLoaderView.__super__.show.apply(this, arguments);
    this.active = true;
    if (this.canvas) {
      return this.canvas.show();
    }
  };

  KDLoaderView.prototype.hide = function() {
    KDLoaderView.__super__.hide.apply(this, arguments);
    this.active = false;
    if (this.canvas) {
      return this.canvas.hide();
    }
  };

  return KDLoaderView;

})(KDView);


},{"./../../core/view.coffee":108}],57:[function(require,module,exports){
var KDBlockingModalView, KDModalView, KDOverlayView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDModalView = require('./modalview.coffee');

KDOverlayView = require('./../overlay/overlayview.coffee');

module.exports = KDBlockingModalView = (function(_super) {
  __extends(KDBlockingModalView, _super);

  function KDBlockingModalView(options, data) {
    if (options == null) {
      options = {};
    }
    KDBlockingModalView.__super__.constructor.call(this, options, data);
    $(window).off("keydown.modal");
  }

  KDBlockingModalView.prototype.putOverlay = function() {
    this.overlay = new KDOverlayView({
      isRemovable: false
    });
    return this.overlay.on("click", (function(_this) {
      return function() {
        return _this.doBlockingAnimation();
      };
    })(this));
  };

  KDBlockingModalView.prototype.doBlockingAnimation = function() {
    this.setClass("blocking-animation");
    return KD.utils.wait(200, (function(_this) {
      return function() {
        return _this.unsetClass("blocking-animation");
      };
    })(this));
  };

  KDBlockingModalView.prototype.setDomElement = function(cssClass) {
    return this.domElement = $("<div class='kdmodal " + cssClass + "'>\n  <div class='kdmodal-shadow'>\n    <div class='kdmodal-inner'>\n      <div class='kdmodal-title'></div>\n      <div class='kdmodal-content'></div>\n    </div>\n  </div>\n</div>");
  };

  KDBlockingModalView.prototype.click = function(e) {};

  return KDBlockingModalView;

})(KDModalView);


},{"./../overlay/overlayview.coffee":62,"./modalview.coffee":58}],58:[function(require,module,exports){
var KDButtonView, KDModalView, KDModalViewStack, KDOverlayView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

KDOverlayView = require('./../overlay/overlayview.coffee');

KDButtonView = require('./../buttons/buttonview.coffee');

KDModalViewStack = require('./modalviewstack.coffee');

module.exports = KDModalView = (function(_super) {
  __extends(KDModalView, _super);

  function KDModalView(options, data) {
    var modalButtonsInnerWidth;
    if (options == null) {
      options = {};
    }
    if (options.overlay == null) {
      options.overlay = false;
    }
    if (options.overlayClick == null) {
      options.overlayClick = true;
    }
    options.height || (options.height = "auto");
    if (options.width == null) {
      options.width = 600;
    }
    options.position || (options.position = {});
    options.title || (options.title = null);
    options.subtitle || (options.subtitle = null);
    options.content || (options.content = null);
    options.buttons || (options.buttons = null);
    if (options.fx == null) {
      options.fx = false;
    }
    options.view || (options.view = null);
    if (options.draggable == null) {
      options.draggable = {
        handle: ".kdmodal-title"
      };
    }
    if (options.resizable == null) {
      options.resizable = false;
    }
    if (options.appendToDomBody == null) {
      options.appendToDomBody = true;
    }
    options.helpContent || (options.helpContent = null);
    options.helpTitle || (options.helpTitle = "Need help?");
    if (options.cancelable == null) {
      options.cancelable = true;
    }
    KDModalView.__super__.constructor.call(this, options, data);
    this.setClass("initial");
    if (options.overlay) {
      this.putOverlay(options.overlay);
    }
    if (options.fx) {
      this.setClass("fx");
    }
    if (options.title) {
      this.setTitle(options.title);
    }
    if (options.subtitle) {
      this.setSubtitle(options.subtitle);
    }
    if (options.content) {
      this.setContent(options.content);
    }
    if (options.view) {
      this.addSubView(options.view);
    }
    if (options.cancel) {
      this.on('ModalCancelled', options.cancel);
    }
    this.on("viewAppended", (function(_this) {
      return function() {
        return _this.utils.wait(500, function() {
          return _this.unsetClass("initial");
        });
      };
    })(this));
    if (this.getOptions().appendToDomBody) {
      this.appendToDomBody();
    }
    this.setModalWidth(options.width);
    if (options.height) {
      this.setModalHeight(options.height);
    }
    if (options.buttons) {
      this.buttonHolder = new KDView({
        cssClass: "kdmodal-buttons clearfix"
      });
      this.addSubView(this.buttonHolder, ".kdmodal-inner");
      this.setButtons(options.buttons);
      modalButtonsInnerWidth = this.$(".kdmodal-inner").width();
      this.buttonHolder.setWidth(modalButtonsInnerWidth);
    }
    this.display();
    this._windowDidResize();
    $(window).one("keydown.modal", (function(_this) {
      return function(e) {
        if (e.which === 27) {
          return _this.cancel();
        }
      };
    })(this));
    this.on("childAppended", this.setPositions.bind(this));
    this.listenWindowResize();
  }

  KDModalView.prototype.setDomElement = function(cssClass) {
    var helpButton, helpContent, helpTitle, _ref;
    _ref = this.getOptions(), helpContent = _ref.helpContent, helpTitle = _ref.helpTitle;
    if (helpContent) {
      helpButton = "<span class='showHelp'>" + helpTitle + "</span>";
    } else {
      helpButton = "";
    }
    return this.domElement = $("<div class='kdmodal " + cssClass + "'>\n  <div class='kdmodal-inner'>\n    " + helpButton + "\n    <span class='close-icon closeModal' title='Close [ESC]'></span>\n    <div class='kdmodal-title hidden'></div>\n    <div class='kdmodal-content'></div>\n  </div>\n</div>");
  };

  KDModalView.prototype.addSubView = function(view, selector) {
    if (selector == null) {
      selector = ".kdmodal-content";
    }
    if (this.$(selector).length === 0) {
      selector = null;
    }
    return KDModalView.__super__.addSubView.call(this, view, selector);
  };

  KDModalView.prototype.setButtons = function(buttonDataSet, destroyExists) {
    var button, buttonOptions, buttonTitle, defaultFocusTitle, focused, _ref;
    if (destroyExists == null) {
      destroyExists = false;
    }
    this.buttons || (this.buttons = {});
    this.setClass("with-buttons");
    defaultFocusTitle = null;
    if (destroyExists) {
      this.destroyButtons();
    }
    for (buttonTitle in buttonDataSet) {
      if (!__hasProp.call(buttonDataSet, buttonTitle)) continue;
      buttonOptions = buttonDataSet[buttonTitle];
      if (defaultFocusTitle == null) {
        defaultFocusTitle = buttonTitle;
      }
      button = this.createButton(buttonOptions.title || buttonTitle, buttonOptions);
      this.buttons[buttonTitle] = button;
      if (buttonOptions.focus) {
        focused = true;
      }
    }
    if (!focused && defaultFocusTitle) {
      return (_ref = this.buttons[defaultFocusTitle]) != null ? _ref.setFocus() : void 0;
    }
  };

  KDModalView.prototype.destroyButtons = function() {
    var button, _key, _ref, _results;
    _ref = this.buttons;
    _results = [];
    for (_key in _ref) {
      if (!__hasProp.call(_ref, _key)) continue;
      button = _ref[_key];
      _results.push(button.destroy());
    }
    return _results;
  };

  KDModalView.prototype.click = function(e) {
    var helpContent;
    if ($(e.target).is(".closeModal")) {
      this.cancel();
    }
    if ($(e.target).is(".showHelp")) {
      helpContent = this.getOptions().helpContent;
      if (helpContent) {
        helpContent = KD.utils.applyMarkdown(helpContent);
        return new KDModalView({
          cssClass: "help-dialog",
          overlay: true,
          content: "<div class='modalformline'><p>" + helpContent + "</p></div>"
        });
      }
    }
  };

  KDModalView.prototype.setTitle = function(title) {
    this.$().find(".kdmodal-title").removeClass('hidden').html("<span class='title'>" + title + "</span>");
    return this.modalTitle = title;
  };

  KDModalView.prototype.setSubtitle = function(subtitle) {
    this.$().find(".kdmodal-title").append("<span class='subtitle'>" + subtitle + "</span>");
    return this.modalSubtitle = subtitle;
  };

  KDModalView.prototype.setModalHeight = function(value) {
    if (value === "auto") {
      this.$().css("height", "auto");
      return this.modalHeight = this.getHeight();
    } else {
      this.$().height(value);
      return this.modalHeight = value;
    }
  };

  KDModalView.prototype.setModalWidth = function(value) {
    this.modalWidth = value;
    return this.$().width(value);
  };

  KDModalView.prototype.setPositions = function() {
    return this.utils.defer((function(_this) {
      return function() {
        var bottom, height, left, newRules, right, top, width, _ref;
        _ref = _this.getOptions().position, top = _ref.top, right = _ref.right, bottom = _ref.bottom, left = _ref.left;
        newRules = {};
        height = $(window).height();
        width = $(window).width();
        newRules.top = Math.round(top != null ? top : height / 2 - _this.getHeight() / 2);
        newRules.left = Math.round(left != null ? left : width / 2 - _this.modalWidth / 2);
        if (right) {
          newRules.left = Math.round(width - _this.modalWidth - right - 20);
        }
        newRules.opacity = 1;
        return _this.$().css(newRules);
      };
    })(this));
  };

  KDModalView.prototype._windowDidResize = function() {
    var innerHeight;
    this.setPositions();
    innerHeight = window.innerHeight;
    this.$('.kdmodal-content').css({
      maxHeight: innerHeight - 120
    });
    if (!this.getOptions().position.top) {
      return this.setY(Math.round((innerHeight - this.getHeight()) / 2));
    }
  };

  KDModalView.prototype.putOverlay = function() {
    var isRemovable;
    isRemovable = this.getOptions().overlayClick;
    this.overlay = new KDOverlayView({
      isRemovable: isRemovable
    });
    if (isRemovable) {
      return this.overlay.once("click", this.bound("destroy"));
    }
  };

  KDModalView.prototype.createButton = function(title, buttonOptions) {
    var button, itemClass;
    buttonOptions.title = title;
    buttonOptions.delegate = this;
    itemClass = buttonOptions.itemClass;
    delete buttonOptions.itemClass;
    this.buttonHolder.addSubView(button = new (itemClass || KDButtonView)(buttonOptions));
    button.on('KDModalShouldClose', (function(_this) {
      return function() {
        return _this.emit('KDModalShouldClose');
      };
    })(this));
    return button;
  };

  KDModalView.prototype.setContent = function(content) {
    this.modalContent = content;
    return this.getDomElement().find(".kdmodal-content").html(content);
  };

  KDModalView.prototype.display = function() {
    if (this.getOptions().fx) {
      return this.utils.defer((function(_this) {
        return function() {
          return _this.setClass("active");
        };
      })(this));
    }
  };

  KDModalView.prototype.cancel = function() {
    if (!this.getOptions().cancelable) {
      return;
    }
    this.emit('ModalCancelled');
    return this.destroy();
  };

  KDModalView.prototype.destroy = function() {
    var uber, _ref;
    $(window).off("keydown.modal");
    uber = KDView.prototype.destroy.bind(this);
    if (this.options.fx) {
      this.unsetClass("active");
      setTimeout(uber, 300);
    } else {
      this.getDomElement().hide();
      uber();
    }
    if ((_ref = this.overlay) != null) {
      _ref.destroy();
    }
    return this.emit('KDModalViewDestroyed', this);
  };


  /* STACK HELPERS */

  KDModalView.createStack = function(options) {
    return this.stack || (this.stack = new KDModalViewStack(options));
  };

  KDModalView.addToStack = function(modal) {
    return this.stack.addModal(modal);
  };

  KDModalView.destroyStack = function() {
    this.stack.destroy();
    return delete this.stack;
  };

  KDModalView.confirm = function(options) {
    var cancel, content, description, modal, noop, ok, title;
    noop = function() {
      return modal.destroy();
    };
    ok = options.ok, cancel = options.cancel, title = options.title, content = options.content, description = options.description;
    if (!ok || 'function' === typeof ok) {
      ok = {
        callback: ok
      };
    }
    if (!cancel || 'function' === typeof cancel) {
      cancel = {
        callback: cancel
      };
    }
    modal = new this({
      title: title || 'You must confirm this action',
      content: content || (description ? "<div class='modalformline'>\n  <p>" + description + "</p>\n</div>" : void 0),
      overlay: true,
      buttons: {
        OK: {
          title: ok.title,
          style: ok.style || "modal-clean-red",
          callback: ok.callback || noop
        },
        cancel: {
          title: cancel.title,
          style: cancel.style || "modal-cancel",
          callback: cancel.callback || noop
        }
      }
    });
    if (options.subView) {
      modal.addSubView(options.subView);
    }
    return modal;
  };

  return KDModalView;

})(KDView);


},{"./../../core/view.coffee":108,"./../buttons/buttonview.coffee":20,"./../overlay/overlayview.coffee":62,"./modalviewstack.coffee":59}],59:[function(require,module,exports){
var KDModalViewStack, KDObject,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDObject = require('./../../core/object.coffee');

module.exports = KDModalViewStack = (function(_super) {
  __extends(KDModalViewStack, _super);

  function KDModalViewStack(options, data) {
    if (options == null) {
      options = {};
    }
    if (options.lastToFirst == null) {
      options.lastToFirst = false;
    }
    KDModalViewStack.__super__.constructor.call(this, options, data);
    this.modals = [];
  }

  KDModalViewStack.prototype.addModal = function(modal) {
    var lastToFirst;
    if (!(modal instanceof KDModalView)) {
      return warn("You can only add KDModalView instances to the modal stack.");
    }
    modal.on("KDObjectWillBeDestroyed", (function(_this) {
      return function() {
        return _this.next();
      };
    })(this));
    lastToFirst = this.getOptions().lastToFirst;
    this.modals.push(modal);
    KD.utils.defer((function(_this) {
      return function() {
        modal.hide();
        if (lastToFirst) {
          _this.modals.forEach(function(modal) {
            return modal.hide();
          });
          return _this.modals.last.show();
        } else {
          return _this.modals.first.show();
        }
      };
    })(this));
    return modal;
  };

  KDModalViewStack.prototype.next = function() {
    var lastToFirst, _ref, _ref1;
    lastToFirst = this.getOptions().lastToFirst;
    if (lastToFirst) {
      this.modals.pop();
      return (_ref = this.modals.last) != null ? _ref.show() : void 0;
    } else {
      this.modals.shift();
      return (_ref1 = this.modals.first) != null ? _ref1.show() : void 0;
    }
  };

  KDModalViewStack.prototype.destroy = function() {
    this.modals.forEach(function(modal) {
      return KD.utils.defer(function() {
        return modal.destroy();
      });
    });
    this.modals = [];
    return KDModalViewStack.__super__.destroy.apply(this, arguments);
  };

  return KDModalViewStack;

})(KDObject);


},{"./../../core/object.coffee":104}],60:[function(require,module,exports){
var KDModalView, KDModalViewWithForms, KDTabViewWithForms,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDModalView = require('./modalview.coffee');

KDTabViewWithForms = require('./../tabs/tabviewwithforms');

module.exports = KDModalViewWithForms = (function(_super) {
  __extends(KDModalViewWithForms, _super);

  function KDModalViewWithForms(options, data) {
    this.modalButtons = [];
    KDModalViewWithForms.__super__.constructor.call(this, options, data);
    this.addSubView(this.modalTabs = new KDTabViewWithForms(options.tabs));
  }

  KDModalViewWithForms.prototype.aggregateFormData = function() {
    var data, form, formName;
    data = (function() {
      var _ref, _results;
      _ref = this.modalTabs.forms;
      _results = [];
      for (formName in _ref) {
        if (!__hasProp.call(_ref, formName)) continue;
        form = _ref[formName];
        _results.push({
          name: formName,
          data: form.getData()
        });
      }
      return _results;
    }).call(this);
    return data.reduce(function(acc, form) {
      var key, val, _ref;
      _ref = form.data;
      for (key in _ref) {
        if (!__hasProp.call(_ref, key)) continue;
        val = _ref[key];
        if (key in acc) {
          console.warn("Property " + key + " will be overwitten!");
        }
        acc[key] = val;
      }
      return acc;
    }, {});
  };

  return KDModalViewWithForms;

})(KDModalView);


},{"./../tabs/tabviewwithforms":83,"./modalview.coffee":58}],61:[function(require,module,exports){
var KDLoaderView, KDNotificationView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

KDLoaderView = require('./../loader/loaderview.coffee');

module.exports = KDNotificationView = (function(_super) {
  __extends(KDNotificationView, _super);

  function KDNotificationView(options) {
    KDNotificationView.__super__.constructor.call(this, options);
    options = this.notificationSetDefaults(options);
    this.notificationSetType(options.type);
    if (options.title != null) {
      this.notificationSetTitle(options.title);
    }
    if (options.content != null) {
      this.notificationSetContent(options.content);
    }
    if (options.duration != null) {
      this.notificationSetTimer(options.duration);
    }
    if (options.overlay != null) {
      this.notificationSetOverlay(options.overlay);
    }
    if (options.followUps != null) {
      this.notificationSetFollowUps(options.followUps);
    }
    if (options.showTimer != null) {
      this.notificationShowTimer();
    }
    this.notificationSetCloseHandle(options.closeManually);
    if (options.loader) {
      this.once("viewAppended", this.bound("setLoader"));
    }
    this.notificationDisplay();
  }

  KDNotificationView.prototype.setDomElement = function(cssClass) {
    if (cssClass == null) {
      cssClass = '';
    }
    return this.domElement = $("<div class='kdnotification " + cssClass + "'> <a class='kdnotification-close hidden'></a> <div class='kdnotification-timer hidden'></div> <div class='kdnotification-title'></div> <div class='kdnotification-content hidden'></div> </div>");
  };

  KDNotificationView.prototype.destroy = function() {
    this.notificationCloseHandle.unbind(".notification");
    if (this.notificationOverlay != null) {
      this.notificationOverlay.remove();
    }
    KDNotificationView.__super__.destroy.call(this);
    this.notificationStopTimer();
    return this.notificationRepositionOtherNotifications();
  };

  KDNotificationView.prototype.viewAppended = function() {
    return this.notificationSetPositions();
  };

  KDNotificationView.prototype.notificationSetDefaults = function(options) {
    if (options.duration == null) {
      options.duration = 1500;
    }
    if (options.duration > 2999 || options.duration === 0) {
      if (options.closeManually == null) {
        options.closeManually = true;
      }
    }
    return options;
  };

  KDNotificationView.prototype.notificationSetTitle = function(title) {
    if (!(title instanceof KDView)) {
      this.$().find(".kdnotification-title").html(title);
    } else {
      if (this.notificationTitle && this.notificationTitle instanceof KDView) {
        this.notificationTitle.destroy();
      }
      this.addSubView(title, ".kdnotification-title");
    }
    return this.notificationTitle = title;
  };

  KDNotificationView.prototype.notificationSetType = function(type) {
    if (type == null) {
      type = "main";
    }
    return this.notificationType = type;
  };

  KDNotificationView.prototype.notificationSetPositions = function() {
    var bottomMargin, i, notification, sameTypeNotifications, styles, topMargin, winHeight, winWidth, _i, _j, _len, _len1;
    this.setClass(this.notificationType);
    sameTypeNotifications = $("body").find(".kdnotification." + this.notificationType);
    if (this.getOptions().container) {
      winHeight = this.getOptions().container.getHeight();
      winWidth = this.getOptions().container.getWidth();
    } else {
      winWidth = window.innerWidth;
      winHeight = window.innerHeight;
    }
    switch (this.notificationType) {
      case "tray":
        bottomMargin = 8;
        for (i = _i = 0, _len = sameTypeNotifications.length; _i < _len; i = ++_i) {
          notification = sameTypeNotifications[i];
          if (i !== 0) {
            bottomMargin += $(notification).outerHeight(false) + 8;
          }
        }
        styles = {
          bottom: bottomMargin,
          right: 8,
          paddingRight: this.options.content && this.options.title ? 10 : 25
        };
        break;
      case "growl":
        topMargin = 63;
        for (i = _j = 0, _len1 = sameTypeNotifications.length; _j < _len1; i = ++_j) {
          notification = sameTypeNotifications[i];
          if (i !== 0) {
            topMargin += $(notification).outerHeight(false) + 8;
          }
        }
        styles = {
          top: topMargin,
          right: 8
        };
        break;
      case "mini":
        styles = {
          top: 0,
          left: winWidth / 2 - this.getDomElement().width() / 2
        };
        break;
      case "sticky":
        styles = {
          top: 0,
          left: winWidth / 2 - this.getDomElement().width() / 2
        };
        break;
      default:
        styles = {
          top: winHeight / 2 - this.getDomElement().height() / 2,
          left: winWidth / 2 - this.getDomElement().width() / 2
        };
    }
    return this.getDomElement().css(styles);
  };

  KDNotificationView.prototype.notificationRepositionOtherNotifications = function() {
    var elm, h, heights, i, j, newValue, options, position, sameTypeNotifications, _i, _j, _len, _len1, _ref, _results;
    sameTypeNotifications = $("body").find(".kdnotification." + this.notificationType);
    heights = (function() {
      var _i, _len, _results;
      _results = [];
      for (i = _i = 0, _len = sameTypeNotifications.length; _i < _len; i = ++_i) {
        elm = sameTypeNotifications[i];
        _results.push($(elm).outerHeight(false));
      }
      return _results;
    })();
    _results = [];
    for (i = _i = 0, _len = sameTypeNotifications.length; _i < _len; i = ++_i) {
      elm = sameTypeNotifications[i];
      switch (this.notificationType) {
        case "tray":
        case "growl":
          newValue = 0;
          position = this.notificationType === "tray" ? "bottom" : "top";
          _ref = heights.slice(0, +i + 1 || 9e9);
          for (j = _j = 0, _len1 = _ref.length; _j < _len1; j = ++_j) {
            h = _ref[j];
            if (j !== 0) {
              newValue += h;
            } else {
              newValue = 8;
            }
          }
          options = {};
          options[position] = newValue + i * 8;
          _results.push($(elm).css(options));
          break;
        default:
          _results.push(void 0);
      }
    }
    return _results;
  };

  KDNotificationView.prototype.notificationSetCloseHandle = function(closeManually) {
    if (closeManually == null) {
      closeManually = false;
    }
    this.notificationCloseHandle = this.getDomElement().find(".kdnotification-close");
    if (closeManually) {
      this.notificationCloseHandle.removeClass("hidden");
    }
    this.notificationCloseHandle.bind("click.notification", (function(_this) {
      return function(e) {
        return _this.destroy();
      };
    })(this));
    return $(window).bind("keydown.notification", (function(_this) {
      return function(e) {
        if (e.which === 27) {
          return _this.destroy();
        }
      };
    })(this));
  };

  KDNotificationView.prototype.notificationSetTimer = function(duration) {
    if (duration === 0) {
      return;
    }
    this.notificationTimerDiv = this.getDomElement().find(".kdnotification-timer");
    this.notificationTimerDiv.text(Math.floor(duration / 1000));
    this.notificationTimeout = setTimeout((function(_this) {
      return function() {
        return _this.getDomElement().fadeOut(200, function() {
          return _this.destroy();
        });
      };
    })(this), duration);
    return this.notificationInterval = setInterval((function(_this) {
      return function() {
        var next;
        next = parseInt(_this.notificationTimerDiv.text(), 10) - 1;
        return _this.notificationTimerDiv.text(next);
      };
    })(this), 1000);
  };

  KDNotificationView.prototype.notificationSetFollowUps = function(followUps) {
    var chainDuration;
    if (!Array.isArray(followUps)) {
      followUps = [followUps];
    }
    chainDuration = 0;
    return followUps.forEach((function(_this) {
      return function(followUp) {
        var _ref;
        chainDuration += (_ref = followUp.duration) != null ? _ref : 10000;
        return _this.utils.wait(chainDuration, function() {
          if (followUp.title) {
            _this.notificationSetTitle(followUp.title);
          }
          if (followUp.content) {
            _this.notificationSetContent(followUp.content);
          }
          return _this.notificationSetPositions();
        });
      };
    })(this));
  };

  KDNotificationView.prototype.notificationShowTimer = function() {
    this.notificationTimerDiv.removeClass("hidden");
    this.getDomElement().bind("mouseenter", (function(_this) {
      return function() {
        return _this.notificationStopTimer();
      };
    })(this));
    return this.getDomElement().bind("mouseleave", (function(_this) {
      return function() {
        var newDuration;
        newDuration = parseInt(_this.notificationTimerDiv.text(), 10) * 1000;
        return _this.notificationSetTimer(newDuration);
      };
    })(this));
  };

  KDNotificationView.prototype.notificationStopTimer = function() {
    clearTimeout(this.notificationTimeout);
    return clearInterval(this.notificationInterval);
  };

  KDNotificationView.prototype.notificationSetOverlay = function(options) {
    if (options.transparent == null) {
      options.transparent = true;
    }
    if (options.destroyOnClick == null) {
      options.destroyOnClick = true;
    }
    this.notificationOverlay = $("<div/>", {
      "class": "kdoverlay transparent"
    });
    this.notificationOverlay.hide();
    if (!options.transparent) {
      this.notificationOverlay.removeClass("transparent");
    }
    this.notificationOverlay.appendTo("body");
    this.notificationOverlay.fadeIn(200);
    return this.notificationOverlay.bind("click", (function(_this) {
      return function() {
        if (options.destroyOnClick) {
          return _this.destroy();
        }
      };
    })(this));
  };

  KDNotificationView.prototype.notificationGetOverlay = function() {
    return this.notificationOverlay;
  };

  KDNotificationView.prototype.setLoader = function() {
    var diameters, loader, _ref, _ref1, _ref2, _ref3;
    this.setClass("w-loader");
    loader = this.getOptions().loader;
    diameters = {
      tray: 25,
      growl: 30,
      mini: 18,
      sticky: 25
    };
    loader.diameter = diameters[this.notificationType] || 30;
    this.loader = new KDLoaderView({
      size: {
        width: loader.diameter
      },
      loaderOptions: {
        color: loader.color || "#ffffff",
        shape: loader.shape || "spiral",
        diameter: loader.diameter,
        density: (_ref = loader.density) != null ? _ref : 30,
        range: (_ref1 = loader.range) != null ? _ref1 : 0.4,
        speed: (_ref2 = loader.speed) != null ? _ref2 : 1.5,
        FPS: (_ref3 = loader.FPS) != null ? _ref3 : 24
      }
    });
    this.addSubView(this.loader, null, true);
    this.setCss("paddingLeft", loader.diameter * 2);
    this.loader.setStyle({
      position: "absolute",
      left: loader.left || Math.floor(loader.diameter / 2),
      top: loader.top || "50%",
      marginTop: -(loader.diameter / 2)
    });
    return this.loader.show();
  };

  KDNotificationView.prototype.showLoader = function() {
    this.setClass("loading");
    return this.loader.show();
  };

  KDNotificationView.prototype.hideLoader = function() {
    this.unsetClass("loading");
    return this.loader.hide();
  };

  KDNotificationView.prototype.notificationSetContent = function(content) {
    this.notificationContent = content;
    return this.getDomElement().find(".kdnotification-content").removeClass("hidden").html(content);
  };

  KDNotificationView.prototype.notificationDisplay = function() {
    if (this.getOptions().container) {
      return this.getOptions().container.addSubView(this);
    } else {
      return this.appendToDomBody();
    }
  };

  return KDNotificationView;

})(KDView);


},{"./../../core/view.coffee":108,"./../loader/loaderview.coffee":56}],62:[function(require,module,exports){
var KDOverlayView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDOverlayView = (function(_super) {
  __extends(KDOverlayView, _super);

  function KDOverlayView(options, data) {
    if (options == null) {
      options = {};
    }
    if (options.isRemovable == null) {
      options.isRemovable = true;
    }
    if (options.animated == null) {
      options.animated = false;
    }
    if (options.color == null) {
      options.color = false;
    }
    if (options.transparent == null) {
      options.transparent = false;
    }
    if (options.opacity == null) {
      options.opacity = 0.5;
    }
    if (options.appendToDomBody == null) {
      options.appendToDomBody = true;
    }
    options.cssClass = KD.utils.curry("kdoverlay", options.cssClass);
    KDOverlayView.__super__.constructor.call(this, options, data);
    if (options.animated) {
      this.setClass("animated");
    }
    if (options.transparent) {
      this.setClass("transparent");
    }
    if (options.color) {
      this.setStyle({
        backgroundColor: options.color,
        opacity: options.opacity
      });
    }
    if (options.container instanceof KDView) {
      options.container.addSubView(this);
      this.setCss("position", "absolute");
    } else if (options.appendToDomBody) {
      this.appendToDomBody();
    }
    if (options.animated) {
      this.utils.defer((function(_this) {
        return function() {
          return _this.setClass("in");
        };
      })(this));
      this.utils.wait(300, (function(_this) {
        return function() {
          return _this.emit("OverlayAdded", _this);
        };
      })(this));
    } else {
      this.emit("OverlayAdded", this);
    }
    if (options.isRemovable) {
      if (options.animated) {
        this.once("click", (function(_this) {
          return function() {
            _this.unsetClass("in");
            return _this.utils.wait(300, function() {
              return _this.remove();
            });
          };
        })(this));
      } else {
        this.once("click", (function(_this) {
          return function() {
            return _this.remove();
          };
        })(this));
      }
    }
  }

  KDOverlayView.prototype.remove = function() {
    this.emit("OverlayWillBeRemoved");
    this.destroy();
    return this.emit("OverlayRemoved", this);
  };

  return KDOverlayView;

})(KDView);


},{"./../../core/view.coffee":108}],63:[function(require,module,exports){
var KDSpotlightView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDSpotlightView = (function(_super) {
  __extends(KDSpotlightView, _super);

  function KDSpotlightView(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass = KD.utils.curry("kdspotlightview", options.cssClass);
    if (options.margin == null) {
      options.margin = 50;
    }
    if (options.radial == null) {
      options.radial = true;
    }
    if (options.isRemovable == null) {
      options.isRemovable = true;
    }
    KDSpotlightView.__super__.constructor.call(this, options, data);
    if (!options.radial) {
      this.setClass("shadow");
    }
    this.createElements();
    this.appendToDomBody();
  }

  KDSpotlightView.prototype.createElements = function() {
    var boundaries, height, isRemovable, left, position, top, view, width, _ref, _results;
    isRemovable = this.getOptions().isRemovable;
    _ref = this.getBoundaries();
    _results = [];
    for (position in _ref) {
      boundaries = _ref[position];
      width = boundaries.width, height = boundaries.height, top = boundaries.top, left = boundaries.left;
      if (width > 0 && height > 0) {
        view = new KDView({
          cssClass: KD.utils.curry("kdoverlay", position),
          size: {
            width: width,
            height: height
          },
          position: {
            top: top,
            left: left
          }
        });
        if (isRemovable) {
          view.on("click", (function(_this) {
            return function() {
              _this.destroy();
              return _this.emit("OverlayDestroyed");
            };
          })(this));
        }
        _results.push(this.addSubView(view));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  KDSpotlightView.prototype.getBoundaries = function() {
    var bottomHeight, boundaries, delegate, height, left, leftWidth, margin, radial, top, topHeight, width, windowHeight, windowWidth;
    radial = this.getOptions().radial;
    delegate = this.getDelegate();
    top = delegate.getY();
    left = delegate.getX();
    width = delegate.getWidth();
    height = delegate.getHeight();
    margin = this.getOption("margin");
    windowWidth = window.innerWidth;
    windowHeight = window.innerHeight;
    if (radial) {
      width = height = Math.min(width, height);
    }
    topHeight = top - margin;
    leftWidth = left - margin;
    bottomHeight = windowHeight - (top + height + margin);
    boundaries = {
      top: {
        top: 0,
        left: 0,
        width: windowWidth,
        height: topHeight
      },
      left: {
        top: topHeight,
        left: 0,
        width: leftWidth,
        height: windowHeight - top + margin
      },
      bottom: {
        top: top + height + margin,
        left: leftWidth,
        width: windowWidth - left + margin,
        height: bottomHeight
      },
      right: {
        top: topHeight,
        left: left + width + margin,
        width: windowWidth - (left + width + margin),
        height: windowHeight - (bottomHeight + topHeight)
      },
      main: {
        top: topHeight,
        left: leftWidth,
        width: width + margin + margin,
        height: height + margin + margin
      }
    };
    return boundaries;
  };

  return KDSpotlightView;

})(KDView);


},{"./../../core/view.coffee":108}],64:[function(require,module,exports){
var KDCustomHTMLView, KDProgressBarView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDCustomHTMLView = require('./../../core/customhtmlview.coffee');

module.exports = KDProgressBarView = (function(_super) {
  __extends(KDProgressBarView, _super);

  function KDProgressBarView(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass = KD.utils.curry("progressbar-container", options.cssClass);
    if (options.determinate == null) {
      options.determinate = true;
    }
    if (options.initial == null) {
      options.initial = false;
    }
    if (options.title == null) {
      options.title = "";
    }
    KDProgressBarView.__super__.constructor.call(this, options, data);
  }

  KDProgressBarView.prototype.viewAppended = function() {
    var initial, title, _ref;
    _ref = this.getOptions(), initial = _ref.initial, title = _ref.title;
    this.createBar();
    return this.updateBar(initial || 1, "%", title);
  };

  KDProgressBarView.prototype.createBar = function(value, label) {
    if (label == null) {
      label = this.getOptions().title;
    }
    this.addSubView(this.bar = new KDCustomHTMLView({
      cssClass: "bar"
    }));
    this.addSubView(this.spinner = new KDCustomHTMLView({
      cssClass: "bar spinner hidden"
    }));
    this.addSubView(this.darkLabel = new KDCustomHTMLView({
      tagName: "span",
      cssClass: 'dark-label'
    }));
    this.bar.addSubView(this.lightLabel = new KDCustomHTMLView({
      tagName: "span",
      cssClass: 'light-label'
    }));
    return this.lightLabel.setWidth(this.getWidth());
  };

  KDProgressBarView.prototype.updateBar = function(value, unit, label) {
    var determinate;
    if (unit == null) {
      unit = '%';
    }
    if (label == null) {
      label = this.getOptions().title;
    }
    determinate = this.getOptions().determinate;
    if (determinate) {
      this.bar.show();
      this.spinner.hide();
      this.bar.setWidth(value, unit);
      this.darkLabel.updatePartial("" + label + "&nbsp;");
      return this.lightLabel.updatePartial("" + label + "&nbsp;");
    } else {
      this.bar.hide();
      return this.spinner.show();
    }
  };

  return KDProgressBarView;

})(KDCustomHTMLView);


},{"./../../core/customhtmlview.coffee":97}],65:[function(require,module,exports){
var KDCustomHTMLView, KDCustomScrollView, KDCustomScrollViewWrapper, KDScrollTrack,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

require('jquery-mousewheel')($);

KDCustomHTMLView = require('./../../core/customhtmlview');

KDScrollTrack = require('./scrolltrack');

KDCustomScrollViewWrapper = require('./customscrollviewinner');

module.exports = KDCustomScrollView = (function(_super) {
  var intent;

  __extends(KDCustomScrollView, _super);

  function KDCustomScrollView(options, data) {
    var mouseWheelSpeed;
    if (options == null) {
      options = {};
    }
    if (options.bind == null) {
      options.bind = 'mouseenter mouseleave';
    }
    options.cssClass = KD.utils.curry('kdcustomscrollview', options.cssClass);
    if (options.mouseWheelSpeed == null) {
      options.mouseWheelSpeed = 3;
    }
    KDCustomScrollView.__super__.constructor.call(this, options, data);
    mouseWheelSpeed = this.getOptions().mouseWheelSpeed;
    this.wrapper = new KDCustomScrollViewWrapper({
      tagName: 'main',
      mouseWheelSpeed: mouseWheelSpeed
    });
    this.verticalTrack = new KDScrollTrack({
      delegate: this.wrapper
    });
    this.horizontalTrack = new KDScrollTrack({
      delegate: this.wrapper,
      type: 'horizontal'
    });
    this.wrapper.verticalThumb = this.verticalTrack.thumb;
    this.wrapper.horizontalThumb = this.horizontalTrack.thumb;
    this.wrapper.on('ScrollTrackShown', (function(_this) {
      return function(type) {
        return _this.setClass("has-" + type);
      };
    })(this));
    this.wrapper.on('ScrollTrackHidden', (function(_this) {
      return function(type) {
        return _this.unsetClass("has-" + type);
      };
    })(this));
    this.on('mouseenter', this.bound('showTracks'));
    this.on('mouseleave', this.bound('hideTracks'));
  }

  KDCustomScrollView.prototype.viewAppended = function() {
    this.addSubView(this.wrapper);
    this.addSubView(this.verticalTrack);
    this.addSubView(this.horizontalTrack);
    this.wrapper.observeMutations();
    this.wrapper.on('MutationHappened', this.verticalTrack.thumb.bound('handleMutation'));
    return this.wrapper.on('MutationHappened', this.horizontalTrack.thumb.bound('handleMutation'));
  };

  intent = null;

  KDCustomScrollView.prototype.hideTracks = function() {
    return intent = KD.utils.wait(1000, (function(_this) {
      return function() {
        _this.verticalTrack.setClass('out');
        return _this.horizontalTrack.setClass('out');
      };
    })(this));
  };

  KDCustomScrollView.prototype.showTracks = function() {
    if (intent) {
      KD.utils.killWait(intent);
    }
    this.verticalTrack.unsetClass('out');
    return this.horizontalTrack.unsetClass('out');
  };

  return KDCustomScrollView;

})(KDCustomHTMLView);


},{"./../../core/customhtmlview":97,"./customscrollviewinner":66,"./scrolltrack":68,"jquery-mousewheel":2}],66:[function(require,module,exports){
var KDCustomHTMLView, KDCustomScrollViewWrapper, KDScrollThumb, KDScrollTrack, KDScrollView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

require('jquery-mousewheel')($);

KDCustomHTMLView = require('./../../core/customhtmlview');

KDScrollView = require('./scrollview');

KDScrollThumb = require('./scrollthumb');

KDScrollTrack = require('./scrolltrack');

module.exports = KDCustomScrollViewWrapper = (function(_super) {
  __extends(KDCustomScrollViewWrapper, _super);

  function KDCustomScrollViewWrapper() {
    return KDCustomScrollViewWrapper.__super__.constructor.apply(this, arguments);
  }

  KDCustomScrollViewWrapper.prototype.scroll = function(event) {
    if (this.verticalThumb.beingDragged || this.horizontalThumb.beingDragged) {
      return KD.utils.stopDOMEvent(event);
    }
  };

  KDCustomScrollViewWrapper.prototype.mouseWheel = function(event) {
    var deltaFactor, resX, resY, speed, stop, x, y, _delta;
    KDCustomScrollViewWrapper.__super__.mouseWheel.apply(this, arguments);
    _delta = event._delta, deltaFactor = event.deltaFactor;
    if (!_delta) {
      return;
    }
    speed = deltaFactor || this.getOptions().mouseWheelSpeed;
    x = _delta.deltaX;
    y = _delta.deltaY;
    resX = x !== 0 && this.getScrollWidth() > this.getWidth() ? this._scrollHorizontally({
      speed: speed,
      velocity: x
    }) : false;
    resY = y !== 0 && this.getScrollHeight() > this.getHeight() ? this._scrollVertically({
      speed: speed,
      velocity: y
    }) : false;
    stop = Math.abs(x) > Math.abs(y) ? resX : resY;
    return !stop;
  };

  KDCustomScrollViewWrapper.prototype._scrollVertically = (function() {
    var lastPosition;
    lastPosition = 0;
    return function(_arg) {
      var actPosition, newPosition, shouldStop, speed, stepInPixels, velocity;
      speed = _arg.speed, velocity = _arg.velocity;
      stepInPixels = velocity * speed;
      actPosition = this.getScrollTop();
      newPosition = actPosition - stepInPixels;
      shouldStop = velocity > 0 ? lastPosition > newPosition : lastPosition < newPosition;
      this.setScrollTop(lastPosition = newPosition);
      return shouldStop;
    };
  })();

  KDCustomScrollViewWrapper.prototype._scrollHorizontally = (function() {
    var lastPosition;
    lastPosition = 0;
    return function(_arg) {
      var actPosition, newPosition, shouldStop, speed, stepInPixels, velocity;
      speed = _arg.speed, velocity = _arg.velocity;
      stepInPixels = velocity * speed;
      actPosition = this.getScrollLeft();
      newPosition = actPosition + stepInPixels;
      shouldStop = velocity < 0 ? lastPosition >= newPosition : lastPosition <= newPosition;
      this.setScrollLeft(lastPosition = newPosition);
      return shouldStop;
    };
  })();

  return KDCustomScrollViewWrapper;

})(KDScrollView);


},{"./../../core/customhtmlview":97,"./scrollthumb":67,"./scrolltrack":68,"./scrollview":69,"jquery-mousewheel":2}],67:[function(require,module,exports){
var KDScrollThumb, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDScrollThumb = (function(_super) {
  __extends(KDScrollThumb, _super);

  function KDScrollThumb(options, data) {
    var _ref;
    if (options == null) {
      options = {};
    }
    options.type || (options.type = 'vertical');
    options.cssClass = KD.utils.curry('kdscrollthumb', options.cssClass);
    if (options.draggable == null) {
      options.draggable = {
        axis: options.type === 'vertical' ? 'y' : 'x',
        containment: this
      };
    }
    KDScrollThumb.__super__.constructor.call(this, options, data);
    _ref = this.getOptions(), this.type = _ref.type, this.track = _ref.track;
    this.view = this.track.getDelegate();
    this.on('viewAppended', this.bound('calculateSize'));
    this.on('DragInAction', this.bound('handleDrag'));
    this.view.on('scroll', this.bound('calculatePosition'));
    this.listenWindowResize();
  }

  KDScrollThumb.prototype.resetSizes = function() {
    this.size = null;
    this.trackSize = null;
    return this.scrollSize = null;
  };

  KDScrollThumb.prototype.handleMutation = function() {
    this.scrollSize = null;
    return this.calculateSize();
  };

  KDScrollThumb.prototype.handleDrag = function() {
    var availOffset, offset, ratio, size, trackSize;
    size = this.getSize();
    offset = this.getOffset();
    trackSize = this.getTrackSize();
    availOffset = trackSize - size;
    ratio = Math.min(Math.max(0, offset / availOffset), 1);
    if (this.isVertical()) {
      return this.view.setScrollTop((this.view.getScrollHeight() - trackSize) * ratio);
    } else {
      return this.view.setScrollLeft((this.view.getScrollWidth() - trackSize) * ratio);
    }
  };

  KDScrollThumb.prototype.isVertical = function() {
    return this.type === 'vertical';
  };

  KDScrollThumb.prototype.getTrackSize = function() {
    if (this.trackSize) {
      return this.trackSize;
    } else if (this.isVertical()) {
      return this.track.getHeight();
    } else {
      return this.track.getWidth();
    }
  };

  KDScrollThumb.prototype.setSize = function(size) {
    if (this.isVertical()) {
      this.setHeight(size);
    } else {
      this.setWidth(size);
    }
    return this.size = size;
  };

  KDScrollThumb.prototype.getSize = function() {
    if (this.size) {
      return this.size;
    } else if (this.isVertical()) {
      return this.getHeight();
    } else {
      return this.getWidth();
    }
  };

  KDScrollThumb.prototype.setOffset = function(offset) {
    return this.setStyle(this.isVertical() ? {
      top: offset
    } : {
      left: offset
    });
  };

  KDScrollThumb.prototype.getOffset = function() {
    if (this.isVertical()) {
      return this.getY() - this.track.getY();
    } else {
      return this.getX() - this.track.getX();
    }
  };

  KDScrollThumb.prototype.getScrollOffset = function() {
    if (this.isVertical()) {
      return this.view.getScrollTop();
    } else {
      return this.view.getScrollLeft();
    }
  };

  KDScrollThumb.prototype.getScrollSize = function() {
    if (this.scrollSize) {
      return this.scrollSize;
    } else if (this.isVertical()) {
      return this.view.getScrollHeight();
    } else {
      return this.view.getScrollWidth();
    }
  };

  KDScrollThumb.prototype.calculateSize = function() {
    this.trackSize = this.getTrackSize();
    this.scrollSize = this.getScrollSize();
    if (this.trackSize >= this.scrollSize) {
      this.track.hide();
    } else {
      this.track.show();
    }
    return this.setSize(this.trackSize * this.trackSize / this.scrollSize);
  };

  KDScrollThumb.prototype.calculatePosition = function(event) {
    var ratio;
    ratio = this.getScrollOffset() / this.getScrollSize();
    return this.setOffset(this.getTrackSize() * ratio);
  };

  KDScrollThumb.prototype._windowDidResize = function() {
    return this.resetSizes();
  };

  return KDScrollThumb;

})(KDView);


},{"./../../core/view.coffee":108}],68:[function(require,module,exports){
var KDScrollTrack, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view');

module.exports = KDScrollTrack = (function(_super) {
  __extends(KDScrollTrack, _super);

  function KDScrollTrack(options, data) {
    if (options == null) {
      options = {};
    }
    options.type || (options.type = 'vertical');
    options.cssClass = KD.utils.curry("kdscrolltrack " + options.type, options.cssClass);
    KDScrollTrack.__super__.constructor.call(this, options, data);
    this.type = this.getOptions().type;
    this.thumb = new KDScrollThumb({
      cssClass: 'kdscrollthumb',
      type: this.type,
      track: this
    });
  }

  KDScrollTrack.prototype.viewAppended = function() {
    KDScrollTrack.__super__.viewAppended.call(this);
    return this.addSubView(this.thumb);
  };

  KDScrollTrack.prototype.show = function() {
    this.getDelegate().emit("ScrollTrackShown", this.type);
    return this.unsetClass('invisible');
  };

  KDScrollTrack.prototype.hide = function() {
    this.getDelegate().emit("ScrollTrackHidden", this.type);
    return this.setClass('invisible');
  };

  return KDScrollTrack;

})(KDView);


},{"./../../core/view":108}],69:[function(require,module,exports){
var KDScrollView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

require('jquery-mousewheel')($);

KDView = require('./../../core/view.coffee');

module.exports = KDScrollView = (function(_super) {
  __extends(KDScrollView, _super);

  function KDScrollView(options, data) {
    if (options == null) {
      options = {};
    }
    options.bind || (options.bind = "mouseenter");
    options.cssClass = KD.utils.curry("kdscrollview", options.cssClass);
    KDScrollView.__super__.constructor.call(this, options, data);
    this.stopScrolling = false;
    this.on('click', function() {
      return KD.getSingleton('windowController').enableScroll();
    });
  }

  KDScrollView.prototype.bindEvents = function() {
    this.$().bind("mousewheel scroll", (function(_this) {
      return function(event, delta, deltaX, deltaY) {
        if (delta) {
          event._delta = {
            delta: delta,
            deltaX: deltaX,
            deltaY: deltaY
          };
        }
        return _this.handleEvent(event);
      };
    })(this));
    return KDScrollView.__super__.bindEvents.apply(this, arguments);
  };

  KDScrollView.prototype.hasScrollBars = function() {
    return this.getScrollHeight() > this.getHeight();
  };

  KDScrollView.prototype.getScrollHeight = function() {
    return this.getElement().scrollHeight;
  };

  KDScrollView.prototype.getScrollWidth = function() {
    return this.getElement().scrollWidth;
  };

  KDScrollView.prototype.getScrollTop = function() {
    return this.getElement().scrollTop;
  };

  KDScrollView.prototype.getScrollLeft = function() {
    return this.getElement().scrollLeft;
  };

  KDScrollView.prototype.setScrollHeight = function(val) {
    return this.getElement().scrollHeight = val;
  };

  KDScrollView.prototype.setScrollWidth = function(val) {
    return this.getElement().scrollWidth = val;
  };

  KDScrollView.prototype.setScrollTop = function(val) {
    return this.getElement().scrollTop = val;
  };

  KDScrollView.prototype.setScrollLeft = function(val) {
    return this.getElement().scrollLeft = val;
  };

  KDScrollView.prototype.scrollTo = function(_arg, callback) {
    var duration, left, top;
    top = _arg.top, left = _arg.left, duration = _arg.duration;
    top || (top = 0);
    left || (left = 0);
    duration || (duration = null);
    if (duration) {
      return this.$().animate({
        scrollTop: top,
        scrollLeft: left
      }, duration, callback);
    } else {
      this.setScrollTop(top);
      this.setScrollLeft(left);
      return typeof callback === "function" ? callback() : void 0;
    }
  };

  KDScrollView.prototype.scrollToSubView = function(subView) {
    var subViewHeight, subViewRelTop, subViewTop, viewHeight, viewScrollTop, viewTop;
    viewTop = this.getY();
    viewHeight = this.getHeight();
    viewScrollTop = this.getScrollTop();
    subViewTop = subView.getY();
    subViewHeight = subView.getHeight();
    subViewRelTop = subViewTop - viewTop + viewScrollTop;
    if (subViewTop - viewTop + subViewHeight < viewHeight && subViewTop - viewTop >= 0) {

    } else if (subViewTop - viewTop < 0) {
      return this.scrollTo({
        top: subViewRelTop
      });
    } else if (subViewTop - viewTop + subViewHeight > viewHeight) {
      return this.scrollTo({
        top: subViewRelTop - viewHeight + subViewHeight
      });
    }
  };

  KDScrollView.prototype.fractionOfHeightBelowFold = function(_arg) {
    var scrollViewGlobalOffset, view, viewGlobalOffset, viewHeight, viewOffsetFromScrollView;
    view = _arg.view;
    viewHeight = view.getHeight();
    viewGlobalOffset = view.$().offset().top;
    scrollViewGlobalOffset = this.$().offset().top;
    viewOffsetFromScrollView = viewGlobalOffset - scrollViewGlobalOffset;
    return (viewHeight + viewOffsetFromScrollView - this.getHeight()) / this.getHeight();
  };

  KDScrollView.prototype.mouseWheel = function() {
    if (this.stopScrolling) {
      return false;
    }
  };

  return KDScrollView;

})(KDView);


},{"./../../core/view.coffee":108,"jquery-mousewheel":2}],70:[function(require,module,exports){
var KDCustomHTMLView, KDSliderBarHandleView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDCustomHTMLView = require('./../../core/customhtmlview.coffee');

module.exports = KDSliderBarHandleView = (function(_super) {
  __extends(KDSliderBarHandleView, _super);

  function KDSliderBarHandleView(options) {
    if (options == null) {
      options = {};
    }
    options.tagName = "a";
    options.cssClass = "handle";
    if (options.value == null) {
      options.value = 0;
    }
    options.draggable = {
      axis: "x"
    };
    KDSliderBarHandleView.__super__.constructor.call(this, options);
    this.value = this.getOption('value');
  }

  KDSliderBarHandleView.prototype.attachEvents = function() {
    var currentValue, maxValue, minValue, width, _ref;
    _ref = this.parent.getOptions(), maxValue = _ref.maxValue, minValue = _ref.minValue, width = _ref.width;
    currentValue = this.value;
    this.on("DragStarted", function() {
      return currentValue = this.value;
    });
    this.on("DragInAction", function() {
      var relPos, valueChange;
      relPos = this.dragState.position.relative.x;
      valueChange = ((maxValue - minValue) * relPos) / width;
      this.setValue(currentValue + valueChange);
      if (this.parent.getOption("snapOnDrag")) {
        return this.snap();
      }
    });
    return this.on("DragFinished", function() {
      if (this.parent.getOption("snap")) {
        return this.snap();
      }
    });
  };

  KDSliderBarHandleView.prototype.getPosition = function() {
    var maxValue, minValue, percentage, position, sliderWidth, _ref;
    _ref = this.parent.getOptions(), maxValue = _ref.maxValue, minValue = _ref.minValue;
    sliderWidth = this.parent.getWidth();
    percentage = ((this.value - minValue) * 100) / (maxValue - minValue);
    position = (sliderWidth / 100) * percentage;
    return "" + position + "px";
  };

  KDSliderBarHandleView.prototype.setValue = function(value) {
    var leftLimit, rightLimit, _ref;
    _ref = this.getOptions(), leftLimit = _ref.leftLimit, rightLimit = _ref.rightLimit;
    if (typeof rightLimit === "number") {
      value = Math.min(value, rightLimit);
    }
    if (typeof leftLimit === "number") {
      value = Math.max(value, leftLimit);
    }
    this.value = value;
    this.setX(this.getPosition());
    return this.parent.setValue(value, this, false);
  };

  KDSliderBarHandleView.prototype.getSnappedValue = function(value) {
    var interval, mid, mod;
    interval = this.parent.getOptions().interval;
    value || (value = this.value);
    if (interval) {
      mod = value % interval;
      mid = interval / 2;
      return value = (function() {
        switch (false) {
          case !(mod <= mid):
            return value - mod;
          case !(mod > mid):
            return value + (interval - mod);
          default:
            return value;
        }
      })();
    }
  };

  KDSliderBarHandleView.prototype.snap = function() {
    var interval, value;
    interval = this.parent.getOptions().interval;
    value = this.getSnappedValue();
    if (interval && this.parent.getOption("snap")) {
      this.setValue(value);
      if (this.parent.getOption('drawBar')) {
        return this.parent.drawBar();
      }
    }
  };

  KDSliderBarHandleView.prototype.viewAppended = function() {
    this.setX("" + (this.getPosition()));
    this.attachEvents();
    if (this.parent.getOption("snap")) {
      return this.snap();
    }
  };

  return KDSliderBarHandleView;

})(KDCustomHTMLView);


},{"./../../core/customhtmlview.coffee":97}],71:[function(require,module,exports){
var KDCustomHTMLView, KDSliderBarHandleView, KDSliderBarView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDCustomHTMLView = require('./../../core/customhtmlview.coffee');

KDSliderBarHandleView = require('./sliderbarhandleview.coffee');

module.exports = KDSliderBarView = (function(_super) {
  __extends(KDSliderBarView, _super);

  function KDSliderBarView(options, data) {
    if (options == null) {
      options = {};
    }
    if (data == null) {
      data = {};
    }
    this._createLabel = __bind(this._createLabel, this);
    options.cssClass = KD.utils.curry("sliderbar-container", options.cssClass);
    if (options.minValue == null) {
      options.minValue = 0;
    }
    if (options.maxValue == null) {
      options.maxValue = 100;
    }
    if (options.interval == null) {
      options.interval = false;
    }
    if (options.drawBar == null) {
      options.drawBar = true;
    }
    if (options.showLabels == null) {
      options.showLabels = true;
    }
    if (options.snap == null) {
      options.snap = true;
    }
    if (options.snapOnDrag == null) {
      options.snapOnDrag = false;
    }
    options.width || (options.width = 300);
    if (options.drawOpposite == null) {
      options.drawOpposite = false;
    }
    KDSliderBarView.__super__.constructor.call(this, options, data);
    this.handles = [];
    this.labels = [];
  }

  KDSliderBarView.prototype.createHandles = function() {
    var handle, sortRef, value, _i, _len, _ref;
    _ref = this.getOption("handles");
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      value = _ref[_i];
      this.handles.push(this.addSubView(handle = new KDSliderBarHandleView({
        value: value
      })));
    }
    sortRef = function(a, b) {
      if (a.options.value < b.options.value) {
        return -1;
      }
      if (a.options.value > b.options.value) {
        return 1;
      }
      return 0;
    };
    this.handles.sort(sortRef);
    return this.setClass("labeled");
  };

  KDSliderBarView.prototype.drawBar = function() {
    var diff, handle, left, len, positions, right, _i, _len, _ref;
    positions = [];
    _ref = this.handles;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      handle = _ref[_i];
      positions.push(handle.getRelativeX());
    }
    len = positions.length;
    left = (len > 1 ? parseInt(positions.first) : void 0) || 0;
    right = parseInt(positions.last);
    diff = right - left;
    if (!this.bar) {
      this.addSubView(this.bar = new KDCustomHTMLView({
        cssClass: "bar"
      }));
    }
    this.bar.setWidth(diff);
    return this.bar.setX("" + left + "px");
  };

  KDSliderBarView.prototype.drawOppositeBar = function() {
    var diff, handle, positions, right, _i, _len, _ref;
    positions = [];
    _ref = this.handles;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      handle = _ref[_i];
      positions.push(handle.getRelativeX());
    }
    right = parseInt(positions.last);
    diff = this.getWidth() - right;
    if (!this.oppositeBar) {
      this.addSubView(this.oppositeBar = new KDCustomHTMLView({
        cssClass: "opposite bar"
      }));
    }
    this.oppositeBar.setWidth(diff);
    return this.oppositeBar.setX("" + right + "px");
  };

  KDSliderBarView.prototype._createLabel = function(value) {
    var interval, label, maxValue, minValue, pos, showLabels, _ref;
    _ref = this.getOptions(), maxValue = _ref.maxValue, minValue = _ref.minValue, interval = _ref.interval, showLabels = _ref.showLabels;
    pos = ((value - minValue) * 100) / (maxValue - minValue);
    this.labels.push(this.addSubView(label = new KDCustomHTMLView({
      cssClass: "sliderbar-label",
      partial: "" + value
    })));
    return label.setX("" + pos + "%");
  };

  KDSliderBarView.prototype.addLabels = function() {
    var interval, maxValue, minValue, showLabels, value, _i, _j, _len, _ref, _results, _results1;
    _ref = this.getOptions(), maxValue = _ref.maxValue, minValue = _ref.minValue, interval = _ref.interval, showLabels = _ref.showLabels;
    if (Array.isArray(showLabels)) {
      _results = [];
      for (_i = 0, _len = showLabels.length; _i < _len; _i++) {
        value = showLabels[_i];
        _results.push(this._createLabel(value));
      }
      return _results;
    } else {
      _results1 = [];
      for (value = _j = minValue; interval > 0 ? _j <= maxValue : _j >= maxValue; value = _j += interval) {
        _results1.push(this._createLabel(value));
      }
      return _results1;
    }
  };

  KDSliderBarView.prototype.getValues = function() {
    var handle, _i, _len, _ref, _results;
    _ref = this.handles;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      handle = _ref[_i];
      _results.push(handle.getOptions().value);
    }
    return _results;
  };

  KDSliderBarView.prototype.setValue = function(value, handle, updateHandle) {
    if (handle == null) {
      handle = this.handles.first;
    }
    if (updateHandle == null) {
      updateHandle = true;
    }
    if (updateHandle) {
      handle.setValue(value);
    }
    if (this.getOption('drawBar')) {
      this.drawBar();
    }
    if (this.getOption('drawOpposite')) {
      this.drawOppositeBar();
    }
    this.setLimits();
    this.emit("ValueIsChanging", handle.value);
    return this.emit("ValueChanged", handle);
  };

  KDSliderBarView.prototype.setLimits = function() {
    var handle, i, interval, maxValue, minValue, options, _i, _len, _ref, _ref1, _ref2, _ref3, _results;
    _ref = this.getOptions(), maxValue = _ref.maxValue, minValue = _ref.minValue, interval = _ref.interval;
    if (this.handles.length === 1) {
      this.handles.first.options.leftLimit = minValue;
      return this.handles.first.options.rightLimit = maxValue;
    } else {
      _ref1 = this.handles;
      _results = [];
      for (i = _i = 0, _len = _ref1.length; _i < _len; i = ++_i) {
        handle = _ref1[i];
        options = handle.getOptions();
        options.leftLimit = ((_ref2 = this.handles[i - 1]) != null ? _ref2.value : void 0) + interval || minValue;
        _results.push(options.rightLimit = ((_ref3 = this.handles[i + 1]) != null ? _ref3.value : void 0) - interval || maxValue);
      }
      return _results;
    }
  };

  KDSliderBarView.prototype.attachEvents = function() {
    return this.on("click", function(event) {
      var clickedPos, clickedValue, closestHandle, diff, handle, maxValue, minValue, mindiff, sliderWidth, snappedValue, value, _i, _len, _ref, _ref1;
      _ref = this.getOptions(), maxValue = _ref.maxValue, minValue = _ref.minValue;
      sliderWidth = this.getWidth();
      clickedPos = event.pageX - this.getBounds().x;
      clickedValue = ((maxValue - minValue) * clickedPos) / sliderWidth + minValue;
      snappedValue = this.handles.first.getSnappedValue(clickedValue);
      closestHandle = null;
      mindiff = null;
      _ref1 = this.handles;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        handle = _ref1[_i];
        value = handle.value;
        diff = Math.abs(clickedValue - value);
        if ((diff < mindiff) || !mindiff) {
          mindiff = diff;
          closestHandle = handle;
        }
      }
      return closestHandle.setValue(snappedValue);
    });
  };

  KDSliderBarView.prototype.viewAppended = function() {
    this.setWidth(this.getOption("width"));
    this.createHandles();
    this.setLimits();
    if (this.getOption('drawBar')) {
      this.drawBar();
    }
    if (this.getOption('drawOpposite')) {
      this.drawOppositeBar();
    }
    if (this.getOption('showLabels')) {
      this.addLabels();
    }
    return this.attachEvents();
  };

  return KDSliderBarView;

})(KDCustomHTMLView);


},{"./../../core/customhtmlview.coffee":97,"./sliderbarhandleview.coffee":70}],72:[function(require,module,exports){
var KDSlidePageView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDSlidePageView = (function(_super) {
  __extends(KDSlidePageView, _super);

  function KDSlidePageView(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass = KD.utils.curry('kd-page', options.cssClass);
    KDSlidePageView.__super__.constructor.call(this, options, data);
    this._currentCssClass = null;
  }

  KDSlidePageView.prototype.move = function(cssClass) {
    if (!cssClass) {
      return;
    }
    this.unsetClass(this._currentCssClass);
    this._currentCssClass = cssClass;
    return this.setClass(cssClass);
  };

  return KDSlidePageView;

})(KDView);


},{"./../../core/view.coffee":108}],73:[function(require,module,exports){
var KDSlideShowView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDSlideShowView = (function(_super) {
  var X_COORD, Y_COORD, _ref;

  __extends(KDSlideShowView, _super);

  _ref = [1, 2], X_COORD = _ref[0], Y_COORD = _ref[1];

  function KDSlideShowView(options, data) {
    var animation, direction, hammer, leftToRight, topToBottom, touchCallbacks, touchEnabled, _ref1;
    if (options == null) {
      options = {};
    }
    options.cssClass = KD.utils.curry('kd-slide', options.cssClass);
    if (options.animation == null) {
      options.animation = 'move';
    }
    if (options.direction == null) {
      options.direction = 'leftToRight';
    }
    if (options.touchEnabled == null) {
      options.touchEnabled = true;
    }
    KDSlideShowView.__super__.constructor.call(this, options, data);
    this.pages = [];
    this._coordsY = [];
    this._currentX = 0;
    _ref1 = this.getOptions(), animation = _ref1.animation, direction = _ref1.direction, touchEnabled = _ref1.touchEnabled;
    topToBottom = [["" + animation + "FromTop", "" + animation + "FromBottom"], ["" + animation + "ToBottom", "" + animation + "ToTop"]];
    leftToRight = [["" + animation + "FromLeft", "" + animation + "FromRight"], ["" + animation + "ToRight", "" + animation + "ToLeft"]];
    if (direction === 'topToBottom') {
      this.xcoordAnimations = topToBottom;
      this.ycoordAnimations = leftToRight;
      touchCallbacks = ['nextSubPage', 'previousSubPage', 'nextPage', 'previousPage'];
    } else {
      this.xcoordAnimations = leftToRight;
      this.ycoordAnimations = topToBottom;
      touchCallbacks = ['nextPage', 'previousPage', 'nextSubPage', 'previousSubPage'];
    }
    if (touchEnabled) {
      hammer = Hammer(this.getElement());
      hammer.on("swipeleft", this.bound(touchCallbacks[0]));
      hammer.on("swiperight", this.bound(touchCallbacks[1]));
      hammer.on("swipeup", this.bound(touchCallbacks[2]));
      hammer.on("swipedown", this.bound(touchCallbacks[3]));
      hammer.on("touchmove", function(e) {
        return e.preventDefault();
      });
    }
  }

  KDSlideShowView.prototype.addPage = function(page) {
    this.addSubView(page);
    if (this.pages.length === 0) {
      page.setClass('current');
      this.currentPage = page;
    }
    this.pages.push([page]);
    return this._coordsY.push(0);
  };

  KDSlideShowView.prototype.addSubPage = function(page) {
    var lastAddedPage;
    this.addSubView(page);
    lastAddedPage = this.pages.last;
    return lastAddedPage.push(page);
  };

  KDSlideShowView.prototype.nextPage = function() {
    return this.jump(this._currentX + 1, X_COORD);
  };

  KDSlideShowView.prototype.previousPage = function() {
    return this.jump(this._currentX - 1, X_COORD);
  };

  KDSlideShowView.prototype.nextSubPage = function() {
    return this.jump(this._coordsY[this._currentX] + 1, Y_COORD);
  };

  KDSlideShowView.prototype.previousSubPage = function() {
    return this.jump(this._coordsY[this._currentX] - 1, Y_COORD);
  };

  KDSlideShowView.prototype.jump = function(pageIndex, coord, callback) {
    var current, currentPage, direction, index, newPage, pages, _ref1, _ref2;
    if (coord == null) {
      coord = 1;
    }
    if (callback == null) {
      callback = noop;
    }
    if (coord === X_COORD) {
      _ref1 = [this.pages, this._currentX], pages = _ref1[0], current = _ref1[1];
    } else {
      _ref2 = [this.pages[this._currentX], this._coordsY[this._currentX]], pages = _ref2[0], current = _ref2[1];
    }
    if (pages.length <= 1) {
      return;
    }
    index = Math.min(pages.length - 1, Math.max(0, pageIndex));
    if (current === index) {
      return;
    }
    direction = index < current ? 0 : 1;
    if (coord === X_COORD) {
      currentPage = pages[current][this._coordsY[current]];
      newPage = pages[index][this._coordsY[index]];
      this._currentX = index;
      newPage.move(this.xcoordAnimations[0][direction]);
      currentPage.move(this.xcoordAnimations[1][direction]);
    } else {
      currentPage = pages[current];
      newPage = pages[index];
      this._coordsY[this._currentX] = index;
      newPage.move(this.ycoordAnimations[0][direction]);
      currentPage.move(this.ycoordAnimations[1][direction]);
    }
    this.emit('CurrentPageChanged', {
      x: this._currentX,
      y: this._coordsY[this._currentX]
    });
    newPage.setClass('current');
    this.currentPage = newPage;
    return this.utils.wait(600, function() {
      currentPage.unsetClass('current');
      return callback();
    });
  };

  return KDSlideShowView;

})(KDView);


},{"./../../core/view.coffee":108}],74:[function(require,module,exports){
var KDSplitComboView, KDSplitView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

KDSplitView = require('./splitview.coffee');

module.exports = KDSplitComboView = (function(_super) {
  __extends(KDSplitComboView, _super);

  function KDSplitComboView(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass || (options.cssClass = "kdsplitcomboview");
    KDSplitComboView.__super__.constructor.call(this, options, data);
    this.init(options);
  }

  KDSplitComboView.prototype.init = function(options) {
    return this.addSubView(this.createSplitView(options.direction, options.sizes, options.views));
  };

  KDSplitComboView.prototype.createSplitView = function(type, sizes, viewsConfig) {
    var config, index, options, views, _i, _len;
    views = [];
    for (index = _i = 0, _len = viewsConfig.length; _i < _len; index = ++_i) {
      config = viewsConfig[index];
      if (config.type === "split") {
        options = config.options;
        views.push(this.createSplitView(options.direction, options.sizes, config.views));
      } else {
        views.push(config);
      }
    }
    return new KDSplitView({
      type: type,
      sizes: sizes,
      views: views
    });
  };

  return KDSplitComboView;

})(KDView);


},{"./../../core/view.coffee":108,"./splitview.coffee":77}],75:[function(require,module,exports){
var KDScrollView, KDSplitViewPanel,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDScrollView = require('./../scrollview/scrollview.coffee');

module.exports = KDSplitViewPanel = (function(_super) {
  __extends(KDSplitViewPanel, _super);

  function KDSplitViewPanel(options, data) {
    var _ref;
    if (options == null) {
      options = {};
    }
    if (options.fixed == null) {
      options.fixed = false;
    }
    options.minimum || (options.minimum = null);
    options.maximum || (options.maximum = null);
    options.view || (options.view = null);
    KDSplitViewPanel.__super__.constructor.call(this, options, data);
    this.isVertical = this.getOptions().type.toLowerCase() === "vertical";
    this.isFixed = this.getOptions().fixed;
    _ref = this.options, this.size = _ref.size, this.minimum = _ref.minimum, this.maximum = _ref.maximum;
  }

  KDSplitViewPanel.prototype._getIndex = function() {
    return this.parent.getPanelIndex(this);
  };

  KDSplitViewPanel.prototype._getSize = function() {
    if (this.isVertical) {
      return this.getWidth();
    } else {
      return this.getHeight();
    }
  };

  KDSplitViewPanel.prototype._setSize = function(size) {
    if (this._wouldResize(size)) {
      if (size < 0) {
        size = 0;
      }
      if (this.isVertical) {
        this.setWidth(size);
      } else {
        this.setHeight(size);
      }
      this.parent.sizes[this._getIndex()] = this.size = size;
      this.parent.emit("PanelDidResize", {
        panel: this
      });
      this.emit("PanelDidResize", {
        newSize: size
      });
      return size;
    } else {
      return false;
    }
  };

  KDSplitViewPanel.prototype._wouldResize = function(size) {
    if (this.minimum == null) {
      this.minimum = -1;
    }
    if (this.maximum == null) {
      this.maximum = 99999;
    }
    if (size > this.minimum && size < this.maximum) {
      return true;
    } else {
      if (size < this.minimum) {
        this.parent._panelReachedMinimum(this._getIndex());
      } else if (size > this.maximum) {
        this.parent._panelReachedMaximum(this._getIndex());
      }
      return false;
    }
  };

  KDSplitViewPanel.prototype._setOffset = function(offset) {
    if (offset < 0) {
      offset = 0;
    }
    if (this.isVertical) {
      this.$().css({
        left: offset
      });
    } else {
      this.$().css({
        top: offset
      });
    }
    return this.parent.panelsBounds[this._getIndex()] = offset;
  };

  KDSplitViewPanel.prototype._getOffset = function() {
    if (this.isVertical) {
      return this.getRelativeX();
    } else {
      return this.getRelativeY();
    }
  };

  KDSplitViewPanel.prototype._animateTo = function(size, offset, callback) {
    var cb, d, options, panel, properties;
    if ("undefined" === typeof callback && "function" === typeof offset) {
      callback = offset;
    }
    callback || (callback = noop);
    panel = this;
    d = panel.parent.options.duration;
    cb = function() {
      var newSize;
      newSize = panel._getSize();
      panel.parent.sizes[panel.index] = panel.size = newSize;
      panel.parent.emit("PanelDidResize", {
        panel: panel
      });
      panel.emit("PanelDidResize", {
        newSize: newSize
      });
      return callback.call(panel);
    };
    properties = {};
    if (size < 0) {
      size = 0;
    }
    if (panel.isVertical) {
      properties.width = size;
      if (offset != null) {
        properties.left = offset;
      }
    } else {
      properties.height = size;
      if (offset != null) {
        properties.top = offset;
      }
    }
    options = {
      duration: d,
      complete: cb
    };
    panel.$().stop();
    return panel.$().animate(properties, options);
  };

  return KDSplitViewPanel;

})(KDScrollView);


},{"./../scrollview/scrollview.coffee":69}],76:[function(require,module,exports){
var KDSplitResizer, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDSplitResizer = (function(_super) {
  __extends(KDSplitResizer, _super);

  function KDSplitResizer(options, data) {
    var axis, _ref;
    if (options == null) {
      options = {};
    }
    this.isVertical = options.type.toLowerCase() === "vertical";
    axis = this.isVertical ? "x" : "y";
    if (options.draggable == null) {
      options.draggable = {
        axis: axis
      };
    }
    KDSplitResizer.__super__.constructor.call(this, options, data);
    _ref = this.getOptions(), this.panel0 = _ref.panel0, this.panel1 = _ref.panel1;
    this.on("DragFinished", this.dragFinished);
    this.on("DragInAction", this.dragInAction);
    this.on("DragStarted", this.dragStarted);
  }

  KDSplitResizer.prototype._setOffset = function(offset) {
    if (offset < 0) {
      offset = 0;
    }
    if (this.isVertical) {
      return this.$().css({
        left: offset - 5
      });
    } else {
      return this.$().css({
        top: offset - 5
      });
    }
  };

  KDSplitResizer.prototype._getOffset = function(offset) {
    if (this.isVertical) {
      return this.getRelativeX();
    } else {
      return this.getRelativeY();
    }
  };

  KDSplitResizer.prototype._animateTo = function(offset) {
    var d;
    d = this.parent.options.duration;
    if (this.isVertical) {
      offset -= this.getWidth() / 2;
      return this.$().animate({
        left: offset
      }, d);
    } else {
      offset -= this.getHeight() / 2;
      return this.$().animate({
        top: offset
      }, d);
    }
  };

  KDSplitResizer.prototype.dragFinished = function(event, dragState) {
    return this.parent._resizeDidStop(event);
  };

  KDSplitResizer.prototype.dragStarted = function(event, dragState) {
    this.parent._resizeDidStart();
    this.rOffset = this._getOffset();
    this.p0Size = this.panel0._getSize();
    this.p1Size = this.panel1._getSize();
    return this.p1Offset = this.panel1._getOffset();
  };

  KDSplitResizer.prototype.dragInAction = function(x, y) {
    var p0DidResize, p0WouldResize, p1DidResize, p1WouldResize;
    if (this.isVertical) {
      p0WouldResize = this.panel0._wouldResize(x + this.p0Size);
      if (p0WouldResize) {
        p1WouldResize = this.panel1._wouldResize(-x + this.p1Size);
      }
      this.dragIsAllowed = p1WouldResize ? (this.panel0._setSize(x + this.p0Size), this.panel1._setSize(-x + this.p1Size), true) : (this._setOffset(this.panel1._getOffset()), false);
      if (this.dragIsAllowed) {
        return this.panel1._setOffset(x + this.p1Offset);
      }
    } else {
      p0WouldResize = this.panel0._wouldResize(y + this.p0Size);
      p1WouldResize = this.panel1._wouldResize(-y + this.p1Size);
      p0DidResize = p0WouldResize && p1WouldResize ? this.panel0._setSize(y + this.p0Size) : false;
      p1DidResize = p0WouldResize && p1WouldResize ? this.panel1._setSize(-y + this.p1Size) : false;
      if (p0DidResize && p1DidResize) {
        return this.panel1._setOffset(y + this.p1Offset);
      }
    }
  };

  return KDSplitResizer;

})(KDView);


},{"./../../core/view.coffee":108}],77:[function(require,module,exports){
var KD, KDSplitResizer, KDSplitView, KDSplitViewPanel, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KD = require('./../../core/kd.coffee');

KDView = require('./../../core/view.coffee');

KDSplitViewPanel = require('./splitpanel.coffee');

KDSplitResizer = require('./splitresizer.coffee');

module.exports = KDSplitView = (function(_super) {
  __extends(KDSplitView, _super);

  function KDSplitView(options, data) {
    if (options == null) {
      options = {};
    }
    options.type || (options.type = "vertical");
    if (options.resizable == null) {
      options.resizable = true;
    }
    options.sizes || (options.sizes = ["50%", "50%"]);
    options.minimums || (options.minimums = null);
    options.maximums || (options.maximums = null);
    options.views || (options.views = null);
    options.fixed || (options.fixed = []);
    options.duration || (options.duration = 200);
    options.separator || (options.separator = null);
    if (options.colored == null) {
      options.colored = false;
    }
    if (options.animated == null) {
      options.animated = true;
    }
    options.type = options.type.toLowerCase();
    KDSplitView.__super__.constructor.call(this, options, data);
    this.setClass("kdsplitview kdsplitview-" + (this.getOptions().type) + " " + (this.getOptions().cssClass));
    this.panels = [];
    this.panelsBounds = [];
    this.resizers = [];
    this.sizes = [];
  }

  KDSplitView.prototype.viewAppended = function() {
    this._sanitizeSizes();
    this._createPanels();
    this._calculatePanelBounds();
    this._putPanels();
    this._setPanelPositions();
    this._putViews();
    if (this.getOptions().resizable && this.panels.length) {
      this._createResizers();
    }
    return this.listenWindowResize();
  };

  KDSplitView.prototype._createPanels = function() {
    var i, panelCount;
    panelCount = this.getOptions().sizes.length;
    return this.panels = (function() {
      var _i, _results;
      _results = [];
      for (i = _i = 0; 0 <= panelCount ? _i < panelCount : _i > panelCount; i = 0 <= panelCount ? ++_i : --_i) {
        _results.push(this._createPanel(i));
      }
      return _results;
    }).call(this);
  };

  KDSplitView.prototype._createPanel = function(index) {
    var fixed, maximums, minimums, panel, type, _ref;
    _ref = this.getOptions(), type = _ref.type, fixed = _ref.fixed, minimums = _ref.minimums, maximums = _ref.maximums;
    panel = new KDSplitViewPanel({
      cssClass: "kdsplitview-panel panel-" + index,
      index: index,
      type: type,
      size: this._sanitizeSize(this.sizes[index]),
      fixed: fixed[index] != null,
      minimum: minimums ? this._sanitizeSize(minimums[index]) : void 0,
      maximum: maximums ? this._sanitizeSize(maximums[index]) : void 0
    });
    panel.on("KDObjectWillBeDestroyed", (function(_this) {
      return function() {
        return _this._panelIsBeingDestroyed(panel);
      };
    })(this));
    this.emit("SplitPanelCreated", panel);
    return panel;
  };

  KDSplitView.prototype._calculatePanelBounds = function() {
    var i, offset, prevSize, size;
    return this.panelsBounds = (function() {
      var _i, _j, _len, _ref, _results;
      _ref = this.sizes;
      _results = [];
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        size = _ref[i];
        if (i === 0) {
          _results.push(0);
        } else {
          offset = 0;
          for (prevSize = _j = 0; 0 <= i ? _j < i : _j > i; prevSize = 0 <= i ? ++_j : --_j) {
            offset += this.sizes[prevSize];
          }
          _results.push(offset);
        }
      }
      return _results;
    }).call(this);
  };

  KDSplitView.prototype._putPanels = function() {
    var panel, _i, _len, _ref, _results;
    _ref = this.panels;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      panel = _ref[_i];
      this.addSubView(panel);
      if (this.getOptions().colored) {
        _results.push(panel.$().css({
          backgroundColor: KD.utils.getRandomRGB()
        }));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  KDSplitView.prototype._setPanelPositions = function() {
    var i, panel, _i, _len, _ref;
    _ref = this.panels;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      panel = _ref[i];
      panel._setSize(this.sizes[i]);
      panel._setOffset(this.panelsBounds[i]);
    }
    return false;
  };

  KDSplitView.prototype._panelIsBeingDestroyed = function(panel) {
    var index, o;
    index = this.getPanelIndex(panel);
    o = this.getOptions();
    this.panels = this.panels.slice(0, index).concat(this.panels.slice(index + 1));
    this.sizes = this.sizes.slice(0, index).concat(this.sizes.slice(index + 1));
    this.panelsBounds = this.panelsBounds.slice(0, index).concat(this.panelsBounds.slice(index + 1));
    o.minimums.splice(index, 1);
    o.maximums.splice(index, 1);
    if (o.views[index] != null) {
      return o.views.splice(index, 1);
    }
  };

  KDSplitView.prototype._createResizers = function() {
    var i;
    this.resizers = (function() {
      var _i, _ref, _results;
      _results = [];
      for (i = _i = 1, _ref = this.sizes.length; 1 <= _ref ? _i < _ref : _i > _ref; i = 1 <= _ref ? ++_i : --_i) {
        _results.push(this._createResizer(i));
      }
      return _results;
    }).call(this);
    return this._repositionResizers();
  };

  KDSplitView.prototype._createResizer = function(index) {
    var resizer;
    this.addSubView(resizer = new KDSplitResizer({
      cssClass: "kdsplitview-resizer " + (this.getOptions().type),
      type: this.getOptions().type,
      panel0: this.panels[index - 1],
      panel1: this.panels[index]
    }));
    return resizer;
  };

  KDSplitView.prototype._repositionResizers = function() {
    var i, resizer, _i, _len, _ref, _results;
    _ref = this.resizers;
    _results = [];
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      resizer = _ref[i];
      _results.push(resizer._setOffset(this.panelsBounds[i + 1]));
    }
    return _results;
  };

  KDSplitView.prototype._putViews = function() {
    var i, view, _base, _i, _len, _ref, _results;
    if ((_base = this.getOptions()).views == null) {
      _base.views = [];
    }
    _ref = this.getOptions().views;
    _results = [];
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      view = _ref[i];
      if (view instanceof KDView) {
        _results.push(this.setView(view, i));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  KDSplitView.prototype._sanitizeSizes = function() {
    var i, newSizes, nullCount, nullSize, o, panelSize, size, splitSize, totalOccupied;
    this._setMinsAndMaxs();
    o = this.getOptions();
    nullCount = 0;
    totalOccupied = 0;
    splitSize = this._getSize();
    newSizes = (function() {
      var _i, _len, _ref, _results;
      _ref = o.sizes;
      _results = [];
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        size = _ref[i];
        if (size === null) {
          nullCount++;
          _results.push(null);
        } else {
          panelSize = this._sanitizeSize(size);
          this._getLegitPanelSize(size, i);
          totalOccupied += panelSize;
          _results.push(panelSize);
        }
      }
      return _results;
    }).call(this);
    this.sizes = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = newSizes.length; _i < _len; _i++) {
        size = newSizes[_i];
        if (size === null) {
          nullSize = (splitSize - totalOccupied) / nullCount;
          _results.push(Math.round(nullSize));
        } else {
          _results.push(Math.round(size));
        }
      }
      return _results;
    })();
    return this.sizes;
  };

  KDSplitView.prototype._sanitizeSize = function(size) {
    var splitSize;
    if ("number" === typeof size || /px$/.test(size)) {
      return parseInt(size, 10);
    } else if (/%$/.test(size)) {
      splitSize = this._getSize();
      return splitSize / 100 * parseInt(size, 10);
    }
  };

  KDSplitView.prototype._setMinsAndMaxs = function() {
    var i, panelAmount, _base, _base1, _i, _results;
    if ((_base = this.getOptions()).minimums == null) {
      _base.minimums = [];
    }
    if ((_base1 = this.getOptions()).maximums == null) {
      _base1.maximums = [];
    }
    panelAmount = this.getOptions().sizes.length || 2;
    _results = [];
    for (i = _i = 0; 0 <= panelAmount ? _i < panelAmount : _i > panelAmount; i = 0 <= panelAmount ? ++_i : --_i) {
      this.getOptions().minimums[i] = this.getOptions().minimums[i] ? this._sanitizeSize(this.getOptions().minimums[i]) : -1;
      _results.push(this.getOptions().maximums[i] = this.getOptions().maximums[i] ? this._sanitizeSize(this.getOptions().maximums[i]) : 99999);
    }
    return _results;
  };

  KDSplitView.prototype._getSize = function() {
    if (this.getOptions().type === "vertical") {
      return this.getWidth();
    } else {
      return this.getHeight();
    }
  };

  KDSplitView.prototype._setSize = function(size) {
    if (this.getOptions().type === "vertical") {
      return this.setWidth(size);
    } else {
      return this.setHeight(size);
    }
  };

  KDSplitView.prototype._getParentSize = function() {
    var $parent, type;
    type = this.getOptions().type;
    $parent = this.$().parent();
    if (type === "vertical") {
      return $parent.width();
    } else {
      return $parent.height();
    }
  };

  KDSplitView.prototype._getLegitPanelSize = function(size, index) {
    return size = this.getOptions().minimums[index] > size ? this.getOptions().minimums[index] : this.getOptions().maximums[index] < size ? this.getOptions().maximums[index] : size;
  };

  KDSplitView.prototype._resizePanels = function() {
    return this._sanitizeSizes();
  };

  KDSplitView.prototype._repositionPanels = function() {
    this._calculatePanelBounds();
    return this._setPanelPositions();
  };

  KDSplitView.prototype._windowDidResize = function(event) {
    this._setSize(this._getParentSize());
    this._resizePanels();
    this._repositionPanels();
    this._setPanelPositions();
    if (this.getOptions().resizable) {
      return this._repositionResizers();
    }
  };

  KDSplitView.prototype.mouseUp = function(event) {
    this.$().unbind("mousemove.resizeHandle");
    return this._resizeDidStop(event);
  };

  KDSplitView.prototype._panelReachedMinimum = function(panelIndex) {
    this.panels[panelIndex].emit("PanelReachedMinimum");
    return this.emit("PanelReachedMinimum", {
      panel: this.panels[panelIndex]
    });
  };

  KDSplitView.prototype._panelReachedMaximum = function(panelIndex) {
    this.panels[panelIndex].emit("PanelReachedMaximum");
    return this.emit("PanelReachedMaximum", {
      panel: this.panels[panelIndex]
    });
  };

  KDSplitView.prototype._resizeDidStart = function(event) {
    $('body').addClass("resize-in-action");
    return this.emit("ResizeDidStart", {
      orgEvent: event
    });
  };

  KDSplitView.prototype._resizeDidStop = function(event) {
    this.emit("ResizeDidStop", {
      orgEvent: event
    });
    return this.utils.wait(300, function() {
      return $('body').removeClass("resize-in-action");
    });
  };


  /* PUBLIC METHODS */

  KDSplitView.prototype.isVertical = function() {
    return this.getOptions().type === "vertical";
  };

  KDSplitView.prototype.getPanelIndex = function(panel) {
    var i, p, _i, _len, _ref;
    _ref = this.panels;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      p = _ref[i];
      if (p.getId() === panel.getId()) {
        return i;
      }
    }
  };

  KDSplitView.prototype.hidePanel = function(panelIndex, callback) {
    var panel;
    if (callback == null) {
      callback = noop;
    }
    panel = this.panels[panelIndex];
    panel._lastSize = panel._getSize();
    return this.resizePanel(0, panelIndex, (function(_this) {
      return function() {
        return callback.call(_this, {
          panel: panel,
          index: panelIndex
        });
      };
    })(this));
  };

  KDSplitView.prototype.showPanel = function(panelIndex, callback) {
    var newSize, panel;
    if (callback == null) {
      callback = noop;
    }
    panel = this.panels[panelIndex];
    newSize = panel._lastSize || this.getOptions().sizes[panelIndex] || 200;
    panel._lastSize = null;
    return this.resizePanel(newSize, panelIndex, function() {
      return callback.call(this, {
        panel: panel,
        index: panelIndex
      });
    });
  };

  KDSplitView.prototype.resizePanel = function(value, panelIndex, callback) {
    var isReverse, p0offset, p0size, p1index, p1newSize, p1offset, p1size, panel0, panel1, race, raceCounter, resizer, surplus, totalActionArea;
    if (value == null) {
      value = 0;
    }
    if (panelIndex == null) {
      panelIndex = 0;
    }
    if (callback == null) {
      callback = noop;
    }
    this._resizeDidStart();
    value = this._sanitizeSize(value);
    panel0 = this.panels[panelIndex];
    isReverse = false;
    if (panel0.size === value) {
      this._resizeDidStop();
      callback();
      return;
    }
    panel1 = this.panels.length - 1 !== panelIndex ? (p1index = panelIndex + 1, this.getOptions().resizable ? resizer = this.resizers[panelIndex] : void 0, this.panels[p1index]) : (isReverse = true, p1index = panelIndex - 1, this.getOptions().resizable ? resizer = this.resizers[p1index] : void 0, this.panels[p1index]);
    totalActionArea = panel0.size + panel1.size;
    if (value > totalActionArea) {
      return false;
    }
    p0size = this._getLegitPanelSize(value, panelIndex);
    surplus = panel0.size - p0size;
    p1newSize = panel1.size + surplus;
    p1size = this._getLegitPanelSize(p1newSize, p1index);
    raceCounter = 0;
    race = (function(_this) {
      return function() {
        raceCounter++;
        if (raceCounter === 2) {
          _this._resizeDidStop();
          return callback();
        }
      };
    })(this);
    if (!isReverse) {
      p1offset = panel1._getOffset() - surplus;
      if (this.getOptions().animated) {
        panel0._animateTo(p0size, race);
        panel1._animateTo(p1size, p1offset, race);
        if (resizer) {
          return resizer._animateTo(p1offset);
        }
      } else {
        panel0._setSize(p0size);
        race();
        panel1._setSize(p1size, panel1._setOffset(p1offset));
        race();
        if (resizer) {
          return resizer._setOffset(p1offset);
        }
      }
    } else {
      p0offset = panel0._getOffset() + surplus;
      if (this.getOptions().animated) {
        panel0._animateTo(p0size, p0offset, race);
        panel1._animateTo(p1size, race);
        if (resizer) {
          return resizer._animateTo(p0offset);
        }
      } else {
        panel0._setSize(p0size);
        panel0._setOffset(p0offset);
        race();
        panel1._setSize(p1size);
        race();
        if (resizer) {
          return resizer._setOffset(p0offset);
        }
      }
    }
  };

  KDSplitView.prototype.splitPanel = function(index, options) {
    var i, isLastPanel, newIndex, newPanel, newPanelOptions, newResizer, newSize, o, oldResizer, panel, panelToBeSplitted, _i, _len, _ref;
    newPanelOptions = {};
    o = this.getOptions();
    isLastPanel = this.resizers[index] ? false : true;
    panelToBeSplitted = this.panels[index];
    this.panels.splice(index + 1, 0, newPanel = this._createPanel(index));
    this.sizes.splice(index + 1, 0, this.sizes[index] / 2);
    this.sizes[index] = this.sizes[index] / 2;
    o.minimums.splice(index + 1, 0, newPanelOptions.minimum);
    o.maximums.splice(index + 1, 0, newPanelOptions.maximum);
    o.views.splice(index + 1, 0, newPanelOptions.view);
    o.sizes = this.sizes;
    this.subViews.push(newPanel);
    newPanel.setParent(this);
    panelToBeSplitted.$().after(newPanel.$());
    newPanel.emit('viewAppended');
    newSize = panelToBeSplitted._getSize() / 2;
    panelToBeSplitted._setSize(newSize);
    newPanel._setSize(newSize);
    newPanel._setOffset(panelToBeSplitted._getOffset() + newSize);
    this._calculatePanelBounds();
    _ref = this.panels.slice(index + 1, this.panels.length);
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      panel = _ref[i];
      panel.index = newIndex = index + 1 + i;
      panel.unsetClass("panel-" + (index + i)).setClass("panel-" + newIndex);
    }
    if (this.getOptions().resizable) {
      if (!isLastPanel) {
        oldResizer = this.resizers[index];
        oldResizer._setOffset(this.panelsBounds[index + 1]);
        oldResizer.panel0 = panelToBeSplitted;
        oldResizer.panel1 = newPanel;
        this.resizers.splice(index + 1, 0, newResizer = this._createResizer(index + 2));
        newResizer._setOffset(this.panelsBounds[index + 2]);
      } else {
        this.resizers.push(newResizer = this._createResizer(index + 1));
        newResizer._setOffset(this.panelsBounds[index + 1]);
      }
    }
    this.emit("panelSplitted", newPanel);
    return newPanel;
  };

  KDSplitView.prototype.removePanel = function(index) {
    var l, panel, r, res;
    l = this.panels.length;
    if (l === 1) {
      warn("this is the only panel left");
      return false;
    }
    panel = this.panels[index];
    panel.destroy();
    if (index === 0) {
      r = this.resizers.shift();
      r.destroy();
      if (res = this.resizers[0]) {
        res.panel0 = this.panels[0];
        res.panel1 = this.panels[1];
      }
    } else if (index === l - 1) {
      r = this.resizers.pop();
      r.destroy();
      if (res = this.resizers[l - 2]) {
        res.panel0 = this.panels[l - 2];
        res.panel1 = this.panels[l - 1];
      }
    } else {
      r = this.resizers.splice(index - 1, 1)[0];
      r.destroy();
      this.resizers[index - 1].panel0 = this.panels[index - 1];
      this.resizers[index - 1].panel1 = this.panels[index];
    }
    return true;
  };

  KDSplitView.prototype.setView = function(view, index) {
    if (index > this.panels.length || !view) {
      warn("Either 'view' or 'index' is missing at KDSplitView::setView!");
      return;
    }
    return this.panels[index].addSubView(view);
  };

  return KDSplitView;

})(KDView);


},{"./../../core/kd.coffee":100,"./../../core/view.coffee":108,"./splitpanel.coffee":75,"./splitresizer.coffee":76}],78:[function(require,module,exports){
var KDTabHandleContainer, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDTabHandleContainer = (function(_super) {
  __extends(KDTabHandleContainer, _super);

  function KDTabHandleContainer(options, data) {
    if (options == null) {
      options = {};
    }
    KDTabHandleContainer.__super__.constructor.call(this, options, data);
    this.tabs = new KDView({
      cssClass: 'kdtabhandle-tabs clearfix'
    });
  }

  KDTabHandleContainer.prototype.viewAppended = function() {
    return this.addSubView(this.tabs);
  };

  return KDTabHandleContainer;

})(KDView);


},{"./../../core/view.coffee":108}],79:[function(require,module,exports){
var KDCustomHTMLView, KDTabHandleMoveNav,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDCustomHTMLView = require('./../../core/customhtmlview.coffee');

module.exports = KDTabHandleMoveNav = (function(_super) {
  __extends(KDTabHandleMoveNav, _super);

  function KDTabHandleMoveNav(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass = KD.utils.curry('kdtabhandle-movenav', options.cssClass);
    KDTabHandleMoveNav.__super__.constructor.call(this, options, data);
    this._current = 0;
  }

  KDTabHandleMoveNav.prototype.viewAppended = function() {
    this.addSubView(this.left = new KDCustomHTMLView({
      cssClass: 'leftButton',
      click: (function(_this) {
        return function() {
          return _this.move('right');
        };
      })(this)
    }));
    this.addSubView(this.right = new KDCustomHTMLView({
      cssClass: 'rightButton',
      click: (function(_this) {
        return function() {
          return _this.move('left');
        };
      })(this)
    }));
    return this.listenWindowResize();
  };

  KDTabHandleMoveNav.prototype._windowDidResize = function() {
    var delegate;
    delegate = this.getDelegate();
    if (!(delegate.getWidth() > delegate._tabsWidth + 50)) {
      return this.show();
    } else {
      this.move('initial');
      return this.hide();
    }
  };

  KDTabHandleMoveNav.prototype.move = function(direction) {
    var delegate, handleWidth, tabHandleContainer;
    tabHandleContainer = (delegate = this.getDelegate()).tabHandleContainer;
    handleWidth = delegate.getOption('maxHandleWidth');
    switch (direction) {
      case 'left':
        if (handleWidth * delegate.handles.length + 100 < tabHandleContainer.getWidth() - this._current) {
          return;
        }
        this._current -= handleWidth;
        break;
      case 'right':
        if (this._current === 0) {
          return;
        }
        this._current += handleWidth;
        break;
      case 'initial':
        this._current = 0;
    }
    return tabHandleContainer.tabs.setCss('marginLeft', "" + this._current + "px");
  };

  return KDTabHandleMoveNav;

})(KDCustomHTMLView);


},{"./../../core/customhtmlview.coffee":97}],80:[function(require,module,exports){
var KDTabHandleView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDTabHandleView = (function(_super) {
  __extends(KDTabHandleView, _super);

  function KDTabHandleView(options, data) {
    if (options == null) {
      options = {};
    }
    if (options.hidden == null) {
      options.hidden = false;
    }
    options.title || (options.title = "Title");
    if (options.pane == null) {
      options.pane = null;
    }
    if (options.view == null) {
      options.view = null;
    }
    if (options.sortable == null) {
      options.sortable = false;
    }
    if (options.closable == null) {
      options.closable = true;
    }
    if (options.addTitleAttribute == null) {
      options.addTitleAttribute = true;
    }
    if (options.sortable) {
      options.draggable = {
        axis: "x"
      };
      this.dragStartPosX = null;
    }
    KDTabHandleView.__super__.constructor.call(this, options, data);
    this.on("DragStarted", (function(_this) {
      return function(event, dragState) {
        _this.startedDragFromCloseElement = $(event.target).hasClass("close-tab");
        return _this.handleDragStart(event, dragState);
      };
    })(this));
    this.on("DragInAction", (function(_this) {
      return function(x, y) {
        if (_this.startedDragFromCloseElement) {
          _this.dragIsAllowed = false;
        }
        return _this.handleDragInAction(x, y);
      };
    })(this));
    this.on("DragFinished", (function(_this) {
      return function(event) {
        _this.handleDragFinished(event);
        return _this.getDelegate().showPaneByIndex(_this.index);
      };
    })(this));
  }

  KDTabHandleView.prototype.setDomElement = function(cssClass) {
    var addTitleAttribute, closable, closeHandle, hidden, tagName, title, _ref;
    if (cssClass == null) {
      cssClass = "";
    }
    _ref = this.getOptions(), hidden = _ref.hidden, closable = _ref.closable, tagName = _ref.tagName, title = _ref.title, addTitleAttribute = _ref.addTitleAttribute;
    cssClass = hidden ? "" + cssClass + " hidden" : cssClass;
    closeHandle = closable ? "<span class='close-tab'></span>" : "";
    title = addTitleAttribute ? "title='" + title + "'" : "";
    return this.domElement = $("<" + tagName + " " + title + " class='kdtabhandle " + cssClass + "'>" + closeHandle + "</" + tagName + ">");
  };

  KDTabHandleView.prototype.viewAppended = function() {
    var view;
    view = this.getOptions().view;
    if (view && view instanceof KDView) {
      return this.addSubView(view);
    } else {
      return this.setPartial(this.partial());
    }
  };

  KDTabHandleView.prototype.partial = function() {
    return "<b>" + (this.getOptions().title || 'Default Title') + "</b>";
  };

  KDTabHandleView.prototype.makeActive = function() {
    return this.getDomElement().addClass("active");
  };

  KDTabHandleView.prototype.makeInactive = function() {
    return this.getDomElement().removeClass("active");
  };

  KDTabHandleView.prototype.setTitle = function(title) {
    return this.setAttribute("title", title);
  };

  KDTabHandleView.prototype.isHidden = function() {
    return this.getOptions().hidden;
  };

  KDTabHandleView.prototype.getWidth = function() {
    return this.$().outerWidth(false) || 0;
  };

  KDTabHandleView.prototype.cloneElement = function(x) {
    var holder, pane, tabView;
    if (this.$cloned) {
      return;
    }
    pane = this.getOptions().pane;
    tabView = pane.getDelegate();
    holder = tabView.tabHandleContainer;
    this.$cloned = this.$().clone();
    holder.$().append(this.$cloned);
    return this.$cloned.css({
      marginLeft: -(tabView.handles.length - this.index) * this.getWidth()
    });
  };

  KDTabHandleView.prototype.updateClonedElementPosition = function(x) {
    return this.$cloned.css({
      left: x
    });
  };

  KDTabHandleView.prototype.reorderTabHandles = function(x) {
    var dragDir, targetDiff, targetIndex, width;
    dragDir = this.dragState.direction;
    width = this.getWidth();
    if (dragDir.current.x === 'left') {
      targetIndex = this.index - 1;
      targetDiff = -(width * this.draggedItemIndex - width * targetIndex - width / 2);
      if (x < targetDiff) {
        this.emit("HandleIndexHasChanged", this.index, 'left');
        return this.index--;
      }
    } else {
      targetIndex = this.index + 1;
      targetDiff = width * targetIndex - width * this.draggedItemIndex - width / 2;
      if (x > targetDiff) {
        this.emit("HandleIndexHasChanged", this.index, 'right');
        return this.index++;
      }
    }
  };

  KDTabHandleView.prototype.handleDragStart = function(event, dragState) {
    var handles, pane, tabView;
    pane = this.getOptions().pane;
    tabView = pane.getDelegate();
    handles = tabView.handles;
    this.index = handles.indexOf(this);
    return this.draggedItemIndex = this.index;
  };

  KDTabHandleView.prototype.handleDragInAction = function(x, y) {
    if (!this.dragIsAllowed) {
      return;
    }
    if (-(this.draggedItemIndex * this.getWidth()) > x) {
      return this.$().css({
        'left': 0
      });
    }
    this.unsetClass('first');
    this.cloneElement(x);
    this.$().css({
      opacity: 0
    });
    this.updateClonedElementPosition(x);
    return this.reorderTabHandles(x);
  };

  KDTabHandleView.prototype.handleDragFinished = function(event) {
    if (!this.$cloned) {
      return;
    }
    this.$cloned.remove();
    this.$().css({
      left: '',
      opacity: 1,
      marginLeft: ''
    });
    if (!this.targetTabHandle && this.draggedItemIndex === 0) {
      this.$().css({
        left: 0
      });
    }
    this.targetTabHandle = null;
    return this.$cloned = null;
  };

  return KDTabHandleView;

})(KDView);


},{"./../../core/view.coffee":108}],81:[function(require,module,exports){
var KDTabPaneView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDTabPaneView = (function(_super) {
  __extends(KDTabPaneView, _super);

  function KDTabPaneView(options, data) {
    var defaultCssClass;
    if (options == null) {
      options = {};
    }
    if (options.hiddenHandle == null) {
      options.hiddenHandle = false;
    }
    options.name || (options.name = "");
    defaultCssClass = "kdtabpaneview kdhiddentab " + (KD.utils.slugify(options.name.toLowerCase())) + " clearfix";
    options.cssClass = KD.utils.curry(defaultCssClass, options.cssClass);
    KDTabPaneView.__super__.constructor.call(this, options, data);
    this.name = options.name;
    this.lastScrollTops = {
      window: 0,
      parent: 0,
      self: 0,
      body: 0
    };
    this.on("KDTabPaneActive", this.bound("setMainView"));
    this.on("KDTabPaneLazyViewAdded", this.bound("fireLazyCallback"));
  }

  KDTabPaneView.prototype.show = function() {
    var _ref;
    this.setClass("active");
    this.unsetClass("kdhiddentab");
    if (this.getOption("detachable")) {
      if ((_ref = this.parent) != null) {
        _ref.getElement().appendChild(this.getElement());
      }
    }
    this.active = true;
    this.emit("KDTabPaneActive");
    return KD.utils.defer((function(_this) {
      return function() {
        var _ref1;
        _this.getElement().scrollTop = _this.lastScrollTops.self;
        return (_ref1 = _this.parent) != null ? _ref1.getElement().scrollTop = _this.lastScrollTops.parent : void 0;
      };
    })(this));
  };

  KDTabPaneView.prototype.hide = function() {
    var _ref, _ref1;
    if (!this.active) {
      return;
    }
    this.lastScrollTops.parent = ((_ref = this.parent) != null ? _ref.getElement().scrollTop : void 0) || 0;
    this.lastScrollTops.self = this.getElement().scrollTop;
    this.setClass("kdhiddentab");
    this.unsetClass("active");
    if (this.active && this.getOption("detachable")) {
      if ((_ref1 = this.parent) != null) {
        _ref1.getElement().removeChild(this.getElement());
      }
    }
    this.active = false;
    return this.emit("KDTabPaneInactive");
  };

  KDTabPaneView.prototype.setTitle = function(title) {
    this.getDelegate().setPaneTitle(this, title);
    return this.name = title;
  };

  KDTabPaneView.prototype.getHandle = function() {
    return this.getDelegate().getHandleByPane(this);
  };

  KDTabPaneView.prototype.hideTabCloseIcon = function() {
    return this.getDelegate().hideCloseIcon(this);
  };

  KDTabPaneView.prototype.setMainView = function(view) {
    var data, options, viewClass, viewOptions, _ref;
    if (!view) {
      _ref = this.getOptions(), view = _ref.view, viewOptions = _ref.viewOptions;
    }
    if (this.mainView) {
      return;
    }
    if (!(view || viewOptions)) {
      return;
    }
    if (view instanceof KDView) {
      this.mainView = this.addSubView(view);
    } else if (viewOptions) {
      viewClass = viewOptions.viewClass, options = viewOptions.options, data = viewOptions.data;
      this.mainView = this.addSubView(new viewClass(options, data));
    } else {
      return warn("probably you set a weird lazy view!");
    }
    this.emit("KDTabPaneLazyViewAdded", this, this.mainView);
    return this.mainView;
  };

  KDTabPaneView.prototype.getMainView = function() {
    return this.mainView;
  };

  KDTabPaneView.prototype.destroyMainView = function() {
    this.mainView.destroy();
    return delete this.mainView;
  };

  KDTabPaneView.prototype.fireLazyCallback = function(pane, view) {
    var callback, viewOptions;
    viewOptions = this.getOptions().viewOptions;
    if (!viewOptions) {
      return;
    }
    callback = viewOptions.callback;
    if (!callback) {
      return;
    }
    return callback.call(this, pane, view);
  };

  return KDTabPaneView;

})(KDView);


},{"./../../core/view.coffee":108}],82:[function(require,module,exports){
var KDScrollView, KDTabHandleContainer, KDTabHandleMoveNav, KDTabView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDScrollView = require('./../scrollview/scrollview.coffee');

KDTabHandleContainer = require('./tabhandlecontainer.coffee');

KDTabHandleMoveNav = require('./tabhandlemovenav.coffee');

module.exports = KDTabView = (function(_super) {
  __extends(KDTabView, _super);

  function KDTabView(options, data) {
    var _ref;
    if (options == null) {
      options = {};
    }
    if (options.resizeTabHandles == null) {
      options.resizeTabHandles = false;
    }
    if (options.maxHandleWidth == null) {
      options.maxHandleWidth = 128;
    }
    if (options.minHandleWidth == null) {
      options.minHandleWidth = 30;
    }
    if (options.lastTabHandleMargin == null) {
      options.lastTabHandleMargin = 0;
    }
    if (options.sortable == null) {
      options.sortable = false;
    }
    if (options.hideHandleContainer == null) {
      options.hideHandleContainer = false;
    }
    if (options.hideHandleCloseIcons == null) {
      options.hideHandleCloseIcons = false;
    }
    if (options.enableMoveTabHandle == null) {
      options.enableMoveTabHandle = false;
    }
    if (options.detachPanes == null) {
      options.detachPanes = true;
    }
    if (options.tabHandleContainer == null) {
      options.tabHandleContainer = null;
    }
    options.tabHandleClass || (options.tabHandleClass = KDTabHandleView);
    options.paneData || (options.paneData = []);
    options.cssClass = KD.utils.curry("kdtabview", options.cssClass);
    this.handles = [];
    this.panes = [];
    this.selectedIndex = [];
    this.tabConstructor = (_ref = options.tabClass) != null ? _ref : KDTabPaneView;
    this.lastOpenPaneIndex = 0;
    KDTabView.__super__.constructor.call(this, options, data);
    this.activePane = null;
    this.handlesHidden = false;
    this.blockTabHandleResize = false;
    this.setTabHandleContainer(options.tabHandleContainer);
    if (options.enableMoveTabHandle) {
      this.setTabHandleMoveNav();
    }
    if (options.hideHandleCloseIcons) {
      this.hideHandleCloseIcons();
    }
    if (options.hideHandleContainer) {
      this.hideHandleContainer();
    }
    this.on("PaneRemoved", (function(_this) {
      return function() {
        return _this.resizeTabHandles();
      };
    })(this));
    this.on("PaneAdded", (function(_this) {
      return function() {
        _this.blockTabHandleResize = false;
        return _this.resizeTabHandles();
      };
    })(this));
    this.on("PaneDidShow", this.bound("setActivePane"));
    if (options.paneData.length > 0) {
      this.on("viewAppended", (function(_this) {
        return function() {
          return _this.createPanes(options.paneData);
        };
      })(this));
    }
    this.tabHandleContainer.on("mouseleave", (function(_this) {
      return function() {
        if (_this.blockTabHandleResize) {
          _this.blockTabHandleResize = false;
          return _this.resizeTabHandles();
        }
      };
    })(this));
  }

  KDTabView.prototype.createPanes = function(paneData) {
    var paneOptions, _i, _len, _results;
    if (paneData == null) {
      paneData = this.getOptions().paneData;
    }
    _results = [];
    for (_i = 0, _len = paneData.length; _i < _len; _i++) {
      paneOptions = paneData[_i];
      _results.push(this.addPane(new this.tabConstructor(paneOptions, null)));
    }
    return _results;
  };

  KDTabView.prototype.addPane = function(paneInstance, shouldShow) {
    var closable, detachPanes, hiddenHandle, lazy, maxHandleWidth, minHandleWidth, name, newTabHandle, sortable, tabHandleClass, tabHandleView, title, _ref, _ref1, _ref2;
    if (shouldShow == null) {
      shouldShow = true;
    }
    if (paneInstance instanceof KDTabPaneView) {
      _ref = this.getOptions(), tabHandleClass = _ref.tabHandleClass, sortable = _ref.sortable, detachPanes = _ref.detachPanes;
      paneInstance.setOption("detachable", detachPanes);
      this.panes.push(paneInstance);
      _ref1 = paneInstance.getOptions(), name = _ref1.name, title = _ref1.title, hiddenHandle = _ref1.hiddenHandle, tabHandleView = _ref1.tabHandleView, closable = _ref1.closable, lazy = _ref1.lazy;
      this.addHandle(newTabHandle = new tabHandleClass({
        pane: paneInstance,
        title: name || title,
        hidden: hiddenHandle,
        cssClass: KD.utils.slugify(name.toLowerCase()),
        view: tabHandleView,
        closable: closable,
        sortable: sortable,
        click: (function(_this) {
          return function(event) {
            return _this.handleMouseDownDefaultAction(newTabHandle, event);
          };
        })(this)
      }));
      paneInstance.tabHandle = newTabHandle;
      this.appendPane(paneInstance);
      if (shouldShow && !lazy) {
        this.showPane(paneInstance);
      }
      this.emit("PaneAdded", paneInstance);
      _ref2 = this.getOptions(), minHandleWidth = _ref2.minHandleWidth, maxHandleWidth = _ref2.maxHandleWidth;
      newTabHandle.getDomElement().css({
        maxWidth: maxHandleWidth,
        minWidth: minHandleWidth
      });
      newTabHandle.on("HandleIndexHasChanged", this.bound("resortTabHandles"));
      return paneInstance;
    } else {
      name = ((paneInstance != null ? paneInstance.constructor : void 0) != null).name;
      warn("You can't add " + (name ? name : void 0) + " as a pane, use KDTabPaneView instead");
      return false;
    }
  };

  KDTabView.prototype.resortTabHandles = function(index, dir) {
    var methodName, newIndex, splicedHandle, splicedPane, targetIndex;
    if ((index === 0 && dir === 'left') || (index === this.handles.length - 1 && dir === 'right') || (index >= this.handles.length) || (index < 0)) {
      return;
    }
    this.handles[0].unsetClass('first');
    if (dir === 'right') {
      methodName = 'insertAfter';
      targetIndex = index + 1;
    } else {
      methodName = 'insertBefore';
      targetIndex = index - 1;
    }
    this.handles[index].$()[methodName](this.handles[targetIndex].$());
    newIndex = dir === 'left' ? index - 1 : index + 1;
    splicedHandle = this.handles.splice(index, 1);
    splicedPane = this.panes.splice(index, 1);
    this.handles.splice(newIndex, 0, splicedHandle[0]);
    this.panes.splice(newIndex, 0, splicedPane[0]);
    this.handles[0].setClass('first');
    return this.emit('TabsSorted');
  };

  KDTabView.prototype.removePane = function(pane) {
    var firstPane, handle, index, isActivePane, prevPane;
    pane.emit("KDTabPaneDestroy");
    index = this.getPaneIndex(pane);
    isActivePane = this.getActivePane() === pane;
    this.panes.splice(index, 1);
    pane.destroy();
    handle = this.getHandleByIndex(index);
    this.handles.splice(index, 1);
    handle.destroy();
    if (isActivePane) {
      if (prevPane = this.getPaneByIndex(this.lastOpenPaneIndex)) {
        this.showPane(prevPane);
      } else if (firstPane = this.getPaneByIndex(0)) {
        this.showPane(firstPane);
      }
    }
    return this.emit("PaneRemoved");
  };

  KDTabView.prototype.removePaneByName = function(name) {
    var pane, _i, _len, _ref, _results;
    _ref = this.panes;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      pane = _ref[_i];
      if (pane.name === name) {
        this.removePane(pane);
        break;
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  KDTabView.prototype.appendHandleContainer = function() {
    return this.addSubView(this.tabHandleContainer);
  };

  KDTabView.prototype.appendPane = function(pane) {
    pane.setDelegate(this);
    return this.addSubView(pane);
  };

  KDTabView.prototype.appendHandle = function(tabHandle) {
    var enableMoveTabHandle, maxHandleWidth, _ref;
    this.handleHeight || (this.handleHeight = this.tabHandleContainer.getHeight());
    tabHandle.setDelegate(this);
    this.tabHandleContainer.tabs.addSubView(tabHandle);
    _ref = this.getOptions(), enableMoveTabHandle = _ref.enableMoveTabHandle, maxHandleWidth = _ref.maxHandleWidth;
    if (enableMoveTabHandle) {
      return this._tabsWidth = this.handles.length * maxHandleWidth;
    }
  };

  KDTabView.prototype.addHandle = function(handle) {
    var name;
    if (handle instanceof KDTabHandleView) {
      this.handles.push(handle);
      this.appendHandle(handle);
      if (handle.getOptions().hidden) {
        handle.setClass("hidden");
      }
      return handle;
    } else {
      name = ((handle != null ? handle.constructor : void 0) != null).name;
      return warn("You can't add " + (name != null ? name : void 0) + " as a pane, use KDTabHandleView instead");
    }
  };

  KDTabView.prototype.removeHandle = function() {};

  KDTabView.prototype.showPane = function(pane) {
    var activePane, handle, index;
    if (!pane) {
      return;
    }
    activePane = this.getActivePane();
    if (pane === activePane) {
      return;
    }
    if (activePane) {
      this.lastOpenPaneIndex = this.getPaneIndex(activePane);
    }
    this.hideAllPanes();
    pane.show();
    index = this.getPaneIndex(pane);
    handle = this.getHandleByIndex(index);
    handle.makeActive();
    pane.emit("PaneDidShow");
    this.emit("PaneDidShow", pane, index);
    return pane;
  };

  KDTabView.prototype.hideAllPanes = function() {
    var handle, pane, _i, _j, _len, _len1, _ref, _ref1, _results;
    _ref = this.panes;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      pane = _ref[_i];
      if (pane) {
        pane.hide();
      }
    }
    _ref1 = this.handles;
    _results = [];
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      handle = _ref1[_j];
      if (handle) {
        _results.push(handle.makeInactive());
      }
    }
    return _results;
  };

  KDTabView.prototype.hideHandleContainer = function() {
    this.tabHandleContainer.hide();
    return this.handlesHidden = true;
  };

  KDTabView.prototype.showHandleContainer = function() {
    this.tabHandleContainer.show();
    return this.handlesHidden = false;
  };

  KDTabView.prototype.toggleHandleContainer = function(duration) {
    if (duration == null) {
      duration = 0;
    }
    return this.tabHandleContainer.$().toggle(duration);
  };

  KDTabView.prototype.hideHandleCloseIcons = function() {
    return this.tabHandleContainer.$().addClass("hide-close-icons");
  };

  KDTabView.prototype.showHandleCloseIcons = function() {
    return this.tabHandleContainer.$().removeClass("hide-close-icons");
  };

  KDTabView.prototype.handleMouseDownDefaultAction = function(clickedTabHandle, event) {
    var handle, index, _i, _len, _ref, _results;
    _ref = this.handles;
    _results = [];
    for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
      handle = _ref[index];
      if (clickedTabHandle === handle) {
        _results.push(this.handleClicked(index, event));
      }
    }
    return _results;
  };

  KDTabView.prototype.handleClicked = function(index, event) {
    var pane;
    pane = this.getPaneByIndex(index);
    if ($(event.target).hasClass("close-tab")) {
      this.blockTabHandleResize = true;
      this.removePane(pane);
      return false;
    }
    return this.showPane(pane);
  };

  KDTabView.prototype.setTabHandleContainer = function(aViewInstance) {
    if (aViewInstance != null) {
      if (this.tabHandleContainer != null) {
        this.tabHandleContainer.destroy();
      }
      this.tabHandleContainer = aViewInstance;
    } else {
      this.tabHandleContainer = new KDTabHandleContainer;
      this.appendHandleContainer();
    }
    return this.tabHandleContainer.setClass("kdtabhandlecontainer");
  };

  KDTabView.prototype.getTabHandleContainer = function() {
    return this.tabHandleContainer;
  };

  KDTabView.prototype.setTabHandleMoveNav = function() {
    return this.tabHandleContainer.addSubView(new KDTabHandleMoveNav({
      delegate: this
    }));
  };

  KDTabView.prototype.checkPaneExistenceById = function(id) {
    var pane, result, _i, _len, _ref;
    result = false;
    _ref = this.panes;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      pane = _ref[_i];
      if (pane.id === id) {
        result = true;
      }
    }
    return result;
  };

  KDTabView.prototype.getPaneByName = function(name) {
    var pane, result, _i, _len, _ref;
    result = false;
    _ref = this.panes;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      pane = _ref[_i];
      if (pane.name === name) {
        result = pane;
      }
    }
    return result;
  };

  KDTabView.prototype.getPaneById = function(id) {
    var pane, paneInstance, _i, _len, _ref;
    paneInstance = null;
    _ref = this.panes;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      pane = _ref[_i];
      if (pane.id === id) {
        paneInstance = pane;
      }
    }
    return paneInstance;
  };

  KDTabView.prototype.getActivePane = function() {
    return this.activePane;
  };

  KDTabView.prototype.getActivePaneIndex = function() {
    return this.getPaneIndex(this.getActivePane());
  };

  KDTabView.prototype.setActivePane = function(activePane) {
    this.activePane = activePane;
  };

  KDTabView.prototype.getPaneByIndex = function(index) {
    return this.panes[index];
  };

  KDTabView.prototype.getHandleByIndex = function(index) {
    return this.handles[index];
  };

  KDTabView.prototype.getPaneIndex = function(aPane) {
    if (!aPane) {
      throw new Error("no pane provided!");
    }
    return this.panes.indexOf(aPane);
  };

  KDTabView.prototype.showPaneByIndex = function(index) {
    return this.showPane(this.getPaneByIndex(index));
  };

  KDTabView.prototype.showPaneByName = function(name) {
    return this.showPane(this.getPaneByName(name));
  };

  KDTabView.prototype.showNextPane = function() {
    var activeIndex, activePane;
    activePane = this.getActivePane();
    activeIndex = this.getPaneIndex(activePane);
    return this.showPane(this.getPaneByIndex(activeIndex + 1));
  };

  KDTabView.prototype.showPreviousPane = function() {
    var activeIndex, activePane;
    activePane = this.getActivePane();
    activeIndex = this.getPaneIndex(activePane);
    return this.showPane(this.getPaneByIndex(activeIndex - 1));
  };

  KDTabView.prototype.setPaneTitle = function(pane, title) {
    var handle;
    handle = this.getHandleByPane(pane);
    handle.getDomElement().find("b").text(title);
    return handle.setAttribute("title", title);
  };

  KDTabView.prototype.getHandleByPane = function(pane) {
    var handle, index;
    index = this.getPaneIndex(pane);
    return handle = this.getHandleByIndex(index);
  };

  KDTabView.prototype.hideCloseIcon = function(pane) {
    var handle, index;
    index = this.getPaneIndex(pane);
    handle = this.getHandleByIndex(index);
    return handle.getDomElement().addClass("hide-close-icon");
  };

  KDTabView.prototype.getVisibleHandles = function() {
    return this.handles.filter(function(handle) {
      return handle.isHidden() === false;
    });
  };

  KDTabView.prototype.getVisibleTabs = function() {
    return this.panes.filter(function(pane) {
      return pane.tabHandle.isHidden() === false;
    });
  };

  KDTabView.prototype.resizeTabHandles = function() {
    var containerMargin, containerSize, handle, lastTabHandleMargin, outerWidth, possiblePercent, visibleHandles, visibleTotalSize, _i, _j, _len, _len1, _ref, _results;
    if (!this.getOptions().resizeTabHandles || this._tabHandleContainerHidden || this.blockTabHandleResize) {
      return;
    }
    lastTabHandleMargin = this.getOptions().lastTabHandleMargin;
    visibleHandles = [];
    visibleTotalSize = 0;
    outerWidth = this.tabHandleContainer.tabs.getElement().offsetWidth;
    if (outerWidth <= 0) {
      return;
    }
    containerSize = outerWidth - lastTabHandleMargin;
    containerMargin = 100 - (100 * lastTabHandleMargin / containerSize);
    _ref = this.handles;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      handle = _ref[_i];
      if (!(!handle.isHidden())) {
        continue;
      }
      visibleHandles.push(handle);
      visibleTotalSize += handle.getElement().offsetWidth;
    }
    possiblePercent = (containerMargin / visibleHandles.length).toFixed(2);
    _results = [];
    for (_j = 0, _len1 = visibleHandles.length; _j < _len1; _j++) {
      handle = visibleHandles[_j];
      _results.push(handle.setWidth(possiblePercent, "%"));
    }
    return _results;
  };

  return KDTabView;

})(KDScrollView);


},{"./../scrollview/scrollview.coffee":69,"./tabhandlecontainer.coffee":78,"./tabhandlemovenav.coffee":79}],83:[function(require,module,exports){
var KDFormViewWithFields, KDTabPaneView, KDTabView, KDTabViewWithForms,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDTabView = require('./tabview.coffee');

KDTabPaneView = require('./tabpaneview.coffee');

KDFormViewWithFields = require('./../forms/formviewwithfields.coffee');

module.exports = KDTabViewWithForms = (function(_super) {
  __extends(KDTabViewWithForms, _super);

  function KDTabViewWithForms(options, data) {
    var forms;
    if (options == null) {
      options = {};
    }
    if (options.navigable == null) {
      options.navigable = true;
    }
    if (options.goToNextFormOnSubmit == null) {
      options.goToNextFormOnSubmit = true;
    }
    KDTabViewWithForms.__super__.constructor.call(this, options, data);
    this.forms = {};
    this.hideHandleCloseIcons();
    forms = this.getOptions().forms;
    if (forms) {
      this.createTabs(forms = KDFormViewWithFields.sanitizeFormOptions(forms));
      this.showPane(this.panes[0]);
    }
    if (forms.length === 1) {
      this.hideHandleContainer();
    }
  }

  KDTabViewWithForms.prototype.handleClicked = function(index, event) {
    if (this.getOptions().navigable) {
      return KDTabViewWithForms.__super__.handleClicked.apply(this, arguments);
    }
  };

  KDTabViewWithForms.prototype.createTab = function(formData, index) {
    var oldCallback, tab;
    this.addPane((tab = new KDTabPaneView({
      name: formData.title
    })), formData.shouldShow);
    oldCallback = formData.callback;
    formData.callback = (function(_this) {
      return function(formData) {
        var forms;
        if (_this.getOptions().goToNextFormOnSubmit) {
          _this.showNextPane();
        }
        if (typeof oldCallback === "function") {
          oldCallback(formData);
        }
        forms = _this.getOptions().forms;
        if (forms && index === Object.keys(forms).length - 1) {
          return _this.fireFinalCallback();
        }
      };
    })(this);
    this.createForm(formData, tab);
    return tab;
  };

  KDTabViewWithForms.prototype.createTabs = function(forms) {
    return forms.forEach((function(_this) {
      return function(formData, i) {
        return _this.createTab(formData, i);
      };
    })(this));
  };

  KDTabViewWithForms.prototype.createForm = function(formData, parentTab) {
    var form;
    parentTab.addSubView(form = new KDFormViewWithFields(formData));
    this.forms[formData.title] = parentTab.form = form;
    return form;
  };

  KDTabViewWithForms.prototype.getFinalData = function() {
    var finalData, pane, _i, _len, _ref;
    finalData = {};
    _ref = this.panes;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      pane = _ref[_i];
      finalData = $.extend(pane.form.getData(), finalData);
    }
    return finalData;
  };

  KDTabViewWithForms.prototype.fireFinalCallback = function() {
    var finalData, _base;
    finalData = this.getFinalData();
    return typeof (_base = this.getOptions()).callback === "function" ? _base.callback(finalData) : void 0;
  };

  return KDTabViewWithForms;

})(KDTabView);


},{"./../forms/formviewwithfields.coffee":35,"./tabpaneview.coffee":81,"./tabview.coffee":82}],84:[function(require,module,exports){
var KDTimeAgoView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDTimeAgoView = (function(_super) {
  __extends(KDTimeAgoView, _super);

  KDTimeAgoView.registerStaticEmitter();

  KD.utils.repeat(60000, function() {
    return KDTimeAgoView.emit("OneMinutePassed");
  });

  function KDTimeAgoView(options, data) {
    if (options == null) {
      options = {};
    }
    options.tagName = "time";
    KDTimeAgoView.__super__.constructor.call(this, options, data);
    KDTimeAgoView.on("OneMinutePassed", (function(_this) {
      return function() {
        return _this.updatePartial($.timeago(_this.getData()));
      };
    })(this));
  }

  KDTimeAgoView.prototype.setData = function() {
    KDTimeAgoView.__super__.setData.apply(this, arguments);
    if (this.parent) {
      return this.updatePartial($.timeago(this.getData()));
    }
  };

  KDTimeAgoView.prototype.viewAppended = function() {
    return this.setPartial($.timeago(this.getData()));
  };

  return KDTimeAgoView;

})(KDView);


},{"./../../core/view.coffee":108}],85:[function(require,module,exports){

/*

  KDTooltip

  A tooltip has a position and a direction, relative to the delegate
  element it is attached to.

  Valid positioning types are 'top','bottom','left' and 'right'
  Valid direction types are 'top','bottom','left','right' and 'center'

  Should a tooltip move off-screen, it will be relocated to be fully
  visible.
 */
var KDTooltip, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

module.exports = KDTooltip = (function(_super) {
  var directionMap, getBoundaryViolations, getCoordsDiff, getCoordsFromPlacement, placementMap;

  __extends(KDTooltip, _super);

  function KDTooltip(options, data) {
    options.bind || (options.bind = "mouseenter mouseleave");
    if (options.sticky == null) {
      options.sticky = false;
    }
    options.cssClass = KD.utils.curry("kdtooltip", options.cssClass);
    KDTooltip.__super__.constructor.call(this, options, data);
    this.visible = false;
    this.parentView = this.getDelegate();
    this.wrapper = new KDView({
      cssClass: 'wrapper'
    });
    if (this.getOptions().animate) {
      this.setClass('out');
    } else {
      this.hide();
    }
    this.addListeners();
    KD.singletons.windowController.on("ScrollHappened", this.bound("hide"));
    this.once("viewAppended", (function(_this) {
      return function() {
        var o;
        o = _this.getOptions();
        if (o.view != null) {
          _this.setView(o.view);
        } else {
          _this.setClass('just-text');
          _this.setTitle(o.title, o);
        }
        _this.parentView.emit('TooltipReady');
        _this.addSubView(_this.wrapper);
        return _this.visible = true;
      };
    })(this));
  }

  KDTooltip.prototype.show = function(event) {
    var selector;
    selector = this.getOptions().selector;
    if (selector) {
      return;
    }
    this.display();
    KDTooltip.__super__.show.apply(this, arguments);
    return this.visible = true;
  };

  KDTooltip.prototype.hide = function(event) {
    if (!this.visible) {
      return;
    }
    KDTooltip.__super__.hide.apply(this, arguments);
    this.getDomElement().remove();
    KD.singletons.windowController.removeLayer(this);
    return this.visible = false;
  };

  KDTooltip.prototype.update = function(o, view) {
    if (o == null) {
      o = this.getOptions();
    }
    if (view == null) {
      view = null;
    }
    if (!view) {
      o.selector || (o.selector = null);
      o.title || (o.title = "");
      this.getOptions().title = o.title;
      this.setTitle(o.title);
      this.display(this.getOptions());
    } else {
      this.setView(view);
    }
    return this.visible = true;
  };

  KDTooltip.prototype.addListeners = function() {
    var events, name, _hide, _i, _len, _show;
    events = this.getOptions().events;
    _show = this.bound("show");
    _hide = this.bound("hide");
    for (_i = 0, _len = events.length; _i < _len; _i++) {
      name = events[_i];
      this.parentView.bindEvent(name);
    }
    this.parentView.on('mouseenter', _show);
    this.parentView.on('mouseleave', _hide);
    this.on('ReceivedClickElsewhere', _hide);
    return this.once('KDObjectWillBeDestroyed', (function(_this) {
      return function() {
        _this.parentView.off('mouseenter', _show);
        return _this.parentView.off('mouseleave', _hide);
      };
    })(this));
  };

  KDTooltip.prototype.setView = function(childView) {
    var constructorName, data, options;
    if (!childView) {
      return;
    }
    if (this.wrapper.view != null) {
      this.wrapper.view.destroy();
    }
    if (childView.constructorName) {
      options = childView.options, data = childView.data, constructorName = childView.constructorName;
      return this.childView = new constructorName(options, data);
    } else {
      return this.wrapper.addSubView(childView);
    }
  };

  KDTooltip.prototype.getView = function() {
    return this.childView;
  };

  KDTooltip.prototype.destroy = function() {
    this.parentView.tooltip = null;
    delete this.parentView.tooltip;
    return KDTooltip.__super__.destroy.apply(this, arguments);
  };

  KDTooltip.prototype.translateCompassDirections = function(o) {
    var gravity, placement;
    placement = o.placement, gravity = o.gravity;
    o.placement = placementMap[placement];
    o.direction = directionMap(o.placement, gravity);
    return o;
  };

  KDTooltip.prototype.display = function(o) {
    if (o == null) {
      o = this.getOptions();
    }
    this.appendToDomBody();
    KD.singletons.windowController.addLayer(this);
    if (o.gravity) {
      o = this.translateCompassDirections(o);
    }
    o.gravity = null;
    if (o.animate) {
      this.setClass('in');
    }
    this.utils.defer((function(_this) {
      return function() {
        return _this.setPositions(o);
      };
    })(this));
    return this.visible = true;
  };

  KDTooltip.prototype.getCorrectPositionCoordinates = function(o, positionValues, callback) {
    var container, correctValues, d, direction, forcePosition, placement, selector, variant, variants, violations, _i, _len;
    if (o == null) {
      o = {};
    }
    if (callback == null) {
      callback = noop;
    }
    container = this.$();
    selector = this.parentView.$(o.selector);
    d = {
      container: {
        height: container.height(),
        width: container.width()
      },
      selector: {
        offset: selector.offset(),
        height: selector.height(),
        width: selector.width()
      }
    };
    placement = positionValues.placement, direction = positionValues.direction;
    forcePosition = this.getOptions().forcePosition;
    violations = getBoundaryViolations(getCoordsFromPlacement(d, placement, direction), d.container.width, d.container.height);
    if (!forcePosition && Object.keys(violations).length > 0) {
      variants = [['top', 'right'], ['right', 'top'], ['right', 'bottom'], ['bottom', 'right'], ['top', 'left'], ['top', 'center'], ['right', 'center'], ['bottom', 'center'], ['bottom', 'left'], ['left', 'bottom'], ['left', 'center'], ['left', 'top']];
      for (_i = 0, _len = variants.length; _i < _len; _i++) {
        variant = variants[_i];
        if (Object.keys(getBoundaryViolations(getCoordsFromPlacement(d, variant[0], variant[1]), d.container.width, d.container.height)).length === 0) {
          placement = variant[0], direction = variant[1];
          break;
        }
      }
    }
    correctValues = {
      coords: getCoordsFromPlacement(d, placement, direction),
      placement: placement,
      direction: direction
    };
    callback(correctValues);
    return correctValues;
  };

  KDTooltip.prototype.setPositions = function(o, animate) {
    var coords, direction, direction_, offset, placement, placement_, _i, _j, _len, _len1, _ref, _ref1, _ref2;
    if (o == null) {
      o = this.getOptions();
    }
    if (animate == null) {
      animate = false;
    }
    if (animate) {
      this.setClass('animate-movement');
    }
    placement = o.placement || 'top';
    direction = o.direction || 'right';
    offset = Number === typeof o.offset ? {
      top: o.offset,
      left: 0
    } : o.offset;
    direction = (placement === 'top' || placement === 'bottom') && (direction === 'top' || direction === 'bottom') ? 'center' : (placement === 'left' || placement === 'right') && (direction === 'left' || direction === 'right') ? 'center' : direction;
    _ref = this.getCorrectPositionCoordinates(o, {
      placement: placement,
      direction: direction
    }), coords = _ref.coords, placement = _ref.placement, direction = _ref.direction;
    _ref1 = ['top', 'bottom', 'left', 'right'];
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      placement_ = _ref1[_i];
      if (placement === placement_) {
        this.setClass('placement-' + placement_);
      } else {
        this.unsetClass('placement-' + placement_);
      }
    }
    _ref2 = ['top', 'bottom', 'left', 'right', 'center'];
    for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
      direction_ = _ref2[_j];
      if (direction === direction_) {
        this.setClass('direction-' + direction_);
      } else {
        this.unsetClass('direction-' + direction_);
      }
    }
    this.$().css({
      left: coords.left + offset.left,
      top: coords.top + offset.top
    });
    return this.utils.wait(500, (function(_this) {
      return function() {
        return _this.unsetClass('animate-movement');
      };
    })(this));
  };

  KDTooltip.prototype.setTitle = function(title, o) {
    if (o == null) {
      o = {};
    }
    if (o.html !== false) {
      return this.wrapper.updatePartial(title);
    } else {
      return this.wrapper.updatePartial(Encoder.htmlEncode(title));
    }
  };

  directionMap = function(placement, gravity) {
    if (placement === "top" || placement === "bottom") {
      if (/e/.test(gravity)) {
        return "left";
      } else if (/w/.test(gravity)) {
        return "right";
      } else {
        return "center";
      }
    } else if (placement === "left" || placement === "right") {
      if (/n/.test(gravity)) {
        return "top";
      } else if (/s/.test(gravity)) {
        return "bottom";
      } else {
        return placement;
      }
    }
  };

  placementMap = {
    top: "top",
    above: "top",
    below: "bottom",
    bottom: "bottom",
    left: "left",
    right: "right"
  };

  getBoundaryViolations = function(coordinates, width, height) {
    var violations;
    violations = {};
    if (coordinates.left < 0) {
      violations.left = -coordinates.left;
    }
    if (coordinates.top < 0) {
      violations.top = -coordinates.top;
    }
    if (coordinates.left + width > window.innerWidth) {
      violations.right = coordinates.left + width - window.innerWidth;
    }
    if (coordinates.top + height > window.innerHeight) {
      violations.bottom = coordinates.top + height - window.innerHeight;
    }
    return violations;
  };

  getCoordsDiff = function(dimensions, type, center) {
    var diff;
    if (center == null) {
      center = false;
    }
    diff = dimensions.selector[type] - dimensions.container[type];
    if (center) {
      return diff / 2;
    } else {
      return diff;
    }
  };

  getCoordsFromPlacement = function(dimensions, placement, direction) {
    var coordinates, dynamicAxis, dynamicC, exclusion, staticAxis, staticC, _ref;
    coordinates = {
      top: dimensions.selector.offset.top,
      left: dimensions.selector.offset.left
    };
    _ref = /o/.test(placement) ? ['height', 'width', 'top', 'left', 'right'] : ['width', 'height', 'left', 'top', 'bottom'], staticAxis = _ref[0], dynamicAxis = _ref[1], staticC = _ref[2], dynamicC = _ref[3], exclusion = _ref[4];
    coordinates[staticC] += !(placement.length < 5) ? dimensions.selector[staticAxis] + 10 : -(dimensions.container[staticAxis] + 10);
    if (direction !== exclusion) {
      coordinates[dynamicC] += getCoordsDiff(dimensions, dynamicAxis, direction === 'center');
    }
    return coordinates;
  };

  return KDTooltip;

})(KDView);


},{"./../../core/view.coffee":108}],86:[function(require,module,exports){
var JTreeItemView, KDListItemView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDListItemView = require('./../list/listitemview.coffee');

module.exports = JTreeItemView = (function(_super) {
  __extends(JTreeItemView, _super);

  function JTreeItemView(options, data) {
    var childClass, childOptions, _ref;
    if (options == null) {
      options = {};
    }
    if (data == null) {
      data = {};
    }
    options.tagName || (options.tagName = "li");
    options.type || (options.type = "jtreeitem");
    options.bind || (options.bind = "mouseenter contextmenu dragstart dragenter dragleave dragend dragover drop");
    options.childClass || (options.childClass = null);
    options.childOptions || (options.childOptions = {});
    JTreeItemView.__super__.constructor.call(this, options, data);
    this.setClass("jtreeitem");
    this.expanded = false;
    _ref = this.getOptions(), childClass = _ref.childClass, childOptions = _ref.childOptions;
    if (childClass) {
      this.child = new childClass(childOptions, this.getData());
    }
  }

  JTreeItemView.prototype.viewAppended = function() {
    if (this.getOptions().childClass) {
      return this.addSubView(this.child);
    } else {
      return this.updatePartial("<span class='arrow'></span>\n" + (this.getData().title));
    }
  };

  JTreeItemView.prototype.toggle = function(callback) {
    if (this.expanded) {
      return this.collapse();
    } else {
      return this.expand();
    }
  };

  JTreeItemView.prototype.expand = function(callback) {
    this.expanded = true;
    return this.setClass("expanded");
  };

  JTreeItemView.prototype.collapse = function(callback) {
    this.expanded = false;
    return this.unsetClass("expanded");
  };

  JTreeItemView.prototype.decorateSubItemsState = function(state) {
    if (state == null) {
      state = true;
    }
    if (state) {
      return this.setClass("has-sub-items");
    } else {
      return this.unsetClass("has-sub-items");
    }
  };

  return JTreeItemView;

})(KDListItemView);


},{"./../list/listitemview.coffee":53}],87:[function(require,module,exports){
var JTreeView, KDListView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDListView = require('./../list/listview.coffee');

module.exports = JTreeView = (function(_super) {
  __extends(JTreeView, _super);

  function JTreeView(options, data) {
    if (options == null) {
      options = {};
    }
    if (options.animated == null) {
      options.animated = false;
    }
    JTreeView.__super__.constructor.call(this, options, data);
    this.setClass("jtreeview expanded");
  }

  JTreeView.prototype.toggle = function(callback) {
    if (this.expanded) {
      return this.collapse(callback);
    } else {
      return this.expand(callback);
    }
  };

  JTreeView.prototype.expand = function(callback) {
    if (this.getOptions().animated) {
      return this.$().slideDown(150, (function(_this) {
        return function() {
          _this.setClass("expanded");
          return typeof callback === "function" ? callback() : void 0;
        };
      })(this));
    } else {
      this.show();
      this.setClass("expanded");
      return typeof callback === "function" ? callback() : void 0;
    }
  };

  JTreeView.prototype.collapse = function(callback) {
    if (this.getOptions().animated) {
      return this.$().slideUp(100, (function(_this) {
        return function() {
          _this.unsetClass("expanded");
          return typeof callback === "function" ? callback() : void 0;
        };
      })(this));
    } else {
      this.hide();
      this.unsetClass("expanded");
      return typeof callback === "function" ? callback() : void 0;
    }
  };

  JTreeView.prototype.mouseDown = function() {
    KD.getSingleton("windowController").setKeyView(this);
    return false;
  };

  JTreeView.prototype.keyDown = function(event) {
    return this.emit("KeyDownOnTreeView", event);
  };

  JTreeView.prototype.destroy = function() {
    KD.getSingleton("windowController").revertKeyView(this);
    return JTreeView.__super__.destroy.apply(this, arguments);
  };

  JTreeView.prototype.appendItemAtIndex = function(itemInstance, index, animation) {
    var added, _ref;
    itemInstance.setParent(this);
    added = true;
    if (index <= 0) {
      this.$().prepend(itemInstance.$());
    } else if (index > 0) {
      if ((_ref = this.items[index - 1]) != null ? _ref.$().hasClass('has-sub-items') : void 0) {
        this.items[index - 1].$().next().after(itemInstance.$());
      } else if (this.items[index - 1] != null) {
        this.items[index - 1].$().after(itemInstance.$());
      } else {
        warn("Out of bound");
        added = false;
      }
    }
    if (this.parentIsInDom && added) {
      itemInstance.emit('viewAppended');
    }
    return null;
  };

  return JTreeView;

})(KDListView);


},{"./../list/listview.coffee":54}],88:[function(require,module,exports){
var JTreeViewController, KDListViewController, KDScrollView, KDViewController,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

KDViewController = require('./../../core/viewcontroller.coffee');

KDScrollView = require('./../scrollview/scrollview.coffee');

KDListViewController = require('./../list/listviewcontroller.coffee');

module.exports = JTreeViewController = (function(_super) {
  var cacheDragHelper, dragHelper, keyMap;

  __extends(JTreeViewController, _super);

  keyMap = function() {
    return {
      37: "left",
      38: "up",
      39: "right",
      40: "down",
      8: "backspace",
      9: "tab",
      13: "enter",
      27: "escape"
    };
  };

  dragHelper = null;

  cacheDragHelper = (function() {
    dragHelper = document.createElement('img');
    dragHelper.src = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAG4AAAAYCAMAAAAs/jgVAAAA0lBMVEX///+It9YAAAD///8AAACIt9aIt9aIt9aIt9aIt9aIt9YAAAD///+It9aIt9aIt9aIt9aIt9aIt9aIt9bT09OIt9aIt9aIt9b///+It9bv9fr+/v79/f2QvNn4+PioyuHA2enP4u/09PS41Obf7PTn8ff6+vr29vb3+vygxd78/Pz19fX7+/vs7OzY2NjR0dGwz+Tv7+/T09Pz8/PX19fQ0NCYwdvx8fHLy8vq6urZ2dnX5/H5+fny8vLOzs739/fPz8/W1tbu7u7w8PDH3ezd3d0P0SzzAAAAGHRSTlMAACZqGJkG2/k2rkZV4bG0V9gDaYBabJYxtX/TAAACLElEQVR4Xu3V127bMBQG4NT1SOw4s0kP59Ce3iN7tu//Sj2i0iiKE8AB7Juiv0SIFAR9OAQJ7mwy/9NsvElz61yDA4cEgGWQZA0Evm0xyAFAYkVMr/nCtU8PjsnGcnxw2n7lGMsSnmSMAX9slNxRh2w4naMXjrGEByzgCWPsqtdE7qT7ARDrOuCqL4LdE8tlyCCHWMZmjw3kWuSDuJ5V4K9iKl7BWl7LcgHnXOLFecAHV8jtkU841wqrHGbhreHtWS6QN5nMbiR2BjPkfhaAoh7QEQVfKFqMkNMAoEAp3wNwC05FQGNbXQwAeuEX7z2DXVP0NIAv6uUhl8gslFKGmUzkbIBcx3L4/XUUC+q+crYg5NDSkTBaRIpo33J2qj1NYhCeL2IwRFMBC6Lqy8VWJ8MwxSuUQTgpuN2SI0Tbf6xyKETKaAVFKs4OlWc/Kt4ZX5NadgvuPrxPp+E0xWc4mX2Bi4FgKi6ytVQcESZafMAtnWWKDdnhBLlOnYshJteW+2Vqk0ko8qOSG1FCDJKjihMuIXS0Mpnj6e341sE2HTuWa9U5YgCM5eJyqUQeYCHIxRRAl5ygoIUP4FVcOdSUeAbv16WSPz/l+WWePz3nl/PhpxthjV22zkZo9i4e7i7u5tgeLn4P7TbfDme3+f4PJ0wdZ+o4aegs5wXX7m6D67aRe18ecpizPtlw+mf2RHhfnuWwwPPDDYr9w/PyAFo9z7d8vGJ5399kf+cfyh+807YxJJdmLQAAAABJRU5ErkJggg==";
    return dragHelper.width = 110;
  })();

  function JTreeViewController(options, data) {
    var o;
    if (options == null) {
      options = {};
    }
    o = options;
    o.view || (o.view = new KDScrollView({
      cssClass: "jtreeview-wrapper"
    }));
    o.listViewControllerClass || (o.listViewControllerClass = KDListViewController);
    o.treeItemClass || (o.treeItemClass = JTreeItemView);
    o.listViewClass || (o.listViewClass = JTreeView);
    o.itemChildClass || (o.itemChildClass = null);
    o.itemChildOptions || (o.itemChildOptions = {});
    o.nodeIdPath || (o.nodeIdPath = "id");
    o.nodeParentIdPath || (o.nodeParentIdPath = "parentId");
    if (o.contextMenu == null) {
      o.contextMenu = false;
    }
    if (o.multipleSelection == null) {
      o.multipleSelection = false;
    }
    if (o.addListsCollapsed == null) {
      o.addListsCollapsed = false;
    }
    if (o.sortable == null) {
      o.sortable = false;
    }
    if (o.putDepthInfo == null) {
      o.putDepthInfo = true;
    }
    if (o.addOrphansToRoot == null) {
      o.addOrphansToRoot = true;
    }
    if (o.dragdrop == null) {
      o.dragdrop = false;
    }
    JTreeViewController.__super__.constructor.call(this, o, data);
    this.listData = {};
    this.listControllers = {};
    this.nodes = {};
    this.indexedNodes = [];
    this.selectedNodes = [];
  }

  JTreeViewController.prototype.loadView = function(treeView) {
    this.initTree(this.getData());
    this.setKeyView();
    this.setMainListeners();
    return this.registerBoundaries();
  };

  JTreeViewController.prototype.registerBoundaries = function() {
    return this.boundaries = {
      top: this.getView().getY(),
      left: this.getView().getX(),
      width: this.getView().getWidth(),
      height: this.getView().getHeight()
    };
  };


  /*
  HELPERS
   */

  JTreeViewController.prototype.initTree = function(nodes) {
    this.removeAllNodes();
    return this.addNodes(nodes);
  };

  JTreeViewController.prototype.logTreeStructure = function() {
    var index, node, o, _ref, _results;
    o = this.getOptions();
    _ref = this.indexedNodes;
    _results = [];
    for (index in _ref) {
      if (!__hasProp.call(_ref, index)) continue;
      node = _ref[index];
      _results.push(log(index, this.getNodeId(node), this.getNodePId(node), node.depth));
    }
    return _results;
  };

  JTreeViewController.prototype.getNodeId = function(nodeData) {
    return nodeData[this.getOptions().nodeIdPath];
  };

  JTreeViewController.prototype.getNodePId = function(nodeData) {
    return nodeData[this.getOptions().nodeParentIdPath];
  };

  JTreeViewController.prototype.getPathIndex = function(targetPath) {
    var index, node, _i, _len, _ref;
    _ref = this.indexedNodes;
    for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
      node = _ref[index];
      if (this.getNodeId(node) === targetPath) {
        return index;
      }
    }
    return -1;
  };

  JTreeViewController.prototype.repairIds = function(nodeData) {
    var idPath, options, pIdPath;
    options = this.getOptions();
    idPath = options.nodeIdPath;
    pIdPath = options.nodeParentIdPath;
    nodeData[idPath] || (nodeData[idPath] = this.utils.getUniqueId());
    nodeData[idPath] = "" + (this.getNodeId(nodeData));
    nodeData[pIdPath] = this.getNodePId(nodeData) ? "" + (this.getNodePId(nodeData)) : "0";
    this.nodes[this.getNodeId(nodeData)] = {};
    if (options.putDepthInfo) {
      if (this.nodes[nodeData[pIdPath]]) {
        nodeData.depth = this.nodes[nodeData[pIdPath]].getData().depth + 1;
      } else {
        nodeData.depth = 0;
      }
    }
    if (nodeData[pIdPath] !== "0" && !this.nodes[nodeData[pIdPath]]) {
      if (options.addOrphansToRoot) {
        nodeData[pIdPath] = "0";
      } else {
        nodeData = false;
      }
    }
    return nodeData;
  };

  JTreeViewController.prototype.isNodeVisible = function(nodeView) {
    var nodeData, parentNode;
    nodeData = nodeView.getData();
    parentNode = this.nodes[this.getNodePId(nodeData)];
    if (parentNode) {
      if (parentNode.expanded) {
        return this.isNodeVisible(parentNode);
      } else {
        return false;
      }
    } else {
      return true;
    }
  };

  JTreeViewController.prototype.areSibling = function(node1, node2) {
    var node1PId, node2PId;
    node1PId = this.getNodePId(node1.getData());
    node2PId = this.getNodePId(node2.getData());
    return node1PId === node2PId;
  };


  /*
  DECORATORS
   */

  JTreeViewController.prototype.setFocusState = function() {
    var view;
    view = this.getView();
    KD.getSingleton("windowController").addLayer(view);
    return view.unsetClass("dim");
  };

  JTreeViewController.prototype.setBlurState = function() {
    var view;
    view = this.getView();
    KD.getSingleton("windowController").removeLayer(view);
    return view.setClass("dim");
  };


  /*
  CRUD OPERATIONS FOR NODES
   */

  JTreeViewController.prototype.addNode = function(nodeData, index) {
    var list, node, parentId;
    if (this.nodes[this.getNodeId(nodeData)]) {
      return;
    }
    nodeData = this.repairIds(nodeData);
    if (!nodeData) {
      return;
    }
    if (__indexOf.call(this.getData(), nodeData) < 0) {
      this.getData().push(nodeData);
    }
    this.registerListData(nodeData);
    parentId = this.getNodePId(nodeData);
    if (this.listControllers[parentId] != null) {
      list = this.listControllers[parentId].getListView();
    } else {
      list = this.createList(parentId).getListView();
      this.addSubList(this.nodes[parentId], parentId);
    }
    node = list.addItem(nodeData);
    this.emit("NodeWasAdded", node);
    this.addIndexedNode(nodeData);
    return node;
  };

  JTreeViewController.prototype.addNodes = function(nodes) {
    var node, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      _results.push(this.addNode(node));
    }
    return _results;
  };

  JTreeViewController.prototype.removeNode = function(id) {
    var index, nodeData, nodeIndexToRemove, nodeToRemove, parentId, _i, _len, _ref;
    nodeIndexToRemove = null;
    _ref = this.getData();
    for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
      nodeData = _ref[index];
      if (this.getNodeId(nodeData) === id) {
        this.removeIndexedNode(nodeData);
        nodeIndexToRemove = index;
      }
    }
    if (nodeIndexToRemove != null) {
      nodeToRemove = this.getData().splice(nodeIndexToRemove, 1)[0];
      this.removeChildNodes(id);
      parentId = this.getNodePId(nodeToRemove);
      this.listControllers[parentId].getListView().removeItem(this.nodes[id]);
      return delete this.nodes[id];
    }
  };

  JTreeViewController.prototype.removeNodeView = function(nodeView) {
    return this.removeNode(this.getNodeId(nodeView.getData()));
  };

  JTreeViewController.prototype.removeAllNodes = function() {
    var id, listController, _ref;
    _ref = this.listControllers;
    for (id in _ref) {
      if (!__hasProp.call(_ref, id)) continue;
      listController = _ref[id];
      listController.itemsOrdered.forEach(this.bound('removeNodeView'));
      if (listController != null) {
        listController.getView().destroy();
      }
      delete this.listControllers[id];
      delete this.listData[id];
    }
    this.nodes = {};
    this.listData = {};
    this.indexedNodes = [];
    this.selectedNodes = [];
    return this.listControllers = {};
  };

  JTreeViewController.prototype.removeChildNodes = function(id) {
    var childNodeId, childNodeIdsToRemove, index, nodeData, _i, _j, _len, _len1, _ref, _ref1;
    childNodeIdsToRemove = [];
    _ref = this.getData();
    for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
      nodeData = _ref[index];
      if (this.getNodePId(nodeData) === id) {
        childNodeIdsToRemove.push(this.getNodeId(nodeData));
      }
    }
    for (_j = 0, _len1 = childNodeIdsToRemove.length; _j < _len1; _j++) {
      childNodeId = childNodeIdsToRemove[_j];
      this.removeNode(childNodeId);
    }
    if ((_ref1 = this.listControllers[id]) != null) {
      _ref1.getView().destroy();
    }
    delete this.listControllers[id];
    return delete this.listData[id];
  };

  JTreeViewController.prototype.nodeWasAdded = function(nodeView) {
    var id, nodeData, parentId;
    nodeData = nodeView.getData();
    if (this.getOptions().dragdrop) {
      nodeView.$().attr("draggable", "true");
    }
    id = nodeData.id, parentId = nodeData.parentId;
    this.nodes[this.getNodeId(nodeData)] = nodeView;
    if (this.nodes[this.getNodePId(nodeData)]) {
      if (!this.getOptions().addListsCollapsed) {
        this.expand(this.nodes[this.getNodePId(nodeData)]);
      }
      this.nodes[this.getNodePId(nodeData)].decorateSubItemsState();
    }
    if (!this.listControllers[id]) {
      return;
    }
    return this.addSubList(nodeView, id);
  };

  JTreeViewController.prototype.getChildNodes = function(aParentNode) {
    var children;
    children = [];
    this.indexedNodes.forEach((function(_this) {
      return function(node, index) {
        if (_this.getNodePId(node) === _this.getNodeId(aParentNode)) {
          return children.push({
            node: node,
            index: index
          });
        }
      };
    })(this));
    if (children.length) {
      return children;
    } else {
      return false;
    }
  };

  JTreeViewController.prototype.getPreviousNeighbor = function(aParentNode) {
    var children, lastChild, neighbor;
    neighbor = aParentNode;
    children = this.getChildNodes(aParentNode);
    if (children) {
      lastChild = children.last;
      neighbor = this.getPreviousNeighbor(lastChild.node);
    }
    return neighbor;
  };

  JTreeViewController.prototype.addIndexedNode = function(nodeData, index) {
    var neighborIndex, parentNodeView, prevNeighbor;
    if (index >= 0) {
      this.indexedNodes.splice(index + 1, 0, nodeData);
      return;
    }
    parentNodeView = this.nodes[this.getNodePId(nodeData)];
    if (parentNodeView) {
      prevNeighbor = this.getPreviousNeighbor(parentNodeView.getData());
      neighborIndex = this.indexedNodes.indexOf(prevNeighbor);
      return this.indexedNodes.splice(neighborIndex + 1, 0, nodeData);
    } else {
      return this.indexedNodes.push(nodeData);
    }
  };

  JTreeViewController.prototype.removeIndexedNode = function(nodeData) {
    var index;
    if (__indexOf.call(this.indexedNodes, nodeData) >= 0) {
      index = this.indexedNodes.indexOf(nodeData);
      this.indexedNodes.splice(index, 1);
      if (this.nodes[this.getNodePId(nodeData)] && !this.getChildNodes(this.nodes[this.getNodePId(nodeData)].getData())) {
        return this.nodes[this.getNodePId(nodeData)].decorateSubItemsState(false);
      }
    }
  };


  /*
  CREATING LISTS
   */

  JTreeViewController.prototype.registerListData = function(node) {
    var parentId, _base;
    parentId = this.getNodePId(node);
    (_base = this.listData)[parentId] || (_base[parentId] = []);
    return this.listData[parentId].push(node);
  };

  JTreeViewController.prototype.createList = function(listId, listItems) {
    var options, _ref, _ref1;
    options = this.getOptions();
    this.listControllers[listId] = new options.listViewControllerClass({
      id: "" + (this.getId()) + "_" + listId,
      wrapper: false,
      scrollView: false,
      selection: (_ref = options.selection) != null ? _ref : false,
      multipleSelection: (_ref1 = options.multipleSelection) != null ? _ref1 : false,
      view: new options.listViewClass({
        tagName: "ul",
        type: options.type,
        itemClass: options.treeItemClass,
        itemChildClass: options.itemChildClass,
        itemChildOptions: options.itemChildOptions
      })
    }, {
      items: listItems
    });
    this.setListenersForList(listId);
    return this.listControllers[listId];
  };

  JTreeViewController.prototype.addSubList = function(nodeView, id) {
    var listToBeAdded, o;
    o = this.getOptions();
    listToBeAdded = this.listControllers[id].getView();
    if (nodeView) {
      nodeView.$().after(listToBeAdded.$());
      listToBeAdded.parentIsInDom = true;
      listToBeAdded.emit('viewAppended');
      if (o.addListsCollapsed) {
        return this.collapse(nodeView);
      } else {
        return this.expand(nodeView);
      }
    } else {
      return this.getView().addSubView(listToBeAdded);
    }
  };


  /*
  REGISTERING LISTENERS
   */

  JTreeViewController.prototype.setMainListeners = function() {
    KD.getSingleton("windowController").on("ReceivedMouseUpElsewhere", (function(_this) {
      return function(event) {
        return _this.mouseUp(event);
      };
    })(this));
    return this.getView().on("ReceivedClickElsewhere", (function(_this) {
      return function() {
        return _this.setBlurState();
      };
    })(this));
  };

  JTreeViewController.prototype.setListenersForList = function(listId) {
    this.listControllers[listId].getView().on('ItemWasAdded', (function(_this) {
      return function(view, index) {
        return _this.setItemListeners(view, index);
      };
    })(this));
    this.listControllers[listId].on("ItemSelectionPerformed", (function(_this) {
      return function(listController, _arg) {
        var event, items;
        event = _arg.event, items = _arg.items;
        return _this.organizeSelectedNodes(listController, items, event);
      };
    })(this));
    this.listControllers[listId].on("ItemDeselectionPerformed", (function(_this) {
      return function(listController, _arg) {
        var event, items;
        event = _arg.event, items = _arg.items;
        return _this.deselectNodes(listController, items, event);
      };
    })(this));
    return this.listControllers[listId].getListView().on('KeyDownOnTreeView', (function(_this) {
      return function(event) {
        return _this.keyEventHappened(event);
      };
    })(this));
  };

  JTreeViewController.prototype.setItemListeners = function(view, index) {
    var mouseEvents;
    view.on("viewAppended", this.nodeWasAdded.bind(this, view));
    mouseEvents = ["dblclick", "click", "mousedown", "mouseup", "mouseenter", "mousemove"];
    if (this.getOptions().contextMenu) {
      mouseEvents.push("contextmenu");
    }
    if (this.getOptions().dragdrop) {
      mouseEvents = mouseEvents.concat(["dragstart", "dragenter", "dragleave", "dragend", "dragover", "drop"]);
    }
    return view.on(mouseEvents, (function(_this) {
      return function(event) {
        return _this.mouseEventHappened(view, event);
      };
    })(this));
  };


  /*
  NODE SELECTION
   */

  JTreeViewController.prototype.organizeSelectedNodes = function(listController, nodes, event) {
    var node, _i, _len, _results;
    if (event == null) {
      event = {};
    }
    if (!((event.metaKey || event.ctrlKey || event.shiftKey) && this.getOptions().multipleSelection)) {
      this.deselectAllNodes(listController);
    }
    _results = [];
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      if (__indexOf.call(this.selectedNodes, node) < 0) {
        _results.push(this.selectedNodes.push(node));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  JTreeViewController.prototype.deselectNodes = function(listController, nodes, event) {
    var node, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      if (__indexOf.call(this.selectedNodes, node) >= 0) {
        _results.push(this.selectedNodes.splice(this.selectedNodes.indexOf(node), 1));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  JTreeViewController.prototype.deselectAllNodes = function(exceptThisController) {
    var id, listController, _ref;
    _ref = this.listControllers;
    for (id in _ref) {
      if (!__hasProp.call(_ref, id)) continue;
      listController = _ref[id];
      if (listController !== exceptThisController) {
        listController.deselectAllItems();
      }
    }
    return this.selectedNodes = [];
  };

  JTreeViewController.prototype.selectNode = function(nodeView, event, setFocus) {
    var controller;
    if (setFocus == null) {
      setFocus = true;
    }
    if (!nodeView) {
      return;
    }
    if (setFocus) {
      this.setFocusState();
    }
    controller = this.listControllers[this.getNodePId(nodeView.getData())];
    if (controller) {
      return controller.selectItem(nodeView, event);
    }
  };

  JTreeViewController.prototype.deselectNode = function(nodeView, event) {
    return this.listControllers[this.getNodePId(nodeView.getData())].deselectSingleItem(nodeView, event);
  };

  JTreeViewController.prototype.selectFirstNode = function() {
    return this.selectNode(this.nodes[this.getNodeId(this.indexedNodes[0])]);
  };

  JTreeViewController.prototype.selectNodesByRange = function(node1, node2) {
    var indicesToBeSliced, itemsToBeSelected, node, _i, _len, _results;
    indicesToBeSliced = [this.indexedNodes.indexOf(node1.getData()), this.indexedNodes.indexOf(node2.getData())];
    indicesToBeSliced.sort(function(a, b) {
      return a - b;
    });
    itemsToBeSelected = this.indexedNodes.slice(indicesToBeSliced[0], indicesToBeSliced[1] + 1);
    _results = [];
    for (_i = 0, _len = itemsToBeSelected.length; _i < _len; _i++) {
      node = itemsToBeSelected[_i];
      _results.push(this.selectNode(this.nodes[this.getNodeId(node)], {
        shiftKey: true
      }));
    }
    return _results;
  };


  /*
  COLLAPSE / EXPAND
   */

  JTreeViewController.prototype.toggle = function(nodeView) {
    if (nodeView.expanded) {
      return this.collapse(nodeView);
    } else {
      return this.expand(nodeView);
    }
  };

  JTreeViewController.prototype.expand = function(nodeView) {
    var nodeData, _ref;
    nodeData = nodeView.getData();
    nodeView.expand();
    return (_ref = this.listControllers[this.getNodeId(nodeData)]) != null ? _ref.getView().expand() : void 0;
  };

  JTreeViewController.prototype.collapse = function(nodeView) {
    var nodeData, _ref;
    nodeData = nodeView.getData();
    return (_ref = this.listControllers[this.getNodeId(nodeData)]) != null ? _ref.getView().collapse((function(_this) {
      return function() {
        return nodeView.collapse();
      };
    })(this)) : void 0;
  };


  /*
  DND UI FEEDBACKS
   */

  JTreeViewController.prototype.showDragOverFeedback = (function() {
    return _.throttle(function(nodeView, event) {
      var nodeData, _ref, _ref1;
      nodeData = nodeView.getData();
      if (nodeData.type !== "file") {
        nodeView.setClass("drop-target");
      } else {
        if ((_ref = this.nodes[nodeData.parentPath]) != null) {
          _ref.setClass("drop-target");
        }
        if ((_ref1 = this.listControllers[nodeData.parentPath]) != null) {
          _ref1.getListView().setClass("drop-target");
        }
      }
      return nodeView.setClass("items-hovering");
    }, 100);
  })();

  JTreeViewController.prototype.clearDragOverFeedback = (function() {
    return _.throttle(function(nodeView, event) {
      var nodeData, _ref, _ref1;
      nodeData = nodeView.getData();
      if (nodeData.type !== "file") {
        nodeView.unsetClass("drop-target");
      } else {
        if ((_ref = this.nodes[nodeData.parentPath]) != null) {
          _ref.unsetClass("drop-target");
        }
        if ((_ref1 = this.listControllers[nodeData.parentPath]) != null) {
          _ref1.getListView().unsetClass("drop-target");
        }
      }
      return nodeView.unsetClass("items-hovering");
    }, 100);
  })();

  JTreeViewController.prototype.clearAllDragFeedback = function() {
    return this.utils.wait(101, (function(_this) {
      return function() {
        var listController, nodeView, path, _ref, _ref1, _results;
        _this.getView().$('.drop-target').removeClass("drop-target");
        _this.getView().$('.items-hovering').removeClass("items-hovering");
        _ref = _this.listControllers;
        for (path in _ref) {
          if (!__hasProp.call(_ref, path)) continue;
          listController = _ref[path];
          listController.getListView().unsetClass("drop-target");
        }
        _ref1 = _this.nodes;
        _results = [];
        for (path in _ref1) {
          if (!__hasProp.call(_ref1, path)) continue;
          nodeView = _ref1[path];
          _results.push(nodeView.unsetClass("items-hovering drop-target"));
        }
        return _results;
      };
    })(this));
  };


  /*
  HANDLING MOUSE EVENTS
   */

  JTreeViewController.prototype.mouseEventHappened = function(nodeView, event) {
    switch (event.type) {
      case "mouseenter":
        return this.mouseEnter(nodeView, event);
      case "dblclick":
        return this.dblClick(nodeView, event);
      case "click":
        return this.click(nodeView, event);
      case "mousedown":
        return this.mouseDown(nodeView, event);
      case "mouseup":
        return this.mouseUp(nodeView, event);
      case "mousemove":
        return this.mouseMove(nodeView, event);
      case "contextmenu":
        return this.contextMenu(nodeView, event);
      case "dragstart":
        return this.dragStart(nodeView, event);
      case "dragenter":
        return this.dragEnter(nodeView, event);
      case "dragleave":
        return this.dragLeave(nodeView, event);
      case "dragover":
        return this.dragOver(nodeView, event);
      case "dragend":
        return this.dragEnd(nodeView, event);
      case "drop":
        return this.drop(nodeView, event);
    }
  };

  JTreeViewController.prototype.dblClick = function(nodeView, event) {
    return this.toggle(nodeView);
  };

  JTreeViewController.prototype.click = function(nodeView, event) {
    if (/arrow/.test(event.target.className)) {
      this.toggle(nodeView);
      return this.selectedItems;
    }
    this.lastEvent = event;
    if (!((event.metaKey || event.ctrlKey || event.shiftKey) && this.getOptions().multipleSelection)) {
      this.deselectAllNodes();
    }
    if (nodeView != null) {
      if (event.shiftKey && this.selectedNodes.length > 0 && this.getOptions().multipleSelection) {
        this.selectNodesByRange(this.selectedNodes[0], nodeView);
      } else {
        this.selectNode(nodeView, event);
      }
    }
    return this.selectedItems;
  };

  JTreeViewController.prototype.contextMenu = function(nodeView, event) {};

  JTreeViewController.prototype.mouseDown = function(nodeView, event) {
    this.lastEvent = event;
    if (__indexOf.call(this.selectedNodes, nodeView) < 0) {
      this.mouseIsDown = true;
      this.cancelDrag = true;
      this.mouseDownTempItem = nodeView;
      return this.mouseDownTimer = setTimeout((function(_this) {
        return function() {
          _this.mouseIsDown = false;
          _this.cancelDrag = false;
          _this.mouseDownTempItem = null;
          return _this.selectNode(nodeView, event);
        };
      })(this), 1000);
    } else {
      this.mouseIsDown = false;
      return this.mouseDownTempItem = null;
    }
  };

  JTreeViewController.prototype.mouseUp = function(event) {
    clearTimeout(this.mouseDownTimer);
    this.mouseIsDown = false;
    this.cancelDrag = false;
    return this.mouseDownTempItem = null;
  };

  JTreeViewController.prototype.mouseEnter = function(nodeView, event) {
    clearTimeout(this.mouseDownTimer);
    if (this.mouseIsDown && this.getOptions().multipleSelection) {
      this.cancelDrag = true;
      if (!((event.metaKey || event.ctrlKey || event.shiftKey) && this.getOptions().multipleSelection)) {
        this.deselectAllNodes();
      }
      return this.selectNodesByRange(this.mouseDownTempItem, nodeView);
    }
  };


  /*
  HANDLING DND
   */

  JTreeViewController.prototype.dragStart = function(nodeView, event) {
    var e, node, transferredData;
    if (this.cancelDrag) {
      event.preventDefault();
      event.stopPropagation();
      return false;
    }
    this.dragIsActive = true;
    e = event.originalEvent;
    e.dataTransfer.effectAllowed = 'copyMove';
    transferredData = (function() {
      var _i, _len, _ref, _results;
      _ref = this.selectedNodes;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        node = _ref[_i];
        _results.push(this.getNodeId(node.getData()));
      }
      return _results;
    }).call(this);
    e.dataTransfer.setData('Text', transferredData.join());
    if (this.selectedNodes.length > 1) {
      e.dataTransfer.setDragImage(dragHelper, -10, 0);
    }
    return nodeView.setClass("drag-started");
  };

  JTreeViewController.prototype.dragEnter = function(nodeView, event) {
    return this.emit("dragEnter", nodeView, event);
  };

  JTreeViewController.prototype.dragLeave = function(nodeView, event) {
    this.clearAllDragFeedback();
    return this.emit("dragLeave", nodeView, event);
  };

  JTreeViewController.prototype.dragOver = function(nodeView, event) {
    return this.emit("dragOver", nodeView, event);
  };

  JTreeViewController.prototype.dragEnd = function(nodeView, event) {
    this.dragIsActive = false;
    nodeView.unsetClass("drag-started");
    this.clearAllDragFeedback();
    return this.emit("dragEnd", nodeView, event);
  };

  JTreeViewController.prototype.drop = function(nodeView, event) {
    this.dragIsActive = false;
    event.preventDefault();
    event.stopPropagation();
    this.emit("drop", nodeView, event);
    return false;
  };


  /*
  HANDLING KEY EVENTS
   */

  JTreeViewController.prototype.setKeyView = function() {
    if (this.listControllers[0]) {
      return KD.getSingleton("windowController").setKeyView(this.listControllers[0].getListView());
    }
  };

  JTreeViewController.prototype.keyEventHappened = function(event) {
    var key, nextNode, nodeView, _base;
    key = keyMap()[event.which];
    nodeView = this.selectedNodes[0];
    this.emit("keyEventPerformedOnTreeView", event);
    if (!nodeView) {
      return;
    }
    switch (key) {
      case "down":
      case "up":
        event.preventDefault();
        nextNode = this["perform" + (key.capitalize()) + "Key"](nodeView, event);
        if (nextNode) {
          return typeof (_base = this.getView()).scrollToSubView === "function" ? _base.scrollToSubView(nextNode) : void 0;
        }
        break;
      case "left":
        return this.performLeftKey(nodeView, event);
      case "right":
        return this.performRightKey(nodeView, event);
      case "backspace":
        return this.performBackspaceKey(nodeView, event);
      case "enter":
        return this.performEnterKey(nodeView, event);
      case "escape":
        return this.performEscapeKey(nodeView, event);
      case "tab":
        return false;
    }
  };

  JTreeViewController.prototype.performDownKey = function(nodeView, event) {
    var nextIndex, nextNode, nodeData;
    if (this.selectedNodes.length > 1) {
      nodeView = this.selectedNodes[this.selectedNodes.length - 1];
      if (!((event.metaKey || event.ctrlKey || event.shiftKey) && this.getOptions().multipleSelection)) {
        this.deselectAllNodes();
        this.selectNode(nodeView);
      }
    }
    nodeData = nodeView.getData();
    nextIndex = this.indexedNodes.indexOf(nodeData) + 1;
    if (this.indexedNodes[nextIndex]) {
      nextNode = this.nodes[this.getNodeId(this.indexedNodes[nextIndex])];
      if (this.isNodeVisible(nextNode)) {
        if (__indexOf.call(this.selectedNodes, nextNode) >= 0) {
          return this.deselectNode(this.nodes[this.getNodeId(nodeData)]);
        } else {
          this.selectNode(nextNode, event);
          return nextNode;
        }
      } else {
        return this.performDownKey(nextNode, event);
      }
    }
  };

  JTreeViewController.prototype.performUpKey = function(nodeView, event) {
    var nextIndex, nextNode, nodeData;
    if (this.selectedNodes.length > 1) {
      nodeView = this.selectedNodes[this.selectedNodes.length - 1];
      if (!((event.metaKey || event.ctrlKey || event.shiftKey) && this.getOptions().multipleSelection)) {
        this.deselectAllNodes();
        this.selectNode(nodeView);
      }
    }
    nodeData = nodeView.getData();
    nextIndex = this.indexedNodes.indexOf(nodeData) - 1;
    if (this.indexedNodes[nextIndex]) {
      nextNode = this.nodes[this.getNodeId(this.indexedNodes[nextIndex])];
      if (this.isNodeVisible(nextNode)) {
        if (__indexOf.call(this.selectedNodes, nextNode) >= 0) {
          this.deselectNode(this.nodes[this.getNodeId(nodeData)]);
        } else {
          this.selectNode(nextNode, event);
        }
      } else {
        this.performUpKey(nextNode, event);
      }
    }
    return nextNode;
  };

  JTreeViewController.prototype.performRightKey = function(nodeView, event) {
    return this.expand(nodeView);
  };

  JTreeViewController.prototype.performLeftKey = function(nodeView, event) {
    var nodeData, parentNode;
    nodeData = nodeView.getData();
    if (this.nodes[this.getNodePId(nodeData)]) {
      parentNode = this.nodes[this.getNodePId(nodeData)];
      this.selectNode(parentNode);
    }
    return parentNode;
  };

  JTreeViewController.prototype.performBackspaceKey = function(nodeView, event) {};

  JTreeViewController.prototype.performEnterKey = function(nodeView, event) {};

  JTreeViewController.prototype.performEscapeKey = function(nodeView, event) {};

  return JTreeViewController;

})(KDViewController);


},{"./../../core/viewcontroller.coffee":109,"./../list/listviewcontroller.coffee":55,"./../scrollview/scrollview.coffee":69}],89:[function(require,module,exports){
var KDCustomHTMLView, KDFileUploadArea, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

KDCustomHTMLView = require('./../../core/customhtmlview.coffee');

module.exports = KDFileUploadArea = (function(_super) {
  __extends(KDFileUploadArea, _super);

  function KDFileUploadArea() {
    return KDFileUploadArea.__super__.constructor.apply(this, arguments);
  }

  KDFileUploadArea.prototype.dragEnter = function(e) {
    e.preventDefault();
    e.stopPropagation();
    return this.setClass("hover");
  };

  KDFileUploadArea.prototype.dragOver = function(e) {
    e.preventDefault();
    e.stopPropagation();
    return this.setClass("hover");
  };

  KDFileUploadArea.prototype.dragLeave = function(e) {
    e.preventDefault();
    e.stopPropagation();
    return this.unsetClass("hover");
  };

  KDFileUploadArea.prototype.drop = function(jQueryEvent) {
    var file, files, orgEvent, _i, _len;
    jQueryEvent.preventDefault();
    jQueryEvent.stopPropagation();
    this.unsetClass("hover");
    orgEvent = jQueryEvent.originalEvent;
    files = orgEvent.dataTransfer.files;
    for (_i = 0, _len = files.length; _i < _len; _i++) {
      file = files[_i];
      this.getDelegate().fileDropped(file);
    }
    return false;
  };

  KDFileUploadArea.prototype.viewAppended = function() {
    var o, title;
    title = this.getOptions().title;
    o = this.getDelegate().getOptions();
    this.setPartial("<span>" + title + "</span>");
    return this.addSubView(new KDCustomHTMLView({
      cssClass: "info",
      tagName: "span",
      tooltip: {
        title: "Max. File Amount: <b>" + o.limit + "</b> files<br/>Max. File Size: <b>" + o.fileMaxSize + "</b> kbytes<br/>Max. Total Size: <b>" + o.totalMaxSize + "</b> kbytes",
        placement: "above",
        offset: 0,
        delayIn: 300,
        html: true,
        animate: true,
        selector: null,
        partial: "i"
      }
    }));
  };

  return KDFileUploadArea;

})(KDView);


},{"./../../core/customhtmlview.coffee":97,"./../../core/view.coffee":108}],90:[function(require,module,exports){
var KDFileUploadListItemView, KDListItemView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDListItemView = require('./../list/listitemview.coffee');

module.exports = KDFileUploadListItemView = (function(_super) {
  __extends(KDFileUploadListItemView, _super);

  function KDFileUploadListItemView(options, data) {
    KDFileUploadListItemView.__super__.constructor.call(this, options, data);
    this.setClass("kdfileuploadlistitem clearfix");
    this.active = false;
  }

  KDFileUploadListItemView.prototype.click = function(e) {
    if ($(e.target).is("span.iconic.x")) {
      return this.emit("removeFile", {
        orgEvent: e
      });
    }
  };

  KDFileUploadListItemView.prototype.viewAppended = function() {
    return this.$().append(this.partial(this.data));
  };

  KDFileUploadListItemView.prototype.partial = function(file) {
    return $("<span class='file-title'>" + file.name + "</span> <span class='file-size'>" + ((file.size / 1024).toFixed(2)) + "kb</span> <span class='x'></span>");
  };

  return KDFileUploadListItemView;

})(KDListItemView);


},{"./../list/listitemview.coffee":53}],91:[function(require,module,exports){
var KDFileUploadListView, KDListView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDListView = require('./../list/listview.coffee');

module.exports = KDFileUploadListView = (function(_super) {
  __extends(KDFileUploadListView, _super);

  function KDFileUploadListView(options, data) {
    if (options.itemClass == null) {
      options.itemClass = KDFileUploadItemView;
    }
    KDFileUploadListView.__super__.constructor.call(this, options, data);
    this.setClass("kdfileuploadlist");
    this.itemsByName = {};
  }

  KDFileUploadListView.prototype.addItem = function(file) {
    var itemInstance;
    itemInstance = new (this.getOptions().itemClass)({
      delegate: this
    }, file);
    this.getDelegate().on("removeFile", this.getDelegate().removeFile);
    this.addItemView(itemInstance);
    return this.itemsByName[file.name] = itemInstance;
  };

  return KDFileUploadListView;

})(KDListView);


},{"./../list/listview.coffee":54}],92:[function(require,module,exports){
var KDFileUploadThumbItemView, KDListItemView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDListItemView = require('./../list/listitemview.coffee');

module.exports = KDFileUploadThumbItemView = (function(_super) {
  __extends(KDFileUploadThumbItemView, _super);

  function KDFileUploadThumbItemView(options, data) {
    KDFileUploadThumbItemView.__super__.constructor.call(this, options, data);
    this.setClass("kdfileuploadthumbitem clearfix");
    this.active = false;
  }

  KDFileUploadThumbItemView.prototype.click = function(e) {
    if ($(e.target).is("span.iconic.x")) {
      return this.emit("removeFile", {
        orgEvent: e
      });
    }
  };

  KDFileUploadThumbItemView.prototype.viewAppended = function() {
    return this.$().append(this.partial(this.data));
  };

  KDFileUploadThumbItemView.prototype.partial = function(file) {
    var fileUrl, imageType;
    imageType = /image.*/;
    fileUrl = file.type.match(imageType) ? window.URL.createObjectURL(file) : "./a/images/icon.file.png";
    return $("<img class='thumb' src='" + fileUrl + "'/> <p class='meta'> <span class='file-title'>" + file.name + "</span> <span class='file-size'>" + ((file.size / 1024).toFixed(2)) + "kb</span> <span class='close-icon'></span> </p>");
  };

  return KDFileUploadThumbItemView;

})(KDListItemView);


},{"./../list/listitemview.coffee":53}],93:[function(require,module,exports){
var KDFileUploadListView, KDFileUploadThumbListView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDFileUploadListView = require('./fileuploadlistview.coffee');

module.exports = KDFileUploadThumbListView = (function(_super) {
  __extends(KDFileUploadThumbListView, _super);

  function KDFileUploadThumbListView(options, data) {
    if (options.itemClass == null) {
      options.itemClass = KDFileUploadThumbItemView;
    }
    KDFileUploadThumbListView.__super__.constructor.call(this, options, data);
    this.setClass("kdfileuploadthumblist");
  }

  return KDFileUploadThumbListView;

})(KDFileUploadListView);


},{"./fileuploadlistview.coffee":91}],94:[function(require,module,exports){
var KDFileUploadArea, KDFileUploadListView, KDFileUploadThumbListView, KDFileUploadView, KDListViewController, KDMultipartUploader, KDNotificationView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./../../core/view.coffee');

KDListViewController = require('./../list/listviewcontroller.coffee');

KDNotificationView = require('./../notifications/notificationview.coffee');

KDFileUploadArea = require('./fileuploadarea.coffee');

KDFileUploadListView = require('./fileuploadlistview.coffee');

KDFileUploadThumbListView = require('./fileuploadthumblistview.coffee');

KDMultipartUploader = require('./multipartuploader.coffee');

module.exports = KDFileUploadView = (function(_super) {
  __extends(KDFileUploadView, _super);

  function KDFileUploadView(options, data) {
    if (window.FileReader != null) {
      if (options.limit == null) {
        options.limit = 20;
      }
      if (options.fileMaxSize == null) {
        options.fileMaxSize = 4096;
      }
      if (options.filetotalSize == null) {
        options.filetotalSize = 4096;
      }
      if (options.extensions == null) {
        options.extensions = null;
      }
      if (options.preview == null) {
        options.preview = "list";
      }
      if (options.title == null) {
        options.title = "Drop your files here!";
      }
      if (options.onlyOne == null) {
        options.onlyOne = false;
      }
      KDFileUploadView.__super__.constructor.call(this, options, data);
      this.listController = null;
      this.addDropArea();
      this.addList();
      this.files = {};
      this.totalSizeToUpload = 0;
      this.setClass("kdfileupload");
    } else {
      KDFileUploadView.__super__.constructor.call(this, options, data);
      this.setPartial("<p class='warning info'><strong>Oops sorry,</strong> file upload is only working on Chrome, Firefox and Opera at the moment. We're working on a fix.</p>");
    }
  }

  KDFileUploadView.prototype.addDropArea = function() {
    this.dropArea = new KDFileUploadArea({
      title: this.getOptions().title,
      bind: 'drop dragenter dragleave dragover dragstart dragend',
      cssClass: "kdfileuploadarea",
      delegate: this
    });
    return this.addSubView(this.dropArea);
  };

  KDFileUploadView.prototype.addList = function() {
    this.fileList = (function() {
      switch (this.getOptions().preview) {
        case "thumbs":
          return this.addThumbnailList();
        default:
          return this.addFileList();
      }
    }).call(this);
    this.listController = new KDListViewController({
      view: this.fileList
    });
    return this.addSubView(this.listController.getView());
  };

  KDFileUploadView.prototype.addFileList = function() {
    return new KDFileUploadListView({
      delegate: this
    });
  };

  KDFileUploadView.prototype.addThumbnailList = function() {
    return new KDFileUploadThumbListView({
      delegate: this
    });
  };

  KDFileUploadView.prototype.fileDropped = function(file) {
    var uploader;
    uploader = new KDMultipartUploader({
      url: '/Upload',
      file: file
    });
    uploader.send();
    uploader.once('FileReadComplete', (function(_this) {
      return function(event) {
        _this.emit('FileReadComplete', {
          file: file,
          progressEvent: event
        });
        return _this.fileReadComplete(file, event);
      };
    })(this));
    uploader.once('FileUploadSuccess', (function(_this) {
      return function(res) {
        return _this.fileUploadComplete(file, res);
      };
    })(this));
    return uploader.once('FileUploadError', this.bound('handleUploadError'));
  };

  KDFileUploadView.prototype.handleUploadError = function(xhr) {};

  KDFileUploadView.prototype.fileUploadComplete = function(file, res) {
    var _ref;
    if ((_ref = this.fileList.itemsByName[file.name]) != null) {
      _ref.setClass('uploaded');
    }
    return this.emit('FileUploadComplete', res);
  };

  KDFileUploadView.prototype.fileReadComplete = function(file, event) {
    file.data = event.target.result;
    return this.putFileInQueue(file);
  };

  KDFileUploadView.prototype.putFileInQueue = function(file) {
    if (this.getOptions().onlyOne) {
      this.files = {};
      this.fileList.empty();
    }
    if (!this.isDuplicate(file) && this.checkLimits(file)) {
      this.files[file.name] = file;
      this.fileList.addItem(file);
      return true;
    } else {
      return false;
    }
  };

  KDFileUploadView.prototype.removeFile = function(pubInst, event) {
    var file;
    file = pubInst.getData();
    delete this.files[file.name];
    return this.fileList.removeItem(pubInst);
  };

  KDFileUploadView.prototype.isDuplicate = function(file) {
    if (this.files[file.name] != null) {
      this.notify("File is already in queue!");
      return true;
    } else {
      return false;
    }
  };

  KDFileUploadView.prototype.checkLimits = function(file) {
    return this.checkFileAmount() && this.checkFileSize(file) && this.checkTotalSize(file);
  };

  KDFileUploadView.prototype.checkFileAmount = function() {
    var amount, file, maxAmount, name, _ref;
    maxAmount = this.getOptions().limit;
    amount = 1;
    _ref = this.files;
    for (name in _ref) {
      if (!__hasProp.call(_ref, name)) continue;
      file = _ref[name];
      amount++;
    }
    if (amount > maxAmount) {
      this.notify("Total number of allowed file is " + maxAmount);
      return false;
    } else {
      return true;
    }
  };

  KDFileUploadView.prototype.checkTotalSize = function(file) {
    var name, totalMaxSize, totalSize, _ref;
    totalMaxSize = this.getOptions().totalMaxSize;
    totalSize = file.size;
    _ref = this.files;
    for (name in _ref) {
      if (!__hasProp.call(_ref, name)) continue;
      file = _ref[name];
      totalSize += file.size;
    }
    if (totalSize / 1024 > totalMaxSize) {
      this.notify("Total allowed filesize is " + totalMaxSize + " kilobytes");
      return false;
    } else {
      return true;
    }
  };

  KDFileUploadView.prototype.checkFileSize = function(file) {
    var fileMaxSize;
    fileMaxSize = this.getOptions().fileMaxSize;
    if (file.size / 1024 > fileMaxSize) {
      this.notify("Maximum allowed filesize is " + fileMaxSize + " kilobytes");
      return false;
    } else {
      return true;
    }
  };

  KDFileUploadView.prototype.notify = function(title) {
    return new KDNotificationView({
      title: title,
      duration: 2000,
      type: "tray"
    });
  };

  return KDFileUploadView;

})(KDView);


},{"./../../core/view.coffee":108,"./../list/listviewcontroller.coffee":55,"./../notifications/notificationview.coffee":61,"./fileuploadarea.coffee":89,"./fileuploadlistview.coffee":91,"./fileuploadthumblistview.coffee":93,"./multipartuploader.coffee":95}],95:[function(require,module,exports){
var KDEventEmitter, KDMultipartUploader,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDEventEmitter = require('./../../core/eventemitter.coffee');

module.exports = KDMultipartUploader = (function(_super) {
  var boundary;

  __extends(KDMultipartUploader, _super);

  boundary = "gc0p4Jq0M2Yt08jU534c0p";

  function KDMultipartUploader(_arg) {
    var id;
    this.url = _arg.url, this.file = _arg.file, id = _arg.id;
    if (!("FileReader" in window)) {
      throw new Error("FileReader API not found!");
    }
    KDMultipartUploader.__super__.constructor.call(this);
    this.id = id != null ? id : 'file';
  }

  KDMultipartUploader.prototype.makeMultipartItem = function(name, value) {
    return "--" + boundary + "\r\n Content-Disposition: form-data; name=\"" + name + "\"\r\n\r\n " + value + "\r\n";
  };

  KDMultipartUploader.prototype.serializedToMultipart = function(list) {
    var i;
    return ((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = list.length; _i < _len; _i++) {
        i = list[_i];
        _results.push(this.makeMultipartItem(i.name, i.value));
      }
      return _results;
    }).call(this)).join("");
  };

  KDMultipartUploader.prototype.fileToMultipart = function(callback) {
    var fr, wrapFile;
    fr = new FileReader;
    if (!this.file) {
      return callback("");
    }
    wrapFile = (function(_this) {
      return function(fileData) {
        return "--" + boundary + "\r\n Content-Disposition: form-data; name=\"" + _this.id + "\"; filename=\"" + _this.file.name + "\"\r\n Content-Type: " + _this.file.type + "\r\n\r\n " + fileData + "\r\n --" + boundary + "--\r\n";
      };
    })(this);
    fr.onload = (function(_this) {
      return function(event) {
        if (event.loaded !== event.total) {
          return;
        }
        _this.emit('FileReadComplete', event);
        return callback(wrapFile(event.currentTarget.result));
      };
    })(this);
    return fr.readAsBinaryString(this.file);
  };

  KDMultipartUploader.prototype.send = function() {
    var body, fr, xhr;
    fr = new FileReader;
    xhr = new XMLHttpRequest;
    body = "";
    xhr.open("POST", this.url, true);
    xhr.setRequestHeader("Content-Type", "multipart/form-data; boundary=" + boundary);
    xhr.onreadystatechange = (function(_this) {
      return function() {
        if (xhr.readyState !== 4) {
          return;
        }
        if (xhr.status >= 200 && xhr.status < 400) {
          return _this.emit('FileUploadSuccess', JSON.parse(xhr.responseText));
        } else {
          return _this.emit('FileUploadError', xhr);
        }
      };
    })(this);
    body += this.serializedToMultipart([
      {
        name: "" + this.id + "-size",
        value: this.file.size
      }
    ]);
    this.fileToMultipart(function(fileData) {
      var arrb, blob, i, len, ui8a;
      body += fileData;
      len = i = body.length;
      arrb = new ArrayBuffer(len);
      ui8a = new Uint8Array(arrb);
      while (i--) {
        ui8a[i] = body.charCodeAt(i) & 0xff;
      }
      blob = new Blob([ui8a]);
      return xhr.send(blob);
    });
    return this;
  };

  return KDMultipartUploader;

})(KDEventEmitter);


},{"./../../core/eventemitter.coffee":98}],96:[function(require,module,exports){
var KDController, KDObject,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDObject = require('./object.coffee');

module.exports = KDController = (function(_super) {
  __extends(KDController, _super);

  function KDController() {
    return KDController.__super__.constructor.apply(this, arguments);
  }

  return KDController;

})(KDObject);


},{"./object.coffee":104}],97:[function(require,module,exports){
var KDCustomHTMLView, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./view.coffee');

module.exports = KDCustomHTMLView = (function(_super) {
  __extends(KDCustomHTMLView, _super);

  function KDCustomHTMLView(options, data) {
    var _ref, _ref1;
    if (options == null) {
      options = {};
    }
    if (typeof options === 'string') {
      this.tagName = options;
    }
    if (this.tagName == null) {
      this.tagName = (_ref = options.tagName) != null ? _ref : 'div';
    }
    if (this.tagName === 'a' && (((_ref1 = options.attributes) != null ? _ref1.href : void 0) == null)) {
      options.attributes || (options.attributes = {});
      options.attributes.href = '#';
    }
    KDCustomHTMLView.__super__.constructor.call(this, options, data);
  }

  KDCustomHTMLView.prototype.setDomElement = function(cssClass) {
    var el;
    KDCustomHTMLView.__super__.setDomElement.apply(this, arguments);
    this.unsetClass('kdview');
    el = this.getElement();
    if (!el.classList.length) {
      return el.removeAttribute('class');
    }
  };

  return KDCustomHTMLView;

})(KDView);


},{"./view.coffee":108}],98:[function(require,module,exports){
var KDEventEmitter,
  __slice = [].slice;

module.exports = KDEventEmitter = (function() {
  var _off, _on, _registerEvent, _unregisterEvent;

  KDEventEmitter.registerStaticEmitter = function() {
    return this._e = {};
  };

  _registerEvent = function(registry, eventName, listener) {
    if (registry[eventName] == null) {
      registry[eventName] = [];
    }
    return registry[eventName].push(listener);
  };

  _unregisterEvent = function(registry, eventName, listener) {
    var cbIndex;
    if (!eventName || eventName === "*") {
      return registry = {};
    } else if (listener && registry[eventName]) {
      cbIndex = registry[eventName].indexOf(listener);
      if (cbIndex >= 0) {
        return registry[eventName].splice(cbIndex, 1);
      }
    } else {
      return registry[eventName] = [];
    }
  };

  _on = function(registry, eventName, listener) {
    var name, _i, _len, _results;
    if (eventName == null) {
      throw new Error('Try passing an event, genius!');
    }
    if (listener == null) {
      throw new Error('Try passing a listener, genius!');
    }
    if (Array.isArray(eventName)) {
      _results = [];
      for (_i = 0, _len = eventName.length; _i < _len; _i++) {
        name = eventName[_i];
        _results.push(_registerEvent(registry, name, listener));
      }
      return _results;
    } else {
      return _registerEvent(registry, eventName, listener);
    }
  };

  _off = function(registry, eventName, listener) {
    var name, _i, _len, _results;
    if (Array.isArray(eventName)) {
      _results = [];
      for (_i = 0, _len = eventName.length; _i < _len; _i++) {
        name = eventName[_i];
        _results.push(_unregisterEvent(registry, name, listener));
      }
      return _results;
    } else {
      return _unregisterEvent(registry, eventName, listener);
    }
  };

  KDEventEmitter.emit = function() {
    var args, eventName, listener, listeners, _base, _i, _len;
    if (this._e == null) {
      throw new Error('Static events are not enabled for this constructor.');
    }
    eventName = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    listeners = (_base = this._e)[eventName] != null ? _base[eventName] : _base[eventName] = [];
    for (_i = 0, _len = listeners.length; _i < _len; _i++) {
      listener = listeners[_i];
      listener.apply(null, args);
    }
    return this;
  };

  KDEventEmitter.on = function(eventName, listener) {
    if ('function' !== typeof listener) {
      throw new Error('listener is not a function');
    }
    if (this._e == null) {
      throw new Error('Static events are not enabled for this constructor.');
    }
    this.emit('newListener', listener);
    _on(this._e, eventName, listener);
    return this;
  };

  KDEventEmitter.off = function(eventName, listener) {
    this.emit('listenerRemoved', eventName, listener);
    _off(this._e, eventName, listener);
    return this;
  };

  function KDEventEmitter(options) {
    var maxListeners;
    if (options == null) {
      options = {};
    }
    maxListeners = options.maxListeners;
    this._e = {};
    this._maxListeners = maxListeners > 0 ? maxListeners : 10;
  }

  KDEventEmitter.prototype.emit = function() {
    var args, eventName, listenerStack, _base;
    eventName = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    if ((_base = this._e)[eventName] == null) {
      _base[eventName] = [];
    }
    listenerStack = [];
    listenerStack = listenerStack.concat(this._e[eventName].slice(0));
    listenerStack.forEach((function(_this) {
      return function(listener) {
        return listener.apply(_this, args);
      };
    })(this));
    return this;
  };

  KDEventEmitter.prototype.on = function(eventName, listener) {
    if ('function' !== typeof listener) {
      throw new Error('listener is not a function');
    }
    this.emit('newListener', eventName, listener);
    _on(this._e, eventName, listener);
    return this;
  };

  KDEventEmitter.prototype.off = function(eventName, listener) {
    this.emit('listenerRemoved', eventName, listener);
    _off(this._e, eventName, listener);
    return this;
  };

  KDEventEmitter.prototype.once = function(eventName, listener) {
    var _listener;
    _listener = (function(_this) {
      return function() {
        var args;
        args = [].slice.call(arguments);
        _this.off(eventName, _listener);
        return listener.apply(_this, args);
      };
    })(this);
    this.on(eventName, _listener);
    return this;
  };

  return KDEventEmitter;

})();


},{}],99:[function(require,module,exports){
var KDEventEmitter,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

KDEventEmitter = require('./eventemitter.coffee');

module.exports = KDEventEmitter.Wildcard = (function(_super) {
  var getAllListeners, listenerKey, removeAllListeners, wildcardKey;

  __extends(Wildcard, _super);

  wildcardKey = '*';

  listenerKey = '_listeners';

  function Wildcard(options) {
    if (options == null) {
      options = {};
    }
    Wildcard.__super__.constructor.apply(this, arguments);
    this._delim = options.delimiter || '.';
  }

  Wildcard.prototype.setMaxListeners = function(n) {
    return this._maxListeners = n;
  };

  getAllListeners = function(node, edges, i) {
    var listeners, nextNode, straight, wild;
    if (i == null) {
      i = 0;
    }
    listeners = [];
    if (i === edges.length) {
      straight = node[listenerKey];
    }
    wild = node[wildcardKey];
    nextNode = node[edges[i]];
    if (straight != null) {
      listeners = listeners.concat(straight);
    }
    if (wild != null) {
      listeners = listeners.concat(getAllListeners(wild, edges, i + 1));
    }
    if (nextNode != null) {
      listeners = listeners.concat(getAllListeners(nextNode, edges, i + 1));
    }
    return listeners;
  };

  removeAllListeners = function(node, edges, it, i) {
    var edge, listener, listeners, nextNode;
    if (i == null) {
      i = 0;
    }
    edge = edges[i];
    nextNode = node[edge];
    if (nextNode != null) {
      return removeAllListeners(nextNode, edges, it, i + 1);
    }
    if ((it != null) && ((listeners = node[listenerKey]) != null)) {
      node[listenerKey] = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = listeners.length; _i < _len; _i++) {
          listener = listeners[_i];
          if (listener !== it) {
            _results.push(listener);
          }
        }
        return _results;
      })();
    } else {
      node[listenerKey] = [];
    }
  };

  Wildcard.prototype.emit = function() {
    var eventName, listener, listeners, oldEvent, rest, _i, _len;
    eventName = arguments[0], rest = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    "use strict";
    if (this.hasOwnProperty('event')) {
      oldEvent = this.event;
    }
    this.event = eventName;
    listeners = getAllListeners(this._e, eventName.split(this._delim));
    for (_i = 0, _len = listeners.length; _i < _len; _i++) {
      listener = listeners[_i];
      listener.apply(this, rest);
    }
    if (oldEvent != null) {
      this.event = oldEvent;
    } else {
      delete this.event;
    }
    return this;
  };

  Wildcard.prototype.off = function(eventName, listener) {
    removeAllListeners(this._e, (eventName != null ? eventName : '*').split(this._delim), listener);
    return this;
  };

  Wildcard.prototype.on = function(eventName, listener) {
    var edge, edges, listeners, node, _i, _len;
    if ('function' !== typeof listener) {
      throw new Error('listener is not a function');
    }
    this.emit('newListener', eventName, listener);
    edges = eventName.split('.');
    node = this._e;
    for (_i = 0, _len = edges.length; _i < _len; _i++) {
      edge = edges[_i];
      node = node[edge] != null ? node[edge] : node[edge] = {};
    }
    listeners = node[listenerKey] != null ? node[listenerKey] : node[listenerKey] = [];
    listeners.push(listener);
    return this;
  };

  return Wildcard;

})(KDEventEmitter);


},{"./eventemitter.coffee":98}],100:[function(require,module,exports){
var e, noop, utils,
  __hasProp = {}.hasOwnProperty;

utils = window.utils = require('./utils.coffee');

require('./support');

window.KD || (window.KD = {});

noop = window.noop = function() {};

KD.log = window.log = console.log.bind(console);

KD.warn = window.warn = console.warn.bind(console);

KD.error = window.error = console.error.bind(console);

if (window.event == null) {
  try {
    Object.defineProperty(window, "event", {
      get: function() {
        return KD.warn("Global \"event\" property is accessed. Did you forget a parameter in a DOM event handler?");
      }
    });
  } catch (_error) {
    e = _error;
    log("we fail silently!", e);
  }
}

window.KD = $.extend(window.KD, (function() {
  var create;
  create = function(constructorName, options, data) {
    var konstructor, _ref;
    konstructor = (_ref = this.classes[constructorName]) != null ? _ref : this.classes["KD" + constructorName];
    if (konstructor != null) {
      return new konstructor(options, data);
    }
  };
  return {
    create: create,
    "new": create,
    debugStates: {},
    instances: {},
    singletons: {},
    subscriptions: [],
    classes: {},
    utils: utils,
    lastFuncCall: null,
    instancesToBeTested: {},
    registerInstance: function(anInstance) {
      if (this.instances[anInstance.id]) {
        warn("Instance being overwritten!!", anInstance);
      }
      return this.instances[anInstance.id] = anInstance;
    },
    unregisterInstance: function(anInstanceId) {
      return delete this.instances[anInstanceId];
    },
    deleteInstance: function(anInstanceId) {
      return this.unregisterInstance(anInstanceId);
    },
    extend: function(obj) {
      var key, val, _results;
      _results = [];
      for (key in obj) {
        val = obj[key];
        if (this[key]) {
          throw new Error("" + key + " is already registered");
        } else {
          _results.push(this[key] = val);
        }
      }
      return _results;
    },
    registerSingleton: function(singletonName, object, override) {
      var existingSingleton;
      if (override == null) {
        override = false;
      }
      if ((existingSingleton = KD.singletons[singletonName]) != null) {
        if (override) {
          warn("singleton overriden! KD.singletons[\"" + singletonName + "\"]");
          if (typeof existingSingleton.destroy === "function") {
            existingSingleton.destroy();
          }
          return KD.singletons[singletonName] = object;
        } else {
          error("KD.singletons[\"" + singletonName + "\"] singleton exists! if you want to override set override param to true]");
          return KD.singletons[singletonName];
        }
      } else {
        return KD.singletons[singletonName] = object;
      }
    },
    getSingleton: function(singletonName) {
      if (KD.singletons[singletonName] != null) {
        return KD.singletons[singletonName];
      } else {
        warn("\"" + singletonName + "\" singleton doesn't exist!");
        return null;
      }
    },
    getAllKDInstances: function() {
      return KD.instances;
    },
    exportKDFramework: function() {
      var item, _ref;
      _ref = KD.classes;
      for (item in _ref) {
        if (!__hasProp.call(_ref, item)) continue;
        window[item] = KD.classes[item];
      }
      KD.exportKDFramework = function() {
        return "Already exported.";
      };
      return "KDFramework loaded successfully.";
    },
    registerInstanceForTesting: function(instance) {
      var key;
      key = instance.getOption('testPath');
      this.instancesToBeTested[key] = instance;
      return instance.on('KDObjectWillBeDestroyed', (function(_this) {
        return function() {
          return delete _this.instancesToBeTested[key];
        };
      })(this));
    },
    getInstanceForTesting: function(key) {
      return this.instancesToBeTested[key];
    }
  };
})());

module.exports = KD;


},{"./support":106,"./utils.coffee":107}],101:[function(require,module,exports){
/*Copyright (c) 2012 Jessie

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.*/


/*
Return URI:
http://127.0.0.1:1337/?addClass=1&appendChild=1&appendHtml=1&createElement=1&findProprietaryStyle=1&getAncestorByClassName=1&getAncestorByTagName=1&getDescendantsByClassName=1&getDescendantsByTagName=1&getElement=1&getElementParentElement=1&getElementPositionStyles=1&getElementTagName=1&getHtml=1&getInnerSize=1&getOuterSize=1&getPositionRelativeToDocument=1&getPositionRelativeToViewport=1&getStyleComputed=1&getText=3&hasClass=1&isDescendant=1&isInQuery=1&isNodeInNodeList=1&prependHtml=1&query=1&removeChild=1&removeClass=1&setHtml=1&setPosition=1&setSize=1&setText=3&attachBoundListener=1&attachBoundWindowListener=1&attachDocumentListener=1&attachListener=1&attachWindowListener=1&cancelDefault=1&cancelPropagation=1&delegateBoundClassNameListener=1&delegateBoundListener=1&delegateBoundQueryListener=1&delegateListener=1&delegateQueryListener=1&delegateTagNameListener=1&detachBoundListener=1&detachListener=1&detachWindowListener=1&getEventTarget=1&getEventTargetRelated=1&bind=1&getViewportScrollPosition=1&getViewportSize=1&htmlToNodes=1&setInputValue=1&setViewportScrollPosition=1&toArray=1&undelegateListener=1&undelegateQueryListener=1
*/

var KD = {};
KD.dom = KD.dom || {};
(function(global) {

	var globalDocument = global.document,
		isHostObjectProperty = function(object, property) {
			var objectProperty = object[property];
			return typeof objectProperty == 'object' && null !== objectProperty;
		},
		isHostMethod = function(object, method) {
			var objectMethod = object[method];
			var type = typeof objectMethod;
			return	type == 'function' ||
					type == 'object' && null !== objectMethod ||
					type == 'unknown';
		},
		areFeatures = function() {
			var i = arguments.length;
			while (i--) {
				if (!KD.dom[arguments[i]]) {
				return false;
				}
			}
			return true;
		},
		html = isHostObjectProperty(globalDocument, 'documentElement') && globalDocument.documentElement,
		canCall = !!Function.prototype.call,
		isStyleCapable = !!(html && isHostObjectProperty(html, 'style'));



/*
Description:
*/

var toArray;

toArray = function(a) {
	var result = [];
	for (var i = 0, l = a.length; i < l; i++) {
		result[i] = a[i];
	}
	return result;
};



/*
Description:
Relies on W3C `el.removeEventListener`
*/

/*
Degrades:
IE8, IE7, IE6, IE5.5, IE5, IE4, IE3, NN4, Opera 7.6
*/

/*
Author:
David Mark
*/

var detachListener;

if(html && isHostMethod(html, 'removeEventListener')) {
	detachListener = function(el, eventType, fn) {
		el.removeEventListener(eventType, fn, false);
	};
}



/*
Description:
Relies on W3C `e.target`
*/

/*
Degrades:
IE8, IE7, IE6, IE5.5, IE5, IE4, IE3, Opera 7.6
*/

var getEventTarget;

if(html && isHostMethod(html, 'addEventListener')) {
	getEventTarget = function(e) {
		var target = e.target;
		// Check if not an element (e.g. a text node)
		if (1 != target.nodeType) {
			// Set reference to parent node (which must be an element)
			target = target.parentNode;
		}
		return target;
	};
}



/*
Description:
Relies on W3C `el.addEventListener`
*/

/*
Degrades:
IE8, IE7, IE6, IE5.5, IE5, IE4, IE3, Opera 7.6
*/

/*
Author:
David Mark
*/

var attachListener;

if(html && isHostMethod(html, 'addEventListener')) {
	attachListener = function(el, eventType, fn) {

		var listener = function(e) {
			fn.call(el, e);
		};

		el.addEventListener(eventType, listener, false);

		return listener;
	};
}



/*
Description:
Relies on `document.querySelectorAll` and `jessie.toArray`
*/

/*
Author:
David Mark
*/

var query;

if(globalDocument && isHostMethod(globalDocument, 'querySelectorAll') && toArray) {
	query = function(selector, doc) {
		return toArray((doc || document).querySelectorAll(selector));
	};
}

/*
Description:
Relies on `document.querySelector` and `jessie.toArray`
*/

/*
Author:
Christopher Thorn
*/

var queryOne;

if(globalDocument && isHostMethod(globalDocument, 'querySelector')) {
	queryOne = function(selector, doc) {
		return (doc || document).querySelector(selector);
	};
}



/*
Description:
Iterates a node list to see if any of the nodes match the passed in node.
*/

/*
Author:
Graham Veal
*/

var isNodeInNodeList;

isNodeInNodeList = function( node, nodeList ){

	var isInNodeList = false,
		i = 0,
		l = nodeList.length;

	// could use Array.prototype.indexOf in another rendition
	for( ; i < l; i++ ) {
		if(nodeList[i] === node) {
			isInNodeList = true;
			break;
		}
	}

	return isInNodeList;
};



/*
Description:
Relies on `Function.prototype.bind`
*/

/*
Degrades:
IE8, IE7, IE6, IE5.5, IE5, IE4, IE3, Chrome 6, Firefox 3.6, Safari 5.1, Opera 11.5
*/

/*
Author:
David Mark
*/

var bind;

if(canCall && Function.prototype.bind){
    bind = function(fn, thisObject) {
        return fn.bind.apply(fn, Array.prototype.slice.call(arguments, 1));
    };
}



/*
Description:
Relies on `jessie.detachListener`
*/

/*
Author:
Adam Silver
*/

var undelegateListener;

if(detachListener) {
	undelegateListener = function(el, eventType, delegateListener) {
		return detachListener(el, eventType, delegateListener);
	};
}



/*
Description:
Relies on `jessie.attachListener` and `jessie.getEventTarget` `Function.prototype.call`
*/

/*
Author:
Adam Silver
*/

var delegateListener;

if(attachListener && getEventTarget && canCall) {
	delegateListener = function(el, eventType, fn, fnDelegate) {

		var listener = function(e) {
			var currentTarget = fnDelegate(el, getEventTarget(e));
			if(currentTarget) {
				fn.call(currentTarget, e, currentTarget, el);
			}
		};

		return attachListener(el, eventType, listener);
	};
}



var getElementTagName;

/*
Description:
Relies on `el.tagName` or `el.nodeName`
*/

getElementTagName = function (el) {
	var tagName = (el.tagName || el.nodeName).toLowerCase();
	return tagName.indexOf('html:') > -1 ? tagName.substring(5) : tagName;
};



/*global html, globalDocument, isHostObjectProperty*/

var getElementParentElement;

/*
Description:
Relies on `el.parentNode`
*/

/*
Degrades:
IE5, IE4, IE3
*/

if (html && isHostObjectProperty(html, 'parentNode')) {
	getElementParentElement = function(el) {
		var parentNode = el.parentNode,
			parentElement = null;

		if (parentNode && (parentNode.tagName || parentNode.nodeType == 1)) {
			parentElement = parentNode;
		}
		return parentElement;
	};
}



/*
Description:
Relies on `jessie.isNodeInNodeList`, `jessie.query`
*/

/*
Author:
Graham Veal
*/

var isInQuery;

if(isNodeInNodeList && query) {
	isInQuery = function(el, selector) {

		return isNodeInNodeList( el, query(selector) );
	};
}



/*
Description:
Relies on `el.parentNode` which has very good support
*/

/*
Degrades:
In browsers without `el.parentNode`
*/

var isDescendant;

if(html && 'undefined' != typeof html.parentNode) {
	isDescendant = function(el, elDescendant) {
		var parent = elDescendant.parentNode;
		while(parent && parent != el) {
			parent = parent.parentNode;
		}
		return parent == el;
	};
}



/*
Description:
Relies on `jessie.attachListener`, `jessie.bind` and `jessie.getEventTarget` and `Function.prototype.call`
*/

/*
Author:
Adam Silver
*/

var delegateBoundListener;

if(attachListener && bind && getEventTarget && canCall) {
	delegateBoundListener = function(el, eventType, fn, fnDelegate, thisObject) {

		var listener = bind(function(e) {
			var currentTarget = fnDelegate(el, getEventTarget(e));
			if(currentTarget) {
				fn.call(thisObject, e, currentTarget);
			}
		}, thisObject);

		return attachListener(el, eventType, listener);
	};
}



/*
Description:
Relies on the `el.classList.contains`
*/

/*
Degrades:
IE9, IE8, IE7, IE6, IE5.5, IE5, IE4, IE3, Chrome 7, FF3.5, Safari 5.0, Opera 11.1, IOS Safari 4.3, Opera Mini 6.0, Opera Mobile 11.0, Android Safari 2.3
*/

/*
Author:
Adam Silver
*/

var hasClass;

if (html && isHostObjectProperty(html, "classList") && isHostMethod(html.classList, "contains") ) {
	hasClass = function(el, className) {
		return el.classList.contains(className);
	};
}




/*
Description:
Relies on `window.addEventListener`. No frames.
*/

/*
Degrades:
IE8, IE7, IE6, IE5.5, IE5, IE4, IE3, Opera 7.6
*/

/*
Author:
David Mark
*/

var attachWindowListener;

if(window && isHostMethod(window, 'addEventListener')) {
	attachWindowListener = function(eventType, fn) {

		var listener = function(e) {
			fn.call(window, e);
		};

		window.addEventListener(eventType, listener, false);

		return listener;
	};
}



/*
Description:
Relies on `window.page(X/Y)Offset
*/

/*
Author:
David Mark
*/

var getViewportScrollPosition;

if('number' == typeof window.pageXOffset && 'number' == typeof window.pageYOffset ) {
	getViewportScrollPosition = function() {
		return [window.pageXOffset, window.pageYOffset];
	};
}



/*
Description:
Relies on `el.getBoundingClientRect`
*/

//https://groups.google.com/group/comp.lang.javascript/browse_thread/thread/cd625a14ce603084?hl=en&noredirect=true

/*
Author:
David Mark
*/

var getPositionRelativeToViewport;

if(html && isHostMethod(html, 'getBoundingClientRect')) {
	getPositionRelativeToViewport = function(el) {
		var rect = el.getBoundingClientRect();
		return [rect.left, rect.top];
	};
}



/*
Description:
Basic rendition which relies on valid markup i.e. forms with unique names and ids
*/

/*
See: <a href="https://groups.google.com/forum/#!starred/comp.lang.javascript/fVp-DWAIGnc">Article</a>

That's the most basic rendition: no allowance for screwy markup like this:

<input name="test">
<input id="test">
*/

/*
Degrades:
IE4, IE3, NN4
*/

/*
Author:
David Mark
*/

var getElement;

if (isHostMethod(document, 'getElementById')) {
	getElement = function(id, doc) {
		return (doc || document).getElementById(id);
	};
}



/*
Description:
Relies on `jessie.undelegateListener`
*/

/*
could have simply used detachListener
but this reinforces  that this function
expects a delegate listener which was returned
when it was attached
*/

/*
Author:
Adam Silver
*/

var undelegateQueryListener;

if(undelegateListener) {
	undelegateQueryListener = function(el, eventType, listener) {
		return undelegateListener(el, eventType, listener);
	};
}



/*
Description:
Relies on `window.scrollTo`
*/

var setViewportScrollPosition;

if(isHostMethod(global, "scrollTo")) {
	setViewportScrollPosition = function(x, y) {
		window.scrollTo(x, y);
	};
}



var setInputValue;

/*
Description:
setInputValue
*/

setInputValue = function(elInput, value) {
    elInput.value = value;
};


var getViewportSize;

/*

Description:
Will likely *include* space occupied by scroll bars

*** Viewport META

Relies on:
Degrades: IE8
*/


/*
Author: David Mark
*/

if (typeof global.innerWidth == 'number') {
	getViewportSize = function(win /* window */) {
		if (!win) {
			win = window;
		}
		return [win.innerWidth, win.innerHeight]; // Array
	};
}



/*
Description:
Relies on W3C `e.relatedTarget`
*/

/*
Degrades:
IE8, IE7, IE6, IE5.5, IE5, IE4, IE3, Opera 7.6
*/

/*
Author:
David Mark
*/

var getEventTargetRelated;

if(html && isHostMethod(html, 'addEventListener')) {
	getEventTargetRelated = function(e) {
		var target = e.relatedTarget;
		// Check if not an element (e.g. a text node)
		if (1 != target.nodeType) {
			// Set reference to parent node (which must be an element)
			target = target.parentNode;
		}
		return target;
	};
}



/*
Description:
Relies on W3C `window.removeEventListener`
*/

/*
Degrades:
IE8, IE7, IE6, IE5.5, IE5, IE4, IE3, NN4, Opera 7.6
*/

/*
Author:
David Mark
*/

var detachWindowListener;

if(window && isHostMethod(window, 'removeEventListener')) {
	detachWindowListener = function(eventType, fn) {
		return window.removeEventListener(eventType, fn);
	};
}



/*
Description:
Relies on `jessie.detachListener`
*/

// could have simply used detachListener
// but this reinforces  that this function
// expects a bound listener

/*
Author:
David Mark
*/

var detachBoundListener;

if(detachListener) {
	detachBoundListener = function(el, eventType, boundListener) {
		return detachListener(el, eventType, boundListener);
	};
}



/*
Description:
Relies on `jessie.delegateListener` and `jessie.getElementTagName` and `jessie.getElementParentElement`
*/

/*
Author:
Adam Silver
*/

var delegateTagNameListener;

if(delegateListener && getElementTagName) {
	delegateTagNameListener = function(el, eventType, tagName, fn) {

		var fnDelegate = function(el, target) {
			var sourceNode,
				descendant;

			if(getElementTagName(target) === tagName) {
				sourceNode = target;
			} else {
				descendant = getElementParentElement(target);

				while (null !== descendant && descendant !== el) {
					if (getElementTagName(descendant) === tagName) {
						sourceNode = descendant;
						break;
					}
					descendant = getElementParentElement(descendant);
				}
			}
			return sourceNode;
		};

		return delegateListener(el, eventType, fn, fnDelegate);
	};
}



/*
Description:
Relies on `jessie.isNodeInNodeList`, `jessie.delegateListener`, `jessie.query` and `jessie.isDescendant`
*/

/*
Author:
Adam Silver, Graham Veal
*/

var delegateQueryListener;

if(isNodeInNodeList && delegateListener && query && isDescendant) {

	delegateQueryListener = function(el, eventType, selector, fn) {

		function fnDelegate(target) {

			var elements = query(selector),
				i = 0,
				l,
				el;

			if(isNodeInNodeList(target, elements)) {
				return target;
			}

			// its not in query so loop through by selector
			// if the target is a child of the element then
			// return that element

			for( l = elements.length ; i < l; i++ ) {

				el = elements[i];

				if( isDescendant(el, target) ) {
					return el;
				}
			}
		}

		return delegateListener(el, eventType, fn, fnDelegate);
	};
}



/*
Description:
Relies on `jessie.delegateBoundListener`, `jessie.query`, `jessie.isInQuery` and `jessie.isDecendant`
*/

/*
Author:
Adam Silver
*/

var delegateBoundQueryListener;

if(delegateBoundListener && query && isDescendant) {
	delegateBoundQueryListener = function(el, eventType, selector, fn, thisObject) {

		var fnDelegate = function(el, target) {
			if(isInQuery(target, selector)) {
				return target;
			}

			// its not in query so loop through by selector
			// if the target is a child of the element then
			// return that element
			var elements = jessie.query(selector);
			for(var i = 0; i < elements.length; i++) {
				if( isDescendant(elements[i], target) ) {
					return elements[i];
				}
			}
		};

		return delegateBoundListener(el, eventType, fn, fnDelegate, thisObject);
	};
}



/*
Description:
Relies on `jessie.delegateBoundListener`, `jessie.hasClass`, and `jessie.getElementParentElement`
*/

/*
Author:
Adam Silver
*/

var delegateBoundClassNameListener;

if(delegateBoundListener && hasClass && getElementParentElement) {
	delegateBoundClassNameListener = function(el, eventType, className, fn, thisObject) {

		var fnDelegate = function(el, target) {
			var currentTarget = target;

			if(el === currentTarget) {
				currentTarget = null;
			}

			// traverse up the tree until we find an element with the class or until we find the delegate/el
			while(currentTarget && (currentTarget !== el) && !hasClass(currentTarget, className)) {
				// if we clicked on the delegate/container/el then set to null
				currentTarget = getElementParentElement(currentTarget);
				if(el === currentTarget) {
					currentTarget = null;
				}
			}

			return currentTarget;
		};

		return delegateBoundListener(el, eventType, fn, fnDelegate, thisObject);
	};
}



/*
Description:
Relies on W3C compliant `e.stopPropagation()`
*/

/*
Degrades:
IE8, IE7, IE6, IE5.5, IE5, IE4, IE3, Opera 7.6
*/

/*
Author:
Adam Silver
*/

var cancelPropagation;

if(html && isHostMethod(html, 'addEventListener')) {
	cancelPropagation = function(e) {
		e.stopPropagation();
	};
}



/*
Description:
Relies on W3C compliant `e.preventDefault()`
*/

/*
Degrades:
IE8, IE7, IE6, IE5.5, IE5, IE4, IE3, Opera 7.6
*/

/*
Author:
Adam Silver
*/

var cancelDefault;

if(html && isHostMethod(html, 'addEventListener')) {
	cancelDefault = function(e) {
		e.preventDefault();
	};
}



/*
Description:
Relies on `document.addEventListener`.
*/

/*
Degrades:
IE8, IE7, IE6, IE5.5, IE5, IE4, IE3
*/

var attachDocumentListener;

if(globalDocument && isHostMethod(globalDocument, 'addEventListener') && attachListener) {
	attachDocumentListener = function(eventType, fn) {

		var listener = function(e) {
			fn.call(document, e);
		};

		return attachListener(document, eventType, fn);
	};
}



/*
Description:
Relies on `jessie.bind` and `jessie.attachWindowListener`
*/

/*
Author:
Adam Silver
*/

var attachBoundWindowListener;

if(attachWindowListener && bind) {
	attachBoundWindowListener = function(eventType, fn, thisObject) {
		var listener = bind(fn, thisObject);
		return attachWindowListener(eventType, listener);
	};
}



/*
Description:
Relies on `jessie.bind` and `jessie.attachListener`
*/

/*
Author:
Adam Silver
*/

var attachBoundListener;

if(bind && attachListener) {
	attachBoundListener = function(el, eventType, fn, thisObject) {
		var listener = bind(fn, thisObject);
		thisObject = null;
		return attachListener(el, eventType, listener);
	};
}



/*
Description:
Relies on `el.textContent` or `el.innerText` providing widest browser support.
*/

var setText;

if(html && "string" == typeof html.textContent) {
	setText = function(el, text) {
		el.textContent = text;
	};
} else if(html && "string" == typeof html.innerText) {
	setText = function(el, text) {
		el.innerText = text;
	};
}



var setSize;
if(html && isHostObjectProperty(html, "style")){
  setSize = (function() {
    var px = (typeof html.style.top == 'number') ? 0 : 'px';
    return function(el, h, w) {
      if (h !== null && h >= 0) { el.style.height = h + px; }
      if (w !== null && w >= 0) { el.style.width = w + px; }
    };
  }());
}



var setPosition;
if(html && isHostObjectProperty(html, "style")){
  setPosition = (function(el) {
    var px = (typeof html.style.top == 'number') ? 0 : 'px';
    return function(el, x, y) {
      if (x !== null) { el.style.left = x + px; }
      if (y !== null) { el.style.top = y + px; }
    };
  }());
}



/*
Description:
Relies on `el.innerHTML` which degrades in IE3
*/

/*
See: <a href="https://groups.google.com/forum/#!search/david$20mark$20innerHTML/comp.lang.javascript/QQ9ClOT6igQ/LIZ5QXmmuw0J">Related article</a>
NOTE: Don't use this rendition with anything but DIV's
*/

/*
Degrades:
IE3
*/

/*
Author:
David Mark
*/

var setHtml;

if(html && "string" == typeof html.innerHTML) {
	setHtml = function(el, html) {
		el.innerHTML = html;
	};
}



/*
Description:
Relies on the `el.classList.remove`
*/

/*
Degrades:
Chrome 7, FF3.5, IE9, Safari 5.0, Opera 11.1, IOS Safari 4.3, Opera Mini 6.0, Opera Mobile 11.0, Android Safari 2.3
*/

/*
Author:
Adam Silver
*/

var removeClass;

if (html && isHostObjectProperty(html, "classList") && isHostMethod(html.classList, "remove") ) {
    removeClass = function(el, className) {
			return el.classList.remove(className);
    };
}





/*
Description:
Relies on `el.removeChild`
*/

/*
Author:
Adam Silver
*/

var removeChild;

if(html && isHostMethod(html, "removeChild")) {
	removeChild = function(el, childNode) {
		return el.removeChild(childNode);
	};
}




/*
 Description:
 Relies on `el.insertAdjacentHTML
 IE6 `el.insertAdjacentHtml` does not work on table, tbody, thead, tr elements
 */

/*
 Degrades:
 IE3, Firefox 7, Safari 3, Opera 7
 */

/*
 Author:
 Ben Chidgey
 */

var prependHtml;

if (html && isHostMethod(html, 'insertAdjacentHTML')) {
	prependHtml = function (el, html) {
		el.insertAdjacentHTML('afterBegin', html);
	};
}



/*
Description:
Relies on `el.textContent` or `el.innerText` providing widest browser support.
*/

var getText;

if(html && "string" == typeof html.textContent) {
	getText = function(el) {
		return el.textContent;
	};
} else if(html && "string" == typeof html.innerText) {
	getText = function(el) {
		return el.innerText;
	};
}



/*
Description:
Relies on `document.defaultView.getComputedStyle` which degrades in IE8-
and compatibility modes. No float styles with this one and camel-case
names.
*/

/*
Degrades:
IE8, IE7, IE6, IE5.5, IE5, IE4, IE3
*/

/*
Author:
David Mark
*/

var getStyleComputed;

if (isHostObjectProperty(globalDocument, 'defaultView') &&
	isHostMethod(globalDocument.defaultView, 'getComputedStyle')) {
	getStyleComputed = function(el, style) {

		return document.defaultView.getComputedStyle(el, null)[style];
	};
}



/*
Description:

Note: no borders on the HTML element as that can add cross-browser complications (part of the chrome in IE and other MSHTML-based browsers, not so in others) and no quirks mode (as the BODY then becomes outermost element in the layout in IE and the BODY should be allowed to have borders).
*/

/*
Degrades:
*/

/*
Author:
Adam Silver
*/

var getPositionRelativeToDocument;

if(getPositionRelativeToViewport && getViewportScrollPosition) {
	getPositionRelativeToDocument = function(el) {
		var position = getPositionRelativeToViewport(el),
			scrollPosition = getViewportScrollPosition(),
			x = position[0]+scrollPosition[0],
			y = position[1]+scrollPosition[1];

		return [x, y];
	};
}



/*
Description:
Relies on `el.offsetWidth/Height`
*/

/*
Degrades:
IE3
*/

/*
Author:
David Mark
*/

var getOuterSize;

if(html && typeof html.offsetWidth == 'number') {
	getOuterSize = function(el) {
		return [el.offsetHeight, el.offsetWidth];
	};
}



/*
Description:
Relies on `el.clientWidth/Height`
*/

/*
Degrades:
IE3
*/

/*
Author:
David Mark
*/

var getInnerSize;

if(html && typeof html.clientWidth == 'number') {
	getInnerSize = function(el) {
		return [el.clientHeight, el.clientWidth];
	};
}



/*
Description:
Relies on `el.innerHTML`
*/

// See: https://groups.google.com/forum/#!search/david$20mark$20innerHTML/comp.lang.javascript/QQ9ClOT6igQ/LIZ5QXmmuw0J

/*
Degrades:
IE3
*/

/*
Author:
David Mark
*/

var getHtml;

if(html && "string" == typeof html.innerHTML) {
	getHtml = function(el) {
		return el.innerHTML;
	};
}


/*
Description:
Relies on 'document.getElementsByTagName'
*/

var getDescendantsByTagName;

if(globalDocument && isHostMethod(globalDocument, "getElementsByTagName") && toArray) {
	getDescendantsByTagName = function(el, tagName) {
		return toArray((el || document).getElementsByTagName(tagName));
	};
}



/*
Description:
Relies on 'document.getElementsByClassName'
*/

var getDescendantsByClassName;

if (globalDocument && isHostMethod(globalDocument, "getElementsByClassName") && toArray) {
	getDescendantsByClassName = function(el, className) {
		return toArray((el || document).getElementsByClassName(className));
	};
}



/*
Description:
Relies on `jessie.getElementParentElement` and `jessie.getElementTagName`
*/

var getAncestorByTagName;

if(getElementParentElement && getElementTagName){
	getAncestorByTagName = function(el, tagName) {
		el = getElementParentElement(el);
		while (el && tagName && getElementTagName(el) != tagName) {
			el = getElementParentElement(el);
		}
		return el;
	};
}



/*
Description:
Relies on `el.className` property, `jessie.getElementParentElement` and `jessie.hasClass`
*/

var getAncestorByClassName;

if(html && 'string' == typeof html.className && getElementParentElement && hasClass) {
	getAncestorByClassName = function(el, className) {
		el = getElementParentElement(el);
		while (el && !hasClass(el, className)) {
			el = getElementParentElement(el);
		}
		return el;
	};
}



var findProprietaryStyle;

if(html && isHostObjectProperty(html, "style")){
	findProprietaryStyle = function (style, el) {
		if ('string' != typeof el.style[style]) {
			var prefixes = ['Moz', 'O', 'Khtml', 'Webkit', 'Ms'],
			i = prefixes.length;
			style = style.charAt(0).toUpperCase() + style.substring(1);
			while ( i-- ) {
				if ('undefined' != typeof el.style[prefixes[i] + style]) {
					return prefixes[i] + style;
				}
			}
			return null;
		}
		return style;
	};
}




/*
Description:
Relies on `document.createElement`
*/

/*
Author:
David Mark
*/

var createElement;

if(globalDocument && isHostMethod(globalDocument, "createElement")) {
	createElement = function(tagName, doc) {
		return (doc || document).createElement(tagName);
	};
}


/* */

var htmlToNodes;

/*
 * htmlToNodes
 *
 * Relies on 'jessie.setHtml' and 'jessie.createElement'
 *
 */

if (setHtml && createElement) {
    htmlToNodes = function(html, docNode) {
        var c;

        elTemp = createElement('div', docNode);

        if (elTemp) {
            setHtml(html);
            c = elTemp.childNodes;
            elTemp = null;
        }

        return c;
    };
}





/*
 Description:
 Relies on `el.insertAdjacentHTML
 IE6 `el.insertAdjacentHtml` does not work on table, tbody, thead, tr elements
 */

/*
 Degrades:
 IE3, Firefox 7, Safari 3, Opera 7
 */

/*
 Author:
 Ben Chidgey
 */

var appendHtml;

if (html && isHostMethod(html, 'insertAdjacentHTML')) {
	appendHtml = function (el, html) {
		el.insertAdjacentHTML('beforeEnd', html);
	};
}



/*
Description:
Relies on `el.appendChild`
*/

/*
Author:
Adam Silver
*/

var appendChild;

if(html && isHostMethod(html, 'appendChild')) {
	appendChild = function(el, appendEl) {
		return el.appendChild(appendEl);
	};
}




/*
Description:
Relies on the `el.classList.add`
*/

/*
Degrades:
IE9, IE8, IE7, IE6, IE5.5, IE5, IE4, IE3 Chrome 7, FF3.5, Safari 5.0, Opera 11.1, IOS Safari 4.3, Opera Mini 6.0, Opera Mobile 11.0, Android Safari 2.3
*/

/*
See:
This is the see also section
*/

/*
Author:
Adam Silver
*/

var addClass;

if (html && isHostObjectProperty(html, "classList") && isHostMethod(html.classList, "add") ) {
	addClass = function(el, className) {
		return el.classList.add(className);
	};
}


KD.dom.isHostMethod = isHostMethod;
KD.dom.isHostObjectProperty = isHostObjectProperty;
KD.dom.areFeatures = areFeatures;
KD.dom.toArray = toArray;
KD.dom.detachListener = detachListener;
KD.dom.getEventTarget = getEventTarget;
KD.dom.attachListener = attachListener;
KD.dom.query = query;
KD.dom.queryOne = queryOne;
KD.dom.isNodeInNodeList = isNodeInNodeList;
KD.dom.bind = bind;
KD.dom.undelegateListener = undelegateListener;
KD.dom.delegateListener = delegateListener;
KD.dom.getElementTagName = getElementTagName;
KD.dom.getElementParentElement = getElementParentElement;
KD.dom.isInQuery = isInQuery;
KD.dom.isDescendant = isDescendant;
KD.dom.delegateBoundListener = delegateBoundListener;
KD.dom.hasClass = hasClass;
KD.dom.attachWindowListener = attachWindowListener;
KD.dom.getViewportScrollPosition = getViewportScrollPosition;
KD.dom.getPositionRelativeToViewport = getPositionRelativeToViewport;
KD.dom.getElement = getElement;
KD.dom.undelegateQueryListener = undelegateQueryListener;
KD.dom.setViewportScrollPosition = setViewportScrollPosition;
KD.dom.setInputValue = setInputValue;
KD.dom.getViewportSize = getViewportSize;
KD.dom.getEventTargetRelated = getEventTargetRelated;
KD.dom.detachWindowListener = detachWindowListener;
KD.dom.detachBoundListener = detachBoundListener;
KD.dom.delegateTagNameListener = delegateTagNameListener;
KD.dom.delegateQueryListener = delegateQueryListener;
KD.dom.delegateBoundQueryListener = delegateBoundQueryListener;
KD.dom.delegateBoundClassNameListener = delegateBoundClassNameListener;
KD.dom.cancelPropagation = cancelPropagation;
KD.dom.cancelDefault = cancelDefault;
KD.dom.attachDocumentListener = attachDocumentListener;
KD.dom.attachBoundWindowListener = attachBoundWindowListener;
KD.dom.attachBoundListener = attachBoundListener;
KD.dom.setText = setText;
KD.dom.setSize = setSize;
KD.dom.setPosition = setPosition;
KD.dom.setHtml = setHtml;
KD.dom.removeClass = removeClass;
KD.dom.removeChild = removeChild;
KD.dom.prependHtml = prependHtml;
KD.dom.getText = getText;
KD.dom.getStyleComputed = getStyleComputed;
KD.dom.getPositionRelativeToDocument = getPositionRelativeToDocument;
KD.dom.getOuterSize = getOuterSize;
KD.dom.getInnerSize = getInnerSize;
KD.dom.getHtml = getHtml;
KD.dom.getDescendantsByTagName = getDescendantsByTagName;
KD.dom.getDescendantsByClassName = getDescendantsByClassName;
KD.dom.getAncestorByTagName = getAncestorByTagName;
KD.dom.getAncestorByClassName = getAncestorByClassName;
KD.dom.findProprietaryStyle = findProprietaryStyle;
KD.dom.createElement = createElement;
KD.dom.htmlToNodes = htmlToNodes;
KD.dom.appendHtml = appendHtml;
KD.dom.appendChild = appendChild;
KD.dom.addClass = addClass;

	globalDocument = html = null;

}(window));

module.exports = KD.dom;
},{}],102:[function(require,module,exports){
var KDKeyboardListener,
  __hasProp = {}.hasOwnProperty;

module.exports = KDKeyboardListener = (function() {
  var makeUpdater;

  function KDKeyboardListener() {
    this.maps = {};
    this.isListening = false;
  }

  makeUpdater = function(fn) {
    return function() {
      var isListening, retVal;
      isListening = this.isListening;
      if (isListening) {
        this.reset();
      }
      retVal = fn.apply(this, arguments);
      if (isListening) {
        this.listen();
      }
      return retVal;
    };
  };

  KDKeyboardListener.prototype.addComboMap = makeUpdater(function(comboMap, priority) {
    var m, _base, _name, _ref;
    m = (_base = this.maps)[_name = (_ref = priority != null ? priority : comboMap.priority) != null ? _ref : 0] != null ? _base[_name] : _base[_name] = [];
    m.push(comboMap);
    return this;
  });

  KDKeyboardListener.prototype.removeComboMap = makeUpdater(function(comboMap) {
    var ms, priority, _ref;
    _ref = this.maps;
    for (priority in _ref) {
      if (!__hasProp.call(_ref, priority)) continue;
      ms = _ref[priority];
      this.maps[priority] = ms.filter(function(m) {
        return m !== comboMap;
      });
    }
    return this;
  });

  KDKeyboardListener.prototype.listen = function() {
    var seen, _ref;
    if (this.isActive()) {
      return this;
    }
    if ((_ref = KDKeyboardListener.currentListener) != null) {
      _ref.reset();
    }
    seen = {};
    this.combos(function(combo, options, listener) {
      var method;
      if (options == null) {
        options = {
          global: true
        };
      }
      if (seen[combo]) {
        return;
      }
      seen[combo] = true;
      method = options.global ? 'bindGlobal' : 'bind';
      return Mousetrap[method](combo, listener);
    });
    KDKeyboardListener.currentListener = this;
    this.isListening = true;
    return this;
  };

  KDKeyboardListener.prototype.reset = function() {
    if (!this.isActive()) {
      return this;
    }
    Mousetrap.reset();
    this.isListening = false;
    KDKeyboardListener.currentListener = null;
    return this;
  };

  KDKeyboardListener.prototype.getCombos = function() {
    return Object.keys(this.maps).sort(function(a, b) {
      return b - a;
    }).map((function(_this) {
      return function(k) {
        return _this.maps[k];
      };
    })(this)).reduce(function(a, b) {
      return a.concat(b);
    }, []);
  };

  KDKeyboardListener.prototype.combos = function(fn) {
    this.getCombos().forEach(function(m) {
      return m.eachCombo(fn);
    });
    return this;
  };

  KDKeyboardListener.prototype.isActive = function() {
    return this.isListening && this === KDKeyboardListener.currentListener;
  };

  KDKeyboardListener.current = function() {
    if (this.currentListener != null) {
      return this.currentListener;
    }
    this.currentListener = new this;
    this.currentListener.listen();
    return this.currentListener;
  };

  return KDKeyboardListener;

})();


},{}],103:[function(require,module,exports){
var KDKeyboardMap,
  __hasProp = {}.hasOwnProperty;

module.exports = KDKeyboardMap = (function() {
  function KDKeyboardMap(options) {
    var combo, combos, listener;
    this.combos = {};
    if (options != null) {
      combos = options.combos, this.priority = options.priority;
    }
    if (combos != null) {
      for (combo in combos) {
        if (!__hasProp.call(combos, combo)) continue;
        listener = combos[combo];
        this.addCombo(combo, null, listener);
      }
    }
  }

  KDKeyboardMap.prototype.addCombo = function(combo, options, listener) {
    var _ref;
    if (listener == null) {
      _ref = [options, listener], listener = _ref[0], options = _ref[1];
    }
    this.combos[combo] = {
      listener: listener,
      options: options
    };
    return this;
  };

  KDKeyboardMap.prototype.removeCombo = function(combo) {
    this.combos[combo] = null;
    return this;
  };

  KDKeyboardMap.prototype.eachCombo = function(fn, thisArg) {
    var combo, listener, options, _ref, _ref1;
    _ref = this.combos;
    for (combo in _ref) {
      if (!__hasProp.call(_ref, combo)) continue;
      _ref1 = _ref[combo], options = _ref1.options, listener = _ref1.listener;
      fn.call(thisArg, combo, options, listener);
    }
  };

  return KDKeyboardMap;

})();


},{}],104:[function(require,module,exports){
var KD, KDEventEmitter, KDObject,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

KD = require('./kd.coffee');

KDEventEmitter = require('./eventemitter.coffee');

module.exports = KDObject = (function(_super) {
  var NOTREADY, READY, _ref;

  __extends(KDObject, _super);

  _ref = [0, 1], NOTREADY = _ref[0], READY = _ref[1];

  KDObject.prototype.utils = KD.utils;

  function KDObject(options, data) {
    if (options == null) {
      options = {};
    }
    this.id || (this.id = options.id || KD.utils.getUniqueId());
    this.setOptions(options);
    if (data) {
      this.setData(data);
    }
    if (options.delegate) {
      this.setDelegate(options.delegate);
    }
    this.registerKDObjectInstance();
    KDObject.__super__.constructor.apply(this, arguments);
    if (options.testPath) {
      KD.registerInstanceForTesting(this);
    }
    this.on('error', error);
    this.once('ready', (function(_this) {
      return function() {
        return _this.readyState = READY;
      };
    })(this));
  }

  KDObject.prototype.bound = function(method) {
    var boundMethod;
    if ('function' !== typeof this[method]) {
      throw new Error("bound: unknown method! " + method);
    }
    boundMethod = "__bound__" + method;
    boundMethod in this || Object.defineProperty(this, boundMethod, {
      value: this[method].bind(this)
    });
    return this[boundMethod];
  };

  KDObject.prototype.lazyBound = function() {
    var method, rest, _ref1;
    method = arguments[0], rest = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return (_ref1 = this[method]).bind.apply(_ref1, [this].concat(__slice.call(rest)));
  };

  KDObject.prototype.forwardEvent = function(target, eventName, prefix) {
    if (prefix == null) {
      prefix = "";
    }
    return target.on(eventName, this.lazyBound('emit', prefix + eventName));
  };

  KDObject.prototype.forwardEvents = function(target, eventNames, prefix) {
    var eventName, _i, _len, _results;
    if (prefix == null) {
      prefix = "";
    }
    _results = [];
    for (_i = 0, _len = eventNames.length; _i < _len; _i++) {
      eventName = eventNames[_i];
      _results.push(this.forwardEvent(target, eventName, prefix));
    }
    return _results;
  };

  KDObject.prototype.ready = function(listener) {
    if (typeof Promise !== "undefined" && Promise !== null ? Promise.prototype.nodeify : void 0) {
      return new Promise((function(_this) {
        return function(resolve) {
          if (_this.readyState === READY) {
            resolve();
          }
          return _this.once('ready', resolve);
        };
      })(this)).nodeify(listener);
    } else if (this.readyState === READY) {
      return this.utils.defer(listener);
    } else {
      return this.once('ready', listener);
    }
  };

  KDObject.prototype.registerSingleton = KD.registerSingleton;

  KDObject.prototype.getSingleton = KD.getSingleton;

  KDObject.prototype.getInstance = function(instanceId) {
    var _ref1;
    return (_ref1 = KD.getAllKDInstances()[instanceId]) != null ? _ref1 : null;
  };

  KDObject.prototype.registerKDObjectInstance = function() {
    return KD.registerInstance(this);
  };

  KDObject.prototype.setData = function(data) {
    this.data = data;
  };

  KDObject.prototype.getData = function() {
    return this.data;
  };

  KDObject.prototype.setOptions = function(options) {
    this.options = options != null ? options : {};
  };

  KDObject.prototype.setOption = function(option, value) {
    return this.options[option] = value;
  };

  KDObject.prototype.unsetOption = function(option) {
    if (this.options[option]) {
      return delete this.options[option];
    }
  };

  KDObject.prototype.getOptions = function() {
    return this.options;
  };

  KDObject.prototype.getOption = function(key) {
    var _ref1;
    return (_ref1 = this.options[key]) != null ? _ref1 : null;
  };

  KDObject.prototype.changeId = function(id) {
    KD.deleteInstance(id);
    this.id = id;
    return KD.registerInstance(this);
  };

  KDObject.prototype.getId = function() {
    return this.id;
  };

  KDObject.prototype.setDelegate = function(delegate) {
    this.delegate = delegate;
  };

  KDObject.prototype.getDelegate = function() {
    return this.delegate;
  };

  KDObject.prototype.destroy = function() {
    this.isDestroyed = true;
    this.emit('KDObjectWillBeDestroyed');
    return KD.deleteInstance(this.id);
  };

  KDObject.prototype.chainNames = function(options) {
    options.chain;
    options.newLink;
    return "" + options.chain + "." + options.newLink;
  };

  return KDObject;

})(KDEventEmitter);


},{"./eventemitter.coffee":98,"./kd.coffee":100}],105:[function(require,module,exports){
var KDNotificationView, KDObject, KDRouter,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  __slice = [].slice;

KDObject = require('./object.coffee');

KDNotificationView = require('./../components/notifications/notificationview.coffee');

module.exports = KDRouter = (function(_super) {
  var createObjectRef, history, listenerKey, revive, routeWithoutEdgeAtIndex;

  __extends(KDRouter, _super);

  history = window.history;

  listenerKey = 'ಠ_ಠ';

  KDRouter.registerStaticEmitter();

  createObjectRef = function(obj) {
    var _ref;
    if (!(((obj != null ? obj.bongo_ : void 0) != null) && (obj.getId != null))) {
      return;
    }
    return {
      constructorName: (_ref = obj.bongo_) != null ? _ref.constructorName : void 0,
      id: obj.getId()
    };
  };

  revive = function(objRef, callback) {
    if (!(((objRef != null ? objRef.constructorName : void 0) != null) && (objRef.id != null))) {
      return callback(null);
    } else {
      return KD.remote.cacheable(objRef.constructorName, objRef.id, callback);
    }
  };

  function KDRouter(routes) {
    KDRouter.__super__.constructor.call(this);
    this.tree = {};
    this.routes = {};
    this.visitedRoutes = [];
    if (routes) {
      this.addRoutes(routes);
    }
    KD.utils.defer((function(_this) {
      return function() {
        return KDRouter.emit('RouterIsReady', _this);
      };
    })(this));
  }

  KDRouter.prototype.listen = function() {
    var hashFragment;
    if (location.hash.length) {
      hashFragment = location.hash.substr(1);
      this.userRoute = hashFragment;
      this.utils.defer((function(_this) {
        return function() {
          return _this.handleRoute(hashFragment, {
            shouldPushState: true,
            replaceState: true
          });
        };
      })(this));
    }
    return this.startListening();
  };

  KDRouter.prototype.popState = function(event) {
    return revive(event.state, (function(_this) {
      return function(err, state) {
        if (err) {
          return KD.showError(err);
        }
        return _this.handleRoute("" + location.pathname + location.search, {
          shouldPushState: false,
          state: state
        });
      };
    })(this));
  };

  KDRouter.prototype.clear = function(route, replaceState) {
    if (route == null) {
      route = '/';
    }
    if (replaceState == null) {
      replaceState = true;
    }
    delete this.userRoute;
    return this.handleRoute(route, {
      replaceState: replaceState
    });
  };

  KDRouter.prototype.back = function() {
    if (this.visitedRoutes.length <= 1) {
      return this.clear();
    } else {
      return history.back();
    }
  };

  KDRouter.prototype.startListening = function() {
    if (this.isListening) {
      return false;
    }
    this.isListening = true;
    window.addEventListener('popstate', this.bound("popState"));
    return true;
  };

  KDRouter.prototype.stopListening = function() {
    if (!this.isListening) {
      return false;
    }
    this.isListening = false;
    window.removeEventListener('popstate', this.bound("popState"));
    return true;
  };

  KDRouter.handleNotFound = function(route) {
    console.trace();
    return log("The route " + (Encoder.XSSEncode(route)) + " was not found!");
  };

  KDRouter.prototype.getCurrentPath = function() {
    return this.currentPath;
  };

  KDRouter.prototype.handleNotFound = function(route) {
    var message;
    message = /<|>/.test(route) ? "Invalid route!" : "404 Not found! " + (Encoder.XSSEncode(route));
    delete this.userRoute;
    this.clear();
    log("The route " + route + " was not found!");
    return new KDNotificationView({
      title: message
    });
  };

  routeWithoutEdgeAtIndex = function(route, i) {
    return "/" + (route.slice(0, i).concat(route.slice(i + 1)).join('/'));
  };

  KDRouter.prototype.addRoute = function(route, listener) {
    var edge, i, last, node, _i, _len;
    this.routes[route] = listener;
    node = this.tree;
    route = route.split('/');
    route.shift();
    for (i = _i = 0, _len = route.length; _i < _len; i = ++_i) {
      edge = route[i];
      last = edge.length - 1;
      if ('?' === edge.charAt(last)) {
        this.addRoute(routeWithoutEdgeAtIndex(route, i), listener);
        edge = edge.substr(0, last);
      }
      if (/^:/.test(edge)) {
        node[':'] || (node[':'] = {
          name: edge.substr(1)
        });
        node = node[':'];
      } else {
        node[edge] || (node[edge] = {});
        node = node[edge];
      }
    }
    node[listenerKey] || (node[listenerKey] = []);
    if (__indexOf.call(node[listenerKey], listener) < 0) {
      return node[listenerKey].push(listener);
    }
  };

  KDRouter.prototype.addRoutes = function(routes) {
    var listener, route, _results;
    _results = [];
    for (route in routes) {
      if (!__hasProp.call(routes, route)) continue;
      listener = routes[route];
      _results.push(this.addRoute(route, listener));
    }
    return _results;
  };

  KDRouter.prototype.handleRoute = function(userRoute, options) {
    var edge, frag, listener, listeners, method, node, objRef, param, params, path, qs, query, replaceState, routeInfo, shouldPushState, state, suppressListeners, _i, _j, _len, _len1, _ref, _ref1;
    if (options == null) {
      options = {};
    }
    if (/<|>/.test(userRoute)) {
      return this.handleRoute('/Activity');
    }
    if ((userRoute.indexOf('!')) === 0) {
      userRoute = userRoute.slice(1);
    }
    if (this.visitedRoutes.last !== userRoute) {
      this.visitedRoutes.push(userRoute);
    }
    _ref1 = ((_ref = userRoute != null ? userRoute : typeof this.getDefaultRoute === "function" ? this.getDefaultRoute() : void 0) != null ? _ref : '/').split('?'), frag = _ref1[0], query = 2 <= _ref1.length ? __slice.call(_ref1, 1) : [];
    query = this.utils.parseQuery(query.join('&'));
    shouldPushState = options.shouldPushState, replaceState = options.replaceState, state = options.state, suppressListeners = options.suppressListeners;
    if (shouldPushState == null) {
      shouldPushState = true;
    }
    objRef = createObjectRef(state);
    node = this.tree;
    params = {};
    frag = frag.split('/');
    frag.shift();
    frag = frag.filter(Boolean);
    path = "/" + (frag.join('/'));
    qs = this.utils.stringifyQuery(query);
    if (qs.length) {
      path += "?" + qs;
    }
    if (!suppressListeners && shouldPushState && !replaceState && path === this.currentPath) {
      this.emit('AlreadyHere', path);
      return;
    }
    this.currentPath = path;
    if (shouldPushState) {
      method = replaceState ? 'replaceState' : 'pushState';
      history[method](objRef, path, path);
    }
    for (_i = 0, _len = frag.length; _i < _len; _i++) {
      edge = frag[_i];
      if (node[edge]) {
        node = node[edge];
      } else {
        param = node[':'];
        if (param != null) {
          params[param.name] = edge;
          node = param;
        } else {
          this.handleNotFound(frag.join('/'));
        }
      }
    }
    routeInfo = {
      params: params,
      query: query
    };
    this.emit('RouteInfoHandled', {
      params: params,
      query: query,
      path: path
    });
    if (!suppressListeners) {
      listeners = node[listenerKey];
      if (listeners != null ? listeners.length : void 0) {
        for (_j = 0, _len1 = listeners.length; _j < _len1; _j++) {
          listener = listeners[_j];
          listener.call(this, routeInfo, state, path);
        }
      }
    }
    return this;
  };

  KDRouter.prototype.handleQuery = function(query) {
    var nextRoute;
    if ('string' !== typeof query) {
      query = this.utils.stringifyQuery(query);
    }
    if (!query.length) {
      return;
    }
    nextRoute = "" + this.currentPath + "?" + query;
    return this.handleRoute(nextRoute);
  };

  return KDRouter;

})(KDObject);


},{"./../components/notifications/notificationview.coffee":61,"./object.coffee":104}],106:[function(require,module,exports){
var _base, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;

(_base = Function.prototype).bind || (_base.bind = function(context) {
  var args;
  if (1 < arguments.length) {
    args = [].slice.call(arguments, 1);
    return (function(_this) {
      return function() {
        return _this.apply(context, arguments.length ? args.concat([].slice.call(arguments)) : args);
      };
    })(this);
  }
  return (function(_this) {
    return function() {
      if (arguments.length) {
        return _this.apply(context, arguments);
      } else {
        return _this.call(context);
      }
    };
  })(this);
});

if (window.URL == null) {
  window.URL = (_ref = window.webkitURL) != null ? _ref : null;
}

if (window.BlobBuilder == null) {
  window.BlobBuilder = (_ref1 = (_ref2 = window.WebKitBlobBuilder) != null ? _ref2 : window.MozBlobBuilder) != null ? _ref1 : null;
}

if (window.requestFileSystem == null) {
  window.requestFileSystem = (_ref3 = window.webkitRequestFileSystem) != null ? _ref3 : null;
}

if (window.requestAnimationFrame == null) {
  window.requestAnimationFrame = (_ref4 = (_ref5 = window.webkitRequestAnimationFrame) != null ? _ref5 : window.mozRequestAnimationFrame) != null ? _ref4 : null;
}

String.prototype.capitalize = function() {
  return this.charAt(0).toUpperCase() + this.slice(1);
};

String.prototype.trim = function() {
  return this.replace(/^\s+|\s+$/g, "");
};

(function(arrayProto, _arg) {
  var defineProperty;
  defineProperty = _arg.defineProperty;
  "last" in arrayProto || defineProperty(arrayProto, "last", {
    get: function() {
      return this[this.length - 1];
    }
  });
  return "first" in arrayProto || defineProperty(arrayProto, "first", {
    get: function() {
      return this[0];
    }
  });
})(Array.prototype, Object);


},{}],107:[function(require,module,exports){
var createCounter,
  __slice = [].slice;

module.exports = {
  idCounter: 0,
  extend: function() {
    var key, source, sources, target, val, _i, _len;
    target = arguments[0], sources = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    for (_i = 0, _len = sources.length; _i < _len; _i++) {
      source = sources[_i];
      for (key in source) {
        val = source[key];
        target[key] = val;
      }
    }
    return target;
  },
  dict: Object.create.bind(null, null, Object.create(null)),
  getNearestElementByTagName: function(el, tagName) {
    while (!((el == null) || this.elementHasTag(el, tagName))) {
      el = el.parentNode;
    }
    return el;
  },
  elementShow: function(el) {
    return el != null ? el.classList.remove("hidden") : void 0;
  },
  elementHide: function(el) {
    return el != null ? el.classList.add("hidden") : void 0;
  },
  elementHasTag: function(el, tagName) {
    var _ref;
    return Boolean(((_ref = el.tagName) != null ? _ref.toLowerCase() : void 0) === tagName.toLowerCase());
  },
  elementIsVisible: function(el) {
    var height, i, inViewport, l, onTop, r, rects;
    if (el.offsetWidth <= 0 || el.offsetHeight <= 0) {
      return false;
    }
    height = document.documentElement.clientHeight;
    rects = el.getClientRects();
    onTop = function(r) {
      var x, y;
      x = (r.left + r.right) / 2;
      y = (r.top + r.bottom) / 2;
      return document.elementFromPoint(x, y) === el;
    };
    i = 0;
    l = rects.length;
    while (i < l) {
      r = rects[i];
      inViewport = (r.top > 0 ? r.top <= height : r.bottom > 0 && r.bottom <= height);
      if (inViewport && onTop(r)) {
        return true;
      }
      i++;
    }
    return false;
  },
  formatPlural: function(count, noun, showCount) {
    if (showCount == null) {
      showCount = true;
    }
    return "" + (showCount ? "" + (count || 0) + " " : '') + (count === 1 ? noun : Inflector.pluralize(noun));
  },
  formatIndefiniteArticle: function(noun) {
    var _ref;
    if ((_ref = noun[0].toLowerCase()) === 'a' || _ref === 'e' || _ref === 'i' || _ref === 'o' || _ref === 'u') {
      return "an " + noun;
    }
    return "a " + noun;
  },
  getSelection: function() {
    return window.getSelection();
  },
  getSelectionRange: function() {
    var selection;
    selection = this.getSelection();
    if (selection.type !== "None") {
      return selection.getRangeAt(0);
    }
  },
  getCursorNode: function() {
    return this.getSelectionRange().commonAncestorContainer;
  },
  addRange: function(range) {
    var selection;
    selection = window.getSelection();
    selection.removeAllRanges();
    return selection.addRange(range);
  },
  selectText: function(element, start, end) {
    var range, selection;
    if (end == null) {
      end = start;
    }
    if (document.body.createTextRange) {
      range = document.body.createTextRange();
      range.moveToElementText(element);
      return range.select();
    } else if (window.getSelection) {
      selection = window.getSelection();
      range = document.createRange();
      range.selectNodeContents(element);
      if (start != null) {
        range.setStart(element, start);
      }
      if (end != null) {
        range.setEnd(element, end);
      }
      selection.removeAllRanges();
      return selection.addRange(range);
    }
  },
  selectEnd: function(element, range) {
    range || (range = document.createRange());
    element || (element = this.getSelection().focusNode);
    if (!element) {
      return;
    }
    range.setStartAfter(element);
    range.collapse(false);
    return this.addRange(range);
  },
  replaceRange: function(node, replacement, start, end, appendTrailingSpace) {
    var range, trailingSpace;
    if (end == null) {
      end = start;
    }
    if (appendTrailingSpace == null) {
      appendTrailingSpace = true;
    }
    trailingSpace = document.createTextNode("\u00a0");
    range = new Range();
    if (start != null) {
      range.setStart(node, start);
      range.setEnd(node, end);
    } else {
      range.selectNode(node);
    }
    range.deleteContents();
    range.insertNode(replacement);
    this.selectEnd(replacement, range);
    if (appendTrailingSpace) {
      range.insertNode(trailingSpace);
      return this.selectEnd(trailingSpace, range);
    }
  },
  getCallerChain: function(args, depth) {
    var caller, chain;
    caller = args.callee.caller;
    chain = [caller];
    while (depth-- && (caller = caller != null ? caller.caller : void 0)) {
      chain.push(caller);
    }
    return chain;
  },
  createCounter: createCounter = function(i) {
    if (i == null) {
      i = 0;
    }
    return function() {
      return i++;
    };
  },
  getUniqueId: (function(inc) {
    return function() {
      return "kd-" + (inc());
    };
  })(createCounter()),
  getRandomNumber: function(range, min) {
    var res;
    if (range == null) {
      range = 1e6;
    }
    if (min == null) {
      min = 0;
    }
    res = Math.floor(Math.random() * range + 1);
    if (res > min) {
      return res;
    } else {
      return res + min;
    }
  },
  uniqueId: function(prefix) {
    var id;
    id = this.idCounter++;
    if (prefix != null) {
      return "" + prefix + id;
    } else {
      return id;
    }
  },
  getRandomRGB: function() {
    var getRandomNumber;
    getRandomNumber = this.getRandomNumber;
    return "rgb(" + (getRandomNumber(255)) + "," + (getRandomNumber(255)) + "," + (getRandomNumber(255)) + ")";
  },
  getRandomHex: function() {
    var hex;
    hex = (Math.random() * 0x999999 << 0).toString(16);
    while (hex.length < 6) {
      hex += "0";
    }
    return "#" + hex;
  },
  curry: function(obligatory, optional) {
    return obligatory + (optional ? ' ' + optional : '');
  },
  parseQuery: (function() {
    var decode, params, parseQuery, plusses;
    params = /([^&=]+)=?([^&]*)/g;
    plusses = /\+/g;
    decode = function(str) {
      return decodeURIComponent(str.replace(plusses, " "));
    };
    return parseQuery = function(queryString) {
      var m, result;
      if (queryString == null) {
        queryString = location.search.substring(1);
      }
      result = {};
      while (m = params.exec(queryString)) {
        result[decode(m[1])] = decode(m[2]);
      }
      return result;
    };
  })(),
  stringifyQuery: (function() {
    var encode, spaces, stringifyQuery;
    spaces = /\s/g;
    encode = function(str) {
      return encodeURIComponent(str.replace(spaces, "+"));
    };
    return stringifyQuery = function(obj) {
      return Object.keys(obj).map(function(key) {
        return "" + (encode(key)) + "=" + (encode(obj[key]));
      }).join('&').trim();
    };
  })(),
  capAndRemovePeriods: function(path) {
    var arg, newPath;
    newPath = (function() {
      var _i, _len, _ref, _results;
      _ref = path.split(".");
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        arg = _ref[_i];
        _results.push(arg.capitalize());
      }
      return _results;
    })();
    return newPath.join("");
  },
  slugify: function(title) {
    var url;
    if (title == null) {
      title = "";
    }
    return url = String(title).toLowerCase().replace(/^\s+|\s+$/g, "").replace(/[_|\s]+/g, "-").replace(/[^a-z0-9-]+/g, "").replace(/[-]+/g, "-").replace(/^-+|-+$/g, "");
  },
  stripTags: function(value) {
    return value.replace(/<(?:.|\n)*?>/gm, '');
  },
  decimalToAnother: function(n, radix) {
    var a, b, hex, i, s, t, _i, _j;
    hex = [];
    for (i = _i = 0; _i <= 10; i = ++_i) {
      hex[i + 1] = i;
    }
    s = '';
    a = n;
    while (a >= radix) {
      b = a % radix;
      a = Math.floor(a / radix);
      s += hex[b + 1];
    }
    s += hex[a + 1];
    n = s.length;
    t = '';
    for (i = _j = 0; 0 <= n ? _j < n : _j > n; i = 0 <= n ? ++_j : --_j) {
      t = t + s.substring(n - i - 1, n - i);
    }
    s = t;
    return s;
  },
  applyMarkdown: function(text, options) {
    if (options == null) {
      options = {};
    }
    if (!text) {
      return null;
    }
    if (options.gfm == null) {
      options.gfm = true;
    }
    if (options.pedantic == null) {
      options.pedantic = false;
    }
    if (options.sanitize == null) {
      options.sanitize = true;
    }
    if (options.highlight == null) {
      options.highlight = function(text, lang) {
        if (hljs.getLanguage(lang)) {
          return hljs.highlight(lang, text).value;
        } else {
          return text;
        }
      };
    }
    return marked(Encoder.htmlDecode(text), options);
  },
  enterFullscreen: (function() {
    var launchFullscreen;
    launchFullscreen = function(element) {
      if (element.requestFullscreen) {
        return element.requestFullscreen();
      } else if (element.mozRequestFullScreen) {
        return element.mozRequestFullScreen();
      } else if (element.webkitRequestFullscreen) {
        return element.webkitRequestFullscreen();
      } else if (element.msRequestFullscreen) {
        return element.msRequestFullscreen();
      }
    };
    return function(element) {
      if (element == null) {
        element = document.documentElement;
      }
      return launchFullscreen(element);
    };
  })(),
  exitFullscreen: function() {
    if (document.exitFullscreen) {
      return document.exitFullscreen();
    } else if (document.mozCancelFullScreen) {
      return document.mozCancelFullScreen();
    } else if (document.webkitExitFullscreen) {
      return document.webkitExitFullscreen();
    }
  },
  isFullscreen: function() {
    return document.fullscreenElement || document.mozFullScreenElement || document.webkitIsFullScreen;
  },
  createExternalLink: function(href) {
    var tag;
    tag = document.createElement("a");
    tag.href = href.indexOf("http") > -1 ? href : "http://" + href;
    tag.target = "_blank";
    document.body.appendChild(tag);
    tag.click();
    return document.body.removeChild(tag);
  },
  wait: function(duration, fn) {
    if ("function" === typeof duration) {
      fn = duration;
      duration = 0;
    }
    return setTimeout(fn, duration);
  },
  killWait: function(id) {
    if (id) {
      clearTimeout(id);
    }
    return null;
  },
  repeat: function(duration, fn) {
    if ("function" === typeof duration) {
      fn = duration;
      duration = 500;
    }
    return setInterval(fn, duration);
  },
  killRepeat: function(id) {
    return clearInterval(id);
  },
  defer: (function(queue) {
    if ((typeof window !== "undefined" && window !== null ? window.postMessage : void 0) && window.addEventListener) {
      window.addEventListener("message", (function(ev) {
        if (ev.source === window && ev.data === "kd-tick") {
          ev.stopPropagation();
          if (queue.length > 0) {
            return queue.shift()();
          }
        }
      }), true);
      return function(fn) {
        queue.push(fn);
        return window.postMessage("kd-tick", "*");
      };
    } else {
      return function(fn) {
        return setTimeout(fn, 1);
      };
    }
  })([]),
  getCancellableCallback: function(callback) {
    var cancelled, kallback;
    cancelled = false;
    kallback = function() {
      var rest;
      rest = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (!cancelled) {
        return callback.apply(null, rest);
      }
    };
    kallback.cancel = function() {
      return cancelled = true;
    };
    return kallback;
  },
  getTimedOutCallback: function(callback, failcallback, timeout) {
    var cancelled, fallback, fallbackTimer, kallback;
    if (timeout == null) {
      timeout = 5000;
    }
    cancelled = false;
    kallback = function() {
      var rest;
      rest = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      clearTimeout(fallbackTimer);
      if (!cancelled) {
        return callback.apply(null, rest);
      }
    };
    fallback = function() {
      var rest;
      rest = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (!cancelled) {
        failcallback.apply(null, rest);
      }
      return cancelled = true;
    };
    fallbackTimer = setTimeout(fallback, timeout);
    return kallback;
  },
  getTimedOutCallbackOne: function(options) {
    var fallback, fallbackTimer, kallback, onResult, onSuccess, onTimeout, timedOut, timeout, timerName;
    if (options == null) {
      options = {};
    }
    timerName = options.name || "undefined";
    timeout = options.timeout || 10000;
    onSuccess = options.onSuccess || function() {};
    onTimeout = options.onTimeout || function() {};
    onResult = options.onResult || function() {};
    timedOut = false;
    kallback = (function(_this) {
      return function() {
        var rest;
        rest = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        clearTimeout(fallbackTimer);
        _this.updateLogTimer(timerName, fallbackTimer, Date.now());
        if (timedOut) {
          return onResult.apply(null, rest);
        } else {
          return onSuccess.apply(null, rest);
        }
      };
    })(this);
    fallback = (function(_this) {
      return function() {
        var rest;
        rest = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        timedOut = true;
        _this.updateLogTimer(timerName, fallbackTimer);
        return onTimeout.apply(null, rest);
      };
    })(this);
    fallbackTimer = setTimeout(fallback, timeout);
    this.logTimer(timerName, fallbackTimer, Date.now());
    kallback.cancel = function() {
      return clearTimeout(fallbackTimer);
    };
    return kallback;
  },
  logTimer: function(timerName, timerNumber, startTime) {
    var _base;
    log("logTimer name:" + timerName);
    (_base = this.timers)[timerName] || (_base[timerName] = {});
    return this.timers[timerName][timerNumber] = {
      start: startTime,
      status: "started"
    };
  },
  updateLogTimer: function(timerName, timerNumber, endTime) {
    var elapsed, startTime, status, timer;
    timer = this.timers[timerName][timerNumber];
    status = endTime ? "ended" : "failed";
    startTime = timer.start;
    elapsed = endTime - startTime;
    timer = {
      start: startTime,
      end: endTime,
      status: status,
      elapsed: elapsed
    };
    this.timers[timerName][timerNumber] = timer;
    return log("updateLogTimer name:" + timerName + ", status:" + status + " elapsed:" + elapsed);
  },
  timers: {},
  stopDOMEvent: function(event) {
    if (!event) {
      return false;
    }
    event.preventDefault();
    event.stopPropagation();
    return false;
  },
  utf8Encode: function(string) {
    var c, n, utftext;
    string = string.replace(/\r\n/g, "\n");
    utftext = "";
    n = 0;
    while (n < string.length) {
      c = string.charCodeAt(n);
      if (c < 128) {
        utftext += String.fromCharCode(c);
      } else if ((c > 127) && (c < 2048)) {
        utftext += String.fromCharCode((c >> 6) | 192);
        utftext += String.fromCharCode((c & 63) | 128);
      } else {
        utftext += String.fromCharCode((c >> 12) | 224);
        utftext += String.fromCharCode(((c >> 6) & 63) | 128);
        utftext += String.fromCharCode((c & 63) | 128);
      }
      n++;
    }
    return utftext;
  },
  utf8Decode: function(utftext) {
    var c, c1, c2, c3, i, string;
    string = "";
    i = 0;
    c = c1 = c2 = 0;
    while (i < utftext.length) {
      c = utftext.charCodeAt(i);
      if (c < 128) {
        string += String.fromCharCode(c);
        i++;
      } else if ((c > 191) && (c < 224)) {
        c2 = utftext.charCodeAt(i + 1);
        string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
        i += 2;
      } else {
        c2 = utftext.charCodeAt(i + 1);
        c3 = utftext.charCodeAt(i + 2);
        string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
        i += 3;
      }
    }
    return string;
  },
  runXpercent: function(percent) {
    var chance;
    chance = Math.floor(Math.random() * 100);
    return chance <= percent;
  },
  shortenUrl: function(url, callback) {
    var request;
    request = $.ajax("https://www.googleapis.com/urlshortener/v1/url", {
      type: "POST",
      contentType: "application/json",
      data: JSON.stringify({
        longUrl: url
      }),
      timeout: 4000,
      dataType: "json"
    });
    request.done((function(_this) {
      return function(data) {
        return callback((data != null ? data.id : void 0) || url, data);
      };
    })(this));
    return request.error(function(_arg) {
      var responseText, status, statusText;
      status = _arg.status, statusText = _arg.statusText, responseText = _arg.responseText;
      error("URL shorten error, returning self as fallback.", status, statusText, responseText);
      return callback(url);
    });
  },
  formatBytesToHumanReadable: function(bytes, fixedAmout) {
    var minus, thresh, unitIndex, units;
    if (fixedAmout == null) {
      fixedAmout = 2;
    }
    minus = '';
    if (bytes < 0) {
      minus = '-';
      bytes *= -1;
    }
    thresh = 1024;
    units = ["kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    unitIndex = -1;
    if (bytes < thresh) {
      return "" + bytes + " B";
    }
    while (true) {
      bytes /= thresh;
      ++unitIndex;
      if (!(bytes >= thresh)) {
        break;
      }
    }
    return "" + minus + (bytes.toFixed(fixedAmout)) + " " + units[unitIndex];
  },
  splitTrim: function(str, delim, filterEmpty) {
    var arr, _ref;
    if (delim == null) {
      delim = ',';
    }
    if (filterEmpty == null) {
      filterEmpty = true;
    }
    arr = (_ref = str != null ? str.split(delim).map(function(part) {
      return part.trim();
    }) : void 0) != null ? _ref : [];
    if (filterEmpty) {
      arr = arr.filter(Boolean);
    }
    return arr;
  },
  arrayToObject: function(list, key) {
    var dict, obj, _i, _len;
    dict = {};
    for (_i = 0, _len = list.length; _i < _len; _i++) {
      obj = list[_i];
      if (obj[key] != null) {
        dict[obj[key]] = obj;
      }
    }
    return dict;
  },
  partition: function(list, fn) {
    var item, result, _i, _len;
    result = [[], []];
    for (_i = 0, _len = list.length; _i < _len; _i++) {
      item = list[_i];
      result[+(!fn(item))].push(item);
    }
    return result;
  },

  /*
  //     Underscore.js 1.3.1
  //     (c) 2009-2012 Jeremy Ashkenas, DocumentCloud Inc.
  //     Underscore is freely distributable under the MIT license.
  //     Portions of Underscore are inspired or borrowed from Prototype,
  //     Oliver Steele's Functional, and John Resig's Micro-Templating.
  //     For all details and documentation:
  //     http://documentcloud.github.com/underscore
   */
  throttle: function(wait, func) {
    var args, context, more, throttling, timeout, whenDone, _ref;
    if ((typeof func) === "number") {
      _ref = [func, wait], wait = _ref[0], func = _ref[1];
    }
    context = args = timeout = throttling = more = null;
    whenDone = KD.utils.debounce(wait, function() {
      return more = throttling = false;
    });
    return function() {
      var later;
      context = this;
      args = arguments;
      later = function() {
        timeout = null;
        if (more) {
          func.apply(context, args);
        }
        return whenDone();
      };
      if (!timeout) {
        timeout = setTimeout(later, wait);
      }
      if (throttling) {
        more = true;
      } else {
        func.apply(context, args);
      }
      whenDone();
      return throttling = true;
    };
  },
  debounce: function(wait, func) {
    var timeout, _ref;
    if ((typeof func) === "number") {
      _ref = [func, wait], wait = _ref[0], func = _ref[1];
    }
    timeout = null;
    return function() {
      var args, context, later;
      context = this;
      args = arguments;
      later = function() {
        timeout = null;
        return func.apply(context, args);
      };
      clearTimeout(timeout);
      return timeout = setTimeout(later, wait);
    };
  }
};


},{}],108:[function(require,module,exports){
var KDObject, KDView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  __slice = [].slice;

KDObject = require('./object.coffee');

module.exports = KDView = (function(_super) {
  var defineProperty, deprecated, eventNames, eventToMethodMap, overrideAndMergeObjects;

  __extends(KDView, _super);

  defineProperty = Object.defineProperty;

  deprecated = function(methodName) {
    return warn("" + methodName + " is deprecated from KDView if you need it override in your subclass");
  };

  eventNames = /^((dbl)?click|key(up|down|press)|mouse(up|down|over|enter|leave|move)|drag(start|end|enter|leave|over)|blur|change|focus|drop|contextmenu|scroll|paste|error|load)$/;

  eventToMethodMap = function() {
    return {
      dblclick: "dblClick",
      keyup: "keyUp",
      keydown: "keyDown",
      keypress: "keyPress",
      mouseup: "mouseUp",
      mousedown: "mouseDown",
      mouseenter: "mouseEnter",
      mouseleave: "mouseLeave",
      mousemove: "mouseMove",
      mousewheel: "mouseWheel",
      wheel: "mouseWheel",
      mouseover: "mouseOver",
      contextmenu: "contextMenu",
      dragstart: "dragStart",
      dragenter: "dragEnter",
      dragleave: "dragLeave",
      dragover: "dragOver",
      paste: "paste",
      transitionend: "transitionEnd"
    };
  };

  overrideAndMergeObjects = function(objects) {
    var item, title, _ref;
    _ref = objects.overridden;
    for (title in _ref) {
      if (!__hasProp.call(_ref, title)) continue;
      item = _ref[title];
      if (objects.overrider[title]) {
        continue;
      }
      objects.overrider[title] = item;
    }
    return objects.overrider;
  };

  KDView.prototype.appendToDomBody = function() {
    this.parentIsInDom = true;
    if (!this.lazy) {
      $("body").append(this.$());
      return this.utils.defer((function(_this) {
        return function() {
          return _this.emit("viewAppended");
        };
      })(this));
    }
  };

  KDView.appendToDOMBody = function(view) {
    console.warn("KDView.appendToDOMBody is deprecated; use #appendToDomBody instead");
    return view.appendToDomBody();
  };

  function KDView(options, data) {
    var o;
    if (options == null) {
      options = {};
    }
    o = options;
    o.tagName || (o.tagName = "div");
    o.domId || (o.domId = null);
    o.cssClass || (o.cssClass = "");
    o.parent || (o.parent = null);
    o.partial || (o.partial = null);
    o.delegate || (o.delegate = null);
    o.bind || (o.bind = "");
    o.draggable || (o.draggable = null);
    o.droppable || (o.droppable = null);
    o.size || (o.size = null);
    o.position || (o.position = null);
    o.attributes || (o.attributes = null);
    o.prefix || (o.prefix = "");
    o.suffix || (o.suffix = "");
    o.tooltip || (o.tooltip = null);
    o.resizable || (o.resizable = null);
    KDView.__super__.constructor.call(this, o, data);
    if (data != null) {
      if (typeof data.on === "function") {
        data.on('update', this.bound('render'));
      }
    }
    this.domId = options.domId, this.parent = options.parent;
    this.subViews = [];
    this.defaultInit(options, data);
  }

  KDView.prototype.defaultInit = function(options, data) {
    this.setDomElement(options.cssClass);
    this.setDataId();
    if (options.domId) {
      this.setDomId(options.domId);
    }
    if (options.attributes) {
      this.setAttributes(options.attributes);
    }
    if (options.size) {
      this.setSize(options.size);
    }
    if (options.position) {
      this.setPosition(options.position);
    }
    if (options.partial) {
      this.updatePartial(options.partial);
    }
    if (options.draggable) {
      this.setClass('kddraggable');
    }
    this.addEventHandlers(options);
    if (options.lazyLoadThreshold) {
      this.setLazyLoader(options.lazyLoadThreshold);
    }
    if (options.tooltip) {
      this.setTooltip(options.tooltip);
    }
    if (options.draggable) {
      this.setDraggable(options.draggable);
    }
    this.bindEvents();
    this.on('childAppended', this.childAppended.bind(this));
    return this.on('viewAppended', (function(_this) {
      return function() {
        var child, fireViewAppended, key, subViews, _i, _len, _results, _results1;
        _this.setViewReady();
        _this.viewAppended();
        _this.childAppended(_this);
        _this.parentIsInDom = true;
        fireViewAppended = function(child) {
          if (!child.parentIsInDom) {
            child.parentIsInDom = true;
            if (!child.lazy) {
              return child.emit('viewAppended');
            }
          }
        };
        subViews = _this.getSubViews();
        if (Array.isArray(subViews)) {
          _results = [];
          for (_i = 0, _len = subViews.length; _i < _len; _i++) {
            child = subViews[_i];
            _results.push(fireViewAppended(child));
          }
          return _results;
        } else if ((subViews != null) && 'object' === typeof subViews) {
          _results1 = [];
          for (key in subViews) {
            if (!__hasProp.call(subViews, key)) continue;
            child = subViews[key];
            _results1.push(fireViewAppended(child));
          }
          return _results1;
        }
      };
    })(this));
  };

  KDView.prototype.getDomId = function() {
    return this.domElement.attr("id");
  };

  KDView.prototype.setDomElement = function(cssClass) {
    var domId, el, klass, tagName, _i, _len, _ref, _ref1;
    if (cssClass == null) {
      cssClass = '';
    }
    _ref = this.getOptions(), domId = _ref.domId, tagName = _ref.tagName;
    if (domId) {
      el = document.getElementById(domId);
    }
    this.lazy = el == null ? (el = document.createElement(tagName), domId ? el.id = domId : void 0, false) : true;
    _ref1 = ("kdview " + cssClass).split(' ');
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      klass = _ref1[_i];
      if (klass.length) {
        el.classList.add(klass);
      }
    }
    this.domElement = $(el);
    if (this.lazy) {
      return this.utils.defer((function(_this) {
        return function() {
          return _this.emit('viewAppended');
        };
      })(this));
    }
  };

  KDView.prototype.setDomId = function(id) {
    return this.domElement.attr("id", id);
  };

  KDView.prototype.setData = function(data) {
    var _ref, _ref1;
    if ((_ref = this.data) != null) {
      if (typeof _ref.off === "function") {
        _ref.off('update', this.bound('render'));
      }
    }
    KDView.__super__.setData.call(this, data);
    if ((_ref1 = this.data) != null) {
      if (typeof _ref1.on === "function") {
        _ref1.on('update', this.bound('render'));
      }
    }
    if (this.parentIsInDom) {
      return this.render();
    }
  };

  KDView.prototype.setDataId = function() {
    return this.domElement.data("data-id", this.getId());
  };

  KDView.prototype.getAttribute = function(attr) {
    return this.getElement().getAttribute(attr);
  };

  KDView.prototype.setAttribute = function(attr, val) {
    return this.getElement().setAttribute(attr, val);
  };

  KDView.prototype.setAttributes = function(attributes) {
    var attr, val, _results;
    _results = [];
    for (attr in attributes) {
      if (!__hasProp.call(attributes, attr)) continue;
      val = attributes[attr];
      _results.push(this.setAttribute(attr, val));
    }
    return _results;
  };

  KDView.prototype.isInDom = (function() {
    var findUltimateAncestor;
    findUltimateAncestor = function(el) {
      var ancestor;
      ancestor = el;
      while (ancestor.parentNode) {
        ancestor = ancestor.parentNode;
      }
      return ancestor;
    };
    return function() {
      return findUltimateAncestor(this.$()[0]).body != null;
    };
  })();

  Object.defineProperty(KDView.prototype, "$$", {
    get: KDView.prototype.$
  });

  Object.defineProperty(KDView.prototype, "el", {
    get: KDView.prototype.getElement
  });

  KDView.prototype.getDomElement = function() {
    return this.domElement;
  };

  KDView.prototype.getElement = function() {
    return this.getDomElement()[0];
  };

  KDView.prototype.getTagName = function() {
    return this.options.tagName || 'div';
  };

  KDView.prototype.$ = function(selector) {
    if (selector) {
      return this.getDomElement().find(selector);
    } else {
      return this.getDomElement();
    }
  };

  KDView.prototype.append = function(child, selector) {
    this.$(selector).append(child.$());
    if (this.parentIsInDom) {
      child.emit('viewAppended');
    }
    return this;
  };

  KDView.prototype.appendTo = function(parent, selector) {
    this.$().appendTo(parent.$(selector));
    if (this.parentIsInDom) {
      this.emit('viewAppended');
    }
    return this;
  };

  KDView.prototype.appendToSelector = function(selector) {
    $(selector).append(this.$());
    return this.emit('viewAppended');
  };

  KDView.prototype.prepend = function(child, selector) {
    this.$(selector).prepend(child.$());
    if (this.parentIsInDom) {
      child.emit('viewAppended');
    }
    return this;
  };

  KDView.prototype.prependTo = function(parent, selector) {
    this.$().prependTo(parent.$(selector));
    if (this.parentIsInDom) {
      this.emit('viewAppended');
    }
    return this;
  };

  KDView.prototype.prependToSelector = function(selector) {
    $(selector).prepend(this.$());
    return this.emit('viewAppended');
  };

  KDView.prototype.setPartial = function(partial, selector) {
    this.$(selector).append(partial);
    return this;
  };

  KDView.prototype.updatePartial = function(partial, selector) {
    return this.$(selector).html(partial);
  };

  KDView.prototype.clear = function() {
    return this.getElement().innerHTML = '';
  };

  KDView.setElementClass = function(el, addOrRemove, cssClass) {
    var cl, _i, _len, _ref, _results;
    _ref = cssClass.split(' ');
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      cl = _ref[_i];
      if (cl !== '') {
        _results.push(el.classList[addOrRemove](cl));
      }
    }
    return _results;
  };

  KDView.prototype.setCss = function(property, value) {
    return this.$().css(property, value);
  };

  KDView.prototype.setStyle = function(properties) {
    var property, value, _results;
    _results = [];
    for (property in properties) {
      if (!__hasProp.call(properties, property)) continue;
      value = properties[property];
      _results.push(this.$().css(property, value));
    }
    return _results;
  };

  KDView.prototype.setClass = function(cssClass) {
    if (!cssClass) {
      return;
    }
    KDView.setElementClass(this.getElement(), "add", cssClass);
    return this;
  };

  KDView.prototype.unsetClass = function(cssClass) {
    if (!cssClass) {
      return;
    }
    KDView.setElementClass(this.getElement(), "remove", cssClass);
    return this;
  };

  KDView.prototype.toggleClass = function(cssClass) {
    this.$().toggleClass(cssClass);
    return this;
  };

  KDView.prototype.hasClass = function(cssClass) {
    return this.getElement().classList.contains(cssClass);
  };

  KDView.prototype.getBounds = function() {
    var bounds;
    return bounds = {
      x: this.getX(),
      y: this.getY(),
      w: this.getWidth(),
      h: this.getHeight(),
      n: this.constructor.name
    };
  };

  KDView.prototype.setRandomBG = function() {
    return this.getDomElement().css("background-color", KD.utils.getRandomRGB());
  };

  KDView.prototype.hide = function(duration) {
    return this.setClass('hidden');
  };

  KDView.prototype.show = function(duration) {
    return this.unsetClass('hidden');
  };

  KDView.prototype.setSize = function(sizes) {
    if (sizes.width != null) {
      this.setWidth(sizes.width);
    }
    if (sizes.height != null) {
      return this.setHeight(sizes.height);
    }
  };

  KDView.prototype.setPosition = function() {
    var positionOptions;
    positionOptions = this.getOptions().position;
    positionOptions.position = "absolute";
    return this.$().css(positionOptions);
  };

  KDView.prototype.getWidth = function() {
    return this.$().outerWidth(false);
  };

  KDView.prototype.setWidth = function(w, unit) {
    if (unit == null) {
      unit = "px";
    }
    this.getElement().style.width = "" + w + unit;
    return this.emit("ViewResized", {
      newWidth: w,
      unit: unit
    });
  };

  KDView.prototype.getHeight = function() {
    return this.getDomElement().outerHeight(false);
  };

  KDView.prototype.setHeight = function(h, unit) {
    if (unit == null) {
      unit = "px";
    }
    this.getElement().style.height = "" + h + unit;
    return this.emit("ViewResized", {
      newHeight: h,
      unit: unit
    });
  };

  KDView.prototype.setX = function(x) {
    return this.$().css({
      left: x
    });
  };

  KDView.prototype.setY = function(y) {
    return this.$().css({
      top: y
    });
  };

  KDView.prototype.getX = function() {
    return this.$().offset().left;
  };

  KDView.prototype.getY = function() {
    return this.$().offset().top;
  };

  KDView.prototype.getRelativeX = function() {
    return this.$().position().left;
  };

  KDView.prototype.getRelativeY = function() {
    return this.$().position().top;
  };

  KDView.prototype.destroyChild = function(prop) {
    var _base;
    if (this[prop] != null) {
      if (typeof (_base = this[prop]).destroy === "function") {
        _base.destroy();
      }
      delete this[prop];
      return true;
    } else {
      return false;
    }
  };

  KDView.prototype.attach = function(view) {
    return this.getElement().appendChild(view.getElement());
  };

  KDView.prototype.detach = function() {
    var _ref;
    return (_ref = this.parent) != null ? _ref.getElement().removeChild(this.getElement()) : void 0;
  };

  KDView.prototype.destroy = function() {
    var index, _ref;
    if (this.getSubViews().length > 0) {
      this.destroySubViews();
    }
    if (((_ref = this.parent) != null ? _ref.subViews : void 0) && (index = this.parent.subViews.indexOf(this)) >= 0) {
      this.parent.subViews.splice(index, 1);
      this.unsetParent();
    }
    this.getDomElement().remove();
    if (this.$overlay != null) {
      this.removeOverlay();
    }
    return KDView.__super__.destroy.apply(this, arguments);
  };

  KDView.prototype.destroySubViews = function() {
    var view, _i, _len, _ref;
    _ref = this.getSubViews().slice();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      view = _ref[_i];
      if (typeof view.destroy === "function") {
        view.destroy();
      }
    }
  };

  KDView.prototype.addSubView = function(subView, selector, shouldPrepend) {
    if (subView == null) {
      throw new Error('no subview was specified');
    }
    this.subViews.push(subView);
    subView.setParent(this);
    subView.parentIsInDom = this.parentIsInDom;
    if (!subView.lazy) {
      if (shouldPrepend) {
        this.prepend(subView, selector);
      } else {
        this.append(subView, selector);
      }
    }
    subView.on("ViewResized", function() {
      return subView.parentDidResize();
    });
    if (this.template != null) {
      this.template.addSymbol(subView);
    }
    return subView;
  };

  KDView.prototype.removeSubView = function(subView) {
    return subView.destroy();
  };

  KDView.prototype.getSubViews = function() {

    /*
    FIX: NEEDS REFACTORING
    used in @destroy
    not always sub views stored in @subviews but in @items, @itemsOrdered etc
    see KDListView KDTreeView etc. and fix it.
     */
    var subViews;
    subViews = this.subViews;
    if (this.items != null) {
      subViews = subViews.concat([].slice.call(this.items));
    }
    return subViews;
  };

  KDView.prototype.setParent = function(parent) {
    if (this.parent != null) {
      return error('View already has a parent', this, this.parent);
    } else {
      if (defineProperty) {
        return defineProperty(this, 'parent', {
          value: parent,
          configurable: true
        });
      } else {
        return this.parent = parent;
      }
    }
  };

  KDView.prototype.unsetParent = function() {
    return delete this.parent;
  };

  KDView.prototype.embedChild = function(placeholderId, child, isCustom) {
    this.addSubView(child, '#' + placeholderId, false);
    if (!isCustom) {
      return this.$('#' + placeholderId).replaceWith(child.$());
    }
  };

  KDView.prototype.render = function(fields) {
    if (this.template != null) {
      return this.template.update(fields);
    }
  };

  KDView.prototype.addEventHandlers = function(options) {
    var cb, eventName, _results;
    _results = [];
    for (eventName in options) {
      if (!__hasProp.call(options, eventName)) continue;
      cb = options[eventName];
      if (eventNames.test(eventName) && "function" === typeof cb) {
        _results.push(this.on(eventName, cb));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  KDView.prototype.parentDidResize = function(parent, event) {
    var subView, _i, _len, _ref, _results;
    if (this.getSubViews()) {
      _ref = this.getSubViews();
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        subView = _ref[_i];
        _results.push(subView.parentDidResize(parent, event));
      }
      return _results;
    }
  };

  KDView.prototype.setLazyLoader = function(threshold) {
    var view;
    if (threshold == null) {
      threshold = .75;
    }
    if (!/\bscroll\b/.test(this.getOptions().bind)) {
      this.getOptions().bind += ' scroll';
    }
    view = this;
    return this.on('scroll', (function() {
      var lastRatio;
      lastRatio = 0;
      return function(event) {
        var dynamicThreshold, el, ratio, scrollHeight, scrollTop;
        el = view.$()[0];
        scrollHeight = el.scrollHeight, scrollTop = el.scrollTop;
        dynamicThreshold = threshold > 1 ? (scrollHeight - threshold) / scrollHeight : threshold;
        ratio = (scrollTop + view.getHeight()) / scrollHeight;
        if ((dynamicThreshold < ratio && ratio > lastRatio)) {
          this.emit('LazyLoadThresholdReached', {
            ratio: ratio
          });
        }
        return lastRatio = ratio;
      };
    })());
  };

  KDView.prototype.bindEvents = function($elm) {
    var defaultEvents, event, eventsToBeBound, instanceEvents;
    $elm || ($elm = this.getDomElement());
    defaultEvents = "mousedown mouseup click dblclick";
    instanceEvents = this.getOptions().bind;
    eventsToBeBound = (function() {
      var _i, _len;
      if (instanceEvents) {
        eventsToBeBound = defaultEvents.trim().split(" ");
        instanceEvents = instanceEvents.trim().split(" ");
        for (_i = 0, _len = instanceEvents.length; _i < _len; _i++) {
          event = instanceEvents[_i];
          if (__indexOf.call(eventsToBeBound, event) < 0) {
            eventsToBeBound.push(event);
          }
        }
        return eventsToBeBound.join(" ");
      } else {
        return defaultEvents;
      }
    })();
    $elm.bind(eventsToBeBound, (function(_this) {
      return function(event) {
        var willPropagateToDOM;
        willPropagateToDOM = _this.handleEvent(event);
        if (!willPropagateToDOM) {
          event.stopPropagation();
        }
        return true;
      };
    })(this));
    return eventsToBeBound;
  };

  KDView.prototype.bindTransitionEnd = function() {
    var el, key, transitionEvent, transitions, val;
    el = document.createElement('fakeelement');
    transitions = {
      'OTransition': 'oTransitionEnd',
      'MozTransition': 'transitionend',
      'webkitTransition': 'webkitTransitionEnd'
    };
    transitionEvent = 'transitionend';
    for (key in transitions) {
      if (!__hasProp.call(transitions, key)) continue;
      val = transitions[key];
      if (!(key in el.style)) {
        continue;
      }
      transitionEvent = val;
      break;
    }
    this.bindEvent(transitionEvent);
    if (transitionEvent !== "transitionend") {
      return this.on(transitionEvent, this.emit.bind(this, "transitionend"));
    }
  };

  KDView.prototype.bindEvent = function($elm, eventName) {
    var _ref;
    if (!eventName) {
      _ref = [$elm, this.$()], eventName = _ref[0], $elm = _ref[1];
    }
    return $elm.bind(eventName, (function(_this) {
      return function(event) {
        var shouldPropagate;
        shouldPropagate = _this.handleEvent(event);
        if (!shouldPropagate) {
          event.stopPropagation();
        }
        return true;
      };
    })(this));
  };

  KDView.prototype.handleEvent = function(event) {
    var methodName, shouldPropagate;
    methodName = eventToMethodMap()[event.type] || event.type;
    shouldPropagate = this[methodName] != null ? this[methodName](event) : true;
    if (shouldPropagate !== false) {
      this.emit(event.type, event);
    }
    return shouldPropagate;
  };

  KDView.prototype.scroll = function(event) {
    return true;
  };

  KDView.prototype.load = function(event) {
    return true;
  };

  KDView.prototype.error = function(event) {
    return true;
  };

  KDView.prototype.keyUp = function(event) {
    return true;
  };

  KDView.prototype.keyDown = function(event) {
    return true;
  };

  KDView.prototype.keyPress = function(event) {
    return true;
  };

  KDView.prototype.dblClick = function(event) {
    return true;
  };

  KDView.prototype.click = function(event) {
    return true;
  };

  KDView.prototype.contextMenu = function(event) {
    return true;
  };

  KDView.prototype.mouseMove = function(event) {
    return true;
  };

  KDView.prototype.mouseEnter = function(event) {
    return true;
  };

  KDView.prototype.mouseLeave = function(event) {
    return true;
  };

  KDView.prototype.mouseUp = function(event) {
    return true;
  };

  KDView.prototype.mouseOver = function(event) {
    return true;
  };

  KDView.prototype.mouseWheel = function(event) {
    return true;
  };

  KDView.prototype.mouseDown = function(event) {
    this.unsetKeyView();
    return true;
  };

  KDView.prototype.paste = function(event) {
    return true;
  };

  KDView.prototype.dragEnter = function(e) {
    e.preventDefault();
    return e.stopPropagation();
  };

  KDView.prototype.dragOver = function(e) {
    e.preventDefault();
    return e.stopPropagation();
  };

  KDView.prototype.dragLeave = function(e) {
    e.preventDefault();
    return e.stopPropagation();
  };

  KDView.prototype.drop = function(event) {
    event.preventDefault();
    return event.stopPropagation();
  };

  KDView.prototype.submit = function(event) {
    return false;
  };

  KDView.prototype.setEmptyDragState = function(moveBacktoInitialPosition) {
    var el;
    if (moveBacktoInitialPosition == null) {
      moveBacktoInitialPosition = false;
    }
    if (moveBacktoInitialPosition && this.dragState) {
      el = this.$();
      el.css('left', 0);
      el.css('top', 0);
    }
    return this.dragState = {
      containment: null,
      handle: null,
      axis: null,
      direction: {
        current: {
          x: null,
          y: null
        },
        global: {
          x: null,
          y: null
        }
      },
      position: {
        relative: {
          x: 0,
          y: 0
        },
        initial: {
          x: 0,
          y: 0
        },
        global: {
          x: 0,
          y: 0
        }
      },
      meta: {
        top: 0,
        right: 0,
        bottom: 0,
        left: 0
      }
    };
  };

  KDView.prototype.setDraggable = function(options) {
    var handle;
    if (options == null) {
      options = {};
    }
    if (options === true) {
      options = {};
    }
    this.setEmptyDragState();
    handle = options.handle instanceof KDView ? options.handle : this;
    this.on("DragFinished", (function(_this) {
      return function(e) {
        return _this.beingDragged = false;
      };
    })(this));
    return handle.on("mousedown", (function(_this) {
      return function(event) {
        var bounds, dragEl, dragMeta, dragPos, dragState, oPad, p, padding, v, view;
        if ("string" === typeof options.handle) {
          if ($(event.target).closest(options.handle).length === 0) {
            return;
          }
        }
        _this.dragIsAllowed = true;
        _this.setEmptyDragState();
        dragState = _this.dragState;
        if (options.containment) {
          dragState.containment = {};
          dragState.containment.m = {
            w: _this.getWidth(),
            h: _this.getHeight()
          };
          view = options.containment.view;
          bounds = 'string' === typeof view ? _this[view].getBounds() : view instanceof KDView ? view.getBounds() : _this.parent.getBounds();
          dragState.containment.viewBounds = bounds;
          padding = {
            top: 0,
            right: 0,
            bottom: 0,
            left: 0
          };
          oPad = options.containment.padding;
          if ('number' === typeof oPad) {
            for (p in padding) {
              if (!__hasProp.call(padding, p)) continue;
              v = padding[p];
              v = oPad;
            }
          } else if ('object' === typeof oPad) {
            KD.utils.extend(padding, oPad);
          }
          dragState.containment.padding = padding;
        }
        dragState.handle = options.handle;
        dragState.axis = options.axis;
        dragMeta = dragState.meta;
        dragEl = _this.getElement();
        dragMeta.top = parseInt(dragEl.style.top, 10) || 0;
        dragMeta.right = parseInt(dragEl.style.right, 10) || 0;
        dragMeta.bottom = parseInt(dragEl.style.bottom, 10) || 0;
        dragMeta.left = parseInt(dragEl.style.left, 10) || 0;
        dragPos = _this.dragState.position;
        dragPos.initial.x = event.pageX;
        dragPos.initial.y = event.pageY;
        KD.getSingleton('windowController').setDragView(_this);
        _this.emit("DragStarted", event, _this.dragState);
        event.stopPropagation();
        event.preventDefault();
        return false;
      };
    })(this));
  };

  KDView.prototype.drag = function(event, delta) {
    var axis, containment, cp, directionX, directionY, dragCurDir, dragDir, dragGlobDir, dragGlobPos, dragInitPos, dragMeta, dragPos, dragRelPos, draggedDistance, el, m, newX, newY, p, targetPosX, targetPosY, x, y, _ref;
    _ref = this.dragState, directionX = _ref.directionX, directionY = _ref.directionY, axis = _ref.axis, containment = _ref.containment;
    x = delta.x, y = delta.y;
    dragPos = this.dragState.position;
    dragRelPos = dragPos.relative;
    dragInitPos = dragPos.initial;
    dragGlobPos = dragPos.global;
    dragDir = this.dragState.direction;
    dragGlobDir = dragDir.global;
    dragCurDir = dragDir.current;
    axis = this.getOptions().draggable.axis;
    draggedDistance = axis ? axis === "x" ? Math.abs(x) : Math.abs(y) : Math.max(Math.abs(x), Math.abs(y));
    this.dragIsAllowed = this.beingDragged = !(draggedDistance < 20 && !this.beingDragged);
    if (x > dragRelPos.x) {
      dragCurDir.x = 'right';
    } else if (x < dragRelPos.x) {
      dragCurDir.x = 'left';
    }
    if (y > dragRelPos.y) {
      dragCurDir.y = 'bottom';
    } else if (y < dragRelPos.y) {
      dragCurDir.y = 'top';
    }
    dragGlobPos.x = dragInitPos.x + x;
    dragGlobPos.y = dragInitPos.y + y;
    dragGlobDir.x = x > 0 ? 'right' : 'left';
    dragGlobDir.y = y > 0 ? 'bottom' : 'top';
    if (this.dragIsAllowed) {
      el = this.$();
      dragMeta = this.dragState.meta;
      targetPosX = dragMeta.right && !dragMeta.left ? 'right' : 'left';
      targetPosY = dragMeta.bottom && !dragMeta.top ? 'bottom' : 'top';
      newX = targetPosX === 'left' ? dragMeta.left + dragRelPos.x : dragMeta.right - dragRelPos.x;
      newY = targetPosY === 'top' ? dragMeta.top + dragRelPos.y : dragMeta.bottom - dragRelPos.y;
      if (containment) {
        m = containment.m;
        p = containment.viewBounds;
        cp = containment.padding;
        if (newX <= cp.left) {
          newX = cp.left;
        }
        if (newY <= cp.top) {
          newY = cp.top;
        }
        if (newX + m.w >= p.w - cp.right) {
          newX = p.w - m.w - cp.right;
        }
        if (newY + m.h >= p.h - cp.bottom) {
          newY = p.h - m.h - cp.bottom;
        }
      }
      if (axis !== 'y') {
        el.css(targetPosX, newX);
      }
      if (axis !== 'x') {
        el.css(targetPosY, newY);
      }
    }
    dragRelPos.x = x;
    dragRelPos.y = y;
    return this.emit("DragInAction", x, y);
  };

  KDView.prototype.viewAppended = function() {};

  KDView.prototype.childAppended = function(child) {
    var _ref;
    return (_ref = this.parent) != null ? _ref.emit('childAppended', child) : void 0;
  };

  KDView.prototype.setViewReady = function() {
    return this.viewIsReady = true;
  };

  KDView.prototype.isViewReady = function() {
    return this.viewIsReady || false;
  };

  KDView.prototype.observeMutations = function() {
    var MutationObserver, MutationSummary, observerSummary;
    MutationSummary = require('./../../libs/mutation-summary.js');
    MutationObserver = window.MutationObserver || window.WebKitMutationObserver || window.MozMutationObserver;
    return observerSummary = new MutationSummary({
      callback: (function(_this) {
        return function(rest) {
          return _this.emit.apply(_this, ['MutationHappened'].concat(__slice.call(rest)));
        };
      })(this),
      rootNode: this.getElement(),
      queries: [
        {
          all: true
        }
      ]
    });
  };

  KDView.prototype.putOverlay = function(options) {
    var KDOverlayView;
    if (options == null) {
      options = {};
    }
    options.delegate = this;
    KDOverlayView = require('./../components/overlay/overlayview.coffee');
    return this.overlay = new KDOverlayView(options);
  };

  KDView.prototype.removeOverlay = function() {
    var _ref;
    return (_ref = this.overlay) != null ? _ref.destroy() : void 0;
  };

  KDView.prototype.unsetTooltip = function(o) {
    var _ref;
    if (o == null) {
      o = {};
    }
    if ((_ref = this.tooltip) != null) {
      _ref.destroy();
    }
    return delete this.tooltip;
  };

  KDView.prototype.setTooltip = function(o) {
    var KDTooltip, placementMap;
    if (o == null) {
      o = {};
    }
    placementMap = {
      above: "s",
      below: "n",
      left: "e",
      right: "w"
    };
    o.title || (o.title = "");
    o.cssClass || (o.cssClass = "");
    o.placement || (o.placement = "top");
    o.direction || (o.direction = "center");
    o.offset || (o.offset = {
      top: 0,
      left: 0
    });
    o.delayIn || (o.delayIn = 0);
    o.delayOut || (o.delayOut = 0);
    if (o.html == null) {
      o.html = true;
    }
    if (o.animate == null) {
      o.animate = false;
    }
    o.selector || (o.selector = null);
    o.gravity || (o.gravity = placementMap[o.placement]);
    o.fade || (o.fade = o.animate);
    o.fallback || (o.fallback = o.title);
    o.view || (o.view = null);
    if (o.sticky == null) {
      o.sticky = false;
    }
    o.delegate || (o.delegate = this);
    o.events || (o.events = ['mouseenter', 'mouseleave', 'mousemove']);
    this.unsetTooltip();
    KDTooltip = require('./../components/tooltip/tooltip.coffee');
    return this.tooltip = new KDTooltip(o, {});
  };

  KDView.prototype.getTooltip = function() {
    return this.tooltip;
  };

  KDView.prototype._windowDidResize = function() {};

  KDView.prototype.listenWindowResize = function(state) {
    if (state == null) {
      state = true;
    }
    if (state) {
      return KD.singletons.windowController.registerWindowResizeListener(this);
    } else {
      return KD.singletons.windowController.unregisterWindowResizeListener(this);
    }
  };

  KDView.prototype.setKeyView = function() {
    return KD.singletons.windowController.setKeyView(this);
  };

  KDView.prototype.unsetKeyView = function() {
    return KD.singletons.windowController.setKeyView(null);
  };

  KDView.prototype.activateKeyView = function() {
    return typeof this.emit === "function" ? this.emit('KDViewBecameKeyView') : void 0;
  };

  return KDView;

})(KDObject);


},{"./../../libs/mutation-summary.js":1,"./../components/overlay/overlayview.coffee":62,"./../components/tooltip/tooltip.coffee":85,"./object.coffee":104}],109:[function(require,module,exports){
var KDController, KDView, KDViewController,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

KDView = require('./view.coffee');

KDController = require('./controller.coffee');

module.exports = KDViewController = (function(_super) {
  __extends(KDViewController, _super);

  function KDViewController(options, data) {
    if (options == null) {
      options = {};
    }
    options.view || (options.view = new KDView);
    KDViewController.__super__.constructor.call(this, options, data);
    if (this.getOptions().view) {
      this.setView(this.getOptions().view);
    }
  }

  KDViewController.prototype.loadView = function(mainView) {};

  KDViewController.prototype.getView = function() {
    return this.mainView;
  };

  KDViewController.prototype.setView = function(aViewInstance) {
    var cb;
    this.mainView = aViewInstance;
    this.emit("ControllerHasSetItsView");
    cb = this.loadView.bind(this, aViewInstance);
    if (aViewInstance.isViewReady()) {
      return cb();
    } else {
      aViewInstance.once('viewAppended', cb);
      return aViewInstance.once('KDObjectWillBeDestroyed', (function(_this) {
        return function() {
          return KD.utils.defer(_this.bound("destroy"));
        };
      })(this));
    }
  };

  return KDViewController;

})(KDController);


},{"./controller.coffee":96,"./view.coffee":108}],110:[function(require,module,exports){

/*
todo:

  - make addLayer implementation more clear, by default adding a layer
    should set a listener for next ReceivedClickElsewhere and remove the layer automatically
    2012/5/21 Sinan
 */
var KDController, KDWindowController,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

KDController = require('./controller.coffee');

module.exports = KDWindowController = (function(_super) {
  var addListener, getVisibilityEventName, getVisibilityProperty, superKey, superizeCombos;

  __extends(KDWindowController, _super);

  KDWindowController.keyViewHistory = [];

  superKey = navigator.userAgent.indexOf("Mac OS X") === -1 ? "ctrl" : "command";

  addListener = function(eventName, listener, capturePhase) {
    if (capturePhase == null) {
      capturePhase = true;
    }
    return window.addEventListener(eventName, listener, capturePhase);
  };

  getVisibilityProperty = function() {
    var prefix, prefixes, _i, _len;
    prefixes = ["webkit", "moz", "o"];
    if ("hidden" in document) {
      return "hidden";
    }
    for (_i = 0, _len = prefixes.length; _i < _len; _i++) {
      prefix = prefixes[_i];
      if (prefix + "Hidden" in document) {
        return "" + prefix + "Hidden";
      }
    }
    return "";
  };

  getVisibilityEventName = function() {
    return "" + (getVisibilityProperty().replace(/[Hh]idden/, '')) + "visibilitychange";
  };

  function KDWindowController(options, data) {
    this.windowResizeListeners = {};
    this.keyEventsToBeListened = ['keydown', 'keyup', 'keypress'];
    this.currentCombos = {};
    this.keyView = null;
    this.dragView = null;
    this.scrollingEnabled = true;
    this.layers = [];
    this.unloadListeners = {};
    this.focusListeners = [];
    this.bindEvents();
    KDWindowController.__super__.constructor.call(this, options, data);
  }

  KDWindowController.prototype.addLayer = function(layer) {
    if (__indexOf.call(this.layers, layer) < 0) {
      this.layers.push(layer);
      return layer.on('KDObjectWillBeDestroyed', (function(_this) {
        return function() {
          return _this.removeLayer(layer);
        };
      })(this));
    }
  };

  KDWindowController.prototype.removeLayer = function(layer) {
    var index;
    if (__indexOf.call(this.layers, layer) >= 0) {
      index = this.layers.indexOf(layer);
      return this.layers.splice(index, 1);
    }
  };

  KDWindowController.prototype.bindEvents = function() {
    var eventName, layers, _i, _len, _ref;
    _ref = this.keyEventsToBeListened;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      eventName = _ref[_i];
      addEventListener(eventName, this.bound('key'));
    }
    addEventListener('resize', this.bound('notifyWindowResizeListeners'));
    document.addEventListener('scroll', (function(_this) {
      return function() {
        var body, timer;
        timer = null;
        body = document.body;
        return _.throttle(function(event) {
          return _this.emit("ScrollHappened", event);
        }, 50);
      };
    })(this)(), false);
    addListener("dragenter", (function(_this) {
      return function(event) {
        if (!_this.dragInAction) {
          _this.emit('DragEnterOnWindow', event);
          return _this.setDragInAction(true);
        }
      };
    })(this));
    addListener("dragleave", (function(_this) {
      return function(event) {
        var _ref1, _ref2;
        if (!((0 < (_ref1 = event.clientX) && _ref1 < _this.winWidth) && (0 < (_ref2 = event.clientY) && _ref2 < _this.winHeight))) {
          _this.emit('DragExitOnWindow', event);
          return _this.setDragInAction(false);
        }
      };
    })(this));
    addListener("drop", (function(_this) {
      return function(event) {
        _this.emit('DragExitOnWindow', event);
        _this.emit('DropOnWindow', event);
        return _this.setDragInAction(false);
      };
    })(this));
    layers = this.layers;
    addListener('mousedown', (function(_this) {
      return function(e) {
        var lastLayer;
        lastLayer = layers.last;
        if (lastLayer && $(e.target).closest(lastLayer != null ? lastLayer.$() : void 0).length === 0) {
          lastLayer.emit('ReceivedClickElsewhere', e);
          return _this.removeLayer(lastLayer);
        }
      };
    })(this));
    addListener('mouseup', (function(_this) {
      return function(e) {
        if (_this.dragView) {
          _this.unsetDragView(e);
        }
        return _this.emit('ReceivedMouseUpElsewhere', e);
      };
    })(this));
    addListener('mousemove', (function(_this) {
      return function(e) {
        if (_this.dragView) {
          return _this.redirectMouseMoveEvent(e);
        }
      };
    })(this));
    addListener('click', function(e) {
      var href, isHttp, nearestLink, _ref1;
      nearestLink = KD.utils.getNearestElementByTagName(e.target, 'a');
      if ((nearestLink != null ? (_ref1 = nearestLink.target) != null ? _ref1.length : void 0 : void 0) === 0) {
        href = nearestLink.getAttribute("href");
        isHttp = (href != null ? href.indexOf("http") : void 0) === 0;
        if (isHttp) {
          return nearestLink.target = "_blank";
        } else {
          e.preventDefault();
          if (href && !/^#/.test(href)) {
            return KD.getSingleton("router").handleRoute(href);
          }
        }
      }
    }, false);
    window.addEventListener('beforeunload', this.bound("beforeUnload"));
    return document.addEventListener(getVisibilityEventName(), (function(_this) {
      return function(event) {
        return _this.focusChange(event, _this.isFocused());
      };
    })(this));
  };

  KDWindowController.prototype.addUnloadListener = function(key, listener) {
    var _base;
    (_base = this.unloadListeners)[key] || (_base[key] = []);
    return this.unloadListeners[key].push(listener);
  };

  KDWindowController.prototype.clearUnloadListeners = function(key) {
    if (key) {
      return this.unloadListeners[key] = [];
    } else {
      return this.unloadListeners = {};
    }
  };

  KDWindowController.prototype.isFocused = function() {
    return !Boolean(document[getVisibilityProperty()]);
  };

  KDWindowController.prototype.addFocusListener = function(listener) {
    return this.focusListeners.push(listener);
  };

  KDWindowController.prototype.focusChange = function(event, state) {
    var listener, _i, _len, _ref, _results;
    if (!event) {
      return;
    }
    _ref = this.focusListeners;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      listener = _ref[_i];
      _results.push(listener(state, event));
    }
    return _results;
  };

  KDWindowController.prototype.beforeUnload = function(event) {
    var key, listener, listeners, message, _i, _len, _ref;
    if (!event) {
      return;
    }
    _ref = this.unloadListeners;
    for (key in _ref) {
      if (!__hasProp.call(_ref, key)) continue;
      listeners = _ref[key];
      for (_i = 0, _len = listeners.length; _i < _len; _i++) {
        listener = listeners[_i];
        if (listener() === false) {
          message = key !== "window" ? " on " + key : "";
          return "Please make sure that you saved all your work" + message + ".";
        }
      }
    }
  };

  KDWindowController.prototype.setDragInAction = function(dragInAction) {
    this.dragInAction = dragInAction != null ? dragInAction : false;
    return $('body')[this.dragInAction ? "addClass" : "removeClass"]("dragInAction");
  };

  KDWindowController.prototype.setMainView = function(mainView) {
    this.mainView = mainView;
  };

  KDWindowController.prototype.getMainView = function(view) {
    return this.mainView;
  };

  KDWindowController.prototype.revertKeyView = function(view) {
    if (!view) {
      warn("you must pass the view as a param, which doesn't want to be keyview anymore!");
      return;
    }
    if (view === this.keyView && this.keyView !== this.oldKeyView) {
      return this.setKeyView(this.oldKeyView);
    }
  };

  superizeCombos = function(combos) {
    var cb, combo, safeCombos;
    safeCombos = {};
    for (combo in combos) {
      if (!__hasProp.call(combos, combo)) continue;
      cb = combos[combo];
      if (/\bsuper(\+|\s)/.test(combo)) {
        combo = combo.replace(/super/g, superKey);
      }
      safeCombos[combo] = cb;
    }
    return safeCombos;
  };

  KDWindowController.prototype.viewHasKeyCombos = function(view) {
    var cb, combo, combos, e, o, _i, _len, _ref, _ref1;
    if (!view) {
      return;
    }
    o = view.getOptions();
    combos = {};
    _ref = this.keyEventsToBeListened;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      e = _ref[_i];
      if ("object" === typeof o[e]) {
        _ref1 = o[e];
        for (combo in _ref1) {
          if (!__hasProp.call(_ref1, combo)) continue;
          cb = _ref1[combo];
          combos[combo] = cb;
        }
      }
    }
    if (Object.keys(combos).length > 0) {
      return combos;
    } else {
      return false;
    }
  };

  KDWindowController.prototype.registerKeyCombos = function(view) {
    var combos;
    combos = this.viewHasKeyCombos(view);
    if (combos != null) {
      this.comboMap = new KDKeyboardMap({
        combos: combos
      });
      return KDKeyboardListener.current().addComboMap(this.comboMap);
    }
  };

  KDWindowController.prototype.unregisterKeyCombos = function() {
    KDKeyboardListener.current().removeComboMap(this.comboMap);
    if (this.keyView) {
      return this.keyView.unsetClass("mousetrap");
    }
  };

  KDWindowController.prototype.setKeyView = function(keyView) {
    if (keyView != null) {
      if (typeof keyView.activateKeyView === "function") {
        keyView.activateKeyView();
      }
    }
    if (keyView === this.keyView) {
      return;
    }
    this.unregisterKeyCombos();
    this.oldKeyView = this.keyView;
    this.keyView = keyView;
    this.registerKeyCombos(keyView);
    this.constructor.keyViewHistory.push(keyView);
    if (keyView != null) {
      if (typeof keyView.activateKeyView === "function") {
        keyView.activateKeyView();
      }
    }
    return this.emit('WindowChangeKeyView', keyView);
  };

  KDWindowController.prototype.setDragView = function(dragView) {
    this.setDragInAction(true);
    return this.dragView = dragView;
  };

  KDWindowController.prototype.unsetDragView = function(e) {
    this.setDragInAction(false);
    this.dragView.emit("DragFinished", e);
    return this.dragView = null;
  };

  KDWindowController.prototype.redirectMouseMoveEvent = function(event) {
    var delta, initial, initialX, initialY, pageX, pageY, view;
    view = this.dragView;
    pageX = event.pageX, pageY = event.pageY;
    initial = view.dragState.position.initial;
    initialX = initial.x;
    initialY = initial.y;
    delta = {
      x: pageX - initialX,
      y: pageY - initialY
    };
    return view.drag(event, delta);
  };

  KDWindowController.prototype.getKeyView = function() {
    return this.keyView;
  };

  KDWindowController.prototype.key = function(event) {
    var _ref;
    this.emit(event.type, event);
    return (_ref = this.keyView) != null ? _ref.handleEvent(event) : void 0;
  };

  KDWindowController.prototype.enableScroll = function() {
    return this.scrollingEnabled = true;
  };

  KDWindowController.prototype.disableScroll = function() {
    return this.scrollingEnabled = false;
  };

  KDWindowController.prototype.registerWindowResizeListener = function(instance) {
    this.windowResizeListeners[instance.id] = instance;
    return instance.on("KDObjectWillBeDestroyed", (function(_this) {
      return function() {
        return delete _this.windowResizeListeners[instance.id];
      };
    })(this));
  };

  KDWindowController.prototype.unregisterWindowResizeListener = function(instance) {
    return delete this.windowResizeListeners[instance.id];
  };

  KDWindowController.prototype.setWindowProperties = function(event) {
    this.winWidth = window.innerWidth;
    return this.winHeight = window.innerHeight;
  };

  KDWindowController.prototype.notifyWindowResizeListeners = function(event, throttle, duration) {
    var fireResizeHandlers;
    if (throttle == null) {
      throttle = false;
    }
    if (duration == null) {
      duration = 17;
    }
    event || (event = {
      type: "resize"
    });
    fireResizeHandlers = (function(_this) {
      return function() {
        var instance, key, _ref, _results;
        _ref = _this.windowResizeListeners;
        _results = [];
        for (key in _ref) {
          if (!__hasProp.call(_ref, key)) continue;
          instance = _ref[key];
          if (instance._windowDidResize) {
            _results.push(instance._windowDidResize(event));
          }
        }
        return _results;
      };
    })(this);
    if (throttle) {
      KD.utils.killWait(this.resizeNotifiersTimer);
      return this.resizeNotifiersTimer = KD.utils.wait(duration, fireResizeHandlers);
    } else {
      return fireResizeHandlers();
    }
  };

  return KDWindowController;

})(KDController);

(function() {
  var KD;
  KD = require('./kd.coffee');
  return KD.registerSingleton("windowController", new KDWindowController);
})();


},{"./controller.coffee":96,"./kd.coffee":100}],111:[function(require,module,exports){
var KD, utils;

require('./lib.includes.coffee');

utils = require('./core/utils.coffee');

KD = require('./core/kd.coffee');

KD.dom = require('./core/kd.dom.js');

KD.classes = {};

KD.classes.KDAutoComplete = require("./components/autocomplete/autocomplete.coffee");

KD.classes.KDAutoCompleteController = require("./components/autocomplete/autocompletecontroller.coffee");

KD.classes.KDAutoCompletedItem = require("./components/autocomplete/autocompleteditems.coffee");

KD.classes.KDAutoCompleteFetchingItem = require("./components/autocomplete/autocompletefetchingitem.coffee");

KD.classes.KDAutoCompleteListView = require("./components/autocomplete/autocompletelist.coffee");

KD.classes.KDAutoCompleteListItemView = require("./components/autocomplete/autocompletelistitem.coffee");

KD.classes.KDAutoCompleteNothingFoundItem = require("./components/autocomplete/autocompletenothingfounditem.coffee");

KD.classes.KDAutocompleteUnselecteableItem = require("./components/autocomplete/autocompleteunselecteableitem.coffee");

KD.classes.MultipleInputListView = require("./components/autocomplete/multipleinputlistview.coffee");

KD.classes.KDMultipleInputView = require("./components/autocomplete/multipleinputview.coffee");

KD.classes.MultipleListItemView = require("./components/autocomplete/multiplelistitemview.coffee");

KD.classes.NoAutocompleteInputView = require("./components/autocomplete/noautocompleteinputview.coffee");

KD.classes.NoAutocompleteMultipleListView = require("./components/autocomplete/noautocompletemultiplelistview.coffee");

KD.classes.KDSimpleAutocomplete = require("./components/autocomplete/simpleautocomplete.coffee");

KD.classes.KDButtonBar = require("./components/buttons/buttonbar.coffee");

KD.classes.KDButtonGroupView = require("./components/buttons/buttongroupview.coffee");

KD.classes.JButtonMenu = require("./components/buttons/buttonmenu.coffee");

KD.classes.KDButtonView = require("./components/buttons/buttonview.coffee");

KD.classes.KDButtonViewWithMenu = require("./components/buttons/buttonviewwithmenu.coffee");

KD.classes.KDToggleButton = require("./components/buttons/togglebutton.coffee");

KD.classes.KDContextMenu = require("./components/contextmenu/contextmenu.coffee");

KD.classes.JContextMenuItem = require("./components/contextmenu/contextmenuitem.coffee");

KD.classes.JContextMenuTreeView = require("./components/contextmenu/contextmenutreeview.coffee");

KD.classes.JContextMenuTreeViewController = require("./components/contextmenu/contextmenutreeviewcontroller.coffee");

KD.classes.KDCounterDigitView = require("./components/counter/counterdigitview.coffee");

KD.classes.KDCounterView = require("./components/counter/counterview.coffee");

KD.classes.KDDiaContainer = require("./components/dia/diacontainer.coffee");

KD.classes.KDDiaJoint = require("./components/dia/diajoint.coffee");

KD.classes.KDDiaObject = require("./components/dia/diaobject.coffee");

KD.classes.KDDiaScene = require("./components/dia/diascene.coffee");

KD.classes.KDDialogView = require("./components/dialog/dialogview.coffee");

KD.classes.KDFormView = require("./components/forms/formview.coffee");

KD.classes.KDFormViewWithFields = require("./components/forms/formviewwithfields.coffee");

KD.classes.KDHeaderView = require("./components/header/headerview.coffee");

KD.classes.KDWebcamView = require("./components/image/webcamview.coffee");

KD.classes.KDCheckBox = require("./components/inputs/checkbox.coffee");

KD.classes.KDContentEditableView = require("./components/inputs/contenteditableview.coffee");

KD.classes.KDDelimitedInputView = require("./components/inputs/delimitedinputview.coffee");

KD.classes.KDHitEnterInputView = require("./components/inputs/hitenterinputview.coffee");

KD.classes.KDInputCheckboxGroup = require("./components/inputs/inputcheckboxgroup.coffee");

KD.classes.KDInputRadioGroup = require("./components/inputs/inputradiogroup.coffee");

KD.classes.KDInputSwitch = require("./components/inputs/inputswitch.coffee");

KD.classes.KDInputValidator = require("./components/inputs/inputvalidator.coffee");

KD.classes.KDInputView = require("./components/inputs/inputview.coffee");

KD.classes.KDLabelView = require("./components/inputs/labelview.coffee");

KD.classes.KDMultipleChoice = require("./components/inputs/multiplechoice.coffee");

KD.classes.KDOnOffSwitch = require("./components/inputs/onoffswitch.coffee");

KD.classes.KDSelectBox = require("./components/inputs/selectbox.coffee");

KD.classes.KDTokenizedInput = require("./components/inputs/tokenizedinputview.coffee");

KD.classes.KDWmdInput = require("./components/inputs/wmdinput.coffee");

KD.classes.KDListItemView = require("./components/list/listitemview.coffee");

KD.classes.KDListView = require("./components/list/listview.coffee");

KD.classes.KDListViewController = require("./components/list/listviewcontroller.coffee");

KD.classes.KDLoaderView = require("./components/loader/loaderview.coffee");

KD.classes.KDBlockingModalView = require("./components/modals/blockingmodalview.coffee");

KD.classes.KDModalView = require("./components/modals/modalview.coffee");

KD.classes.KDModalViewStack = require("./components/modals/modalviewstack.coffee");

KD.classes.KDModalViewWithForms = require("./components/modals/modalviewwithforms.coffee");

KD.classes.KDNotificationView = require("./components/notifications/notificationview.coffee");

KD.classes.KDOverlayView = require("./components/overlay/overlayview.coffee");

KD.classes.KDSpotlightView = require("./components/overlay/spotlightview.coffee");

KD.classes.KDProgressBarView = require("./components/progressbar/progressbarview.coffee");

KD.classes.KDCustomScrollView = require("./components/scrollview/customscrollview.coffee");

KD.classes.KDCustomScrollViewWrapper = require("./components/scrollview/customscrollviewinner.coffee");

KD.classes.KDScrollThumb = require("./components/scrollview/scrollthumb.coffee");

KD.classes.KDScrollTrack = require("./components/scrollview/scrolltrack.coffee");

KD.classes.KDScrollView = require("./components/scrollview/scrollview.coffee");

KD.classes.KDSliderBarHandleView = require("./components/sliderbar/sliderbarhandleview.coffee");

KD.classes.KDSliderBarView = require("./components/sliderbar/sliderbarview.coffee");

KD.classes.KDSlidePageView = require("./components/slideshow/slidepageview.coffee");

KD.classes.KDSlideShowView = require("./components/slideshow/slideshowview.coffee");

KD.classes.KDSplitComboView = require("./components/split/splitcomboview.coffee");

KD.classes.KDSplitViewPanel = require("./components/split/splitpanel.coffee");

KD.classes.KDSplitResizer = require("./components/split/splitresizer.coffee");

KD.classes.KDSplitView = require("./components/split/splitview.coffee");

KD.classes.KDTabHandleContainer = require("./components/tabs/tabhandlecontainer.coffee");

KD.classes.KDTabHandleMoveNav = require("./components/tabs/tabhandlemovenav.coffee");

KD.classes.KDTabHandleView = require("./components/tabs/tabhandleview.coffee");

KD.classes.KDTabPaneView = require("./components/tabs/tabpaneview.coffee");

KD.classes.KDTabView = require("./components/tabs/tabview.coffee");

KD.classes.KDTabViewWithForms = require("./components/tabs/tabviewwithforms.coffee");

KD.classes.KDTimeAgoView = require("./components/time/timeagoview.coffee");

KD.classes.KDTooltip = require("./components/tooltip/tooltip.coffee");

KD.classes.JTreeItemView = require("./components/tree/treeitemview.coffee");

KD.classes.JTreeView = require("./components/tree/treeview.coffee");

KD.classes.JTreeViewController = require("./components/tree/treeviewcontroller.coffee");

KD.classes.KDFileUploadArea = require("./components/upload/fileuploadarea.coffee");

KD.classes.KDFileUploadListItemView = require("./components/upload/fileuploadlistitemview.coffee");

KD.classes.KDFileUploadListView = require("./components/upload/fileuploadlistview.coffee");

KD.classes.KDFileUploadThumbItemView = require("./components/upload/fileuploadthumbitemview.coffee");

KD.classes.KDFileUploadThumbListView = require("./components/upload/fileuploadthumblistview.coffee");

KD.classes.KDFileUploadView = require("./components/upload/fileuploadview.coffee");

KD.classes.KDMultipartUploader = require("./components/upload/multipartuploader.coffee");

KD.classes.KDController = require("./core/controller.coffee");

KD.classes.KDCustomHTMLView = require("./core/customhtmlview.coffee");

KD.classes.KDEventEmitter = require("./core/eventemitter.coffee");

KD.classes.KDEventEmitter.Wildcard = require("./core/eventemitterwildcard.coffee");

KD.classes.KDKeyboardListener = require("./core/keyboard/listener.coffee");

KD.classes.KDKeyboardMap = require("./core/keyboard/map.coffee");

KD.classes.KDObject = require("./core/object.coffee");

KD.classes.KDRouter = require("./core/router.coffee");

KD.classes.KDView = require("./core/view.coffee");

KD.classes.KDViewController = require("./core/viewcontroller.coffee");

KD.classes.KDWindowController = require("./core/windowcontroller.coffee");

KD.exportKDFramework();


},{"./components/autocomplete/autocomplete.coffee":3,"./components/autocomplete/autocompletecontroller.coffee":4,"./components/autocomplete/autocompleteditems.coffee":5,"./components/autocomplete/autocompletefetchingitem.coffee":6,"./components/autocomplete/autocompletelist.coffee":7,"./components/autocomplete/autocompletelistitem.coffee":8,"./components/autocomplete/autocompletenothingfounditem.coffee":9,"./components/autocomplete/autocompleteunselecteableitem.coffee":10,"./components/autocomplete/multipleinputlistview.coffee":11,"./components/autocomplete/multipleinputview.coffee":12,"./components/autocomplete/multiplelistitemview.coffee":13,"./components/autocomplete/noautocompleteinputview.coffee":14,"./components/autocomplete/noautocompletemultiplelistview.coffee":15,"./components/autocomplete/simpleautocomplete.coffee":16,"./components/buttons/buttonbar.coffee":17,"./components/buttons/buttongroupview.coffee":18,"./components/buttons/buttonmenu.coffee":19,"./components/buttons/buttonview.coffee":20,"./components/buttons/buttonviewwithmenu.coffee":21,"./components/buttons/togglebutton.coffee":22,"./components/contextmenu/contextmenu.coffee":23,"./components/contextmenu/contextmenuitem.coffee":24,"./components/contextmenu/contextmenutreeview.coffee":25,"./components/contextmenu/contextmenutreeviewcontroller.coffee":26,"./components/counter/counterdigitview.coffee":27,"./components/counter/counterview.coffee":28,"./components/dia/diacontainer.coffee":29,"./components/dia/diajoint.coffee":30,"./components/dia/diaobject.coffee":31,"./components/dia/diascene.coffee":32,"./components/dialog/dialogview.coffee":33,"./components/forms/formview.coffee":34,"./components/forms/formviewwithfields.coffee":35,"./components/header/headerview.coffee":36,"./components/image/webcamview.coffee":37,"./components/inputs/checkbox.coffee":38,"./components/inputs/contenteditableview.coffee":39,"./components/inputs/delimitedinputview.coffee":40,"./components/inputs/hitenterinputview.coffee":41,"./components/inputs/inputcheckboxgroup.coffee":42,"./components/inputs/inputradiogroup.coffee":43,"./components/inputs/inputswitch.coffee":44,"./components/inputs/inputvalidator.coffee":45,"./components/inputs/inputview.coffee":46,"./components/inputs/labelview.coffee":47,"./components/inputs/multiplechoice.coffee":48,"./components/inputs/onoffswitch.coffee":49,"./components/inputs/selectbox.coffee":50,"./components/inputs/tokenizedinputview.coffee":51,"./components/inputs/wmdinput.coffee":52,"./components/list/listitemview.coffee":53,"./components/list/listview.coffee":54,"./components/list/listviewcontroller.coffee":55,"./components/loader/loaderview.coffee":56,"./components/modals/blockingmodalview.coffee":57,"./components/modals/modalview.coffee":58,"./components/modals/modalviewstack.coffee":59,"./components/modals/modalviewwithforms.coffee":60,"./components/notifications/notificationview.coffee":61,"./components/overlay/overlayview.coffee":62,"./components/overlay/spotlightview.coffee":63,"./components/progressbar/progressbarview.coffee":64,"./components/scrollview/customscrollview.coffee":65,"./components/scrollview/customscrollviewinner.coffee":66,"./components/scrollview/scrollthumb.coffee":67,"./components/scrollview/scrolltrack.coffee":68,"./components/scrollview/scrollview.coffee":69,"./components/sliderbar/sliderbarhandleview.coffee":70,"./components/sliderbar/sliderbarview.coffee":71,"./components/slideshow/slidepageview.coffee":72,"./components/slideshow/slideshowview.coffee":73,"./components/split/splitcomboview.coffee":74,"./components/split/splitpanel.coffee":75,"./components/split/splitresizer.coffee":76,"./components/split/splitview.coffee":77,"./components/tabs/tabhandlecontainer.coffee":78,"./components/tabs/tabhandlemovenav.coffee":79,"./components/tabs/tabhandleview.coffee":80,"./components/tabs/tabpaneview.coffee":81,"./components/tabs/tabview.coffee":82,"./components/tabs/tabviewwithforms.coffee":83,"./components/time/timeagoview.coffee":84,"./components/tooltip/tooltip.coffee":85,"./components/tree/treeitemview.coffee":86,"./components/tree/treeview.coffee":87,"./components/tree/treeviewcontroller.coffee":88,"./components/upload/fileuploadarea.coffee":89,"./components/upload/fileuploadlistitemview.coffee":90,"./components/upload/fileuploadlistview.coffee":91,"./components/upload/fileuploadthumbitemview.coffee":92,"./components/upload/fileuploadthumblistview.coffee":93,"./components/upload/fileuploadview.coffee":94,"./components/upload/multipartuploader.coffee":95,"./core/controller.coffee":96,"./core/customhtmlview.coffee":97,"./core/eventemitter.coffee":98,"./core/eventemitterwildcard.coffee":99,"./core/kd.coffee":100,"./core/kd.dom.js":101,"./core/keyboard/listener.coffee":102,"./core/keyboard/map.coffee":103,"./core/object.coffee":104,"./core/router.coffee":105,"./core/utils.coffee":107,"./core/view.coffee":108,"./core/viewcontroller.coffee":109,"./core/windowcontroller.coffee":110,"./lib.includes.coffee":112}],112:[function(require,module,exports){
module.exports = ["./libs/docwritenoop.js", "./libs/encode.js", "./libs/jquery-1.9.1.js", "./libs/underscore-min.1.3.js", "./libs/cookies.js", "./libs/jquery-timeago.js", "./libs/date.format.js", "./libs/highlight.pack.js", "./libs/inflector.js", "./libs/canvas-loader.js", "./libs/mousetrap.js", "./libs/mousetrap-global-bind.js", "./libs/marked.js", "./libs/jspath.js", "./libs/hammer.js"];


},{}]},{},[111])