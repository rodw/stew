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

  @to_text:(elt,filter)->
    filter ?= ()->true
    buffer = ''
    DOMUtil.walk_dom elt, visit:(node,node_metadata,all_metadata)=>
      if(filter(node,node_metadata,all_metadata))
        buffer += node.raw if node?.type is 'text' and node?.raw?
        return {'continue':true,'visit-children':true}
      else
        return {'continue':true,'visit-children':false}
    return buffer

  # ***walk_dom*** performs a depth-first walk of the given DOM tree (or trees),
  # invoking the specified "visit" function for each node.
  #
  # `dom` is either a single DOM node or an array of DOM nodes.
  #
  # `callbacks` is a map that contains (at minimum) an attribute named `visit`
  # that is a function with the signature:
  #
  #   visit(node,node_metadata,all_metadata)
  #
  # where:
  #
  #  - `node` is the DOM node currently being visited,
  #  - `node_metadata` is a map containing `parent`, `path`, `siblings` and `sib_index` keys, and
  #  - `all_metadata` is an array of `node_metadata` values for all previously
  #    visited nodes, indexed by `node._stew_node_id`.
  #
  # The `visit` function should return a map containing
  # `continue` and `visit-children` attributes.
  #
  # When `visit-children` is `true`, the children of
  # `node` (if any) will be visited next.
  #
  # When `visit-children` is `false`, the childen of `node` (if any)
  # will be skipped, but processing will continue with `node`'s siblings
  # (or `node`'s parent's, siblings, etc.)
  #
  # When `continue` is `false`, all subsequent processing
  # will be aborted and the `walk_dom` method will exit as
  # soon as possible.
  #
  # If `callbacks` is a function, then that function
  # will be treated as the `visit` function. (I.e., if `callbacks` is
  # a function, then it is treated as the map `{ 'visit':callbacks }`.
  #
  # If the value returned by `visit` is a boolean, that
  # value will be assumed for the values of `continue` and
  # `visit-children`. (I.e, `true` is treated as
  # `{ 'continue':true, 'visit-children':true }`
  # and `false` is treated as
  # `{ 'continue':false, 'visit-children':false }`.)
  @walk_dom:(dom,callbacks)->
    if typeof callbacks is 'function'
      callbacks = { visit:callbacks }
    nodes = DOMUtil.as_nodeset(dom)
    dom_metadata = []
    for node, sib_index in nodes
      node_metadata = { parent:null, path:[], siblings:nodes, sib_index: sib_index }
      node._stew_node_id = dom_metadata.length
      dom_metadata.push node_metadata
      should_continue = DOMUtil._unguarded_walk_dom(node,node_metadata,dom_metadata,callbacks)
      if not should_continue
        break

  # node_metadata := { parent:, path:, siblings:, sib_index: }
  # dom_metadata := [ <node_metadata> ], indexed by node._stew_node_id
  # returns `false` if processing if further processing should be aborted, `true` otherwise
  @_unguarded_walk_dom:(node,node_metadata,dom_metadata,callbacks)->
    response = callbacks.visit?(node,node_metadata,dom_metadata)
    if response is true
      response = { 'continue':true, 'visit-children':true }
    else if response is false
      response = { 'continue':false, 'visit-children':false }

    if response['continue'] or (not response['continue']?)
      if response['visit-children'] and node.children?
        new_path = [].concat(node_metadata.path)
        new_path.push(node)
        for child,index in node.children
          new_node_metadata = { parent:node, path:new_path, siblings:node.children, sib_index: index }
          child._stew_node_id = dom_metadata.length
          dom_metadata.push new_node_metadata
          should_continue = DOMUtil._unguarded_walk_dom(child,new_node_metadata,dom_metadata,callbacks)
          if not should_continue
            return false
      return true
    else
      return false


exports = exports ? this
exports.DOMUtil = DOMUtil
