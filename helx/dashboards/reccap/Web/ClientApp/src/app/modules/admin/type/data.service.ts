import { Injectable } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { share } from 'rxjs/operators';

import { CustomEncoder } from '@core/models/custom-encoder';
import { SearchParams } from '@shared/models/types';

@Injectable()
export class DataService {
  private baseUrl = 'api/v1/admin/types';

  constructor(private route: ActivatedRoute, private http: HttpClient) {}

  getEntities(category: string, search?: SearchParams): Observable<{}> {
    const httpParams = new HttpParams({
      fromObject: search,
      encoder: new CustomEncoder(),
    });

    return this.http.get(`${this.baseUrl}/${category}?${httpParams}`).pipe(share());
  }

  getEntity(category: string | null, id: string | null): Observable<{}> {
    return this.http.get(`${this.baseUrl}/${category}/${id}`);
  }

  updateEntity(category: string, entity: IEntity): Observable<{}> {
    return this.http.put(`${this.baseUrl}/${category}/${entity.typeId}`, entity);
  }

  deleteEntity(category: string, id: string): Observable<{}> {
    return this.http.delete(`${this.baseUrl}/${category}/${id}`);
  }
}

export interface IEntity {
  typeId: string;
  displayName: string;
  name: string;
  categoryName: string;
  code: string;
  orderSequence: number;
  isActive: boolean;
  parentTypeCategoryName: string;
  parentTypeName: string;
  roles: Array<string>;
  modifiedBy: string;
  modifiedDate: Date;
}
