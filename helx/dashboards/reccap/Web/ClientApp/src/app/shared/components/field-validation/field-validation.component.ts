import { Component, Input, OnInit, OnChanges, SimpleChanges } from '@angular/core';
import { ValidationErrors } from '@angular/forms';
import { ValidationMessages } from '@shared/models/types';

@Component({
  selector: 'app-field-validation',
  templateUrl: './field-validation.component.html',
  styleUrls: ['./field-validation.component.scss'],
})
export class FieldValidationComponent implements OnInit, OnChanges {
  @Input() error!: false | ValidationErrors | null;

  @Input() messages!: ValidationMessages | null;

  errors: Array<string> = [];

  constructor() {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.errors = [];
    if (changes.error && this.error) {
      for (const fieldName of Object.keys(this.error)) {
        if (this.error.serverError) {
          if (Array.isArray(this.error.serverError)) {
            this.errors.push(...this.error.serverError);
          } else {
            this.errors.push(this.error.serverError);
          }
        } else if (this.messages && this.messages[fieldName]) {
          this.errors.push(this.messages[fieldName](this.error));
        } else {
          this.errors.push(`${fieldName} error has no description`);
        }
      }
    }
  }
}
