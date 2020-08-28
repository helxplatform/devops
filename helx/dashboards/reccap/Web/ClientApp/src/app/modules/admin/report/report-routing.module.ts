import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { AuthenticationActivateGuard } from '@core/guards/authentication-activate.guard';
import { HomeComponent } from './pages/home/home.component';
import { UpdateComponent } from './pages/update/update.component';
import { CreateComponent } from './pages/create/create.component';

import { EntityResolver } from './resolvers/entity.resolver';
import { EntitiesResolver } from './resolvers/entities.resolver';

const routes: Routes = [
  {
    path: '',
    redirectTo: 'home',
    pathMatch: 'full',
  },
  {
    path: 'update/:id',
    resolve: { entity: EntityResolver },
    runGuardsAndResolvers: 'always',
    component: UpdateComponent,
    canActivate: [AuthenticationActivateGuard],
  },
  {
    path: 'create',
    component: CreateComponent,
    canActivate: [AuthenticationActivateGuard],
  },
  {
    path: 'home',
    component: HomeComponent,
    canActivate: [AuthenticationActivateGuard],
    data: {
      title: 'Report Administration',
    },
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class AdminReportRoutingModule {}
