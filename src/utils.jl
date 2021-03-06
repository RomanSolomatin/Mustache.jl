
## regular expressions to use
whiteRe = r"\s*"
spaceRe = r"\s+"
nonSpaceRe = r"\S"
eqRe = r"\s*="
curlyRe = r"\s*\}"

# # section
# ^ inversion
# / close section
# > partials
# { dont' escape
# & unescape a variable
# = set delimiters {{=<% %>=}} will set delimiters to <% %>
# ! comments
# | lamda "section" with *evaluated* value
tagRe = r"^[#^/<>{&=!|]"

function asRegex(txt)
    for i in ("[","]")
        txt = replace(txt, Regex("\\$i") => "\\$i")
    end
    for i in ("(", ")", "{","}", "|")
        txt = replace(txt, Regex("[$i]") => "[$i]")
    end
    Regex(txt)
end


isWhitespace(x) = occursin(whiteRe, x)
function stripWhitespace(x)
    y = replace(x, r"^\s+" => "")
    replace(y, r"\s+$" => "")
end


## this is for falsy value
## Falsy is true if x is false, 0 length, "", ...
falsy(x::Bool) = !x
falsy(x::Array) = isempty(x)
falsy(x::AbstractString) = x == ""
falsy(x::Nothing) = true
falsy(x::Missing) = true
falsy(x::Real) = x == 0
falsy(x) = (x == nothing) || false                #  default

## escape_html with entities

entityMap = [("&", "&amp;"),
             ("<", "&lt;"),
             (">", "&gt;"),
             ("'", "&#39;"),
             ("\"", "&quot;"),
             ("/", "&#x2F;")]

function escape_html(x)
    y = string(x)
    for (k,v) in entityMap
        y = replace(y, k => v)
    end
    y
end

## Make these work
function escapeRe(string)
    replace(string, r"[\-\[\]{}()*+?.,\\\^$|#\s]" => "\\\$&");
end

function escapeTags(tags)
   [Regex(escapeRe(tags[1]) * "\\s*"),
    Regex("\\s*" * escapeRe(tags[2]))]
end


## hueristic to avoid loading DataFrames
is_dataframe(x) = !isa(x, Dict) && !isa(x, Module) &&!isa(x, Array) && occursin(r"DataFrame", string(typeof(x)))
