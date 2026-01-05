; extends

; SQL injection for raw string literals containing SQL keywords
((raw_string_literal
  (raw_string_literal_content) @injection.content)
 (#match? @injection.content "\\c(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER|FROM|WHERE|JOIN)")
 (#set! injection.language "sql"))

; SQL injection for interpreted string literals containing SQL keywords
((interpreted_string_literal
  (interpreted_string_literal_content) @injection.content)
 (#match? @injection.content "\\c(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER|FROM|WHERE|JOIN)")
 (#set! injection.language "sql"))
