import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { ActivatedRoute } from '@angular/router';
import { OidcSecurityService } from 'angular-auth-oidc-client';

@Component({
  templateUrl: './logout.component.html',
  styleUrls: ['./logout.component.scss'],
})
export class LogoutComponent implements OnInit {
  constructor(
    private http: HttpClient,
    private route: ActivatedRoute,
    public oidcSecurityService: OidcSecurityService,
  ) {}

  ngOnInit(): void {}

  login(): void {
    this.oidcSecurityService.authorize();
  }

  logout(): void {
    const logoutId = this.route.snapshot.queryParams.logoutId;
    console.log(logoutId);

    this.http.get('api/account/logout?logoutId=' + logoutId).subscribe(
      (result) => {
        console.log({ result });
      },
      (error) => {
        console.log({ error });
      },
    );
  }
}
