import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { FullComponent } from './layouts/full/full.component';
import { BlankComponent } from './layouts/blank/blank.component';

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

import { PreloadModuleService } from '@core/services/preload-module.service';

const routes: Routes = [
  {
    path: '',
    component: FullComponent,
    data: {
      title: 'Home',
    },
    children: [
      {
        path: 'search',
        data: {
          title: 'Search',
          header: 'Search Result',
        },
        component: SearchComponent,
      },
      {
        path: 'forbidden',
        component: ForbiddenComponent,
      },
      {
        path: 'unauthorized',
        component: UnauthorizedComponent,
      },
      {
        path: 'account',
        loadChildren: () => import('./modules/account/account.module').then((m) => m.AccountModule),
      },
      {
        path: 'admin',
        children: [
          {
            path: 'reports',
            data: {
              preloadId: 'preload_admin_reports',
            },
            loadChildren: () => import('./modules/admin/report/report.module').then((m) => m.AdminReportModule),
          },
          {
            path: 'roles',
            data: {
              preloadId: 'preload_admin_roles',
            },
            loadChildren: () => import('./modules/admin/role/role.module').then((m) => m.AdminRoleModule),
          },
          {
            path: 'types',
            data: {
              preloadId: 'preload_admin_types',
            },
            loadChildren: () => import('./modules/admin/type/type.module').then((m) => m.AdminTypeModule),
          },
          {
            path: 'users',
            data: {
              preloadId: 'preload_admin_users',
            },
            loadChildren: () => import('./modules/admin/user/user.module').then((m) => m.AdminUserModule),
          },
        ],
      },
      {
        path: 'user',
        children: [
          {
            path: 'reports',
            data: {
              preloadId: 'preload_user_reports',
            },
            loadChildren: () => import('./modules/user/report/report.module').then((m) => m.UserReportModule),
          },
        ],
      },
      {
        path: 'dashboard',
        data: {
          preloadId: 'preload_user_reports',
        },
        loadChildren: () => import('./modules/user/dashboard/dashboard.module').then((m) => m.DashboardModule),
      },
      {
        path: '',
        loadChildren: () => import('./modules/home/home.module').then((m) => m.HomeModule),
      },
    ],
  },
  {
    path: '',
    component: BlankComponent,
    children: [
      {
        path: 'login',
        component: LoginComponent,
      },
      {
        path: 'logout',
        component: LogoutComponent,
      },
      {
        path: 'register',
        component: RegisterComponent,
      },
      {
        path: 'confirm',
        component: RegisterConfirmationComponent,
      },
      {
        path: 'password-reset',
        component: PasswordResetComponent,
      },
      {
        path: 'password-forgot',
        component: PasswordForgotComponent,
      },
      { path: 'error/:code', component: ErrorComponent },
      { path: 'error', component: ErrorComponent },
      { path: '**', component: NotFoundComponent },
    ],
  },
];

@NgModule({
  imports: [
    RouterModule.forRoot(routes, {
      enableTracing: false,
      preloadingStrategy: PreloadModuleService,
    }),
  ],
  exports: [RouterModule],
})
export class AppRoutingModule {}
