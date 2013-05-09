class PredicateFactory
  make_by_attribute_predicate:(attrname,attrvalue=null,bytoken=false)->
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
            if bytoken
              if value?
                for token in value.split(/\s/)
                  if vp(token)
                    return true
            else
              if vp(value)
                return true
      return false


  make_by_class_predicate:(selector)=>
    return @make_by_attribute_predicate('class',selector,true)

  make_by_id_predicate:(selector)=>
    return @make_by_attribute_predicate('id',selector)

  make_by_attr_value_predicate:(attrname,attrvalue,bytoken=false)=>
    return @make_by_attribute_predicate(attrname,attrvalue,bytoken)

  make_by_attr_exists_predicate:(attrname)=>
    return @make_by_attribute_predicate(attrname,null)

  make_by_tag_predicate:(selector)->
    if typeof selector is 'string'
      return (node,parent)->(selector is node.name)
    else
      return (node,parent)->(selector.test(node.name))

class Stew
  constructor:()->
    @factory = new PredicateFactory()

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
