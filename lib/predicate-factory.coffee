class PredicateFactory

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
      vp = (str)->str is attrvalue
    else if attrvalue?.test?
      vp = (str)->attrvalue.test(str)

    return (node)->
      for name,value of node?.attribs
        if np(name)
          if vp is null
            return true
          else
            if valuedelim?
              if value?
                for token in value.split(valuedelim)
                  if vp(token)
                    return true
            else
              if vp(value)
                return true
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

exports = exports ? this
exports.PredicateFactory = PredicateFactory
