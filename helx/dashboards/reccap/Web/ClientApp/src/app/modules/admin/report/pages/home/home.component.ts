import { Component, OnInit, ViewChild, AfterViewInit } from '@angular/core';
import { FormGroup, FormBuilder } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';

import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';

import { merge } from 'rxjs';
import { mergeMap, map } from 'rxjs/operators';

import { UserProfileService } from '@core/services/user-profile.service';

import { DataService } from '../../data.service';

export interface Employee {
  id: number;
  Name: string;
  Position: string;
  Email: string;
  Mobile: number;
  DateOfJoining: Date;
  Salary: number;
  Projects: number;
  imagePath: string;
}

@Component({
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss'],
})
export class HomeComponent implements OnInit, AfterViewInit {
  data: Array<any> = [];

  displayedColumns: string[] = ['action', 'displayName', 'reportTypeName', 'description', 'modifiedDate'];
  searchForm!: FormGroup;

  @ViewChild(MatPaginator, { static: true }) paginator!: MatPaginator;
  @ViewChild(MatSort, { static: false }) sort!: MatSort;

  private searchDefaults = {
    page: 1,
    pageSize: this.userProfile.preference.pageSize ?? 25,
    sort: 'displayName',
    dir: 'asc',
  };

  constructor(
    private userProfile: UserProfileService,
    private fb: FormBuilder,
    private router: Router,
    private route: ActivatedRoute,
    private dataService: DataService,
  ) {}

  ngOnInit(): void {
    this.searchForm = this.fb.group({
      name: ['', { updateOn: 'submit' }],
      page: [],
      pageSize: [],
      sort: [],
      dir: [],
    });

    this.route.queryParams
      .pipe(
        mergeMap((queryValues) => {
          const search = {
            ...this.searchDefaults,
            ...queryValues,
          };

          this.searchForm.patchValue(search, {
            onlySelf: true,
            emitEvent: false,
          });

          return this.dataService.getEntities({ ...this.searchForm.value, ...search });
        }),
      )
      .subscribe((e: any) => {
        this.data = e.data;
        this.paginator.length = e.totalItems;
      });
  }

  ngAfterViewInit(): void {
    // If the user changes the sort order, reset back to the first page.
    this.sort.sortChange.subscribe(() => (this.paginator.pageIndex = 0));

    merge(this.sort.sortChange, this.paginator.page, this.searchForm.valueChanges)
      .pipe(
        map(() => {
          const search = {
            ...this.searchForm.getRawValue(),
            page: this.paginator.pageIndex + 1,
            pageSize: this.paginator.pageSize,
            sort: this.sort.active,
            dir: this.sort.direction,
          };
          return search;
        }),
      )
      .subscribe((search) => {
        this.userProfile.preference.pageSize = this.paginator.pageSize;
        this.router.navigate(['.'], {
          relativeTo: this.route,
          queryParams: search,
        });
      });
  }
}
