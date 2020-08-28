import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { share } from 'rxjs/operators';

import { CustomEncoder } from '@core/models/custom-encoder';
import { SearchParams } from '@shared/models/types';

@Injectable()
export class DataService {
  private baseUrl = 'api/v1/user/reports';

  constructor(private authHttp: HttpClient) {}

  getEntities(typeName: string, search?: SearchParams): Observable<{}> {
    const httpParams = new HttpParams({
      fromObject: search,
      encoder: new CustomEncoder(),
    });

    return this.authHttp.get(`${this.baseUrl}/${encodeURIComponent(typeName)}?${httpParams}`).pipe(share());
  }

  getEntity(typeName: string, id: string): Observable<{}> {
    return this.authHttp.get(`${this.baseUrl}/${encodeURIComponent(typeName)}/${encodeURIComponent(id)}`);
  }

  executeReport(typeName: string, id: string, params: SearchParams): Observable<{}> {
    const httpParams = new HttpParams({
      fromObject: params,
      encoder: new CustomEncoder(),
    });

    return this.authHttp.get(
      `${this.baseUrl}/${encodeURIComponent(typeName)}/execute/${encodeURIComponent(id)}?${httpParams}`,
    );
  }

  downloadReport(type: string, typeName: string, id: string, params: SearchParams): Observable<Blob> {
    const httpParams = new HttpParams({
      fromObject: params,
      encoder: new CustomEncoder(),
    });

    return this.authHttp.get(
      `${this.baseUrl}/${encodeURIComponent(typeName)}/download/${encodeURIComponent(type)}/${encodeURIComponent(
        id,
      )}?${httpParams}`,
      {
        responseType: 'blob',
      },
    );
  }

  chartData(typeName: string, id: string, params: SearchParams): Observable<{}> {
    const httpParams = new HttpParams({
      fromObject: params,
      encoder: new CustomEncoder(),
    });
    return this.authHttp
      .get(`${this.baseUrl}/${encodeURIComponent(typeName)}/${encodeURIComponent(id)}/chart?${httpParams}`)
      .pipe(share());
  }
}

export interface IReport {
  reportId: string;
  name: string;
}
