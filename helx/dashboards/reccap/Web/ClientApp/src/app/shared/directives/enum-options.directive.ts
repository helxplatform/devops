import { Directive, ViewContainerRef, TemplateRef, Input, OnChanges } from '@angular/core';
import { MatOption } from '@angular/material/core';
import { CommonDataService } from '@core/services/common-data.service';
import { ICommonValue } from '@core/models/common-value';
import { MatFormFieldControl } from '@angular/material/form-field';
import { MatSelect } from '@angular/material/select';

@Directive({
  selector: '[enums]',
})
export class EnumOptionsDirective implements OnChanges {
  @Input('enums') enumName!: string;
  @Input('enumsSelected-value') selectedValue!: string;

  constructor(
    private matFormFieldControl: MatFormFieldControl<MatSelect>,
    private commonDataService: CommonDataService,
    private template: TemplateRef<any>,
    private viewContainer: ViewContainerRef,
  ) {
    if (!matFormFieldControl) {
      throw new Error('EnumOptionsDirective can be used only inside MatSelect');
    }
  }

  ngOnChanges(): void {
    const value = this.selectedValue || this.matFormFieldControl.ngControl?.value;
    this.viewContainer.clear();

    this.commonDataService.getEnums(this.enumName).subscribe(
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
            text: `Error loading '${this.enumName}'`,
          } as ICommonValue,
        });
      },
    );
  }
}
