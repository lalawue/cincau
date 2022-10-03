
# About

this is a Single Page Application demo for [Cincau](https://github.com/lalawue/cincau) with features:

- rich markdown editor
- unlimited dir level

## Create Dir

these links can create dir, try edit this page to see source.

[level_1/index](wiki/level_1/index)

[level_1/level_2/index](wiki/level_1/level_2/index)

you can use map button on page right top to get all your wiki markdown files, also you can chagne wiki location in sitemap page.

## Technical Details

`app/pages/page_wiki.lua` provide a HTML page container, and `datas/js/wiki_cnt.js` request markdown text from `app/pages/page_wikidata.lua`, then render with markdown engine.

- using markdown editor [SimpleMDE Markdown Editor](https://simplemde.com/)
- using client-side JavaScript framework [Mithril](https://mithril.js.org/)
- using some layout CSS from [Basscss](https://basscss.com/)
