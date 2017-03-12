//: [Previous](@previous)

/*:
 
 # Tracery Grammar
 
 This section attempts to describe the grammar specification for Tracery.
 

```
 rule_candidate -> ( plain_text | rule | tag )*
 
 
 tag -> [ tag_name : tag_value ]
 
    tag_name -> plain_text
 
    tag_value -> tag_value_candidate (,tag_value_candidate)*
 
        tag_value_candidate -> rule | plain_text
 
 
 rule -> # (tag)* | rule_name(.modifier|.call|.method)* #
 
    rule_name -> plain_text
 
    modifier -> plain_text
 
    call -> plain_text
 
    method -> method_name ( param (,param)* )
 
        method_name -> plain_text
 
        param -> plain_text | rule
 
 
```
 
 # Conclusion
 
 Tracery in Swift was developed by [Benzi](https://twitter.com/benziahamed).
 
 Original library in Javascript is available at [Tracery.io](http://www.tracery.io/).
 
 
 */
