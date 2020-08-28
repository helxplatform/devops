import { Component, OnInit, Injector } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';

import { NotificationService } from '@core/services/notification.service';
import { FormBaseComponent } from '@shared/models/form-base.component';

import { IEntity, DataService } from '../../data.service';
import { ControlBaseComponent } from '@shared/models/control-base.component';
import { EditComponent } from '../../components/edit/edit.component';

@Component({
  templateUrl: './update.component.html',
  styleUrls: ['./update.component.scss'],
  providers: [{ provide: ControlBaseComponent, useExisting: EditComponent }],
})
export class UpdateComponent extends FormBaseComponent<IEntity> implements OnInit {
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

  update(): void {
    super.submitForm(
      (data: any) => this.dataService.updateEntity(data),
      (entity: any) => {
        this.notificationService.success(`Report '${entity.displayName}' has been updated`);
      },
      (error: any) => {
        this.notificationService.error('Failed to updated the report.');
      },
    );
  }
}
