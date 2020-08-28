import { Injectable, Injector } from '@angular/core';
import {
  HttpRequest,
  HttpHandler,
  HttpEvent,
  HttpInterceptor,
  HttpErrorResponse,
  HttpResponse,
  HttpResponseBase,
} from '@angular/common/http';
import { Observable, throwError } from 'rxjs';

import { NotificationService } from '../services/notification.service';
import { catchError, filter, tap } from 'rxjs/operators';

@Injectable()
export class HttpAccessDeniedInterceptor implements HttpInterceptor {
  constructor(private injector: Injector) {}

  intercept(request: HttpRequest<unknown>, next: HttpHandler): Observable<HttpEvent<unknown>> {
    return next.handle(request).pipe(
      // There may be other events besides the response.
      filter((event: any) => event instanceof HttpResponseBase),
      tap((event: HttpResponse<any>) => {
        // console.log({ event });
      }),
    );
  }
}
