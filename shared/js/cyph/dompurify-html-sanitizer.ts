import * as DOMPurify from 'dompurify';
import {env} from './env';
import {openWindow} from './util/window';

/**
 * HtmlSanitizerService implementation built on DOMPurify.
 * Uses Cure53's DOMPurify href URI scheme whitelist hook, copied from
 * https://github.com/cure53/DOMPurify/blob/master/demos/hooks-scheme-whitelist.html.
 */
export class DOMPurifyHtmlSanitizer {
	/** @see HtmlSanitizerService.sanitize */
	public sanitize (html: string) : string {
		return this.domPurify.sanitize(html, {FORBID_TAGS: ['style']});
	}

	constructor (
		/** @see DOMPurify */
		private readonly domPurify: typeof DOMPurify,

		/** @see Document */
		private readonly document: Document = self.document,

		/** Allowed URI schemes */
		private readonly whitelist: string[] = [
			'http',
			'https',
			'ftp',
			'mailto'
		]
	) {
		const regex = new RegExp(`^(${this.whitelist.join('|')}):`, 'im');

		/* Add a hook to enforce URI scheme whitelist */
		this.domPurify.addHook('afterSanitizeAttributes', node => {
			/* Build an anchor to map URLs to */
			const anchor = this.document.createElement('a');

			/* Check all href attributes for validity */
			if (node.hasAttribute('href')) {
				anchor.href = node.getAttribute('href') || '';
				if (!regex.test(anchor.protocol)) {
					node.removeAttribute('href');
				}
			}

			/* Check all action attributes for validity */
			if (node.hasAttribute('action')) {
				anchor.href = node.getAttribute('action') || '';
				if (!regex.test(anchor.protocol)) {
					node.removeAttribute('action');
				}
			}

			/* Check all xlink:href attributes for validity */
			if (node.hasAttribute('xlink:href')) {
				anchor.href = node.getAttribute('xlink:href') || '';
				if (!regex.test(anchor.protocol)) {
					node.removeAttribute('xlink:href');
				}
			}

			if (node.tagName !== 'A') {
				return node;
			}

			/* Block window.opener in new window */
			(<HTMLAnchorElement> node).rel = 'noopener noreferrer';

			if (!env.isCordovaMobile) {
				return node;
			}

			node.addEventListener('click', e => {
				if (!(<HTMLAnchorElement> node).href) {
					return;
				}

				e.preventDefault();
				openWindow((<HTMLAnchorElement> node).href);
			});

			return node;
		});
	}
}
