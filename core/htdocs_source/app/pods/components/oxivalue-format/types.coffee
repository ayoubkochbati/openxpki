import moment from "moment"

types =
    certstatus: (v) -> "<span class='certstatus-#{(v.value||v.label).toLowerCase()}' title='#{v.tooltip||""}'>#{v.label}</span>"
    link: (v) -> "<a href='#/openxpki/#{v.page}' target='#{v.target||"modal"}' title='#{v.tooltip||""}'>#{v.label}</a>"
    extlink: (v) -> "<a href='#{v.page}' target='#{v.target||"_blank"}' title='#{v.tooltip||""}'>#{v.label}</a>"
    timestamp: (v) ->
        if v > 0
            moment.unix(v).utc().format("YYYY-MM-DD HH:mm:ss UTC")
        else
            "---"
    datetime: (v) -> moment().utc(v).format("YYYY-MM-DD HH:mm:ss UTC")
    text: (v) -> Em.$('<div/>').text(v).html()
    nl2br: (v) -> Em.$('<div/>').text(v).html().replace(/\n/gm,"<br>")
    code: (v) -> "<code>#{ Em.$('<div/>').text(v).html().replace(/\r/gm,"")}</code>"
    raw: (v) -> v
    defhash: (v) -> "<dl>#{(for k, w of v then "<dt>#{k}</dt><dd>#{ Em.$('<div/>').text(w).html() }</dd>").join ""}</dl>"
    deflist: (v) -> "<dl>#{(for w in v then "<dt>#{w.label}</dt><dd>#{(if w.format is "raw" then w.value else Em.$('<div/>').text(w.value).html())}</dd>").join ""}</dl>"
    ullist: (v) -> "<ul class=\"list-unstyled\">#{(for w in v then "<li>#{Em.$('<div/>').text(w).html()}</li>").join ""}</ul>"
    rawlist: (v) -> "<ul class=\"list-unstyled\">#{(for w in v then "<li>#{w}</li>").join ""}</ul>"
    linklist: (v) -> "<ul class=\"list-unstyled\">#{(for w in v then "<li><a href='#/openxpki/#{w.page}' target='#{w.target||"modal"}' title='#{w.tooltip||""}'>#{w.label}</a></li>").join ""}</ul>"
    styled: (v) -> Em.$('<span/>').text(v).html().replace(/(([a-z]+):)?(.*)/gm, '<span class=\"styled-$2\">$3</span>')
    tooltip: (v) -> "<span title='#{v.tooltip||""}'>#{v.value}</span>"
    head: (v) -> "1"

export default types
