import { Injectable } from '@angular/core';
import { HttpParams, HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { share } from 'rxjs/operators';

import { CustomEncoder } from '@core/models/custom-encoder';

import { SearchParams } from '@shared/models/types';

@Injectable({
  providedIn: 'root',
})
export class DataService {
  private baseUrl = 'api/v1/redcap';

  constructor(private http: HttpClient) {}

  getAll(search?: SearchParams): Observable<{}> {
    const httpParams = new HttpParams({
      fromObject: search,
      encoder: new CustomEncoder(),
    });
    return this.http.get(`${this.baseUrl}/all?${httpParams}`).pipe(share());
  }
}
