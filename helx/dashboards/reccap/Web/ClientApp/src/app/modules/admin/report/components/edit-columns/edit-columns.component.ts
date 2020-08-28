import { Component, ChangeDetectionStrategy, forwardRef, Injector } from '@angular/core';
import { NG_VALUE_ACCESSOR, NG_VALIDATORS, FormBuilder, Validators, FormArray } from '@angular/forms';
import { CdkDragDrop, moveItemInArray } from '@angular/cdk/drag-drop';

import { ArrayBaseComponent } from '@shared/models/array-base.component';

@Component({
  selector: 'app-edit-columns',
  templateUrl: './edit-columns.component.html',
  styleUrls: ['./edit-columns.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => EditColumnsComponent),
      multi: true,
    },
    {
      provide: NG_VALIDATORS,
      useExisting: forwardRef(() => EditColumnsComponent),
      multi: true,
    },
  ],
})
export class EditColumnsComponent extends ArrayBaseComponent {
  constructor(private fb: FormBuilder, injector: Injector) {
    super(injector);
  }
  createEntityForm(): FormArray {
    return this.fb.array([]);
  }

  addItem(name?: string): void {
    this.entityForm.push(
      this.fb.group({
        name: [name, [Validators.required, Validators.maxLength(100)]],
        displayName: [null, [Validators.maxLength(256)]],
        displayValue: [''],
        sortName: [null, [Validators.maxLength(100)]],
        canView: [true],
        canDownload: [true],
        contextMenu: [null],
        className: [null],
      }),
    );
  }
  
  populateColumns(columns: Array<string>) {
    columns.forEach((value, index) => {
      this.addItem(value);
    });
    this.cdr.detectChanges();
  }
}
