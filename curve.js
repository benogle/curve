(function() {
  var Curve, Node, NodeEditor, Path, Point, SelectionModel, SelectionView, attrs, utils,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.Curve = window.Curve || {};

  utils = {
    getObjectFromNode: function(domNode) {
      return $.data(domNode, 'curve.object');
    },
    setObjectOnNode: function(domNode, object) {
      return $.data(domNode, 'curve.object', object);
    }
  };

  _.extend(window.Curve, utils);

  attrs = {
    fill: '#ccc'
  };

  utils = window.Curve;

  /*
    TODO
    * draw handles
    * move handles
    * move nodes
    * move entire object
    * select/deselect things
    * make new objects
  */


  Path = (function() {
    function Path() {
      this.path = null;
      this.nodes = [];
      this.isClosed = false;
      this.path = this._createRaphaelObject([]);
    }

    Path.prototype.addNode = function(node) {
      this.nodes.push(node);
      return this.render();
    };

    Path.prototype.close = function() {
      this.isClosed = true;
      return this.render();
    };

    Path.prototype.render = function(path) {
      if (path == null) {
        path = this.path;
      }
      return path.attr({
        path: this.toPathArray()
      });
    };

    Path.prototype.toPathArray = function() {
      var lastNode, lastPoint, makeCurve, node, path, _i, _len, _ref;

      path = [];
      lastPoint = null;
      makeCurve = function(fromNode, toNode) {
        var curve;

        curve = ['C'];
        curve = curve.concat(fromNode.getAbsoluteHandleOut().toArray());
        curve = curve.concat(toNode.getAbsoluteHandleIn().toArray());
        curve = curve.concat(toNode.point.toArray());
        return curve;
      };
      _ref = this.nodes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        node = _ref[_i];
        if (path.length === 0) {
          path.push(['M'].concat(node.point.toArray()));
        } else {
          path.push(makeCurve(lastNode, node));
        }
        lastNode = node;
      }
      if (this.isClosed) {
        path.push(makeCurve(this.nodes[this.nodes.length - 1], this.nodes[0]));
        path.push(['Z']);
      }
      return path;
    };

    Path.prototype._createRaphaelObject = function(pathArray) {
      var path;

      path = raphael.path(pathArray).attr(attrs);
      utils.setObjectOnNode(path.node, this);
      return path;
    };

    return Path;

  })();

  Point = (function(_super) {
    __extends(Point, _super);

    Point.create = function(x, y) {
      if (x instanceof Point) {
        return x;
      }
      return new Point(x, y);
    };

    function Point(x, y) {
      this.set(x, y);
    }

    Point.prototype.set = function(x, y) {
      var _ref;

      this.x = x;
      this.y = y;
      if (_.isArray(this.x)) {
        _ref = this.x, this.x = _ref[0], this.y = _ref[1];
      }
      return this.emit('change');
    };

    Point.prototype.add = function(other) {
      return new Point(this.x + other.x, this.y + other.y);
    };

    Point.prototype.toArray = function() {
      return [this.x, this.y];
    };

    return Point;

  })(EventEmitter);

  Curve = (function() {
    function Curve(point1, handle1, point2, handle2) {
      this.point1 = point1;
      this.handle1 = handle1;
      this.point2 = point2;
      this.handle2 = handle2;
    }

    return Curve;

  })();

  Node = (function(_super) {
    __extends(Node, _super);

    function Node(point, handleIn, handleOut) {
      this.point = Point.create(point);
      this.handleIn = Point.create(handleIn);
      this.handleOut = Point.create(handleOut);
      this.isBroken = false;
      this._curveIn = null;
      this._curveOut = null;
    }

    Node.prototype.getAbsoluteHandleIn = function() {
      return this.point.add(this.handleIn);
    };

    Node.prototype.getAbsoluteHandleOut = function() {
      return this.point.add(this.handleOut);
    };

    return Node;

  })(EventEmitter);

  SelectionModel = (function(_super) {
    __extends(SelectionModel, _super);

    function SelectionModel() {
      this.selected = null;
      this.selectedNode = null;
    }

    SelectionModel.prototype.setSelected = function(selected) {
      var old;

      if (selected === this.selected) {
        return;
      }
      old = this.selected;
      this.selected = selected;
      return this.emit('change:selected', {
        object: this.selected,
        old: old
      });
    };

    SelectionModel.prototype.setSelectedNode = function(selectedNode) {
      var old;

      if (selectedNode === this.selectedNode) {
        return;
      }
      old = this.selectedNode;
      this.selectedNode = selectedNode;
      return this.emit('change:selectedNode', {
        node: this.selectedNode,
        old: old
      });
    };

    SelectionModel.prototype.clearSelected = function() {
      return this.setSelected(null);
    };

    SelectionModel.prototype.clearSelectedNode = function() {
      return this.setSelectedNode(null);
    };

    return SelectionModel;

  })(EventEmitter);

  SelectionView = (function() {
    SelectionView.prototype.nodeSize = 5;

    function SelectionView(model) {
      this.model = model;
      this.onChangeSelectedNode = __bind(this.onChangeSelectedNode, this);
      this.onChangeSelected = __bind(this.onChangeSelected, this);
      this.path = null;
      this.nodeEditors = [];
      this.model.on('change:selected', this.onChangeSelected);
      this.model.on('change:selectedNode', this.onChangeSelectedNode);
    }

    SelectionView.prototype.onChangeSelected = function(_arg) {
      var object;

      object = _arg.object;
      return this.setSelectedObject(object);
    };

    SelectionView.prototype.onChangeSelectedNode = function(_arg) {
      var node, nodeEditor, old;

      node = _arg.node, old = _arg.old;
      nodeEditor = this._findNodeEditorForNode(old);
      if (nodeEditor) {
        nodeEditor.setEnableHandles(false);
      }
      nodeEditor = this._findNodeEditorForNode(node);
      if (nodeEditor) {
        return nodeEditor.setEnableHandles(true);
      }
    };

    SelectionView.prototype.setSelectedObject = function(object) {
      if (this.path) {
        this.path.remove();
      }
      this.path = null;
      if (object) {
        this.path = object.path.clone().toFront();
        this.path.node.setAttribute('class', 'selected-path');
        object.render(this.path);
      }
      return this._createNodeEditors(object);
    };

    SelectionView.prototype._createNodeEditors = function(object) {
      var i, nodeDiff, _i, _j, _ref, _results;

      if (object) {
        nodeDiff = object.nodes.length - this.nodeEditors.length;
        if (nodeDiff > 0) {
          for (i = _i = 0; 0 <= nodeDiff ? _i < nodeDiff : _i > nodeDiff; i = 0 <= nodeDiff ? ++_i : --_i) {
            this.nodeEditors.push(new NodeEditor(this.model));
          }
        }
      }
      _results = [];
      for (i = _j = 0, _ref = this.nodeEditors.length; 0 <= _ref ? _j < _ref : _j > _ref; i = 0 <= _ref ? ++_j : --_j) {
        _results.push(this.nodeEditors[i].setNode(object && object.nodes[i] || null));
      }
      return _results;
    };

    SelectionView.prototype._findNodeEditorForNode = function(node) {
      var nodeEditor, _i, _len, _ref;

      _ref = this.nodeEditors;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        nodeEditor = _ref[_i];
        if (nodeEditor.node === node) {
          return nodeEditor;
        }
      }
      return null;
    };

    return SelectionView;

  })();

  NodeEditor = (function() {
    var handleElements, lineElement, node, nodeElement;

    NodeEditor.prototype.nodeSize = 5;

    NodeEditor.prototype.handleSize = 3;

    node = null;

    nodeElement = null;

    handleElements = null;

    lineElement = null;

    function NodeEditor(selectionModel) {
      this.selectionModel = selectionModel;
      this.onDraggingNode = __bind(this.onDraggingNode, this);
      this._setupNodeElement();
      this._setupLineElement();
      this._setupHandleElements();
      this.hide();
    }

    NodeEditor.prototype.hide = function() {
      this.visible = false;
      this.lineElement.hide();
      this.nodeElement.hide();
      return this.handleElements.hide();
    };

    NodeEditor.prototype.show = function() {
      this.visible = true;
      this.lineElement.toFront();
      this.nodeElement.toFront().show();
      this.handleElements.toFront();
      if (this.enableHandles) {
        this.lineElement.show();
        return this.handleElements.show();
      } else {
        this.lineElement.hide();
        return this.handleElements.hide();
      }
    };

    NodeEditor.prototype.setEnableHandles = function(enableHandles) {
      this.enableHandles = enableHandles;
      if (this.visible) {
        return this.show();
      }
    };

    NodeEditor.prototype.setNode = function(node) {
      this.node = node;
      this.setEnableHandles(false);
      return this.render();
    };

    NodeEditor.prototype.render = function() {
      var handleIn, handleOut, linePath, point;

      if (!this.node) {
        return this.hide();
      }
      handleIn = this.node.getAbsoluteHandleIn();
      handleOut = this.node.getAbsoluteHandleOut();
      point = this.node.point;
      linePath = [['M', handleIn.x, handleIn.y], ['L', point.x, point.y], ['L', handleOut.x, handleOut.y]];
      this.lineElement.attr({
        path: linePath
      });
      this.handleElements[0].attr({
        cx: handleIn.x,
        cy: handleIn.y
      });
      this.handleElements[1].attr({
        cx: handleOut.x,
        cy: handleOut.y
      });
      this.nodeElement.attr({
        cx: point.x,
        cy: point.y
      });
      return this.show();
    };

    NodeEditor.prototype.onDraggingNode = function(dx, dy, x, y, event) {
      return console.log('dragging', arguments);
    };

    NodeEditor.prototype._setupNodeElement = function() {
      var _this = this;

      this.nodeElement = raphael.circle(0, 0, this.nodeSize);
      this.nodeElement.node.setAttribute('class', 'node-editor-node');
      this.nodeElement.click(function() {
        return _this.selectionModel.setSelectedNode(_this.node);
      });
      return this.nodeElement.drag(this.onDraggingNode, function() {
        return _this.selectionModel.setSelectedNode(_this.node);
      });
    };

    NodeEditor.prototype._setupLineElement = function() {
      this.lineElement = raphael.path([]);
      return this.lineElement.node.setAttribute('class', 'node-editor-lines');
    };

    NodeEditor.prototype._setupHandleElements = function() {
      this.handleElements = raphael.set();
      this.handleElements.push(raphael.circle(0, 0, this.handleSize), raphael.circle(0, 0, this.handleSize));
      this.handleElements[0].node.setAttribute('class', 'node-editor-handle');
      return this.handleElements[1].node.setAttribute('class', 'node-editor-handle');
    };

    return NodeEditor;

  })();

  _.extend(window.Curve, {
    Path: Path,
    Curve: Curve,
    Point: Point,
    Node: Node,
    SelectionModel: SelectionModel,
    SelectionView: SelectionView
  });

  window.main = function() {
    var r;

    this.raphael = r = Raphael("canvas");
    this.path = new Path(r);
    this.path.addNode(new Node([50, 50], [-10, 0], [10, 0]));
    this.path.addNode(new Node([80, 60], [-10, -5], [10, 5]));
    this.path.addNode(new Node([60, 80], [10, 0], [-10, 0]));
    this.path.close();
    this.selectionModel = new SelectionModel();
    this.selectionView = new SelectionView(selectionModel);
    this.selectionModel.setSelected(this.path);
    return this.selectionModel.setSelectedNode(this.path.nodes[2]);
  };

}).call(this);
