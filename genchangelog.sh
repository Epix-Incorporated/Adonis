#!/bin/sh

# # Documentation
# ## --updatepatch or -P
# The update will be a patch version instead of a full release
# 
# ## --to-stdout or -O
# The output will be printed to stdout instead of written to the files
# 
# ## --from-stdin or -I
# Takes the input for custom notes from a stdin instead of asking the user manually for the file
# 


# Copyright (c) 2025 ccuser44, Epix-Incorporated
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

valVer=$(cat Loader/Version.model.json | grep "\"Value\"\s*\:" -E | sed -E "s/\s*\"Value\"\s*:\s*(\-?[0-9][0-9A-Fa-fXx\.]*)\s*,?\s*/\1/gi")
logVer=$(cat MainModule/Shared/Changelog.luau | head -n 20 | grep "Version\s*\:" -E | head -n 1 | sed -E "s/\s*[\"']\s*Version\s*:\s*(Patch|Hot[\-\s]?Fix)?\s*(\-?[0-9][0-9A-Fa-fXx\.]*)\s*[\"']\s*[,;]?\s*/\2/gi")
tagVer=$(git --no-pager tag --list | sed -E 's/^\s*v(ersion)?\s*//gi' | sort -r -u | head -n 1)

if [ "$(echo "$valVer" | grep "^\-?[0-9][0-9A-Fa-fXx\.]*$" -E)" = "" ] || [ "$(echo "$logVer" | grep "^\-?[0-9][0-9A-Fa-fXx\.]*$" -E)" = "" ] || [ "$(echo "$tagVer" | grep "^\-?[0-9][0-9A-Fa-fXx\.]*$" -E)" = "" ]; then
	echo $valVer
	echo $logVer
	echo $tagVer
	echo "This user is an idiot. Laugh at this user"
	sleep 2s
	start "https://www.youtube.com/embed/lpvT-Fciu-4?start=2&end=70&autoplay=1&controls=0&disablekb=1&loop=1&playlist=lpvT-Fciu-4"
	exit 1
fi

verPrefix=""
newVer=$(expr $tagVer + 1 | sed -E 's/\..+//gi')
doEcho=0
doEcho=0
fromStdin=0

for arg in "$@"; do
    if [ "$arg" = "--update-patch" ] || [ "$arg" = "-P" ]; then
		newVer=$(awk "BEGIN {print $tagVer + 0.1}")
        verPrefix="Patch "
	elif [ "$arg" = "--to-stdout" ] || [ "$arg" = "-O" ]; then
		doEcho=1
	elif [ "$arg" = "--from-stdin" ] || [ "$arg" = "-I" ]; then
		fromStdin=1
    fi
done

if [ "$doEcho" != "1" ]; then
	echo "                                  __ __  __ __ _      "
	echo "  ____________  __________  _____/ // / / // /( )_____"
	echo " / ___/ ___/ / / / ___/ _ \/ ___/ // /_/ // /_|// ___/"
	echo "/ /__/ /__/ /_/ (__  )  __/ /  /__  __/__  __/ (__  ) "
	echo "\___/\___/\__,_/____/\___/_/     /_/  __/_/   /____/  "
	echo "  / ____/ /_  ____ _____  ____ ____  / /___  ____ _   "
	echo " / /   / __ \/ __  / __ \/ __  / _ \/ / __ \/ __  /   "
	echo "/ /___/ / / / /_/ / / / / /_/ /  __/ / /_/ / /_/ /    "
	echo "\____/_/ /_/\__,_/_/ /_/\__, /\___/_/\____/\__, /     "
	echo "  ________  ____  ___  /____/___ _/ /_____/____/_     "
	echo " / ___/ _ \/ __ \/ _ \/ ___/ __  / __/ __ \/ ___/     "
	echo "/ /__/  __/ / / /  __/ /  / /_/ / /_/ /_/ / /         "
	echo "\___/\___/_/ /_/\___/_/   \__,_/\__/\____/_/          "
	echo ""
	echo "For Epix-Incorporated. Licensed under MIT"
	echo ""
fi

git --no-pager log v$tagVer..HEAD --max-count=1024 --show-pulls --format="https://github.com/Epix-Incorporated/Adonis/commit/%H (Git/%an) %s" | grep "\\(#[0-9]+\\)$" -E -v | grep "(Update|Add|Change|Bump|Publish|v\-?[0-9][0-9A-Fa-fXx\.]*[ab]?|Changelog)\s*(rojo|Adonis|model|to)?\s*(Version|Changelog|update|v\-?[0-9])" -E -i -v > Adonis_TEMP_ReleaseNotes.txt
if [ "$fromStdin" = "1" ]; then
	cat > Adonis_TEMP_ReleaseNotes.txt
elif [ "$doEcho" = "1" ]; then
	read -p ""
else
	read -p "Please write the release notes (but not pulls) to Adonis_TEMP_ReleaseNotes.txt by examining the commits. DO NOT LEAVE AN UNFORMATTED CHANGELOG! When done, press Enter to continue..."
fi
if [ "$(tail -c1 Adonis_TEMP_ReleaseNotes.txt)" != "" ]; then
	echo "Fatal error. File missing a newline!"
    exit 1
fi

echo "	\"\";" > SigmaSigmaBoy.tmp
printf "\t\"[%sv%s" "$verPrefix" "$newVer" >> SigmaSigmaBoy.tmp
date +" %Y-%m-%d %T %Z" -u | tr -d "\n" >> SigmaSigmaBoy.tmp
printf "] @" >> SigmaSigmaBoy.tmp
git config user.name | sed -e 's/([Nn]ichole|([Dd]imenp?s[yi]onal|[Pp]bst?)[Ff]usion|[Dd]imenp?s[yi]onal)/Dimenpsyonal/g' | tr -d "\n" >> SigmaSigmaBoy.tmp
echo "\";" >> SigmaSigmaBoy.tmp
cat Adonis_TEMP_ReleaseNotes.txt | dos2unix -r -q --to-stdout | tr -d "\r" | sed 's/\\/\\\\/g; s/\"/\\\"/g' | sed -E 's/^.*$/\t\"\0\",/g' >> SigmaSigmaBoy.tmp
#echo "	\"\";" >> SigmaSigmaBoy.tmp
git --no-pager log v$tagVer..HEAD --max-count=2048 --show-pulls --format="(Git/%an) %s" | grep "\\(#[0-9]+\\)$" -E | sed 's/\\/\\\\/g; s/\"/\\\"/g' | sed -E 's/^.*$/\t\"\0\";/g' >> SigmaSigmaBoy.tmp

# Put changes to changelog
if [ "$doEcho" != "1" ]; then
	sed -i -E "s/\t\"\*Report bugs\/issues on our GitHub repository\*\";/\0\n$(cat SigmaSigmaBoy.tmp | dos2unix -r -q --to-stdout | tr -d "\r" | sed -E 's/[\&\/\\]/\\\0/g;' | sed ':a;N;$!ba;s/\n/\\n/g')/gi" MainModule/Shared/Changelog.luau
	sed -i -E "s/\s*\"Value\"\s*:\s*\-?[0-9][0-9A-Fa-fXx\.]*\s*(,?)\s*/\t\t\"Value\": $newVer\1/gi" Loader/Version.model.json
	sed -i -E "s/\s*[\"']\s*Version\s*:\s*(Patch|Hot[\-\s]?Fix)?\s*(\-?[0-9][0-9A-Fa-fXx\.]*)\s*[\"']\s*([,;])?\s*/\t\"Version: $verPrefix$newVer\"\3/gi" MainModule/Shared/Changelog.luau
else
	cat SigmaSigmaBoy.tmp | dos2unix -r -q --to-stdout | tr -d "\r"
fi
rm -f Adonis_TEMP_ReleaseNotes.txt
rm -f SigmaSigmaBoy.tmp
exit 0
