import { Component, OnInit } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { FormBuilder, FormGroup, Validators, FormControl } from '@angular/forms';
import { HttpClient } from '@angular/common/http';

@Component({
  templateUrl: './register-confirmation.component.html',
  styleUrls: ['./register-confirmation.component.scss'],
})
export class RegisterConfirmationComponent implements OnInit {
  form: FormGroup;

  constructor(
    private http: HttpClient,
    private fb: FormBuilder,
    private router: Router,
    private route: ActivatedRoute,
  ) {
    this.form = this.fb.group({
      username: [this.route.snapshot.queryParamMap.get('username')],
      code: [this.route.snapshot.queryParamMap.get('confirmation')],
    });
  }

  ngOnInit(): void {}

  onSubmit(): void {
    this.http.post('api/account/confirm', this.form.getRawValue()).subscribe(
      (r) => {
        // console.log({ r });
        // window.location.href = this.returnUrl;
        this.router.navigate(['/login']);
      },
      (error) => {
        console.log({ error });
      },
    );
  }
}
