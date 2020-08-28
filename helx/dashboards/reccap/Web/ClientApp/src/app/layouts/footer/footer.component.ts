import { Component, OnInit } from '@angular/core';

import { ConfigurationService } from '@core/services/configuration.service';

@Component({
  selector: 'app-footer',
  templateUrl: './footer.component.html',
  styleUrls: ['./footer.component.scss'],
})
export class FooterComponent implements OnInit {
  year: number;
  constructor(public config: ConfigurationService) {
    this.year = new Date().getFullYear();
  }

  ngOnInit(): void {}
}
