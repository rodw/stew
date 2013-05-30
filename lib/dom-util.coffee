class DOMUtil

  # returns `nodeset[0]` if *nodeset* is an array, `nodeset` otherwise.
  @as_node: (nodeset)->
    if Array.isArray(nodeset)
      return nodeset[0]
    else
      return nodeset

  # returns `node` if *node* is an array, `[ node ]` otherwise.
  @as_nodeset: (node)->
    if Array.isArray(node)
      return node
    else if node?
      return [node]
    else
      return []

  @walk_dom:(dom,callbacks)->
    if typeof callbacks is 'function'
      callbacks = { visit:callbacks }
    nodes = DOMUtil.as_nodeset(dom)
    dom_metadata = []
    for node, sib_index in nodes
      node_metadata = { parent:null, path:[], siblings:nodes, sib_index: sib_index }
      node._node_id = dom_metadata.length
      dom_metadata.push node_metadata
      DOMUtil._unguarded_walk_dom(node,node_metadata,dom_metadata,callbacks)

  # node_metadata := { parent:, path:, siblings:, sib_index: }
  # dom_metadata := [ <node_metadata> ], indexed by node._node_id
  @_unguarded_walk_dom:(node,node_metadata,dom_metadata,callbacks)->
    visit_children = callbacks.visit?(node,node_metadata,dom_metadata)
    if visit_children and node.children?
      new_path = [].concat(node_metadata.path)
      new_path.push(node)
      for child,index in node.children
        new_node_metadata = { parent:node, path:new_path, siblings:node.children, sib_index: index }
        child._node_id = dom_metadata.length
        dom_metadata.push new_node_metadata
        DOMUtil._unguarded_walk_dom(child,new_node_metadata,dom_metadata,callbacks)

exports = exports ? this
exports.DOMUtil = DOMUtil
