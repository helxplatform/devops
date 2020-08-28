import { OnInit, ChangeDetectorRef, Injector, Directive, AfterViewInit, OnDestroy } from '@angular/core';
import { FormGroup, ControlValueAccessor, AbstractControl, ValidationErrors, FormControlName } from '@angular/forms';
import { InjectFlags } from '@angular/compiler/src/core';
import { Subscription } from 'rxjs';

import { BaseComponent } from '@shared/models/base-component';

@Directive()
export abstract class ControlBaseComponent extends BaseComponent
  implements OnInit, AfterViewInit, OnDestroy, ControlValueAccessor {
  entity: any;
  entityForm!: FormGroup;

  protected cdr: ChangeDetectorRef;

  private subscriptions: (Subscription | undefined)[] = [];

  constructor(private injector: Injector) {
    super();
    this.cdr = injector.get(ChangeDetectorRef);
  }

  ngOnInit(): void {
    this.entityForm = this.createEntityForm();
    //  TODO:   Unsubscribe
    this.subscriptions.push(
      this.entityForm.valueChanges.subscribe((value) => {
        this.propagateChange({ ...this.entity, ...value });
      }),
    );
  }

  ngAfterViewInit(): void {
    //  TODO: Use optional get to try FormControl
    const parent = this.injector.get<FormControlName>(FormControlName);

    this.subscriptions.push(
      parent.statusChanges?.subscribe((v: any) => {
        if (parent.errors) {
          // this.entityForm.setErrors(parent.errors);
          this.handleError(parent.errors);
          this.cdr.markForCheck();
        }
      }),
    );
  }

  ngOnDestroy(): void {
    for (const subscription of this.subscriptions.filter((v) => v !== undefined)) {
      subscription?.unsubscribe();
    }
  }

  abstract createEntityForm(): FormGroup;

  protected loadEntity(entity: any): void {}

  propagateChange = (_: any) => {};

  writeValue(value: any): void {
    this.entity = value;
    if (value) {
      this.entityForm.patchValue(value, { onlySelf: true });
      this.cdr.markForCheck();
    }
    this.loadEntity(value);
  }

  registerOnChange(fn: any): void {
    this.propagateChange = fn;
  }
  registerOnTouched(fn: any): void {}

  setDisabledState?(isDisabled: boolean): void {
    if (isDisabled) {
      this.entityForm.disable();
    } else {
      this.entityForm.enable();
    }
  }

  validate(c: AbstractControl): ValidationErrors | null {
    return this.entityForm.valid ? null : this.entityForm.errors || { error: true };
  }
}
