import { Injectable, InjectionToken, Inject } from '@angular/core';
import { Router, NavigationEnd, ActivatedRoute } from '@angular/router';
import { OidcSecurityService } from 'angular-auth-oidc-client';

import { map, filter, mergeMap, tap } from 'rxjs/operators';

import { CommonDataService } from './common-data.service';
import { Menu, ChildrenItem } from '../models/menu';

export const APP_MENU_ITEMS = new InjectionToken<Array<Menu>>('APP_MENU_ITEMS');

interface UserData {
  permission: Array<number>;
  sub: string;
}

@Injectable({
  providedIn: 'root',
})
export class MenuService {
  menuItems: Array<Menu> = [];
  private previousPathName = '';

  constructor(
    private oidcSecurityService: OidcSecurityService,
    private router: Router,
    private route: ActivatedRoute,
    private dataService: CommonDataService,
    @Inject(APP_MENU_ITEMS) private menu: Array<Menu>,
  ) {
    this.router.events
      .pipe(
        //  Process only when path name changes and not query params
        filter((event) => event instanceof NavigationEnd && this.previousPathName !== window.location.pathname),
        map(() => this.route),
      )
      .pipe(
        map((lastRoute) => {
          while (lastRoute.firstChild) {
            lastRoute = lastRoute.firstChild;
          }
          this.previousPathName = window.location.pathname;
          return lastRoute;
        }),
        filter((outletRoute) => outletRoute.outlet === 'primary'),
        mergeMap((dataRoute) => dataRoute.data),
        mergeMap((routeData) => this.oidcSecurityService.userData$.pipe(map((userData) => ({ userData, routeData })))),
        mergeMap(({ userData, routeData }) =>
          this.dataService.getMenu().pipe(map((userMenu) => ({ userData, routeData, userMenu }))),
        ),
      )
      .subscribe(({ userData, routeData, userMenu }) => {
        this.menuItems = (routeData.menu ?? [])
          .concat(this.menu)
          .filter(
            (m: { permissions: Array<number> }) =>
              m.permissions === undefined ||
              m.permissions.length === 0 ||
              (userData &&
                userData.permission &&
                m.permissions.filter((x) => [userData.permission].flat().includes(x))),
          )
          .map((e: Menu) =>
            e.loadChildren ? { ...e, children: [...e.loadChildren(userMenu), ...(e.children ?? [])] } : e,
          )
          .map((e: Menu) =>
            e.children ? { ...e, children: this.processChildMenuItems(userMenu, userData, e.children) } : e,
          )
          .filter((e: Menu) => !e.children || e.children.length > 0)
          .map((e: Menu) =>
            e.children
              ? {
                  ...e,
                  expanded: this.router.isActive(e.url, false),
                  children: this.expandPathChildMenuItems(e, e.children),
                }
              : { ...e, selected: this.router.isActive(e.url, false) },
          );
      });
  }

  private processChildMenuItems(menu: any, userData: UserData, children: ChildrenItem[]): ChildrenItem[] {
    return children
      .filter(
        (m) =>
          m.permissions === undefined ||
          m.permissions.length === 0 ||
          (userData && userData.permission && m.permissions.filter((x) => [userData.permission].flat().includes(x))),
      )
      .map((e) => (e.loadChildren ? { ...e, children: [...e.loadChildren(menu), ...(e.children ?? [])] } : e))
      .map((e) => (e.children ? { ...e, children: this.processChildMenuItems(menu, userData, e.children) } : e))
      .filter((e) => !e.children || e.children.length > 0);
  }

  private expandPathChildMenuItems(menu: ChildrenItem, children: ChildrenItem[]): ChildrenItem[] {
    return children.map((e) => {
      return e.children
        ? {
            ...e,
            expanded: this.router.isActive(e.url, false),
            children: this.expandPathChildMenuItems(e, e.children),
          }
        : { ...e, selected: this.router.isActive(e.url, false) };
    });
  }
}
