import { Component, OnInit, ViewChild } from '@angular/core';
import { FormGroup, FormBuilder } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';

import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';

import { mergeMap, map } from 'rxjs/operators';
import { merge } from 'rxjs';

import { FileSaverService } from 'ngx-filesaver';

import { UserProfileService } from '@core/services/user-profile.service';

import { DataService } from '../../data.service';

@Component({
  templateUrl: './execute.component.html',
  styleUrls: ['./execute.component.scss'],
})
export class ExecuteComponent implements OnInit {
  data: Array<any> = [];
  report: any;

  displayedColumns: string[] = ['name', 'description', 'modifiedDate'];
  searchForm!: FormGroup;

  @ViewChild(MatPaginator, { static: true }) paginator!: MatPaginator;
  @ViewChild(MatSort, { static: false }) sort!: MatSort;

  private searchDefaults = {
    page: 1,
    pageSize: this.userProfile.preference.pageSize ?? 25,
    sort: 'name',
    dir: 'asc',
  };

  constructor(
    private userProfile: UserProfileService,
    private fileSaverService: FileSaverService,
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

    this.report = this.route.snapshot.data.entity;
    this.displayedColumns = this.report.columns.map((e: any) => e.name);

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
          const typeName: string = this.route.snapshot.paramMap.get('typeName') ?? 'none';
          return this.dataService.executeReport(typeName, this.report.reportId, {
            ...this.searchForm.value,
            ...search,
          });
        }),
      )
      .subscribe((e: any) => {
        console.log(e);
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

  download(type: string): void {
    this.dataService
      .downloadReport(type, this.report.reportTypeSEO, this.report.reportId, this.searchForm.getRawValue())
      .subscribe(
        (res) => {
          const filename = `${this.report.nameSEO}-${Math.random().toString(36).substr(2, 9)}.${type}`;
          this.fileSaverService.save(res, filename);
        },
        (error) => {
          console.error('Failed to execute the report.', error);
          // this.notificationService.error('Failed to execute report.');
        },
      );
  }
}
