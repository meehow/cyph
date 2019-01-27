#!/bin/bash

path="${1}"
domain="${2}"
package="${3}"
test="${4}"

project="${domain//./-}"

mkdir "${domain}"
cp $(cd "$(dirname "$0")" ; pwd)/../../websign/redirect.py "${domain}/"

cat > "${domain}/${project}.yaml" << EOM
service: ${project}
runtime: python27
api_version: 1
threadsafe: true

handlers:

- url: /
  static_files: index.html
  upload: index.html
  secure: always
  # default_headers Strict-Transport-Security

- url: /appcache.appcache
  static_files: appcache.appcache
  upload: appcache.appcache
  secure: always
  # default_headers Strict-Transport-Security

- url: /serviceworker.js
  static_files: serviceworker.js
  upload: serviceworker.js
  secure: always
  # default_headers Strict-Transport-Security

- url: /.*
  script: redirect.app
  secure: always
EOM

cat > "${domain}/index.html" <<- EOM
	<!DOCTYPE html>
	<html manifest='/appcache.appcache'>
		<head>
			<meta charset='utf-8' />
		</head>
		<body>
			<script>
				function redirect () {
					var storage	= {};
					try {
						localStorage.isPersistent	= 'true';
						storage						= localStorage;
					}
					catch (_) {}

					var isHiddenService	= location.host.split('.').slice(-1)[0] === 'onion';

					$(if [ ! "${test}" ] ; then echo "
						if (location.host.indexOf('www.') === 0) {
							location.host	= location.host.replace('www.', '');
						}
						else if (
							!isHiddenService &&
							storage.isPersistent &&
							!storage.webSignWWWPinned
						) {
							storage.webSignWWWPinned	= true;
							location.host				= 'www.' + location.host;
						}
					" ; fi)

					var path	= (
						'/#' +
						'$(if [ "${path}" ] ; then echo "${path}/" ; fi)' +
						location.toString().
							split(location.host)[1].
							replace('#', '').
							replace(/^\\//, '')
					).replace(/\\/\$/, '');

					var host	= '${package}';

					if (isHiddenService) {
						host	=
							(
								host === 'cyph.app' ?
									'app' :
									host.replace(/\\.(app|ws)\$/, '').replace(/\\./g, '_')
							) +
							'.cyphdbyhiddenbhs.onion'
						;
					}

					location	= 'https://' + host + (path === '/#' ? '' : path);
				}

				try {
					Promise.resolve().
						then(function () {
							return navigator.serviceWorker.register('/serviceworker.js');
						}).
						catch(function () {}).
						then(function () {
							return navigator.storage.persist();
						}).
						catch(function () {}).
						then(redirect)
					;
				}
				catch (_) {
					redirect();
				}
			</script>
		</body>
	</html>
EOM

cat > "${domain}/appcache.appcache" <<- EOM
	CACHE MANIFEST

	CACHE:
	/
	/appcache.appcache
	/serviceworker.js

	NETWORK:
	*
EOM

cat > "${domain}/serviceworker.js" <<- EOM
	var files	= [
		'/',
		'/appcache.appcache',
		'/serviceworker.js'
	].map(function (file) {
		return new Request(file);
	});

	var root	= files[0].url.replace(/(.*)\\/\$/, '\$1');

	self.addEventListener('install', function () {
		Promise.all([
			caches.open('cache'),
			Promise.all(files.map(function (file) {
				return fetch(file, {credentials: 'include'});
			}))
		]).then(function (results) {
			var cache		= results[0];
			var responses	= results[1];

			for (var i = 0 ; i < responses.length ; ++i) {
				cache.put(files[i], responses[i]);
			}
		});
	});

	self.addEventListener('fetch', function (e) {
		/* Let requests to other origins pass through */
		if (e.request.url.indexOf(root) !== 0) {
			return;
		}

		return e.respondWith(
			caches.match(e.request).then(function (cachedResponse) {
				if (cachedResponse) {
					return cachedResponse;
				}

				return Promise.all([
					caches.open('cache'),
					fetch(e.request.clone())
				]).then(function (results) {
					var cache		= results[0];
					var response	= results[1];

					cache.put(e.request, response.clone());

					return response;
				});
			})
		);
	});
EOM

html-minifier --minify-js true "${domain}/index.html" -o "${domain}/index.html"
