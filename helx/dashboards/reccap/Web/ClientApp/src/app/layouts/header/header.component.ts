import { Component, OnInit } from '@angular/core';

import { UserProfileService } from '@core/services/user-profile.service';

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.scss'],
})
export class HeaderComponent implements OnInit {
  constructor(public userProfile: UserProfileService) {}

  ngOnInit(): void {}
}
