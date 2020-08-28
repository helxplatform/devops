import { Component, OnInit, ViewChild } from '@angular/core';
import { FormGroup, FormBuilder } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';

import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';

import { mergeMap, map } from 'rxjs/operators';
import { merge } from 'rxjs';

import { UserProfileService } from '@core/services/user-profile.service';

import { DataService } from '../../data.service';

@Component({
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss'],
})
export class HomeComponent implements OnInit {
  data: Array<any> = [];
  report: any;

  displayedColumns: string[] = [];
  searchForm!: FormGroup;

  @ViewChild(MatPaginator, { static: true }) paginator!: MatPaginator;
  @ViewChild(MatSort, { static: false }) sort!: MatSort;

  private searchDefaults = {
    page: 1,
    pageSize: this.userProfile.preference.pageSize ?? 25,
    sort: '',
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

    // this.report = this.route.snapshot.data.entity;
    this.report = {
      columns: [        
        { name: 'study_id', displayName: 'Study ID' },
        { name: 'compliance_5Text', displayName: 'In which building is your primary workplace?' },
        { name: 'compliance_5a', displayName: 'Please specify building.' },
        { name: 'mns_01', displayName: 'MNS - check in date/time' },
        { name: 'mns_result_01Text', displayName: 'MNS result' },
        { name: 'mns_result_date_01', displayName: 'MNS result - date/time' },
        { name: 'tasso_01', displayName: 'Tasso-ST check in date/time' },
        { name: 'tasso_result_01Text', displayName: 'Tasso-ST result' },
        { name: 'tasso_result_date_01', displayName: 'Tasso result - date/time' },
        { name: 'gold_cap_01', displayName: 'Gold Cap check in date/time' },
        { name: 'gold_cap_result_01Text', displayName: 'Gold Cap IgG result' },
        { name: 'gold_cap_result_date_01', displayName: 'Gold Cap IgG result - date/time' },
        { name: 'gold_cap_result_01bText', displayName: 'Gold Cap IgG/Igm result' },
        { name: 'gold_cap_result_date_01b', displayName: 'Gold Cap IgG/Igm result - date/time' },
        { name: 'saliva_01', displayName: 'Saliva check in date/time' },
        { name: 'saliva_result_01Text', displayName: 'Saliva result' },
        { name: 'saliva_result_date_01', displayName: 'Saliva result - date/time' },
        { name: 'confirm_result_01Text', displayName: 'Confirmatory Result' },
        { name: 'confirm_loc_01Text', displayName: 'Confirmatory Testing Location' },
        { name: 'mns_02', displayName: 'MNS - check in date/time' },
        { name: 'mns_result_02Text', displayName: 'MNS result' },
        { name: 'mns_result_date_02', displayName: 'MNS result - date/time' },
        { name: 'tasso_02', displayName: 'Tasso-ST check in date/time' },
        { name: 'tasso_result_02Text', displayName: 'Tasso-ST result' },
        { name: 'tasso_result_date_02', displayName: 'Tasso result - date/time' },
        { name: 'saliva_02', displayName: 'Saliva check in date/time' },
        { name: 'saliva_result_02Text', displayName: 'Saliva result' },
        { name: 'saliva_result_date_02', displayName: 'Saliva result - date/time' },
        { name: 'complete_studyText', displayName: 'Did the patient complete the study?' },
        { name: 'withdraw_date', displayName: 'Put a date if patient withdrew study' },
        { name: 'withdraw_reasonText', displayName: 'Reason patient withdrew from study' },
      ],
    };

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
          return this.dataService.getAll({
            ...this.searchForm.value,
            ...search,
          });
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
