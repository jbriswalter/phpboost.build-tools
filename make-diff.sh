#!/bin/bash

scriptDir=$(pwd)
repository='phpboost'
oldTag=$1
newTag=$2
diffFile=diff-$oldTag-to-$newTag.zip
diffFileOptimized=diff-$oldTag-to-$newTag-optimized.zip
destination='export/diff'
tmpDir='/tmp/phpboost-diff'
versionControlUtil='git'

if [ -n $3 ] ;
then Branch=$3;
else Branch='5.0';
fi

mkdir -p $destination
rm -rf $tmpDir && mkdir $tmpDir

echo 'building incremental zip files'

# computing modified files
cd $repository
raw_diff_output=$($versionControlUtil diff --stat  --stat-name-width=200 --stat-width=200 ${oldTag} ${newTag})
lines_count=$(echo -e "$raw_diff_output" | wc -l)
changed_files=$(echo -e "$raw_diff_output" | head -n $((lines_count - 1)))
changed_files=$(echo -e "$changed_files" | sed -e "s#\s*|.*\$##")
echo -e "
Modified files list :
$changed_files
"

$versionControlUtil checkout tags/$newTag 1>/dev/null

echo "building non-optimized patch to $tmpDir/$diffFile"
for file in `echo $changed_files`
do
	if [ -f $file ]; then
		if [[ ! $file =~ ^(install|update|UrlUpdater|templates/phpboost|.gitignore|.git|.settings|.project|test|HomePage|PHPBoostOfficial|repository|server_migration.php|todo.txt|changelog.txt|README.md)/.+ ]]; then
			zip $tmpDir/$diffFile $file 1>/dev/null
		fi
	fi
done

echo "copying non-optimized patch from  $tmpDir/$diffFile to $scriptDir/$destination/$diffFile"
cp $tmpDir/$diffFile $scriptDir/$destination/$diffFile

echo "optimizing kernel patch"
cd $tmpDir && unzip $diffFile 1>/dev/null && rm -f $diffFile && mkdir kernel-optimized

java -jar $scriptDir/bin/poptimizer.jar -e lib/ lib/php/geshi/ lib/php/mathpublisher/ framework/util/Url.class.php framework/io/Upload.class.php --ics=iso-8859-1 --ocs=iso-8859-1 -i kernel -o kernel-optimized 1>/dev/null
rm -rf kernel && mv kernel-optimized kernel

rm -f .gitignore

build_version=$(echo $newTag | cut -d '.' -f 3)
if [ "$(echo $build_version | grep "^[ [:digit:] ]*$")" ]
then
	echo $build_version > kernel/.build
fi

# echo 'minifying js files'
curl -X POST -s --data-urlencode 'input@pages/templates/js/pages.js' https://javascript-minifier.com/raw > pages/templates/js/pages.js 1>&2>/dev/null
curl -X POST -s --data-urlencode 'input@wiki/templates/js/wiki.js' https://javascript-minifier.com/raw > wiki/templates/js/wiki.js 1>&2>/dev/null
curl -X POST -s --data-urlencode 'input@BBCode/templates/js/bbcode.js' https://javascript-minifier.com/raw > BBCode/templates/js/bbcode.js 1>&2>/dev/null
curl -X POST -s --data-urlencode 'input@kernel/lib/js/global.js' https://javascript-minifier.com/raw > kernel/lib/js/global.js 1>&2>/dev/null
curl -X POST -s --data-urlencode 'input@kernel/lib/js/jquery/jquery.js' https://javascript-minifier.com/raw > kernel/lib/js/jquery/jquery.js 1>&2>/dev/null
curl -X POST -s --data-urlencode 'input@kernel/lib/js/lightcase/lightcase.js' https://javascript-minifier.com/raw > kernel/lib/js/lightcase/lightcase.js 1>&2>/dev/null
curl -X POST -s --data-urlencode 'input@kernel/lib/js/phpboost/notation.js' https://javascript-minifier.com/raw > kernel/lib/js/phpboost/notation.js 1>&2>/dev/null
curl -X POST -s --data-urlencode 'input@kernel/lib/js/phpboost/form/validator.js' https://javascript-minifier.com/raw > kernel/lib/js/phpboost/form/validator.js 1>&2>/dev/null
curl -X POST -s --data-urlencode 'input@kernel/lib/js/phpboost/form/form.js' https://javascript-minifier.com/raw > kernel/lib/js/phpboost/form/form.js 1>&2>/dev/null
curl -X POST -s --data-urlencode 'input@kernel/lib/js/phpboost/UrlSerializedParameterEncoder.js' https://javascript-minifier.com/raw > kernel/lib/js/phpboost/UrlSerializedParameterEncoder.js 1>&2>/dev/null
curl -X POST -s --data-urlencode 'input@kernel/lib/js/phpboost/upload.js' https://javascript-minifier.com/raw > kernel/lib/js/phpboost/upload.js 1>&2>/dev/null
curl -X POST -s --data-urlencode 'input@kernel/lib/flash/flowplayer/flowplayer.js' https://javascript-minifier.com/raw > kernel/lib/flash/flowplayer/flowplayer.js 1>&2>/dev/null
curl -X POST -s --data-urlencode 'input@GoogleMaps/templates/js/jquery.geocomplete.js' https://javascript-minifier.com/raw > GoogleMaps/templates/js/jquery.geocomplete.js 1>&2>/dev/null
curl -X POST -s --data-urlencode 'input@user/templates/js/cookiebar.js' https://javascript-minifier.com/raw > user/templates/js/cookiebar.js 1>&2>/dev/null

echo "building optimized patch to $scriptDir/$destination/$diffFileOptimized"
rm -f $scriptDir/$destination/$diffFileOptimized
zip -r $scriptDir/$destination/$diffFileOptimized * 1>/dev/null

rm -rf $scriptDir/builds/phpboost-diff
cp -r $tmpDir $scriptDir/builds
rm -rf $tmpDir

cd $scriptDir/$repository
$versionControlUtil checkout $Branch 1>/dev/null

echo 'incremental version build success'
echo -e '';

exit 0
