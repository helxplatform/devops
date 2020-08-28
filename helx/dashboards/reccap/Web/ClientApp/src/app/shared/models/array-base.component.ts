import { OnInit, OnDestroy, AfterViewInit, ChangeDetectorRef, Directive, Injector } from '@angular/core';
import {
  ControlValueAccessor,
  FormControlName,
  ValidationErrors,
  AbstractControl,
  FormControl,
  FormArray,
} from '@angular/forms';
import { CdkDragDrop } from '@angular/cdk/drag-drop';

import { Subscription } from 'rxjs';

import { ConfirmDialogService } from '@core/services/confirm-dialog.service';
import { BaseComponent } from '@shared/models/base-component';

@Directive()
export abstract class ArrayBaseComponent extends BaseComponent
  implements OnInit, OnDestroy, AfterViewInit, ControlValueAccessor {
  entityForm!: FormArray;
  removeConfirmationMessage = 'Are you sure you want to delete this item?';

  protected cdr: ChangeDetectorRef;
  protected dialogService: ConfirmDialogService;

  private entityFormChanges$!: Subscription;
  private subscriptions: (Subscription | undefined)[] = [];

  constructor(private injector: Injector) {
    super();
    this.cdr = injector.get(ChangeDetectorRef);
    this.dialogService = injector.get(ConfirmDialogService);
  }

  ngOnInit(): void {
    this.entityForm = this.createEntityForm();
  }

  ngAfterViewInit(): void {
    this.startWatchingFormChanges();

    //  TODO: Use optional get to try FormControl
    const parent = this.injector.get<FormControlName>(FormControlName);

    this.subscriptions.push(
      parent.statusChanges?.subscribe((v: any) => {
        if (parent.errors) {
          this.handleError(parent.errors);
          this.cdr.markForCheck();
        }
      }),
    );
  }

  ngOnDestroy(): void {
    this.stopWatchingFormChanges();
    for (const subscription of this.subscriptions.filter((v) => v !== undefined)) {
      subscription?.unsubscribe();
    }
  }

  protected abstract createEntityForm(): FormArray;

  abstract addItem(item?: any): void;

  clickAddItem(event: Event): void {
    event.preventDefault();
    event.stopPropagation();
    this.addItem();
    this.cdr.markForCheck();
  }

  clickRemoveItem(event: Event, formControl: AbstractControl): void {
    event.preventDefault();
    event.stopPropagation();
    this.dialogService.confirm(this.removeConfirmationMessage).then((result: boolean) => {
      if (result) {
        const index = this.entityForm.controls.indexOf(formControl);
        this.entityForm.removeAt(index);
        this.cdr.markForCheck();
      }
    });
  }

  valueSet = (_: any) => {};

  propagateChange = (_: any) => {};

  writeValue(value: any): void {
    this.stopWatchingFormChanges();

    this.entityForm = this.createEntityForm();

    if (value) {
      for (const item of value) {
        this.addItem(item);
      }
      this.entityForm.patchValue(value, { onlySelf: true });
      this.cdr.markForCheck();
    }
    this.valueSet(value);

    this.startWatchingFormChanges();
  }

  registerOnChange(fn: (_: any) => {}): void {
    this.propagateChange = fn;
  }

  registerOnTouched(): void {}

  validate(control: FormControl): ValidationErrors | null {
    return this.entityForm.invalid ? this.entityForm.errors || { error: true } : null;
  }

  //  Drag and drop functions
  drop(event: CdkDragDrop<any>): void {
    this.moveItemInFormArray(this.entityForm, event.previousIndex, event.currentIndex);
  }

  moveItemInFormArray(array: FormArray, fromIndex: number, toIndex: number): void {
    const from = this.clamp(fromIndex, array.length - 1);
    const to = this.clamp(toIndex, array.length - 1);

    if (from === to) {
      return;
    }

    const target = array.at(from);
    const delta = to < from ? -1 : 1;

    for (let i = from; i !== to; i += delta) {
      array.setControl(i, array.at(i + delta));
    }

    array.setControl(to, target);
  }

  clamp(value: number, max: number): number {
    return Math.max(0, Math.min(max, value));
  }

  private stopWatchingFormChanges(): void {
    if (this.entityFormChanges$) {
      this.entityFormChanges$.unsubscribe();
    }
  }

  private startWatchingFormChanges(): void {
    this.entityFormChanges$ = this.entityForm.valueChanges.subscribe((m) => {
      this.propagateChange(m);
    });
  }
}
