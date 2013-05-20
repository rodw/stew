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
    parent = null
    path = []
    siblings = nodes
    for node, sib_index in nodes
      DOMUtil._unguarded_walk_dom(node,parent,path,siblings,sib_index,callbacks)

  @_unguarded_walk_dom:(node,parent,path,siblings,sib_index,callbacks)->
    # return if (callbacks.before_visit?(dom,parent,path,siblings,sib_index) is false)
    visit_children = callbacks.visit?(node,parent,path,siblings,sib_index)
    if visit_children and node.children?
      path.push(node)
      for child,index in node.children
        DOMUtil._unguarded_walk_dom(child,node,path,node.children,index,callbacks)
      path.pop()
    # return if (callbacks.after_visit?(dom,parent,path,siblings,sib_index) is false)

exports = exports ? this
exports.DOMUtil = DOMUtil
