import { Component, OnInit, Injector, ChangeDetectionStrategy, forwardRef, ViewChild } from '@angular/core';
import { FormGroup, Validators, FormBuilder, NG_VALUE_ACCESSOR, NG_VALIDATORS } from '@angular/forms';

import { ControlBaseComponent } from '@shared/models/control-base.component';
import { DataService } from '../../data.service';
import { EditColumnsComponent } from '../edit-columns/edit-columns.component';

@Component({
  selector: 'app-edit',
  templateUrl: './edit.component.html',
  styleUrls: ['./edit.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => EditComponent),
      multi: true,
    },
    {
      provide: NG_VALIDATORS,
      useExisting: forwardRef(() => EditComponent),
      multi: true,
    },
  ],
})
export class EditComponent extends ControlBaseComponent implements OnInit {
  chartTypeItems = [
    { id: 'line', text: 'Line' },
    { id: 'bar', text: 'Bar' },
    { id: 'doughnut', text: 'Doughnut' },
    { id: 'radar', text: 'Radar' },
    { id: 'pie', text: 'Pie' },
    { id: 'polarArea', text: 'Polar Area' },
  ];

  options: any = {
    minLines: 10,
    maxLines: 20,
    enableBasicAutocompletion: true,
    enableSnippets: true,
    enableLiveAutocompletion: false,
  };

  @ViewChild(EditColumnsComponent, { static: true })
  columnsEdit!: EditColumnsComponent;

  constructor(private dataService: DataService, private fb: FormBuilder, injector: Injector) {
    super(injector);
  }

  createEntityForm(): FormGroup {
    return this.fb.group({
      name: [null, [Validators.required, Validators.maxLength(256)]],
      description: [],
      shortDescription: [null, Validators.maxLength(512)],
      displayCategory: [null, [Validators.required]],
      reportTypeId: [null, [Validators.required]],
      isActive: [true],
      isVisible: [true],
      isPublic: [false],
      orderSequence: [0],
      queryText: [null, [Validators.required]],
      defaultSort: [null, Validators.maxLength(256)],
      chartTypes: [[]],
      columns: [[]],
      parameters: [[]],
      roles: [[], this.arrayMinLength(1)],
    });
  }

  populateColumns(event: Event) {
    event.preventDefault();
    event.stopPropagation();
    this.dataService.getColumns(this.entityForm.getRawValue()).subscribe(
      (columns: Array<string>) => {
        this.columnsEdit.populateColumns(columns);
      },
      (error) => {
        this.handle400Error(error);
        this.cdr.markForCheck();
      },
    );
  }
}
