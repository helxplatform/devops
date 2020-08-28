import { Title } from '@angular/platform-browser';
import { Component, OnInit, Injector } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { FormBuilder, FormGroup, Validators, FormControl } from '@angular/forms';

import { FormBaseComponent } from '@shared/models/form-base.component';
import { Observable } from 'rxjs';

@Component({
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss'],
})
export class LoginComponent extends FormBaseComponent<any> {
  returnUrl: string;
  encodedReturnUrl: string;

  constructor(private http: HttpClient, private fb: FormBuilder, injector: Injector) {
    super(injector);
    this.returnUrl = this.route.snapshot.queryParams.ReturnUrl;
    this.encodedReturnUrl = encodeURIComponent(this.returnUrl);
    //  TODO: If returnUrl empty, throw an error
  }

  createEntityForm(): FormGroup {
    return this.fb.group({
      username: [null, Validators.compose([Validators.required])],
      password: [null, Validators.compose([Validators.required])],
      isPersistent: [false],
    });
  }

  login(): void {
    super.submitForm(
      (data: any) => this.loginApi(data),
      (entity: any) => {
        window.location.href = this.returnUrl;
      },
      (error: any) => {},
    );
  }

  loginApi(data: any): Observable<any> {
    return this.http.post('api/account/login', data);
  }
}
