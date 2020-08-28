import { Component, OnInit, Injector } from '@angular/core';
import { FormBaseComponent } from '@shared/models/form-base.component';
import { FormBuilder, FormGroup } from '@angular/forms';

import { NotificationService } from '@core/services/notification.service';

import { IEntity, DataService } from '../../data.service';

@Component({
  templateUrl: './create.component.html',
  styleUrls: ['./create.component.scss'],
})
export class CreateComponent extends FormBaseComponent<IEntity> {
  get controlName(): string {
    return 'edit';
  }

  constructor(
    private notificationService: NotificationService,
    private dataService: DataService,
    private fb: FormBuilder,
    injector: Injector,
  ) {
    super(injector);
  }

  createEntityForm(): FormGroup {
    return this.fb.group({
      [this.controlName]: null,
    });
  }

  create(): void {
    super.submitForm(
      (data: any) => this.dataService.createEntity(data),
      (entity: any) => {
        this.notificationService.success(`Report '${entity.displayName}' has been created`);
      },
      (error: any) => {
        this.notificationService.error('Failed to create the report.');
      },
    );
  }
}
