import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { CovalentCodeEditorModule } from '@covalent/code-editor';

import { MaterialModule } from '@shared/material.module';
import { SharedModule } from '@shared/shared.module';

import { AdminReportRoutingModule } from './report-routing.module';
import { HomeComponent } from './pages/home/home.component';
import { UpdateComponent } from './pages/update/update.component';
import { CreateComponent } from './pages/create/create.component';
import { EditComponent } from './components/edit/edit.component';
import { EditColumnsComponent } from './components/edit-columns/edit-columns.component';
import { EditParametersComponent } from './components/edit-parameters/edit-parameters.component';

import { DataService } from './../report/data.service';
import { EntityResolver } from './resolvers/entity.resolver';
import { EntitiesResolver } from './resolvers/entities.resolver';

@NgModule({
  declarations: [
    HomeComponent,
    UpdateComponent,
    CreateComponent,
    EditComponent,
    EditColumnsComponent,
    EditParametersComponent,
  ],
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    CovalentCodeEditorModule,
    MaterialModule,
    SharedModule,
    AdminReportRoutingModule,
  ],
  providers: [DataService, EntityResolver, EntitiesResolver],
})
export class AdminReportModule {}
