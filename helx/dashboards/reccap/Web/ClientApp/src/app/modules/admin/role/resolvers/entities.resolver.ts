import { Injectable } from '@angular/core';
import { Resolve, ActivatedRouteSnapshot, RouterStateSnapshot } from '@angular/router';
import { Observable } from 'rxjs';

import { DataService } from '../data.service';

@Injectable()
export class EntitiesResolver implements Resolve<{}> {
  constructor(private dataService: DataService) {}
  resolve(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): {} | Observable<{}> | Promise<{}> {
    const search = Object.assign(
      {
        page: 1,
        pageSize: '10',
      },
      route.params,
      route.queryParams,
    );

    return this.dataService.getEntities(search);
  }
}
