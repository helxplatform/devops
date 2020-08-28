import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { share, map } from 'rxjs/operators';

import { CustomEncoder } from '@core/models/custom-encoder';
import { SearchParams } from '@shared/models/types';

@Injectable()
export class DataService {
  private baseUrl = 'api/v1/admin/reports';

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

  createEntity(entity: IEntity): Observable<{}> {
    return this.http.post(this.baseUrl, entity);
  }

  updateEntity(entity: IEntity): Observable<{}> {
    return this.http.put(`${this.baseUrl}/${entity.reportId}`, entity);
  }

  deleteEntity(id: string): Observable<{}> {
    return this.http.delete(`${this.baseUrl}/${id}`);
  }

  getColumns(project: IEntity): Observable<Array<string>> {
    return this.http.post(`${this.baseUrl}/parse-columns`, project).pipe(map((e) => e as Array<string>));
  }
}

export interface IEntity {
  reportId: string;
  displayName: string;
  name: string;
  description: string;
  isActive: boolean;
  isVisible: boolean;
  isPublic: boolean;
  displayCategory: string;
  defaultSort: string;
  reportTypeName: string;
  roles: Array<string>;
  chartTypes: string;
  queryText: string;
  columns: Array<any>;
  parameters: Array<any>;
  modifiedBy: string;
  modifiedDate: Date;
}
