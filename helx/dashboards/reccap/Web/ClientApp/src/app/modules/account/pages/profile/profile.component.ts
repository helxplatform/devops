import { Component, OnInit } from '@angular/core';

import { OidcClientNotification, OidcSecurityService, PublicConfiguration } from 'angular-auth-oidc-client';

import { CommonDataService } from '@core/services/common-data.service';
import { MenuService } from '@core/services/menu.service';

@Component({
  selector: 'app-profile',
  templateUrl: './profile.component.html',
  styleUrls: ['./profile.component.scss'],
})
export class ProfileComponent implements OnInit {
  menu$: any;

  constructor(
    public oidcSecurityService: OidcSecurityService,
    private dataService: CommonDataService,
    private menu: MenuService,
  ) {
    console.log('ProfileComponent constructor');
  }

  ngOnInit(): void {
    // this.oidcSecurityService.isAuthenticated$.subscribe((value) => {
    //   console.log('Authentication chnaged', value);
    // });
    // this.router.events.subscribe((e) => {
    //   if (e instanceof NavigationEnd) {
    //     console.log('NavigationEnd', e);
    //   }
    // });
  }

  test(): void {
    console.log({
      token: this.oidcSecurityService.getToken(),
      id: this.oidcSecurityService.getIdToken(),
      rt: this.oidcSecurityService.getRefreshToken(),
    });
  }
}
