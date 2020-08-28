import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { MediaMatcher } from '@angular/cdk/layout';

import { MenuService } from '@app/core/services/menu.service';
import { PreloadOnDemandService } from '@core/services/preload-ondemand.service';
import { trigger, state, style, transition, animate } from '@angular/animations';
import { Router } from '@angular/router';

@Component({
  selector: 'app-sidebar',
  templateUrl: './sidebar.component.html',
  styleUrls: ['./sidebar.component.scss'],
  animations: [
    trigger('slideInOut', [
      state('true', style({ height: '*' })),
      state('false', style({ height: '0' })),
      transition('true => false', animate('500ms ease-in')),
      transition('false => true', animate('500ms ease-out')),
    ]),
  ],
})
export class SidebarComponent implements OnInit {
  searchValue = '';

  constructor(
    private router: Router,
    public menuService: MenuService,
    private onDemandPreloadService: PreloadOnDemandService,
  ) {}

  ngOnInit(): void {}

  scrollToTop(): void {
    const element = document.querySelector('mat-sidenav-content .content');
    if (element) {
      element.scroll({
        top: 0,
        left: 0,
      });
    }
  }

  preloadBundle(preloadId: string | undefined): void {
    if (preloadId) {
      this.onDemandPreloadService.startPreload(preloadId);
    }
  }

  search(searchValue: string): void {
    this.searchValue = '';
    this.router.navigate(['/search'], {
      queryParams: { q: searchValue },
    });
  }
}
