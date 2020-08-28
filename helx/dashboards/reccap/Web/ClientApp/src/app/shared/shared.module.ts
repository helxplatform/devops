import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';

import { CovalentLayoutModule } from '@covalent/core/layout';
import { CovalentNotificationsModule } from '@covalent/core/notifications';

import { SpinnerComponent } from './components/spinner/spinner.component';
import { FieldValidationComponent } from './components/field-validation/field-validation.component';

import { CategoryTypesDirective } from './directives/type-options.directive';
import { EnumOptionsDirective } from './directives/enum-options.directive';
import { RoleOptionsDirective } from './directives/role-options.directive';

import { SafePipe } from './pipes/safe.pipe';

@NgModule({
  declarations: [
    SpinnerComponent,
    FieldValidationComponent,
    CategoryTypesDirective,
    EnumOptionsDirective,
    RoleOptionsDirective,

    SafePipe,
  ],
  imports: [CommonModule],
  exports: [
    ReactiveFormsModule,

    CovalentLayoutModule,
    CovalentNotificationsModule,

    SpinnerComponent,
    FieldValidationComponent,
    CategoryTypesDirective,
    EnumOptionsDirective,
    RoleOptionsDirective,

    SafePipe,
  ],
})
export class SharedModule {}
