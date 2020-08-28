import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { AccountRoutingModule } from './account-routing.module';
import { SharedModule } from '@shared/shared.module';
import { MaterialModule } from '@app/shared/material.module';

import { ProfileComponent } from './pages/profile/profile.component';
import { ConfirmComponent } from './pages/confirm/confirm.component';
import { PasswordChangeComponent } from './pages/password-change/password-change.component';

@NgModule({
  declarations: [ProfileComponent, ConfirmComponent, PasswordChangeComponent],
  imports: [CommonModule, AccountRoutingModule, MaterialModule, SharedModule],
})
export class AccountModule {}
