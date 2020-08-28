import { Observable } from 'rxjs';
import { Component, OnInit, Injector } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { FormBuilder, FormGroup, Validators, FormControl } from '@angular/forms';

import { FormBaseComponent } from '@shared/models/form-base.component';
import { NotificationService } from '@core/services/notification.service';

import { CustomValidators } from 'ngx-custom-validators';

@Component({
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.scss'],
})
export class RegisterComponent extends FormBaseComponent<any> {
  returnUrl: string;

  constructor(private http: HttpClient, private fb: FormBuilder, injector: Injector) {
    super(injector);
    this.returnUrl = this.route.snapshot.queryParams.ReturnUrl;
  }

  createEntityForm(): FormGroup {
    const password = new FormControl('', Validators.required);
    const confirmPassword = new FormControl('');
    return this.fb.group({
      username: [null, Validators.compose([Validators.required])],
      password,
      confirmPassword,
      email: [null, Validators.compose([Validators.required])],
      // email: [null, Validators.compose([Validators.required, CustomValidators.email])],
    });
  }

  register(): void {
    super.submitForm(
      (data: any) => this.registerApi(data),
      (entity: any) => {
        console.log({ entity });
        //  TODO: Redirect after successful registration
        // window.location.href = this.returnUrl;
      },
      (error: any) => {},
    );
  }

  registerApi(data: any): Observable<any> {
    return this.http.post('api/account/register', data);
  }
}
