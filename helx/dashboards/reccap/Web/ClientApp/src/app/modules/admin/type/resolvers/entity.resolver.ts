import { Injectable } from '@angular/core';
import { Resolve, ActivatedRouteSnapshot, RouterStateSnapshot } from '@angular/router';
import { Observable } from 'rxjs';

import { DataService } from '../data.service';

@Injectable()
export class EntityResolver implements Resolve<{}> {
  constructor(private dataService: DataService) {}
  resolve(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): {} | Observable<{}> | Promise<{}> {
    return this.dataService.getEntity(route.paramMap.get('category'), route.paramMap.get('id'));
  }
}
