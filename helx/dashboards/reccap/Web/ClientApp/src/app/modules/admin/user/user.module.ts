import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { MaterialModule } from '@shared/material.module';

import { AdminUserRoutingModule } from './user-routing.module';
import { CreateComponent } from './pages/create/create.component';
import { UpdateComponent } from './pages/update/update.component';
import { HomeComponent } from './pages/home/home.component';
import { EditComponent } from './components/edit/edit.component';

import { DataService } from './data.service';
import { EntityResolver } from './resolvers/entity.resolver';
import { EntitiesResolver } from './resolvers/entities.resolver';

@NgModule({
  declarations: [CreateComponent, UpdateComponent, HomeComponent, EditComponent],
  imports: [CommonModule, MaterialModule, AdminUserRoutingModule],
  providers: [DataService, EntityResolver, EntitiesResolver],
})
export class AdminUserModule {}
