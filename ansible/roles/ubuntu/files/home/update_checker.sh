# sample:
# '{ "cmd": "fzf --version", "regex": "^[0-9.]+", "repo": "junegunn/fzf", "arch2name": { "armv7l": "linux_armv7.tar.gz", "aarch64": "linux_arm64.tar.gz", "x86_64": "linux_arm64.tar.gz" } }'

version_gt() { test "$(printf '%s\n' \"$@\" | sort -V | head -n 1)" != "$1"; }

getLatestBinaryUrl() {
    jsondata="$1"
    echo "$jsondata"
    arch=$(arch)
    filename=$(echo "$jsondata" | jq -r ".arch2name | to_entries[] | select(.key | test(\"$arch\")) | .value")
    cmd=$(echo "$jsondata" | jq -r ".cmd")
    regex=$(echo "$jsondata" | jq -r ".regex")
    repo=$(echo "$jsondata" | jq -r ".repo")

    currentversion=$(exec $cmd | grep -oP "$regex")
    releases=$(curl -s https://api.github.com/repos/$repo/releases/latest)
    newversion=$(echo $releases | jq -r ".tag_name" | sed -re "s/^v//")
    echo "current: $currentversion; new: $newversion"

    if version_gt "$newversion" "$currentversion"; then
        echo $(echo $releases | jq -r ".assets[] | select(.browser_download_url | test(\"$filename\") ) | .browser_download_url")
        return 0
    else
        echo "no new version"
        return 1
    fi
}

if [ -z "$1" ]; then
    echo "Error: JSON or YAML file required."
    return 1
fi

json="$(cat $1 | yq)"
shift
apps="$@"

if [ "$1" = "*" ]; then
    apps=$(echo "$json" | jq -r ".[].name" | xargs echo -n)
fi

for app in $apps; do
    echo $app
    data=$(echo $json | jq -r ".[] | select(.name == \"$app\")")
    getLatestBinaryUrl "$data"
done

return 0
