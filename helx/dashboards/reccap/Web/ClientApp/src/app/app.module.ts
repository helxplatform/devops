import { BrowserModule } from '@angular/platform-browser';
import { APP_INITIALIZER, NgModule } from '@angular/core';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { FormsModule } from '@angular/forms';
import { HttpClientModule, HttpClient, HTTP_INTERCEPTORS } from '@angular/common/http';
import { MatIconRegistry } from '@angular/material/icon';

import { map, catchError } from 'rxjs/operators';
import { Observable, ObservableInput, of } from 'rxjs';

import { NgxWebstorageModule } from 'ngx-webstorage';
import {
  PerfectScrollbarModule,
  PERFECT_SCROLLBAR_CONFIG,
  PerfectScrollbarConfigInterface,
} from 'ngx-perfect-scrollbar';
import { AuthModule, LogLevel, OidcConfigService } from 'angular-auth-oidc-client';

import { AppRoutingModule } from './app-routing.module';

import { AppComponent } from './app.component';

import { CoreModule } from '@core/core.module';
import { SharedModule } from '@shared/shared.module';
import { MaterialModule } from '@shared/material.module';
import { LayoutsModule } from './layouts/layouts.module';

import { HomeComponent } from './pages/home/home.component';
import { SearchComponent } from './pages/search/search.component';
import { NotFoundComponent } from './pages/not-found/not-found.component';
import { ForbiddenComponent } from './pages/forbidden/forbidden.component';
import { UnauthorizedComponent } from './pages/unauthorized/unauthorized.component';
import { ErrorComponent } from './pages/error/error.component';
import { LoginComponent } from './pages/login/login.component';
import { LogoutComponent } from './pages/logout/logout.component';
import { RegisterComponent } from './pages/register/register.component';
import { RegisterConfirmationComponent } from './pages/register-confirmation/register-confirmation.component';
import { PasswordResetComponent } from './pages/password-reset/password-reset.component';
import { PasswordForgotComponent } from './pages/password-forgot/password-forgot.component';

import { ConfigurationService } from '@core/services/configuration.service';
import { APP_MENU_ITEMS } from '@core/services/menu.service';

import { AuthInterceptor } from '@core/interceptors/authentication.interceptor';
import { HttpErrorInterceptor } from '@core/interceptors/http-error.interceptor';
import { HttpAccessDeniedInterceptor } from '@core/interceptors/http-access-denied.interceptor';

import { MenuItems } from './app.menu';

export function configureAuth(oidcConfigService: OidcConfigService): () => void {
  return () =>
    oidcConfigService.withConfig({
      storage: localStorage,
      stsServer: window.location.origin,
      redirectUrl: window.location.origin,
      postLogoutRedirectUri: window.location.origin,
      clientId: 'renci-reccap-dashboard',
      scope: 'openid profile offline_access',
      responseType: 'code',
      silentRenew: true,
      useRefreshToken: true,
      ignoreNonceAfterRefresh: true,
      autoUserinfo: true,
      logLevel: LogLevel.Error,
    });
}

interface Configuration {
  version: string;
}

export function loadConfiguration(http: HttpClient, config: ConfigurationService): () => Promise<boolean> {
  return (): Promise<boolean> => {
    return new Promise<boolean>((resolve: (a: boolean) => void): void => {
      http
        .get<Configuration>('./config.json')
        .pipe(
          map((x: Configuration) => {
            config.version = x.version;
            resolve(true);
          }),
          catchError(
            (x: { status: number }, caught: Observable<void>): ObservableInput<{}> => {
              if (x.status !== 404) {
                resolve(false);
              }
              console.log({ caught });
              config.version = 'error';
              resolve(true);
              return of({});
            },
          ),
        )
        .subscribe();
    });
  };
}

const DEFAULT_PERFECT_SCROLLBAR_CONFIG: PerfectScrollbarConfigInterface = {
  suppressScrollX: true,
  wheelSpeed: 2,
  wheelPropagation: true,
};

@NgModule({
  declarations: [
    AppComponent,

    HomeComponent,
    SearchComponent,
    NotFoundComponent,
    ForbiddenComponent,
    UnauthorizedComponent,
    ErrorComponent,
    LoginComponent,
    LogoutComponent,
    RegisterComponent,
    RegisterConfirmationComponent,
    PasswordResetComponent,
    PasswordForgotComponent,
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    BrowserAnimationsModule,
    FormsModule,
    HttpClientModule,
    NgxWebstorageModule.forRoot({ prefix: 'renci-reccap-dashboard' }),
    PerfectScrollbarModule,

    SharedModule,
    MaterialModule,
    LayoutsModule,

    AuthModule.forRoot(),
    CoreModule.forRoot(),
  ],
  providers: [
    OidcConfigService,
    {
      provide: APP_INITIALIZER,
      useFactory: configureAuth,
      deps: [OidcConfigService],
      multi: true,
    },
    {
      provide: APP_INITIALIZER,
      useFactory: loadConfiguration,
      deps: [HttpClient, ConfigurationService],
      multi: true,
    },
    {
      provide: PERFECT_SCROLLBAR_CONFIG,
      useValue: DEFAULT_PERFECT_SCROLLBAR_CONFIG,
    },
    { provide: APP_MENU_ITEMS, useValue: MenuItems },
    { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true },
    { provide: HTTP_INTERCEPTORS, useClass: HttpErrorInterceptor, multi: true },
    { provide: HTTP_INTERCEPTORS, useClass: HttpAccessDeniedInterceptor, multi: true },
  ],
  bootstrap: [AppComponent],
})
export class AppModule {
  constructor(matIconRegistry: MatIconRegistry) {
    matIconRegistry.registerFontClassAlias('fontawesome', 'fa');
  }
}
