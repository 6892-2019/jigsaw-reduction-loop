(function(factory) {
  var E  = (typeof exports === 'object'),
      js = (typeof JS === 'undefined') ? require('./core') : JS,

      Hash = js.Hash || require('./hash').Hash;

  if (E) exports.JS = exports;
  factory(js, Hash, E ? exports : js);

})(function(JS, Hash, exports) {
'use strict';

var TSort = new JS.Module('TSort', {
  extend: {
    Cyclic: new JS.Class(Error)
  },

  tsort: function() {
    var result = [];
    this.tsortEach(result.push, result);
    return result;
  },

  tsortEach: function(block, context) {
    this.eachStronglyConnectedComponent(function(component) {
      if (component.length === 1)
        block.call(context, component[0]);
      else
        throw new TSort.Cyclic('topological sort failed: ' + component.toString());
    });
  },

  stronglyConnectedComponents: function() {
    var result = [];
    this.eachStronglyConnectedComponent(result.push, result);
    return result;
  },

  eachStronglyConnectedComponent: function(block, context) {
    var idMap = new Hash(),
        stack = [];

    this.tsortEachNode(function(node) {
      if (idMap.hasKey(node)) return;
      this.eachStronglyConnectedComponentFrom(node, idMap, stack, function(child) {
        block.call(context, child);
      });
    }, this);
  },

  eachStronglyConnectedComponentFrom: function(node, idMap, stack, block, context) {
    var nodeId      = idMap.size,
        stackLength = stack.length,
        minimumId   = nodeId,
        component, i;

    idMap.store(node, nodeId);
    stack.push(node);

    this.tsortEachChild(node, function(child) {
      if (idMap.hasKey(child)) {
        var childId = idMap.get(child);
        if (child !== undefined && childId < minimumId) minimumId = childId;
      } else {
        var subMinimumId = this.eachStronglyConnectedComponentFrom(child, idMap, stack, block, context);
        if (subMinimumId < minimumId) minimumId = subMinimumId;
      }
    }, this);

    if (nodeId === minimumId) {
      component = stack.splice(stackLength, stack.length - stackLength);
      i = component.length;
      while (i--) idMap.store(component[i], undefined);
      block.call(context, component);
    }

    return minimumId;
  },

  tsortEachNode: function() {
    throw new JS.NotImplementedError('tsortEachNode');
  },

  tsortEachChild: function() {
    throw new JS.NotImplementedError('tsortEachChild');
  }
});

exports.TSort = TSort;
});