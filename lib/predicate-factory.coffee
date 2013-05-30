class PredicateFactory

  and_predicate:(predicates)->
    return (node,node_metadata,dom_metadata)->
      for predicate in predicates
        if not predicate(node,node_metadata,dom_metadata)
          return false
      return true

  or_predicate:(predicates)->
    return (node,node_metadata,dom_metadata)->
      for predicate in predicates
        if predicate(node,node_metadata,dom_metadata)
          return true
      return false

  # **by_attribute_predicate** creates a predicate
  # that returns `true` if the given `attrname`
  # matches the given `attrvalue`.
  #
  # If `attrvalue` is null, then the predicate will
  # return true if the tested node has an attribute
  # named `attrname`.
  #
  # If `attrvalue` is a RegExp then the predicate will
  # return true if the value of the `attrname` attribute
  # *matches* the `attrvalue` *expression*.
  #
  # If `attrvalue` is a String then the predicate will
  # return true if the value of the `attrname` attribute
  # *equals* the `attrvalue` *string*.
  #
  # If `valuedelim` is non-null, the specified value will
  # be used as a delimiter by which to split the value of
  # the `attrname` attribute, and the corresponding elements
  # will be tested rather than the entire string.
  #
  # For example, the call:
  #
  #     by_attribute_predicate('class','foo',/\s+/)
  #
  # will return a function that tests if a given DOM node
  # has been assigned class `foo`.  E.g, `true` for these:
  #
  #     <span class="foo"></span>
  #
  #     <span class="bar foo"></span>
  #
  # and `false` for these:
  #
  #     <span></span>
  #
  #     <span class="food"></span>
  #
  by_attribute_predicate:(attrname,attrvalue=null,valuedelim=null)->
    if typeof(attrname) is 'string'
      np = (str)->str is attrname
    else
      np = (str)->attrname.test(str)

    if attrvalue is null
      vp = null
    else if typeof(attrvalue) is 'string'
      attrvalue = attrvalue.replace(/\\\"/g,'"')
      vp = (str)->str is attrvalue
    else if attrvalue?.test?
      vp = (str)->attrvalue.test(str)

    return (node)->
      # console.log "by_attribute_predicate",attrname,attrvalue,valuedelim,node.raw
      for name,value of node?.attribs
        if np(name)
          if vp is null
            # console.log "returning true"
            return true
          else
            if valuedelim?
              if value?
                for token in value.split(valuedelim)
                  if vp(token)
                    # console.log "returning true"
                    return true
            else
              # console.log "attrvalue",attrvalue
              # console.log "value",value
              # console.log "vp(value)",vp(value)
              if vp(value)
                # console.log "returning true"
                return true
      # console.log "returning false"
      return false

  # **by_class_predicate** creates a predicate
  # that returns `true` if the given DOM node has
  # the specified `klass` value.
  by_class_predicate:(klass)=>
    return @by_attribute_predicate('class',klass,/\s+/)

  # **by_id_predicate** creates a predicate
  # that returns `true` if the given DOM node has
  # the specified `id` value.
  by_id_predicate:(id)=>
    return @by_attribute_predicate('id',id)

  # **by_attr_value_predicate** is equivalent to `by_attribute_predicate`
  by_attr_value_predicate:(attrname,attrvalue,valuedelim)=>
    return @by_attribute_predicate(attrname,attrvalue,valuedelim)

  # **by_attr_exists_predicate** creates a
  # predicate that returns `true` if the given DOM
  # node has an attributed with the specified `attrname`,
  # regardless of the value for the atttribute.
  by_attr_exists_predicate:(attrname)=>
    return @by_attribute_predicate(attrname,null)

  # **by_tag_predicate** creates a
  # predicate that returns `true` if the given DOM
  # node is a tag with the specified `name`.
  #
  # If `name` is a RegExp then the predicate will
  # return true if tag's name *matches* the
  # specified *expression*.
  #
  # If `name` is a String then the predicate will
  # return true if the tag's name *equals* the
  # specified *string*.
  by_tag_predicate:(name)->
    if typeof name is 'string'
      return (node)->(name is node.name)
    else
      return (node)->(name.test(node.name))

  # **first_child_predicate**
  # returns a predicate that evaluates to `true`
  # iff the given `node` is the first child *tag* node
  # among all of its siblings.
  #
  # TODO FIXME should :first-child also consider elements like <script>?
  first_child_predicate:()->return @_first_child_impl
  _first_child_impl:(node,node_metadata,dom_metadata)->
    if node.type is 'tag' and node_metadata.siblings?
      index_of_first_tag = -1
      for elt, index in node_metadata.siblings
        if elt.type is 'tag'
          return node._node_id is elt._node_id
    return false

  # **any_tag_predicate**
  # returns a predicate that evaluates to `true`
  # iff the given `node` is a tag.
  any_tag_predicate:()->return @_any_tag_impl
  _any_tag_impl:(node)->(node?.type is 'tag')

  # **descendant_predicate**
  # returns a predicate that for the given array
  # of *n* predicates *P*, evaluates to `true` for
  # a given node if:
  #
  #  - *P[n-1](node)* is `true`, and
  #
  #  - *P[n-2](parent)* is `true` for some element
  #    `parent` that is an ancestor of `node`
  #
  #  - *P[n-3](parent2)* is `true` for some element
  #     `parent2` that is an ancestor of `parent`
  #
  #  - ...etc.
  #
  # In other words, the returned predicate will evalue to `true`
  # for the current node if each of the given `predicates`
  # evaluates to true for some ancestor of the node, in sequence.
  # (I.e., the node that matches `predicates[n]` must be an ancestor
  # of the node that mathces `predicates[n+1]`.)
  descendant_predicate:(predicates)->
    if predicates.length is 1
      return predicates[0]
    else
      return (node,node_metadata,dom_metadata)->
        if predicates[predicates.length-1](node,node_metadata,dom_metadata)
          cloned_path = [].concat(node_metadata.path)
          cloned_predicates = [].concat(predicates)
          cloned_predicates.pop() # drop last predicate, we just tested it
          while cloned_path.length > 0
            node = cloned_path.pop()
            node_metadata = dom_metadata[node._node_id]
            if cloned_predicates[cloned_predicates.length-1](node,node_metadata,dom_metadata)
              cloned_predicates.pop()
              if cloned_predicates.length is 0
                return true
                break
        return false

  # **direct_descendant_predicate**
  direct_descendant_predicate:(parent_selector,child_selector)->
    return (node,node_metadata,dom_metadata)->
      if child_selector(node,node_metadata,dom_metadata)
        parent = node_metadata.parent
        parent_metadata = dom_metadata[parent._node_id]
        return parent_selector(parent,parent_metadata,dom_metadata)
      return false

  adjacent_sibling_predicate:(first,second)->
    return (node,node_metadata,dom_metadata)->
      if second(node,node_metadata,dom_metadata)
        # prev_tag_node = null
        prev_tag_index = node_metadata.sib_index - 1
        while prev_tag_index > 0
          if node_metadata.siblings[prev_tag_index].type is 'tag'
            prev_tag = node_metadata.siblings[prev_tag_index]
            return first(prev_tag,dom_metadata[prev_tag._node_id],dom_metadata)
          else
            prev_tag_index -= 1
      return false

exports = exports ? this
exports.PredicateFactory = PredicateFactory
