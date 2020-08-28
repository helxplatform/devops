import { Injectable } from '@angular/core';
import { MediaMatcher } from '@angular/cdk/layout';

import { LocalStorageService } from 'ngx-webstorage';
import * as onChange from 'on-change';

export interface IPreference {
  sideOpen: boolean;
  pageSize: number;
}

@Injectable({
  providedIn: 'root',
})
export class UserProfileService {
  preference: IPreference;
  mobileQuery: MediaQueryList;

  // private mobileQueryListener: (ev: MediaQueryListEvent) => void;
  private previousSideOpen = false;

  constructor(private storage: LocalStorageService, media: MediaMatcher) {
    this.mobileQuery = media.matchMedia('(max-width: 768px)');

    const preference = this.storage.retrieve('prefs') ?? {
      sideOpen: this.mobileQuery.matches ? false : true,
    };

    this.preference = onChange(preference, () => {
      this.storage.store('prefs', preference);
    });

    this.mobileQuery.addEventListener('change', (ev) => {
      if (ev.matches) {
        this.previousSideOpen = this.preference.sideOpen;
        this.preference.sideOpen = false;
      } else {
        this.preference.sideOpen = this.previousSideOpen;
      }
    });
  }
}
