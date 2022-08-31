#!/bin/bash

# Rename in files
echo "Replacing text"

# Renames things with SD prefix
find ./ -type f -not -path '*/\.*' \( -iname \*.swift -or -iname \*.m -or -iname \*.h -or -iname \*.podspec \) -exec sed -E -i '' 's/([^a-zA-Z]|\s+|^)SD/\1TMSD/g' {} \;

# Renames things with sd_ (there are several methods in UIImageView extensions with this prefix
find ./ -type f -not -path '*/\.*' \( -iname \*.swift -or -iname \*.m -or -iname \*.h -or -iname \*.podspec \) -exec sed -E -i '' 's/([^a-zA-Z]?)sd_/\1tmsd_/g' {} \;

# Renames extension methods which used `Sd_`
find ./ -type f -not -path '*/\.*' \( -iname \*.swift -or -iname \*.m -or -iname \*.h -or -iname \*.podspec \) -exec sed -E -i '' 's/Sd_/Tmsd_/g' {} \;

find ./ -type f -not -path '*/\.*' \( -iname \*.m -or -iname \*.h \) -exec perl -i -p -e 's/(?mi-s)(\@interface.*)\((\w+)\)/\1\(TMSD\2\)/g' {} \;
find ./ -type f -not -path '*/\.*' \( -iname \*.m -or -iname \*.h \) -exec perl -i -p -e 's/(?mi-s)(\@implementation.*)\((\w+)\)/\1\(TMSD\2\)/g' {} \;

# Modify imports to specify library
find ./ -type f -not -path '*/\.*' \( -iname \*.m -or -iname \*.h \) -exec perl -i -p -e 's/(?mi-s)(#import\s+)\"([^\/\n]+)\"/\1<TMSDWebImage\/\2>/g' {} \;

# Rename files
echo "Renaming files"
find ./ -type f -depth -not -path '*/\.*' | while read fname

do
	new_fname=`echo $fname | sed 's/\([^a-zA-Z]\)SD/\1TMSD/g'`

        if [ -e "$new_fname" ]
        then
                echo "File $new_fname already exists. Not replacing $fname"
        else
                echo "Creating new file $new_fname to replace $fname"
		directory=`dirname $new_fname`
		mkdir -p "$directory"
                mv "$fname" "$new_fname"
        fi
done
