# reddit-media-downloader

> Bash script to download media content from subreddits with search enabled



## Dependencies

* `bash`
* `wget`
* `jq`
* `sed` 
* `grep`


## Usage

```
bash rmd.sh -r ~/Pictures/rmd/ -l 47 -x 1 -m igv -a top -t all -s "wallpaper" -f "india"
```


## Options

| Arg 	| Desc 			| Example   	|
|-----	|:----			|-----------	|
| `s`  	| subreddit  	| wallpaper 	|
| `f`   | search_text   | india        	|
| `r`   | directory		| ~/Pictures/rmd |
| `l`   | download limit     	| 47          	|
| `a`   | sort     		| (top , hot , new, rising) |
| `t`   | top_time     	| (all, year, month, week, day) |
| `m`   | image, gif, video    | igv          	|
| `x`   | nsfw content     	| (1 , 0)          	|

All comments are optional. Running without sub would get posts from all.
> Audio doesn't work for videos based on how reddit streams video. Yet to figure out this.

## Mention

This script is based on [Simple Subreddit Image Downloader](https://github.com/ostrolucky/Simple-Subreddit-Image-Downloader). Check to see if it fits your usecase. I just kept adding what I needed and ended up with this.
