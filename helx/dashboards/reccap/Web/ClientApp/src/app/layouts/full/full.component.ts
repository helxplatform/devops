import { Component, OnInit } from '@angular/core';
import { PerfectScrollbarConfigInterface } from 'ngx-perfect-scrollbar';

import { UserProfileService } from '@core/services/user-profile.service';

@Component({
  selector: 'app-full',
  templateUrl: './full.component.html',
  styleUrls: ['./full.component.scss'],
})
export class FullComponent implements OnInit {
  public config: PerfectScrollbarConfigInterface = {};

  constructor(public userProfile: UserProfileService) {}

  ngOnInit(): void {}
}
