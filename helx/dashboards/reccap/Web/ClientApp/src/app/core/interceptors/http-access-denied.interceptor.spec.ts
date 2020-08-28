import { TestBed } from '@angular/core/testing';

import { HttpAccessDeniedInterceptor } from './http-access-denied.interceptor';

describe('HttpAccessDeniedInterceptor', () => {
  beforeEach(() => TestBed.configureTestingModule({
    providers: [
      HttpAccessDeniedInterceptor
      ]
  }));

  it('should be created', () => {
    const interceptor: HttpAccessDeniedInterceptor = TestBed.inject(HttpAccessDeniedInterceptor);
    expect(interceptor).toBeTruthy();
  });
});
