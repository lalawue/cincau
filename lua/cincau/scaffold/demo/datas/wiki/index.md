
# About

this is a Single Page Application demo for [Cincau](https://github.com/lalawue/cincau) with feature:

- rich markdown editor
- support unlimited dir level

## Create Dir

these links can create dir, try edit this page to see source.

[dir1/index](wiki/dir1/index)

[dir1/dir2/index](wiki/dir1/dir2/index)

## Technical Details

`app/pages/page_wiki.lua` provide a HTML page container, and `datas/js/wiki_cnt.js` request markdown text from `app/pages/page_wikidata.lua`.

- using markdown editor [SimpleMDE Markdown Editor](https://simplemde.com/)
- using client-side JavaScript framework [Mithril](https://mithril.js.org/)
- using some layout CSS from [Basscss](https://basscss.com/)
