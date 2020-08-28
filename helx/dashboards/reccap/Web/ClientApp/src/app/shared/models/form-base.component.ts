import { HttpErrorResponse } from '@angular/common/http';
import { FormGroup } from '@angular/forms';
import { Input, Injector, Directive, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { LocalStorageService } from 'ngx-webstorage';
import { Observable } from 'rxjs';

import { BaseComponent } from '@shared/models/base-component';

@Directive()
export abstract class FormBaseComponent<T> extends BaseComponent implements OnInit {
  @Input()
  entity!: T;

  entityForm!: FormGroup;
  draft!: T | null;
  formDisabled: boolean | null = null;

  get controlName(): string | null {
    return null;
  }

  protected route: ActivatedRoute;
  protected router: Router;
  private storage: LocalStorageService;

  constructor(injector: Injector) {
    super();
    this.route = injector.get(ActivatedRoute);
    this.router = injector.get(Router);
    this.storage = injector.get(LocalStorageService);
  }

  ngOnInit(): void {
    this.entityForm = this.createEntityForm();

    this.route.data.subscribe((value) => {
      this.entity = value.entity || {};
      this.updateBreadcrumb(this.entity);
      if (this.controlName) {
        this.entityForm.patchValue({
          [this.controlName]: this.entity,
        });
      } else {
        this.entityForm.patchValue(this.entity);
      }
      this.entityForm.markAsPristine();
      this.entityForm.markAsUntouched();
    });
    this.draft = this.storage.retrieve(`draft-${this.router.url}`);
  }

  protected abstract createEntityForm(): FormGroup;

  protected updateBreadcrumb(entity: T): void {}

  protected submitForm(
    submitFunction: (entity: any) => Observable<any>,
    onSuccess: (entity: any) => void,
    onError?: (error: any) => void,
  ): void {
    this.formDisabled = true;

    const submitValue = {
      ...this.entity,
      ...(this.controlName ? this.entityForm.getRawValue()[this.controlName] : this.entityForm.getRawValue()),
    };

    submitFunction(submitValue).subscribe(
      (entity: T) => {
        this.entity = entity;
        if (this.entity) {
          this.updateBreadcrumb(this.entity);
          if (this.controlName) {
            this.entityForm.patchValue({
              [this.controlName]: this.entity,
            });
          } else {
            this.entityForm.patchValue(this.entity);
          }
          this.entityForm.markAsPristine();
          this.entityForm.markAsUntouched();
        }

        this.storage.clear(`draft-${this.router.url}`);
        this.draft = null;
        this.formDisabled = null;

        if (onSuccess) {
          onSuccess(entity);
        }
      },
      (error) => {
        this.formDisabled = null;
        this.handle400Error(error, this.controlName);
        if (onError) {
          onError(error);
        }
      },
    );
  }

  // update() {
  //   this.formDisabled = true;
  //   //  Merge with properties loaded when entity was retrieved
  //   Object.assign(this.entity, this.entityForm.getRawValue());

  //   this.updateService(this.entity).subscribe(
  //     (entity: T) => {
  //       console.log('updated', entity);
  //       this.entity = entity;
  //       this.updateBreadcrumb(this.entity);
  //       this.entityForm.patchValue(this.entity);
  //       this.entityForm.markAsPristine();

  //       this.storage.clear(`draft-${this.router.url}`);
  //       this.draft = null;
  //       this.formDisabled = null;

  //       //  Update breadcrumb with entity name
  //       this.notificationService.success(this.updatedSuccessMessage);
  //     },
  //     (error) => {
  //       debugger;
  //       this.formDisabled = null;
  //       this.handleError(error);
  //       this.notificationService.error(this.updatedFailedMessage);
  //     },
  //   );
  // }

  // create() {
  //   this.formDisabled = true;

  //   //  Merge with properties loaded when entity was retreived
  //   Object.assign(this.entity, this.entityForm.getRawValue());

  //   this.updateService(this.entity).subscribe(
  //     (entity: T) => {
  //       this.entityForm.markAsPristine();
  //       //  Update breadcrumb with entity name
  //       if (this.routerCommands) {
  //         this.router.navigate(this.routerCommands(entity), { relativeTo: this.route });
  //       }

  //       this.notificationService.success(this.updatedSuccessMessage);
  //     },
  //     (error) => {
  //       this.formDisabled = null;
  //       this.handleError(error);
  //       this.notificationService.error(this.updatedFailedMessage);
  //     },
  //   );
  // }

  saveDraft(): void {
    this.draft = { ...this.entity, ...this.entityForm.getRawValue() };
    this.storage.store(`draft-${this.router.url}`, this.draft);
  }

  loadDraft(): void {
    this.entityForm.markAsUntouched();
    this.entity = { ...this.draft } as T;
  }
}
