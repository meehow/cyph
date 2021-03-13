#!/usr/bin/env node

import fs from 'fs';
import glob from 'glob';
import superSphincs from 'supersphincs';

(async () => {
	const files = [
		...glob.sync('*', {nodir: true}),
		...glob.sync('!(node_modules)/**', {nodir: true})
	];

	const filesToCacheBust = files.filter(
		path => !path.endsWith('index.html') && !path.endsWith('apple-pay')
	);

	const filesToModify = files.filter(
		path => path.endsWith('.html') || path.endsWith('.js')
	);

	const fileContents = {};
	const cacheBustedFiles = {};

	for (let file of filesToModify) {
		await new Promise((resolve, reject) =>
			fs.readFile(file, (err, data) => {
				try {
					fileContents[file] = data.toString();
					resolve();
				}
				catch (_) {
					reject(err);
				}
			})
		);

		let content = fileContents[file];

		for (let subresource of filesToCacheBust) {
			if (content.indexOf(subresource) < 0) {
				continue;
			}

			cacheBustedFiles[subresource] = true;

			const hash = (await superSphincs.hash(fs.readFileSync(subresource)))
				.hex;

			content = content.replace(
				new RegExp(subresource + '(?!.map)', 'g'),
				(s, i) =>
					`${s}${
						content.slice(i - 2, i).match(/[a-zA-Z0-9_\-]/) ?
							'' :
							`?${hash}`
					}`
			);
		}

		if (content !== fileContents[file]) {
			fileContents[file] = content;
			fs.writeFileSync(file, content);
		}
	}

	process.exit();
})().catch(err => {
	console.error(err);
	process.exit(1);
});
