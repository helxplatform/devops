import { Directive, ViewContainerRef, TemplateRef, Input, OnChanges } from '@angular/core';
import { MatOption } from '@angular/material/core';
import { CommonDataService } from '@core/services/common-data.service';
import { ICommonValue } from '@core/models/common-value';
import { MatFormFieldControl } from '@angular/material/form-field';
import { MatSelect } from '@angular/material/select';

@Directive({
  selector: '[category-types]',
})
export class CategoryTypesDirective implements OnChanges {
  @Input('category-types') categoryName!: string;
  @Input('category-typesSelected-value') selectedValue!: string;
  @Input('category-typesParent-type') parentTypeId!: string;

  constructor(
    private matFormFieldControl: MatFormFieldControl<MatSelect>,
    private commonDataService: CommonDataService,
    private template: TemplateRef<any>,
    private viewContainer: ViewContainerRef,
  ) {
    if (!matFormFieldControl) {
      throw new Error('CategoryTypesDirective can be used only inside MatSelect');
    }
  }

  ngOnChanges(): void {
    const value = this.selectedValue || this.matFormFieldControl.ngControl?.value;
    this.viewContainer.clear();

    let options = {};
    if (this.parentTypeId) {
      options = { ...options, parentType: this.parentTypeId };
    }
    if (value) {
      options = { ...options, id: value };
    }

    this.commonDataService.getCategoryTypes(this.categoryName, options).subscribe(
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
            text: `Error loading '${this.categoryName}'`,
          } as ICommonValue,
        });
      },
    );
  }
}
