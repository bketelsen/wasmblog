title = "Welcome!"
description = "The Micro-CMS for Wagi"
date = "2021-12-23T17:05:19Z"
template = "index"

[extra]

author = "Matt Butcher"
author_page = "/author/butcher"

---
these are  [rhai scripts](https://github.com/rhaiscript/rhai) producing alerts:

{{ alert "check" "Check" }}
{{ alert "warning" "Warning" }}
{{ alert "circle_info" "Circle Info" }}
{{ alert "comment" "Comment" }}

the contents of the script:

```
let icon = params[0];
let msg = params[1];

let icons = #{
  warning:`<svg... svg elided ...`,
  check:`...`,
  circle_info: `...`,
  comment: `...`,
};


`<div class="flex px-4 py-3 rounded-md bg-primary-100 dark:bg-primary-900">
  <span class="ltr:pr-3 rtl:pl-3 text-primary-400">
  <span class="relative inline-block align-text-bottom icon">`
  + icons[icon] +
  `</span>
  </span>
  <span class="dark:text-neutral-300">` + msg +
 ` </span>
</div>`

```
and the invocation in markdown:
```
{ { alert "check" "Brian" } }


```
I added spaces between the braces so it doesn't get rendered by the script engine. Seems like that might be something we'd want to check for in the render function.

## On with the show

