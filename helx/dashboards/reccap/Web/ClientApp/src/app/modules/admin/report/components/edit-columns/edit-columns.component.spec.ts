import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { EditColumnsComponent } from './edit-columns.component';

describe('EditColumnsComponent', () => {
  let component: EditColumnsComponent;
  let fixture: ComponentFixture<EditColumnsComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ EditColumnsComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(EditColumnsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
