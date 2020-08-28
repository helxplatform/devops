import { Component, ChangeDetectionStrategy, forwardRef, Injector } from '@angular/core';
import { NG_VALUE_ACCESSOR, NG_VALIDATORS, FormBuilder, FormArray, Validators } from '@angular/forms';

import { ArrayBaseComponent } from '@shared/models/array-base.component';

@Component({
  selector: 'app-edit-parameters',
  templateUrl: './edit-parameters.component.html',
  styleUrls: ['./edit-parameters.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => EditParametersComponent),
      multi: true,
    },
    {
      provide: NG_VALIDATORS,
      useExisting: forwardRef(() => EditParametersComponent),
      multi: true,
    },
  ],
})
export class EditParametersComponent extends ArrayBaseComponent {
  constructor(private fb: FormBuilder, injector: Injector) {
    super(injector);
  }
  createEntityForm(): FormArray {
    return this.fb.array([]);
  }

  addItem(name?: string): void {
    this.entityForm.push(
      this.fb.group({
        name: [null, [Validators.required, Validators.maxLength(100)]],
        displayName: [null, [Validators.required, Validators.maxLength(256)]],
        isRequired: [false],
        isHidden: [false],
        defaultValue: [null, [Validators.maxLength(256)]],
        parameterDataType: [null, [Validators.required]],
        customData: [null],
        hintText: [null, Validators.maxLength(256)],
      }),
    );
  }
}
