import { Injectable } from '@angular/core';
import { PreloadingStrategy, Route } from '@angular/router';
import { EMPTY, Observable } from 'rxjs';
import { mergeMap } from 'rxjs/operators';

import { PreloadOnDemandService, PreloadOnDemandOptions } from './preload-ondemand.service';

@Injectable({ providedIn: 'root', deps: [PreloadOnDemandService] })
export class PreloadModuleService implements PreloadingStrategy {
  private preloadOnDemand$: Observable<PreloadOnDemandOptions>;

  constructor(private preloadOnDemandService: PreloadOnDemandService) {
    this.preloadOnDemand$ = this.preloadOnDemandService.state;
  }

  preload(route: Route, load: () => Observable<any>): Observable<any> {
    return this.preloadOnDemand$.pipe(
      mergeMap((preloadOptions) => {
        const shouldPreload = this.preloadCheck(route, preloadOptions);
        return shouldPreload ? load() : EMPTY;
      }),
    );
  }

  private preloadCheck(route: Route, preloadOptions: PreloadOnDemandOptions): boolean {
    return !!route.data && route.data.preloadId === preloadOptions.preloadId && !!preloadOptions.preload;
  }
}
