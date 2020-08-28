import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { AdminRoleRoutingModule } from './role-routing.module';
import { HomeComponent } from './pages/home/home.component';
import { UpdateComponent } from './pages/update/update.component';
import { CreateComponent } from './pages/create/create.component';
import { EditComponent } from './components/edit/edit.component';

import { DataService } from './data.service';
import { EntityResolver } from './resolvers/entity.resolver';
import { EntitiesResolver } from './resolvers/entities.resolver';

@NgModule({
  declarations: [HomeComponent, UpdateComponent, CreateComponent, EditComponent],
  imports: [CommonModule, AdminRoleRoutingModule],
  providers: [DataService, EntityResolver, EntitiesResolver],
})
export class AdminRoleModule {}
