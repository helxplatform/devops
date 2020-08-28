import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { FileSaverModule } from 'ngx-filesaver';

import { MaterialModule } from '@shared/material.module';
import { SharedModule } from '@shared/shared.module';

import { UserReportRoutingModule } from './report-routing.module';
import { HomeComponent } from './pages/home/home.component';
import { ExecuteComponent } from './pages/execute/execute.component';

import { DataService } from './../report/data.service';
import { EntityResolver } from './resolvers/entity.resolver';

@NgModule({
  declarations: [HomeComponent, ExecuteComponent],
  imports: [CommonModule, FormsModule, ReactiveFormsModule, FileSaverModule, MaterialModule, SharedModule, UserReportRoutingModule],
  providers: [DataService, EntityResolver],
})
export class UserReportModule {}
