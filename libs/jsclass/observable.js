(function(factory) {
  var E  = (typeof exports === 'object'),
      js = (typeof JS === 'undefined') ? require('./core') : JS;

  if (E) exports.JS = exports;
  factory(js, E ? exports : js);

})(function(JS, exports) {
'use strict';

var Observable = new JS.Module('Observable', {
  extend: {
    DEFAULT_METHOD: 'update'
  },

  addObserver: function(observer, context) {
    (this.__observers__ = this.__observers__ || []).push({_block: observer, _context: context});
  },

  removeObserver: function(observer, context) {
    this.__observers__ = this.__observers__ || [];
    context = context;
    var i = this.countObservers();
    while (i--) {
      if (this.__observers__[i]._block === observer && this.__observers__[i]._context === context) {
        this.__observers__.splice(i,1);
        return;
      }
    }
  },

  removeObservers: function() {
    this.__observers__ = [];
  },

  countObservers: function() {
    return (this.__observers__ = this.__observers__ || []).length;
  },

  notifyObservers: function() {
    if (!this.isChanged()) return;
    var i = this.countObservers(), observer, block, context;
    while (i--) {
      observer = this.__observers__[i];
      block    = observer._block;
      context  = observer._context;
      if (typeof block === 'function') block.apply(context, arguments);
      else block[context || Observable.DEFAULT_METHOD].apply(block, arguments);
    }
  },

  setChanged: function(state) {
    this.__changed__ = !(state === false);
  },

  isChanged: function() {
    if (this.__changed__ === undefined) this.__changed__ = true;
    return !!this.__changed__;
  }
});

Observable.alias({
  subscribe:    'addObserver',
  unsubscribe:  'removeObserver'
}, true);

exports.Observable = Observable;
});