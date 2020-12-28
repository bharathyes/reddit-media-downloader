#!/bin/bash

useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.2704.79 Safari/537.36 Edge/18.014"
timeout=137

subreddit=""
search_text=""
search_url_prefix=""
url_prefix=""
sort_url_prefix=""
limit=400       # set to 0 for all posts
sort="hot"      # [ top , hot , new , rising ]
top_time=""     # [ all , year , month , week , day ]
root="${HOME}/Pictures/rmd/"
dir=""
media_type="igvy" # [ image, gif, video, ydl ]
over_18=0

while getopts ":s:f:r:l:a:t:m:x:" opt; do
  case $opt in
    s) subreddit=${OPTARG} ;;
    f) search_text=${OPTARG} ;;
    r) root=${OPTARG} ;;
    l) limit=${OPTARG} ;;
    a) sort=${OPTARG} ;;
    t) top_time=${OPTARG} ;;
    m) media_type=${OPTARG} ;;
    x) over_18=${OPTARG} ;;
    \?) echo "Invalid option -$OPTARG" >&2 ;;
  esac
done

if [ ! -z "${subreddit}" ]; then
    url_prefix="${url_prefix}r/${subreddit}/"
    dir=${subreddit}
    if [ -z "${search_text}" ]; then
        url_prefix="${url_prefix}${sort}/"
    fi
fi

if [ ! -z "${search_text}" ]; then
    url_prefix="${url_prefix}search/"
    sort_url_prefix="&sort=${sort}"
    dir=`echo ${search_text} | sed 's: :-:g'`
    search_text=`echo ${search_text} | sed 's: :%20:g'`
    if [ ! -z ${subreddit} ] ; then
        search_url_prefix="&restrict_sr=1&q=${search_text}"
        dir="${subreddit}_${dir}"
    else
        search_url_prefix="&restrict_sr=0&q=${search_text}"
    fi
fi

mkdir -p ${root}
cd ${root}
mkdir -p ${dir}
total_downs=0

echo "Running with values : ${subreddit} ${search_text} media=${media_type} over_18=${over_18} download_limit=${limit} ${sort} ${top_time}"

url="https://www.reddit.com/${url_prefix}.json?limit=100&show=all&raw_json=1${search_url_prefix}&type=link&include_over_18=${over_18}${sort_url_prefix}&t=${top_time}"
echo "Starting download query as ${url}"
wget -T ${timeout} -U "$useragent" --secure-protocol=PFS -q -O ${dir}.json -- ${url}


function get_files {
    a=1
    while IFS=$'\n' read -r line
    do
        # echo "ROW ${line}"
        if [ -z "${line}" ] || [[ "${line}" == *"null"* ]] || [[ "${line}" == "[]" ]]; then
            continue
        fi
        line=$(echo "${line}" | sed -e 's:[])([]::g;s: :-:g;s:%20:-:g' )
        values=($(echo "${line}" | sed -e 's:@:\n:g'))
        id="${values[0]}"
        name="${values[1]}"
        url="${values[2]}"
        if [ -z "${url}" ] || [[ "${url}" == *"null"* ]] || [[ "${url}" == "[]" ]]; then
            continue
        fi
        ext=`echo -n "${url##*.}"|cut -d '?' -f 1`
        if [ -z "${ext}" ] && echo "${media_type}" | grep -q 'v' ; then
            ext='mp4'
        fi
        gallery_index=""
        if [[ "${values[3]}" == "is_gallery" ]]; then
            gallery_index="_${a}"
        fi
        newname=`echo "${name}" | sed 's/^\(.\{137\}\).*/\1/g' | sed "s/^\///;s/\// /g"`_"${dir}"_"${id}${gallery_index}"."${ext}"
        # echo "Downloading with params: id:${id} url:${url} file:${newname}"
        wget -T "${timeout}" -U "${useragent}" --no-check-certificate -nv -nc -P down -q -O "${root}${dir}/${newname}" "${url}" &>/dev/null &
        total_downs=$(($total_downs+1))
        if [ ${limit} -ne 0 ] && [ ${total_downs} -ge ${limit} ]; then
            return 7
        fi
        a=$(($a+1))
    done < "${1}"
    return 0
}

function ydl_file {
    line="${1}"
    youtube-dl --user-agent "${useragent}" -qw --no-warnings -f best --restrict-filenames -o "${root}${dir}/%(title)s-%(resolution)s-%(id)s.%(ext)s" "${line}" # --sleep-interval 1 --max-sleep-interval 3
    status=$?
    if [[ ${status} == 0 ]]; then
        total_downs=$(($total_downs+1))
    elif `echo ${line} | grep -q "gfycat"` ; then
        line=$( echo "${line}" | sed 's:.*gfycat:https\://gifdeliverynetwork:g' )
        ydl_file ${line}
    fi
    if [ ${limit} -ne 0 ] && [ ${total_downs} -ge ${limit} ]; then
        return 7
    fi
}

while : ; do
    if echo ${media_type} | grep -q 'i'
    then
        # echo "Downloading galleries:"
        jq -r '.data.children[].data | select(has("is_gallery")) | {id, title, url: .media_metadata[].s.u} | join("@")' ${dir}.json > ${dir}_gallery.json
        sed -i 's/$/@is_gallery/' ${dir}_gallery.json
        get_files ${dir}_gallery.json
        status=$?
        rm ${dir}_gallery.json
        if [[ ${status} == 7 ]]; then
            break
        fi 
        
        # echo "Downloading images:"
        jq -r '.data.children[].data | select(has("post_hint") and (.post_hint | index("image"))) | {id, title, url: .preview.images[0].source.url} | join("@")' $dir.json > ${dir}_images.json
        get_files ${dir}_images.json
        status=$?
        rm ${dir}_images.json
        if [[ ${status} == 7 ]]; then
            break
        fi
    fi
    if echo ${media_type} | grep -q 'g'
    then
        # echo "Downloading gifs:"
        jq -r '.data.children[].data | select(has("post_hint") and (.post_hint | index("image"))) | select(.preview.images[0].variants.gif.source.url) | {id, title, url: .preview.images[0].variants.gif.source.url} | join("@")' $dir.json > ${dir}_images.json
        get_files ${dir}_images.json
        status=$?
        rm ${dir}_images.json
        if [[ ${status} == 7 ]]; then
            break
        fi
    fi
    if `echo ${media_type} | grep -q 'v'`
    then
        if [[ ! $(echo "${media_type}" | grep -q 'y') ]] && command -v youtube-dl &> /dev/null ;
        then
            jq -r '.data.children[].data | select(has("post_hint") and (.post_hint | test("video"; "ix"))) | .url' ${dir}.json > ${dir}_ytd_videos.txt
            while IFS=$'\n' read -r line
            do
                # youtube-dl --user-agent "${useragent}" -qw --no-warnings -f best --restrict-filenames -o '%(title)s-%(resolution)s-%(id)s.%(ext)s' ${line} # --sleep-interval 1 --max-sleep-interval 3
                ydl_file ${line}
                status=$?
                if [[ ${status} == 7 ]]; then
                    rm ${dir}_ytd_videos.txt
                    break 2
                fi
            done < ${dir}_ytd_videos.txt
            rm ${dir}_ytd_videos.txt
        else
            # echo "Downloading rich:videos:"
            jq -r '.data.children[].data | select(has("post_hint") and (.post_hint | index("rich:video"))) | {id, title, url: .preview.reddit_video_preview.fallback_url} | join("@")' ${dir}.json > ${dir}_rvideos.json
            get_files ${dir}_rvideos.json
            status=$?
            rm ${dir}_rvideos.json
            if [[ ${status} == 7 ]]; then
                break
            fi

            # echo "Downloading hosted:videos:"
            jq -r '.data.children[].data | select(has("post_hint") and (.post_hint | index("hosted:video"))) | {id, title, url: .secure_media.reddit_video.fallback_url} | join("@")' ${dir}.json > ${dir}_hvideos.json
            get_files ${dir}_hvideos.json
            status=$?
            rm ${dir}_hvideos.json
            if [[ ${status} == 7 ]]; then
                break
            fi
        fi
    fi
    # wait
    after=$(jq -r '.data.after//empty' ${dir}.json)
    if [ -z ${after} ]; then
        echo "Break - End of pagination"
        break
    fi
    url="https://www.reddit.com/${url_prefix}.json?limit=100&after=$after&raw_json=1${search_url_prefix}&type=link&include_over_18=$over_18${sort_url_prefix}&t=$top_time"
    echo "Paging after ${after} with ${url}"
    wget -T ${timeout} -U "$useragent" --secure-protocol=PFS -q -O ${dir}.json -- ${url}
done


rm ${dir}.json
if [ ${total_downs} -eq 0 ]; then
    rmdir ${dir}
fi

echo "Done downloading $total_downs in total !!"
