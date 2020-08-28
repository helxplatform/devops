import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { CustomEncoder } from '@core/models/custom-encoder';

import { ICommonValue } from '../models/common-value';

@Injectable({
  providedIn: 'root',
})
export class CommonDataService {
  readonly baseUrl = 'api/v1/common';

  constructor(private http: HttpClient) {}

  getMenu(): Observable<any> {
    return this.http.get(`${this.baseUrl}/menu`);
  }

  getEnums(enumName: string): Observable<ICommonValue[]> {
    return this.http.get(`${this.baseUrl}/enums/${encodeURIComponent(enumName)}`).pipe(map((r) => r as ICommonValue[]));
  }

  getCategoryTypes(categoryName: string, params?: { parentType?: string; id?: string }): Observable<ICommonValue[]> {
    const httpParams = new HttpParams({
      fromObject: params as any,
      encoder: new CustomEncoder(),
    });

    return this.http
      .get(`${this.baseUrl}/types/${encodeURIComponent(categoryName)}?${httpParams}`)
      .pipe(map((r) => r as ICommonValue[]));
  }

  getRoles(search?: string): Observable<ICommonValue[]> {
    let request = this.http.get(`${this.baseUrl}/roles`);
    if (search) {
      request = this.http.get(`${this.baseUrl}/roles?s=` + encodeURIComponent(search));
    }

    return request.pipe(map((r) => r as ICommonValue[]));
  }
}
