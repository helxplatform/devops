import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { FormBuilder, FormGroup, Validators, FormControl } from '@angular/forms';
import { HttpClient } from '@angular/common/http';

@Component({
  templateUrl: './password-forgot.component.html',
  styleUrls: ['./password-forgot.component.scss'],
})
export class PasswordForgotComponent implements OnInit {
  form: FormGroup;

  validationMessages = {
    username: {
      required: () => `Username is required.`,
    },
  };

  constructor(private http: HttpClient, private fb: FormBuilder, private router: Router) {
    this.form = this.fb.group({
      username: [null, Validators.compose([Validators.required])],
    });
  }

  ngOnInit(): void {}

  onSubmit(): void {
    this.http.post('api/account/password-forgot', this.form.getRawValue()).subscribe(
      (r) => {
        console.log({ r });
        // window.location.href = this.returnUrl;
        // this.router.navigate(['/login']);
      },
      (error) => {
        console.log({ error });
      },
    );
  }
}
