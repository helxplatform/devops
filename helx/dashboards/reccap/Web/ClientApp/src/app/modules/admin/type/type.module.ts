import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { TypeRoutingModule } from './type-routing.module';
import { HomeComponent } from './pages/home/home.component';
import { CreateComponent } from './pages/create/create.component';
import { UpdateComponent } from './pages/update/update.component';
import { EditComponent } from './components/edit/edit.component';

import { DataService } from './data.service';
import { EntityResolver } from './resolvers/entity.resolver';
import { EntitiesResolver } from './resolvers/entities.resolver';

@NgModule({
  declarations: [HomeComponent, CreateComponent, UpdateComponent, EditComponent],
  imports: [CommonModule, TypeRoutingModule],
  providers: [DataService, EntityResolver, EntitiesResolver],
})
export class AdminTypeModule {}
