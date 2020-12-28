# reddit-media-downloader

> Bash script to download media content from subreddits with search enabled ( images, gifs, videos ).



## Dependencies

* `bash`
* `wget`
* `jq`
* `sed` 
* `grep`

* `youtube-dl` - optional to fetch video files with audio.

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
| `m`   | image, gif, video    | igvy          	|
| `x`   | nsfw content     	| (1 , 0)          	|

All comments are optional. Running without sub would get all media posts from frontpage.


## Note

Audio doesn't work on `v` option because of how reddit serves video files. Current work-around is to use `youtube-dl` to fetch videos from linked URL. For this, make sure Youtube-dl is installed and use `-m vy` as argument. 

> Beware though using `yt-dl` is considerably slower than downloading directly from Reddit. Would suggest only if videos with audio is present and necessary.


Youtube-dl might produce a lot of `ERROR` while running. This is when the liked URL is not available anymore. This occurs mostly in cases where NSFW content on gfycat was migrated to Redgifs. Y-dl doesn't seem to follow the redirect. The script will retry with appropriate Redgifs URL in such cases.


## TODO

* Handle crossposts - The data is nested and contain both image and video. Need to move most of the code to handle them better.

* Option to fetch posts categorised as `link`. So far I haven't seen many of link type but the ones I have come across vary widely on how media is liked and also contain both images and videos in them without specifing which.

* Identify if videos have audio; to decide to use YDL only if necessary.

* Godmode.


## Mention

This script is based on [Simple Subreddit Image Downloader](https://github.com/ostrolucky/Simple-Subreddit-Image-Downloader). Check to see if it fits your usecase. I just kept adding what I needed and ended up with this big bloated script.
