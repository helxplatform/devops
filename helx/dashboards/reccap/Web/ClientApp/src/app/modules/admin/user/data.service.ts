import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { share } from 'rxjs/operators';

import { CustomEncoder } from '@core/models/custom-encoder';
import { SearchParams } from '@shared/models/types';

@Injectable()
export class DataService {
  private baseUrl = 'api/v1/admin/users';

  constructor(private http: HttpClient) {}

  getEntities(search?: SearchParams): Observable<{}> {
    const httpParams = new HttpParams({
      fromObject: search,
      encoder: new CustomEncoder(),
    });

    return this.http.get(`${this.baseUrl}?${httpParams}`).pipe(share());
  }

  getEntity(id: string | null): Observable<{}> {
    return this.http.get(`${this.baseUrl}/${id}`);
  }

  updateEntity(entity: IEntity): Observable<{}> {
    return this.http.put(`${this.baseUrl}/${entity.userId}`, entity);
  }

  deleteEntity(id: string): Observable<{}> {
    return this.http.delete(`${this.baseUrl}/${id}`);
  }
}

export interface IEntity {
  userId: string;
  userName: string;
  displayName: string;
  roles: Array<string>;
  permissions: Array<any>;
  claims: Array<string>;
  email: string;
  isDisabled?: boolean;
  modifiedBy: string;
  modifiedDate: Date;
}
