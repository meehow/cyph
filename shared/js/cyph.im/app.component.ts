import {Component} from '@angular/core';
import {fadeIn} from '../cyph/animations';
import {EnvService} from '../cyph/services/env.service';
import {StringsService} from '../cyph/services/strings.service';
import {AppService} from './app.service';


/**
 * Angular component for Cyph UI.
 */
@Component({
	animations: [fadeIn],
	selector: 'cyph-app',
	templateUrl: '../../templates/cyph.im/index.html'
})
export class AppComponent {
	constructor (
		/** @see AppService */
		public readonly appService: AppService,

		/** @see EnvService */
		public readonly envService: EnvService,

		/** @see StringsService */
		public readonly stringsService: StringsService
	) {}
}
