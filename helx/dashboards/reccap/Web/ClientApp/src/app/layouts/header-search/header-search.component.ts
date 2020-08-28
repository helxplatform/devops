import { Component, OnInit, ViewChild, ElementRef } from '@angular/core';
import { trigger, state, style, transition, animate } from '@angular/animations';
import { Router } from '@angular/router';

@Component({
  selector: 'app-header-search',
  templateUrl: './header-search.component.html',
  styleUrls: ['./header-search.component.scss'],
  animations: [
    trigger('slideInOut', [
      state('true', style({ width: '100%' })),
      state('false', style({ width: '0' })),
      transition('true => false', animate('300ms ease-in')),
      transition('false => true', animate('300ms ease-out')),
    ]),
  ],
})
export class HeaderSearchComponent implements OnInit {
  searchValue = '';
  searchVisible = false;

  @ViewChild('input') inputElement!: ElementRef;

  constructor(private router: Router) {}

  ngOnInit(): void {}

  toggle() {
    this.searchVisible = !this.searchVisible;
    if (this.searchVisible) {
      this.open();
    } else {
      this.close();
    }
  }

  search(searchValue: string): void {
    this.router.navigate(['/search'], {
      queryParams: { q: searchValue },
    });
    this.close();
  }

  private close(): void {
    this.searchVisible = false;
    this.searchValue = '';
  }

  private open(): void {
    this.searchVisible = true;
    this.inputElement.nativeElement.focus();
  }
}
