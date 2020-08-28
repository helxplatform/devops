import { TestBed } from '@angular/core/testing';

import { PreloadModuleService } from './preload-module.service';

describe('PreloadModuleService', () => {
  let service: PreloadModuleService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(PreloadModuleService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
