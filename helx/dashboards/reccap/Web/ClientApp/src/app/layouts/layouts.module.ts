import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

import { PerfectScrollbarModule } from 'ngx-perfect-scrollbar';
import { CovalentBreadcrumbsModule } from '@covalent/core/breadcrumbs';

import { MaterialModule } from '@app/shared/material.module';

import { BreadcrumbComponent } from './breadcrumb/breadcrumb.component';
import { BlankComponent } from './blank/blank.component';
import { FullComponent } from './full/full.component';

import { HeaderComponent } from './header/header.component';
import { HeaderUserComponent } from './header-user/header-user.component';
import { HeaderSearchComponent } from './header-search/header-search.component';
import { SidebarComponent } from './sidebar/sidebar.component';
import { FooterComponent } from './footer/footer.component';

@NgModule({
  declarations: [
    BlankComponent,
    FullComponent,
    BreadcrumbComponent,
    HeaderComponent,
    HeaderUserComponent,
    HeaderSearchComponent,
    SidebarComponent,
    FooterComponent,
  ],
  imports: [CommonModule, FormsModule, RouterModule, PerfectScrollbarModule, CovalentBreadcrumbsModule, MaterialModule],
})
export class LayoutsModule {}
