#!/bin/bash


eval "$(parseArgs \
	--opt version \
)"


cd $(cd "$(dirname "$0")" ; pwd)/..
dir="$PWD"


version="${_arg_version}"

test=''
if [ ! "${version}" ] || [ "${version}" == 'prod' ] ; then
	version='prod'
else
	test=true
fi


./commands/copyworkspace.sh ~/.build
cd ~/.build

find shared/js -name '*.component.html' -exec bash -c 'echo > {}' \;
echo "export const bitPayLogo = '';" > shared/js/cyph/components/checkout/bit-pay-logo.ts

./commands/buildpackage.sh \
	--branch-dir ~/.build \
	--environment "${version}" \
	--site sdk \
	$(test "${test}" && echo '--test') \
	--version "${version}" \
|| fail

rm -rf ${dir}/sdk/dist 2> /dev/null
mkdir ${dir}/sdk/dist
cp -f LICENSE ${dir}/sdk/

cat > ${dir}/sdk/index.js <<- EOM
import cyphSDK from './dist/sdk.cjs';
await cyphSDK.ready;

$(
	cat shared/js/sdk/app.module.ts |
		tr '\n' ' ' |
		perl -pe 's/.*?Object.entries\(\{(.*?)\}\).*/\1/' |
		perl -pe 's/\s+//g' |
		tr ',' '\n' |
		perl -pe 's/^(.*)$/export const \1 = cyphSDK.\1;/g'
)

export default cyphSDK;
EOM

if [ "${version}" != 'prod' ] ; then
	cp sdk/dist/main.js ${dir}/sdk/dist/sdk.cjs
	exit
fi

cat > ${dir}/sdk/index.debug.js <<- EOM
import cyphSDK from './dist/sdk.debug.cjs';
$(tail -n+2 ${dir}/sdk/index.js)
EOM

cp sdk/dist/main.js ${dir}/sdk/dist/sdk.debug.cjs

./commands/buildpackage.sh \
	--branch-dir ~/.build \
	--environment prodOptimized \
	--site sdk \
	--version prodOptimized \
|| fail

cp sdk/dist/main.js ${dir}/sdk/dist/sdk.cjs
