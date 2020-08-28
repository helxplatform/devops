import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { AuthenticationActivateGuard } from '@core/guards/authentication-activate.guard';

import { HomeComponent } from './pages/home/home.component';
import { ExecuteComponent } from './pages/execute/execute.component';

import { EntityResolver } from './resolvers/entity.resolver';

const routes: Routes = [
  {
    path: ':typeName',
    runGuardsAndResolvers: 'always',
    component: HomeComponent,
    canActivate: [AuthenticationActivateGuard],
    data: {
      title: 'Reports',
    },
  },
  {
    path: ':typeName/:id',
    resolve: { entity: EntityResolver },
    component: ExecuteComponent,
    canActivate: [AuthenticationActivateGuard],
    data: {
      breadcrumb: null,
    },
  },
];
@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class UserReportRoutingModule {}
