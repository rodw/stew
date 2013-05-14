class PredicateFactory

  # **make_by_attribute_predicate** creates a predicate
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
  #     make_by_attribute_predicate('class','foo',/\s+/)
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
  make_by_attribute_predicate:(attrname,attrvalue=null,valuedelim=null)->
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


    return (node,parent)->
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

  # **make_by_class_predicate** creates a predicate
  # that returns `true` if the given DOM node has
  # the specified `klass` value.
  make_by_class_predicate:(klass)=>
    return @make_by_attribute_predicate('class',klass,/\s+/)

  # **make_by_id_predicate** creates a predicate
  # that returns `true` if the given DOM node has
  # the specified `id` value.
  make_by_id_predicate:(id)=>
    return @make_by_attribute_predicate('id',id)

  # **make_by_attr_value_predicate** is equivalent to `make_by_attribute_predicate`
  make_by_attr_value_predicate:(attrname,attrvalue,valuedelim)=>
    return @make_by_attribute_predicate(attrname,attrvalue,valuedelim)

  # **make_by_attr_exists_predicate** creates a
  # predicate that returns `true` if the given DOM
  # node has an attributed with the specified `attrname`,
  # regardless of the value for the atttribute.
  make_by_attr_exists_predicate:(attrname)=>
    return @make_by_attribute_predicate(attrname,null)

  # **make_by_tag_predicate** creates a
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
  make_by_tag_predicate:(name)->
    if typeof name is 'string'
      return (node,parent)->(name is node.name)
    else
      return (node,parent)->(name.test(node.name))

class Stew
  constructor:()->
    @factory = new PredicateFactory()

  # If `str` is a string that starts and ends with `/`
  # (or an optional `g`, `m` or `i` suffix, it is
  # converted to the corresponding RegExp. Else the
  # original `str` value is returned.
  _to_string_or_regex:(str)->
    match = str.match /^\/(.*)\/([gmi]*)$/
    if match?[1]?
      return new RegExp(match[1],match[2])
    else
      return str

  parse_selectors:(selectors)->
    result = []
    if typeof selectors is 'string'
      selectors = selectors.split(/\s/)
    for selector in selectors
      result.push @_parse_selector(selector)
    return result

  _parse_selector:(selector)->
    if /^\.(.+)$/.test(selector)
      # class
      return @factory.make_by_class_predicate( @_to_string_or_regex(selector.substring(1)) )
    else  if /^\#/.test(selector)
      # id
      return @factory.make_by_id_predicate( @_to_string_or_regex(selector.substring(1)) )
    else if /^\[.*\]$/.test(selector)
      # attribute
      selector = selector.substring(1,selector.length-1)
      if selector.indexOf('=') is -1
        return @factory.make_by_attr_exists_predicate( @_to_string_or_regex(selector) )
      else
        [name,value] = selector.split('=') # TODO handle ~= case
        return @factory.make_by_attr_value_predicate( @_to_string_or_regex(name), @_to_string_or_regex(value) )
    else
      return @factory.make_by_tag_predicate( @_to_string_or_regex(selector) )


exports = exports ? this
exports.Stew = Stew
exports.PredicateFactory = PredicateFactory


######################################################################
# htmlparser = require 'htmlparser'
# Encoder    = require('node-html-encoder').Encoder

# HTMLPARSER_OPTIONS =
#   ignoreWhitespace:  false
#   caseSensitiveTags: false
#   caseSensitiveAttr: false

# class RegexSelector

#   _make_class_predicate:(selector)->
#     if typeof selector is 'string'
#      return (node,parent)->
#        return node?.attribs?.class? and selector in node.attribs.class.split(/\s/)
#     else
#       return (node,parent)->
#         if node?.attribs?.class?
#          for classname in node.attribs.class.split(/\s/)
#            if selector.test(classname)
#              return true
#         return false

#   _make_attr_value_predicate:(name,value)->
#     if typeof value is 'string'
#       return (node,parent)->(value is node?.attribs?[name])
#     else
#       return (node,parent)->(value.test(node?.attribs?[name]))

#   _make_attr_predicate:(selector)->
#     if typeof selector is 'string'
#       return (node,parent)->(node?.attribs?[selector]?)
#     else
#       return (node,parent)->
#         for name,value of node?.attribs
#           if selector.test(name)
#             return true
#         return false

#   _to_string_or_regex:(str)->
#     match = str.match /^\/(.*)\/([gmi]*)$/
#     if match?[1]?
#       return new Regex(match[1],match[2])
#     else
#       return str

#   _make_tag_predicate:(selector)->
#     if typeof selector is 'string'
#       return (node,parent)->(selector is node.name)
#     else
#       return (node,parent)->(selector.test(node.name))

#   _parse_selector:(selector)->
#     if /^\.(.+)$/.test(selector)
#       # class
#       return @_make_class_predicate( @_to_string_or_regex(selector.substring(1)) )
#     else  if /^\#/.test(selector)
#       # id
#       return @_make_attr_value_predicate( 'id', @_to_string_or_regex(selector.substring(1)) )
#     else if /^\[.*\]$/.test(selector)
#       # attribute
#       selector = selector.substring(1,selector.length-1)
#       if selector.indexOf('=') is -1
#         return @_make_attr_predicate( name, @_to_string_or_regex(selector) )
#       else
#         [name,value] = selector.split('=')
#         return @_make_attr_value_predicate( name, @_to_string_or_regex(value) )
#       return @_make_attr_value_predicate( 'id', @_to_string_or_regex(selector.substring(1)) )
#     else
#       return @_make_tag_predicate( @_to_string_or_regex(selector) )

#   # parse_selector( "#/comments/i" )
#   parse_selectors:(selectors)->
#     result = []
#     if typeof selectors is 'string'
#       selectors = selectors.split(/s/)
#     for selector in selectors
#       result.push @_parse_selector(selector)
#     return result

# res = new RegexSelector()
# process.argv.shift()
# process.argv.shift()
# console.log(process.argv)
# for s in res.parse_selectors(process.argv)
#   console.log(s)
