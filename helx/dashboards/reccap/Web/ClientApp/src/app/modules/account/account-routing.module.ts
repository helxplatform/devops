import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { ProfileComponent } from './pages/profile/profile.component';
import { ConfirmComponent } from './pages/confirm/confirm.component';
import { PasswordChangeComponent } from './pages/password-change/password-change.component';

const routes: Routes = [
  {
    path: '',
    component: ProfileComponent,
    data: {
      title: 'User Profile',
      urls: [{ title: 'User Profile' }],
    },
  },
  {
    path: 'confirm',
    component: ConfirmComponent,
    data: {
      title: 'Confirm',
      urls: [{ title: 'Account' }, { title: 'Confirm' }],
    },
  },
  {
    path: 'password-change',
    component: PasswordChangeComponent,
    data: {
      title: 'Change Password',
      urls: [{ title: 'Account' }, { title: 'Change Password' }],
    },
  },
  {
    path: 'profile',
    component: ProfileComponent,
    data: {
      title: 'User Profile',
      urls: [{ title: 'Account' }, { title: 'User Profile' }],
    },
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class AccountRoutingModule {}
