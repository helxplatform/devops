import { AbstractControl, ValidatorFn, ValidationErrors } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';

export abstract class BaseComponent {
  abstract entityForm: AbstractControl;

  protected arrayMinLength(size: number): ValidatorFn {
    return (c: AbstractControl): ValidationErrors | null => {
      return c.value.length >= size
        ? null
        : {
            minlength: {
              valid: false,
            },
          };
    };
  }

  protected handle400Error(error: any, controlName?: string | null): void {
    if (error instanceof HttpErrorResponse && error.status === 400) {
      if (error.error && error.error.errors && Object.keys(error.error.errors).length > 0) {
        if (controlName) {
          const validationError: any = {};
          for (const fieldError of Object.keys(error.error.errors)) {
            validationError[controlName + '.' + fieldError] = error.error.errors[fieldError];
          }
          this.handleError(validationError);
        } else {
          this.handleError(error.error.errors);
        }
      } else if (error.error && error.error.title) {
        this.entityForm.setErrors({
          serverError: [error.error.title],
        });
      } else {
        this.entityForm.setErrors({
          serverError: ['Unknown error occurred'],
        });
      }
    }
  }

  protected handleError(validationError: any): void {
    const controlErrors: any = {};
    const formErrors: any = {};
    for (const fieldError of Object.keys(validationError)) {
      const controlNames = fieldError
        .split(/\W/)
        .filter((v) => v !== '')
        .map((v) => this.normalizeName(v));

      let controlFound = false;

      for (let index = controlNames.length; index > 0; index--) {
        const controlPath = controlNames.slice(0, index).join('.');
        const control = this.entityForm.get(controlPath);
        if (control) {
          controlFound = true;

          let newControlPath = controlNames.slice(index).join('.');

          if (newControlPath === '') {
            newControlPath = 'serverError';
          }
          //  Set default values
          controlErrors[controlPath] = controlErrors[controlPath] || {};
          controlErrors[controlPath][newControlPath] = controlErrors[controlPath][newControlPath] || [];

          controlErrors[controlPath][newControlPath] = [
            ...controlErrors[controlPath][newControlPath],
            ...validationError[fieldError],
          ];

          break;
        }
      }

      if (!controlFound) {
        formErrors[fieldError] = validationError[fieldError];
      }
    }

    const serverError = Object.values(formErrors).flat();

    if (serverError.length > 0) {
      this.entityForm.setErrors({ serverError });
    }

    for (const controlPath of Object.keys(controlErrors)) {
      const control = this.entityForm.get(controlPath);
      control?.setErrors(controlErrors[controlPath]);
      control?.markAsTouched();
    }
  }

  normalizeName(str: string): string {
    return str.replace(/^\w/g, (match: string): string => {
      return match.toLowerCase();
    });
  }
}
