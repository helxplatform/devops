import { Directive, ViewContainerRef, TemplateRef, Input, OnInit, OnChanges } from '@angular/core';
import { MatOption } from '@angular/material/core';
import { CommonDataService } from '@core/services/common-data.service';
import { ICommonValue } from '@core/models/common-value';
import { MatFormFieldControl } from '@angular/material/form-field';
import { MatSelect } from '@angular/material/select';

@Directive({
  selector: '[roles]',
})
export class RoleOptionsDirective implements OnInit, OnChanges {
  @Input('roles') roles!: string;
  @Input('rolesSelected-value') selectedValue!: string;

  constructor(
    private matFormFieldControl: MatFormFieldControl<MatSelect>,
    private commonDataService: CommonDataService,
    private template: TemplateRef<any>,
    private viewContainer: ViewContainerRef,
  ) {
    if (!matFormFieldControl) {
      throw new Error('RoleOptionsDirective can be used only inside MatSelect');
    }
  }

  ngOnInit(): void {
    const selectControl = this.matFormFieldControl as MatSelect;
    if (selectControl.multiple) {
      selectControl.compareWith = this.compareWith;
    }
  }

  compareWith(a: any, b: any): boolean {
    if (a.id && b.id) {
      return a.id === b.id;
    }
    return a === b;
  }

  ngOnChanges(): void {
    const value = this.selectedValue || this.matFormFieldControl.ngControl?.value;
    this.viewContainer.clear();

    this.commonDataService.getRoles().subscribe(
      (values: ICommonValue[]) => {
        values.forEach((response: ICommonValue) => {
          this.viewContainer.createEmbeddedView(this.template, {
            $implicit: response,
          });
        });
      },
      (error) => {
        this.viewContainer.createEmbeddedView(this.template, {
          $implicit: {
            text: `Error loading roles`,
          } as ICommonValue,
        });
      },
    );
  }
}
