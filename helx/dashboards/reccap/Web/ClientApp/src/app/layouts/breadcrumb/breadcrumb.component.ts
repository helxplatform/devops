import { Component, OnInit } from '@angular/core';
import { Router, ActivatedRoute, NavigationEnd } from '@angular/router';
import { Title } from '@angular/platform-browser';
import { filter, map, switchMap, toArray } from 'rxjs/operators';
import { from, EMPTY } from 'rxjs';

@Component({
  selector: 'app-breadcrumb',
  templateUrl: './breadcrumb.component.html',
  styleUrls: ['./breadcrumb.component.scss'],
})
export class BreadcrumbComponent implements OnInit {
  routes: Array<any> = [];
  current: any;
  constructor(private router: Router, private activatedRoute: ActivatedRoute, private titleService: Title) {
    this.router.events.pipe(filter((event) => event instanceof NavigationEnd)).subscribe(() => {
      // const routes: Array<ActivatedRoute> = [];
      const routes: Array<{ route: ActivatedRoute; path: string } | null> = [];
      const path = [];
      let route: ActivatedRoute | null = this.activatedRoute;
      let lastRoute = route;
      while (route) {
        lastRoute = route;
        path.push(route.snapshot.url.join(''));
        const routePath = [...path].join('/');
        if (routePath === '') {
          routes.push({ route, path: '/' });
        } else {
          routes.push({ route, path: routePath });
        }
        route = route.firstChild;
      }
      routes.push(null);

      from(routes)
        .pipe(
          filter((routeData: any) => routeData?.path !== '//'),
          switchMap((routeData: { route: ActivatedRoute; path: string } | null) =>
            routeData
              ? routeData.route.data.pipe(
                  map((data: any) => ({
                    title: data.titleResolve ? data.titleResolve(data) : data.title,
                    header: data.headerResolve ? data.headerResolve(data) : data.header,
                    url: routeData.path,
                    component: routeData.route.component,
                  })),
                )
              : EMPTY,
          ),
          filter((item: any) => item.title !== undefined && item.component !== undefined),
          toArray(),
        )
        .subscribe((resultRoutes) => {
          this.routes = resultRoutes;
          this.current = resultRoutes[resultRoutes.length - 1];
          const title = this.current.header ?? this.current.title;
          this.titleService.setTitle(`ReCCAP Dashboard - ${title}`);
        });
    });
  }

  ngOnInit(): void {}
}
